#!/usr/bin/env python3
import asyncio
import configparser
import csv
import datetime
import errno
import json
import logging
import os
import re
import socket
import ssl
import subprocess
from contextlib import asynccontextmanager
from os.path import exists
from pathlib import Path
from pwd import getpwnam
from stat import S_IRGRP, S_IRWXO, S_IRWXU, S_IXGRP

import anyio
import httpx
import psutil
import uvicorn
from alise import Alise
from fastapi import FastAPI, HTTPException, Request
from fastapi.security import HTTPBearer
from flaat.config import AccessLevel
from flaat.fastapi import Flaat
from flaat.requirements import HasSubIss
from starlette.background import BackgroundTask
from starlette.responses import StreamingResponse
from vo_mapping import VOMapping

config = configparser.ConfigParser(interpolation=configparser.ExtendedInterpolation())
config.read("/etc/teapot/config.ini")


# lifespan function for startup and shutdown functions
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    This function is designed to manage the lifespan of a FastAPI application
    instance. It performs certain actions during startup and shutdown of the
    application.

    Parameters:
    - `app` (FastAPI): The FastAPI application instance.

    Actions during startup:
    - Checks if the JSON file for storing sessions exists, and creates it if it
      doesn't.
    - Sets up a task loop for stopping expired instances.

    Actions during shutdown:
    - Stops all active webdav instances associated with session handles.
    - Deletes the session store file if it exists.
    - Closes the HTTP client.

    Note: This function is typically used as a lifespan event handler for the
    FastAPI application.
    """
    await load_session_state()
    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
    loop.create_task(stop_expired_instances())

    yield

    # everything after the yield should be executed after shutdown
    handles = app.state.session_state.keys()
    for k in list(handles):
        await _stop_webdav_instance(k, sw_state, sw_condition)
    session_store_path = Path(SESSION_STORE_PATH)
    if session_store_path.exists():
        session_store_path.unlink()

    await client.aclose()


# create fastAPI app and initialize flaat options
app = FastAPI(lifespan=lifespan)
flaat = Flaat()
security = HTTPBearer()

flaat.set_access_levels([AccessLevel("user", HasSubIss())])

flaat.set_trusted_OP_list(config["Teapot"]["trusted_OP"].split(", "))

# logging
logging.basicConfig(
    filename=config["Teapot"]["log_location"],
    encoding="utf-8",
    filemode="a",
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%d %H:%M",
    level=config["Teapot"]["log_level"],
)
logger = logging.getLogger(__name__)

SESSION_STORE_PATH = os.environ.get(
    "TEAPOT_SESSIONS", config["Teapot"]["sessions_path"]
)
APP_NAME = config["Teapot"]["APP_NAME"]
# Teapot's hostname
teapot_host = config["Teapot"]["hostname"]
# Teapot's port
teapot_port = config.getint("Teapot", "port")
# one less than the first port that is going to be used by any storm webdav
# instance, should be above 1024, as all ports below this are privileged and
# normal users will not be able to use them to run services.
STARTING_PORT = config.getint("Teapot", "STARTING_PORT")
# toggle restarting teapot without deleting saved state and without
# terminating running webdav instances.
RESTART = config.getboolean("Teapot", "TEAPOT_RESTART")
# instance timeout, instances are deleted after this time without being accessed.
# default: 10 minutes
INSTANCE_TIMEOUT_SEC = config.getint("Teapot", "INSTANCE_TIMEOUT_SEC")
# interval between instance timeout checks in stop_expired_instances
# default: 3 minutes
CHECK_INTERVAL_SEC = config.getint("Teapot", "CHECK_INTERVAL_SEC")
# Max amount of attempts for Teapot to reach a particular Storm-webdav server
STARTUP_TIMEOUT = config.getint("Teapot", "STORM_WEBDAV_STARTUP_TIMEOUT")
# standard mode for file creation, currently rwxr-x---
# directories and files are created with the corresponding os.mkdir, os.chmod,
# os.chown commands.
# those are using the bit patterns provided with the "stat" module as below,
# combining them happens via bitwise OR
# TO DO: find a way to not have to use rwx for others!
STANDARD_MODE = S_IRWXU | S_IRGRP | S_IXGRP | S_IRWXO
# session state is kept in this global dict for each username as primary key
# data stored within each subdict is
# pid, port, created_at, last_accessed
app.state.session_state = {}
# lock for the state. any write operation on the state should only be done
# in an "async with app.state_lock:" environment.
app.state.state_lock = anyio.Lock()
# state of the storm webdav servers
sw_state: dict[str, str] = {}
# lock for the state of the storm webdav servers
sw_condition = anyio.Condition()
# user identity mapping method
mapping = config["Teapot"]["mapping"]

context = ssl.create_default_context()
context.load_verify_locations(cafile=config["Teapot"]["Teapot_CA"])
client = httpx.AsyncClient(verify=context)


async def makedir_chown_chmod(dir, mode=STANDARD_MODE):
    """
    This function creates a directory if it does not exist and sets its
    permissions using `os.mkdir` and `os.chmod` functions respectively.

    Parameters:
    - `dir` (str): The directory path to be created.
    - `mode` (int, optional): The permissions mode to be set for the
       directory. Defaults to `STANDARD_MODE`.

    Actions:
    - Checks if the directory exists, and if not, creates it.
    - Sets the permissions of the directory to the specified mode.
    - Logs an error message if the directory creation or permissions setting
     fails.

    Returns:
    - None
    """

    if not exists(dir):
        try:
            os.mkdir(dir)
        except FileExistsError:
            logger.error(
                "Creation of a directory %s is not possible.", dir, exc_info=True
            )
            logger.error("This directory already exists.")
        try:
            os.chmod(dir, mode)
        except OSError:
            logger.error(
                "Could not change access permissions of a directory %s to %s.",
                dir,
                mode,
                exc_info=True,
            )


async def _create_user_dirs(username, port, sub):
    config_update = configparser.ConfigParser()
    config_update.add_section("Current-user")
    config_update.set("Current-user", "username", str(username))
    config_update.set("Current-user", "port", str(port))
    config_update.set("Current-user", "port1", str(port + 1))
    with open("/etc/teapot/user_config.ini", "w", encoding="utf-8") as configfile:
        config_update.write(configfile)
    config.read(["/etc/teapot/config.ini", "/etc/teapot/user_config.ini"])
    # need to create
    # - /var/lib/APP_NAME/user-username
    # - /var/lib/APP_NAME/user-username/log
    # - /var/lib/APP_NAME/user-username/config
    # - /var/lib/APP_NAME/user-username/sa.d
    # - /var/lib/APP_NAME/user-username/tmp
    # need to check files for existence
    # - /etc/APP_NAME/storage-areas

    logger.debug("creating user configuration directories")

    app_dir = f"/var/lib/{APP_NAME}"
    if not exists(app_dir):
        logger.error("Parent %s configuration directory does not exist.", APP_NAME)
        return False

    uid = getpwnam(username).pw_uid
    gid = getpwnam(username).pw_gid
    logger.debug("user %s has uid %d and gid %d", username, uid, gid)

    user_dir = f"{app_dir}/user-{username}"

    user_tmp_dir = f"{user_dir}/tmp"  # trunk-ignore(bandit/B108)
    user_sa_d_dir = f"{user_dir}/sa.d"
    user_config_dir = f"{user_dir}/config"

    dirs_to_create = [
        user_dir,
        user_tmp_dir,
        user_sa_d_dir,
        user_config_dir,
    ]
    for dir in dirs_to_create:
        await makedir_chown_chmod(dir)

    # Automated creation of the user storage_area.properties files
    i = 1
    while config.has_section(f"STORAGE_AREA_{i}"):
        try:
            SA_name = config[f"STORAGE_AREA_{i}"]["name"]
            SA_rootPath = config[f"STORAGE_AREA_{i}"]["rootPath"]
            SA_access_point = config[f"STORAGE_AREA_{i}"]["accessPoint"]
            SA_orgs = config[f"STORAGE_AREA_{i}"]["IdP_URL"]
        except KeyError as e:
            logger.error(
                "Missing key for the STORAGE_AREA_%d in configuration: %s", i, e
            )
            break

        with open(
            f"/etc/{APP_NAME}/storage_area.properties.template",
            "r",
            encoding="utf-8",
        ) as prop:
            template = prop.read()

        replacements = {
            "name=": f"name={SA_name}",
            "rootPath=": f"rootPath={SA_rootPath}",
            "accessPoints=": f"accessPoints={SA_access_point}",
            "orgs=": f"orgs={SA_orgs}",
        }
        for old, new in replacements.items():
            template = template.replace(old, new)

        SA_properties_path = f"{user_sa_d_dir}/{SA_name}.properties"
        if not os.path.exists(SA_properties_path):
            with open(SA_properties_path, "w", encoding="utf-8") as properties:
                properties.write(template)
            os.chmod(SA_properties_path, STANDARD_MODE)
            logger.debug("Created properties file for storage area: %s", SA_name)
        else:
            logger.debug(
                "Skipped creation:"
                + "properties file already exists for storage area %s (%s)",
                SA_name,
                SA_properties_path,
            )

        i += 1

    # Automated creation of the user application.yml files
    app_ym_path = f"{user_config_dir}/application.yml"

    if not os.path.exists(app_ym_path):
        with open(
            f"/etc/{APP_NAME}/application.yml.template", "r", encoding="utf-8"
        ) as prop:
            raw_template = prop.read()

        i = 1
        first = True

        while config.has_section(f"STORAGE_AREA_{i}"):
            try:
                SA_name = config[f"STORAGE_AREA_{i}"]["name"]
                IdP_name = config[f"STORAGE_AREA_{i}"]["IdP_name"]
                IdP_URL = config[f"STORAGE_AREA_{i}"]["IdP_URL"]
            except KeyError as e:
                logger.error(
                    "Missing key for STORAGE_AREA_%d in configuration: %s", i, e
                )
                break

            logger.debug("Processing storage area '%s' (section %d)", SA_name, i)

            template = raw_template

            replacements = {
                "name:": f"name: {IdP_name}",
                "issuer:": f"issuer: {IdP_URL}",
                "sa:": f"sa: {SA_name}",
                "iss:": f"iss: {IdP_URL}",
                "type: jwt-subject": (
                    "type: jwt-issuer" if mapping == "VO" else "type: jwt-subject"
                ),
                "sub:": ("" if mapping == "VO" else f"sub: {sub}"),
            }
            for old, new in replacements.items():
                template = template.replace(old, new)

            if first:
                # Write the full template for the first storage area
                with open(app_ym_path, "w", encoding="utf-8") as yml:
                    yml.write(template)
                first = False
            else:
                # Append only from the '- sa:' block onward
                with open(app_ym_path, "a", encoding="utf-8") as yml:
                    sa_block_started = False
                    for line in template.splitlines():
                        if not sa_block_started and line.strip().startswith("- sa:"):
                            sa_block_started = True
                        if sa_block_started:
                            yml.write(line + "\n")

            i += 1

        os.chmod(app_ym_path, STANDARD_MODE)
        logger.debug(
            "Created application.yml file for the authorization to the storage areas"
        )
    else:
        logger.debug("application.yml already exists; skipping initial creation.")

    return True


async def _create_user_env(username, port):
    os.environ["STORM_WEBDAV_JVM_OPTS"] = config["Storm-webdav"]["JVM_OPTS"]
    os.environ["STORM_WEBDAV_SERVER_ADDRESS"] = config["Storm-webdav"]["SERVER_ADDRESS"]
    os.environ["STORM_WEBDAV_HTTPS_PORT"] = config["Storm-webdav"]["HTTPS_PORT"]
    os.environ["STORM_WEBDAV_HTTP_PORT"] = config["Storm-webdav"]["HTTP_PORT"]
    os.environ["STORM_WEBDAV_CERTIFICATE_PATH"] = config["Storm-webdav"][
        "CERTIFICATE_PATH"
    ]
    os.environ["STORM_WEBDAV_PRIVATE_KEY_PATH"] = config["Storm-webdav"][
        "PRIVATE_KEY_PATH"
    ]
    os.environ["STORM_WEBDAV_TRUST_ANCHORS_DIR"] = config["Storm-webdav"][
        "TRUST_ANCHORS_DIR"
    ]
    os.environ["STORM_WEBDAV_TRUST_ANCHORS_REFRESH_INTERVAL"] = config["Storm-webdav"][
        "TRUST_ANCHORS_REFRESH_INTERVAL"
    ]
    os.environ["STORM_WEBDAV_MAX_CONNECTIONS"] = config["Storm-webdav"][
        "MAX_CONNECTIONS"
    ]
    os.environ["STORM_WEBDAV_MAX_QUEUE_SIZE"] = config["Storm-webdav"]["MAX_QUEUE_SIZE"]
    os.environ["STORM_WEBDAV_CONNECTOR_MAX_IDLE_TIME"] = config["Storm-webdav"][
        "CONNECTOR_MAX_IDLE_TIME"
    ]
    os.environ["STORM_WEBDAV_SA_CONFIG_DIR"] = config["Storm-webdav"]["SA_CONFIG_DIR"]
    os.environ["STORM_WEBDAV_JAR"] = config["Storm-webdav"]["JAR"]
    os.environ["STORM_WEBDAV_LOG"] = config["Storm-webdav"]["LOG"]
    os.environ["STORM_WEBDAV_OUT"] = config["Storm-webdav"]["OUT"]
    os.environ["STORM_WEBDAV_ERR"] = config["Storm-webdav"]["ERR"]
    os.environ["STORM_WEBDAV_LOG_CONFIGURATION"] = config["Storm-webdav"][
        "LOG_CONFIGURATION"
    ]
    os.environ["STORM_WEBDAV_ACCESS_LOG_CONFIGURATION"] = config["Storm-webdav"][
        "ACCESS_LOG_CONFIGURATION"
    ]
    os.environ["STORM_WEBDAV_VO_MAP_FILES_ENABLE"] = config["Storm-webdav"][
        "VO_MAP_FILES_ENABLE"
    ]
    os.environ["STORM_WEBDAV_VO_MAP_FILES_REFRESH_INTERVAL"] = config["Storm-webdav"][
        "VO_MAP_FILES_REFRESH_INTERVAL"
    ]
    os.environ["STORM_WEBDAV_TPC_MAX_CONNECTIONS"] = config["Storm-webdav"][
        "TPC_MAX_CONNECTIONS"
    ]
    os.environ["STORM_WEBDAV_TPC_VERIFY_CHECKSUM"] = config["Storm-webdav"][
        "TPC_VERIFY_CHECKSUM"
    ]
    os.environ["STORM_WEBDAV_REQUIRE_CLIENT_CERT"] = config["Storm-webdav"][
        "REQUIRE_CLIENT_CERT"
    ]
    os.environ["STORM_WEBDAV_TPC_USE_CONSCRYPT"] = config["Storm-webdav"][
        "TPC_USE_CONSCRYPT"
    ]

    return True


async def _remove_user_env():
    keys_to_remove = [key for key in os.environ if key.startswith("STORM_WEBDAV_")]
    for key in keys_to_remove:
        del os.environ[key]


async def _start_webdav_instance(username, port, sub):
    res = await _create_user_dirs(username, port, sub)
    if not res:
        logger.error("could not create user dirs for %s", username)
        return False

    logger.debug("creating user env variables to pass to storm-webdav")
    res = await _create_user_env(username, port)
    if not res:
        logger.error("could not create user env for %s", username)
        return False

    env_pass = [key for key in os.environ if key.startswith("STORM_WEBDAV_")]

    # starting subprocess with all necessary options now.
    # using os.setsid() as a function handle before execution should execute
    # the process in it's own process group such that it can be managed on its own.

    logger.debug("trying to start process for user %s", username)
    loc = f"/var/lib/{APP_NAME}/user-{username}/config/application.yml"
    # trunk-ignore(bandit/B108)
    cmd = f"sudo --preserve-env={','.join(env_pass)} -u {username} \
    /usr/bin/java -jar $STORM_WEBDAV_JAR $STORM_WEBDAV_JVM_OPTS \
    -Djava.io.tmpdir=/var/lib/{APP_NAME}/user-{username}/tmp \
    -Dlogging.config=$STORM_WEBDAV_LOG_CONFIGURATION \
    --spring.config.additional-location=optional:file:{loc} \
     1>$STORM_WEBDAV_OUT 2>$STORM_WEBDAV_ERR &"

    logger.debug("cmd=%s", cmd)
    p = subprocess.Popen(
        cmd, shell=True, preexec_fn=os.setsid  # trunk-ignore(bandit/B602)
    )  # GitHub Issue #30

    # wait for it...
    await anyio.sleep(1)
    # poll the process to get rid of the zombiefied subprocess attached to teapot
    p.poll()

    # get rid of additional whitespace, trailing "&" and output redirects from
    # cmdline, expand env vars
    cmd = " ".join(cmd.split())[:-1]
    cmd = " ".join(cmd.split(","))
    cmd = os.path.expandvars(cmd)
    cmd = cmd.split("1>")[0].rstrip()
    # we can remove all env vars for the user process from teapot now as they
    # were given to the forked process as a copy
    await _remove_user_env()

    # get the process pid for terminating it later.
    kill_proc = await _get_proc(cmd)

    # check process status and store the handle.
    if kill_proc.status() in [psutil.STATUS_RUNNING, psutil.STATUS_SLEEPING]:
        logger.debug(
            "Instance for user %s is running under PID %d",
            username,
            kill_proc.pid,
        )
        return kill_proc.pid
    else:
        logger.error(
            "Instance for user %s under PID %d could not be started",
            username,
            kill_proc.pid,
        )
        # if there was a returncode, we wait for the process and terminate it.
        kill_proc.wait()
        return None


async def _get_proc(cmd):
    # here we are simply looking through all processes and try to find a
    # match for the full command that was issued to start the instance in
    # question. then return the process handle. it should contain the process
    # that is running as root and forked the storm instance for the user
    # themselves. looking through all processes seems a bit of an overkill but
    # at the moment this is the only halfway surefire method to accomplish this
    #  task. shamelessly stolen from
    # https://codereview.stackexchange.com/questions/183091/start-a-sub-process-with-sudo-as-head-of-new-process-group-kill-it-after-time
    for pid in psutil.pids():
        proc = psutil.Process(pid)
        if cmd == " ".join(proc.cmdline()):
            logger.debug("PID for the started storm-webdav server found: %d", pid)
            return proc
    raise RuntimeError("process with full command " + cmd + "does not exist.")


async def _stop_webdav_instance(username, state, condition):
    async with condition:
        if state[username] == "RUNNING":
            state[username] = "STOPPING"
            condition.notify()
        logger.info("Stopping storm-webdav server for user %s", username)
        logger.debug(
            "The state of the storm-webdav server for user %s is %s",
            username,
            state[username],
        )

        async with app.state.state_lock:
            try:
                session = app.state.session_state.pop(username)
                await save_session_state()
            except KeyError:
                logger.error(
                    "Can't delete the session state for user %s, it doesn't exist",
                    username,
                )
                return -1

    pid = session.get("pid")
    if pid:
        try:
            kill_proc = subprocess.Popen(
                f"sudo kill {pid}", shell=True  # trunk-ignore(bandit)
            )  # GitHub Issue #30
            kill_exit_code = kill_proc.wait()
            if kill_exit_code != 0:
                logger.warning("Could not kill process with PID %d.", pid)
                exit_code = kill_exit_code
            else:
                logger.debug("Successfully killed process with PID %d.", pid)
                exit_code = 0
                async with condition:
                    if state[username] == "STOPPING":
                        state[username] = "NOT RUNNING"
                        condition.notify()
            logger.debug(
                "The state of the storm-webdav server for user %s is %s",
                username,
                state[username],
            )

        except subprocess.CalledProcessError as e:
            logger.error(
                "Exception occurred while trying to kill process with PID %d: %s.",
                pid,
                e,
            )
            exit_code = -1
    else:
        logger.info("Webdav instance for user %s was terminated.", username)
        exit_code = -1

    return exit_code


async def stop_expired_instances():
    """
    Checks for expired instances still running.

    While running, this function continuously checks for expired instances
    every `CHECK_INTERVAL_SEC` seconds. It acquires the lock for both
    'users' and 'user_dict' to ensure thread safety when accessing the
    session state. For each user, it calculates the time difference between
    the current time and the last accessed time. If this difference exceeds
    the `INSTANCE_TIMEOUT_SEC`, it stops the corresponding WebDAV instance.
    It logs relevant information such as lock acquisition, instance
    termination, and errors encountered during the process.
    """
    while True:
        await asyncio.sleep(CHECK_INTERVAL_SEC)
        async with app.state.state_lock:
            users = list(app.state.session_state.keys())
        now = datetime.datetime.now()
        for user in users:
            async with app.state.state_lock:
                user_dict = app.state.session_state.get(user, None)
            if user_dict is not None:
                last_accessed = user_dict.get("last_accessed", None)
                if last_accessed is not None:
                    diff = now - datetime.datetime.fromisoformat(last_accessed)
                    if diff.seconds >= INSTANCE_TIMEOUT_SEC:
                        res = await _stop_webdav_instance(user, sw_state, sw_condition)
                        if res != 0:
                            logger.error(
                                "Instance for user %s exited with code %s.",
                                user,
                                str(res),
                            )
                        else:
                            logger.info(
                                "Inactive instance for user %s has been terminated",
                                user,
                            )
                else:
                    logger.error(
                        "Session for user %s does not have the property last_accessed",
                        user,
                    )
            else:
                logger.error(
                    "No session object for user %s in session_state.",
                    user,
                )


async def _find_usable_port_no():
    used_ports = []
    async with app.state.state_lock:
        users = app.state.session_state.keys()
        if users:
            for user in users:
                tmp_port = app.state.session_state[user].get("port", None)
                logger.debug(
                    "user %s has an instance running on port %d",
                    user,
                    tmp_port,
                )
                used_ports.append(tmp_port)
        else:
            # if there are no instances running yet, we want the ports to
            # start from 32400
            logger.debug("no port in use by teapot, using %d", STARTING_PORT)
            used_ports = [STARTING_PORT]

        if None not in used_ports:
            max_used = max(used_ports) + 1
            logger.debug("testing port %d", max_used)
            port = await _test_port(max_used)
        else:
            logger.error(
                "Missing port number for running instances. "
                + "Can not determine fitting port number."
            )
            port = None
        return port


async def _test_port(port):
    """
    This function is recursively searching for an open port.
    """
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        logger.debug("binding to port %d for testing", port)
        s.bind(("127.0.0.1", port))
    except socket.error as e:
        if e.errno == errno.EADDRINUSE:
            logger.debug("Port %d is already in use", port)
            port = await _test_port(port + 1)
        else:
            logger.error("Error while testing ports: %s", e)
            port = await _test_port(port + 1)
    finally:
        s.close()
    return port


async def save_session_state():
    """
    Saves the current session state to a JSON file.

    Acquires the application's state lock to ensure thread safety during the
    file write operation. It opens the session store file located at
    `SESSION_STORE_PATH` and writes the current session staten as a JSON object.
    The encoding used for writing is UTF-8.
    """
    with open(SESSION_STORE_PATH, "w", encoding="utf-8") as f:
        json.dump(app.state.session_state, f)


async def load_session_state():
    """
    Loads the session state from a JSON file into the application's state.

    Acquires the application's state lock to ensure thread safety during file
    read operations. Checks if the session store file specified by
    `SESSION_STORE_PATH` exists. If the file exists, it attempts to read the
    JSON data from the file and assign it to `app.state.session_state`. If the
    file does not exist or encounters a decoding error, it initializes
    `app.state.session_state` as an empty dictionary.
    """
    async with app.state.state_lock:
        if not exists(SESSION_STORE_PATH):
            app.state.session_state = {}
            await save_session_state()
        else:
            with open(SESSION_STORE_PATH, "r", encoding="utf-8") as f:
                app.state.session_state = json.load(f)


async def _map_fed_to_local(sub, iss, eduperson_entitlement):
    """
    This function returns the local username for a federated user or None.
    The local username can be retrieved from a mapping file on the local file
    system or through ALISE (Account Linking Service). Alternatively, mapping
    can be done based on the user's VO membership to a local group account.

    If using a mapping file, it should have a format:
    local-username federated-sub-claim

    The file should be without headers. Only the first hit for a federated sub
    claim is returned. Thus, it is possible to match multiple subs to a single
    local username but not the other way around.

    ALISE implements the concept of site-local account linking. For this a user
    can log in with one local account and with any number of supported external
    accounts. For more information on ALISE check https://github.com/m-team-kit/alise

    VO membership based mapping should be defined in the configi.ini file, where
    group_membership information and username of the local group account should
    be provided.
    """
    logger.debug("For the user's identity mapping, %s method is used", mapping)
    if mapping == "FILE":
        mapping_file = config["Teapot"]["mapping_file"]
        if not exists(mapping_file):
            logger.error(
                "%s does not exist. It should consist of two variables per user: "
                "username and subject claim separated by a single space.",
                mapping_file,
            )
            return None

        with open(mapping_file, "r", encoding="utf-8") as mapping_file_obj:
            mappingreader = csv.reader(mapping_file_obj, delimiter=" ")
            for row in mappingreader:
                if row[1] == sub:
                    if not row[0]:
                        logger.error("local user identity is unknown")
                        return None
                    logger.info("local user identity is %s", row[0])
                    return row[0]

            raise RuntimeError(f"The local user for sub claim {sub} does not exist")

    elif mapping == "ALISE":
        alise_instance = Alise()
        local_username = alise_instance.get_local_username(sub, iss)
        if not local_username:
            raise RuntimeError(
                "Could not determine user's local identity."
                + "Mapping for subject claim %s does not exist",
                sub,
            )
        else:
            logger.info("local user identity is %s", local_username)
        return local_username
    elif mapping == "VO":
        VO_membership = VOMapping(eduperson_entitlement)
        username = VO_membership.get_local_username(sub)
        if not username:
            raise RuntimeError(
                "User with sub %s has no matching VO membership; "
                "cannot determine local username." % sub
            )
        return username
    else:
        logger.error("The identity mapping method information is missing or incorrect.")
        return None


async def storm_webdav_state(state, condition, sub, iss, eduperson_entitlement):
    """
    This function gets the mapping for the federated user from the sub-claim to the
    user's local identity. With this local identity, it manages the state of the
    storm-webdav instance for that user. There are four possible states for a
    storm-webdav instance: STARTING, RUNNING, STOPPING, NOT_RUNNING. The default
    state is NOT_RUNNING. Transition between different states is triggered by an
    incomming request or by storm-webdav instance reaching the inactivity treshold.
    """
    user = await _map_fed_to_local(sub, iss, eduperson_entitlement)

    should_start_sw = False
    logger.info("Assessing the state of the storm webdav instance for user %s", user)

    async with condition:
        if user not in state:
            state[user] = "NOT RUNNING"
        if state[user] == "NOT RUNNING":
            logger.info(
                "Currently, there is no storm webdav instance running for user %s",
                user,
            )

        logger.debug(
            "The state of the storm-webdav server for user %s is %s", user, state[user]
        )

        while not (state[user] == "RUNNING"):
            if state[user] == "NOT RUNNING":
                state[user] = "STARTING"
                condition.notify()
                should_start_sw = True
                logger.info("Storm-webdav instance for user %s is starting", user)
                logger.debug(
                    "The state of the storm-webdav server for user %s is %s",
                    user,
                    state[user],
                )
                break
            elif state[user] == "RUNNING":
                async with app.state.state_lock:
                    app.state.session_state[user][
                        "last_accessed"
                    ] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                    await save_session_state()
                should_start_sw = False
                logger.debug(
                    "Storm webdav instance for user %s is already running", user
                )
                logger.debug(
                    "The state of the storm-webdav server for user %s is %s",
                    user,
                    state[user],
                )
            else:
                await condition.wait()

    if should_start_sw:
        port = await _find_usable_port_no()
        if user is None:
            async with condition:
                state[user] = "NOT RUNNING"
            raise ValueError(
                "No valid user provided. The storm-webdav will NOT be started."
            )
        pid = await _start_webdav_instance(user, port, sub)

        if not pid:
            async with condition:
                if state[user] == "STARTING":
                    state[user] = "NOT RUNNING"
                    condition.notify()
                async with app.state.state_lock:
                    app.state.session_state[user] = {
                        "pid": None,
                        "port": -1,
                        "created_at": None,
                        "last_accessed": datetime.datetime.now().strftime(
                            "%Y-%m-%d %H:%M:%S"
                        ),
                    }
                    await save_session_state()
            logger.error(
                "Something went wrong while starting instance for user %s.",
                user,
            )
            logger.debug(
                "The state of the storm-webdav server for user %s is %s",
                user,
                state[user],
            )
            return -1

        running = False
        loops = 0
        while not running:
            await anyio.sleep(1)
            if loops >= STARTUP_TIMEOUT:
                logger.debug(
                    "The webdav instance for user %s is not reachable after %d tries.",
                    user,
                    STARTUP_TIMEOUT,
                )
                async with condition:
                    if state[user] == "STARTING":
                        state[user] = "NOT RUNNING"
                    async with app.state.state_lock:
                        app.state.session_state.pop(user)
                        await save_session_state()
                    logger.debug("The unresponsive webdav instance is removed.")
                    return None, -1, user
            try:
                context1 = ssl.create_default_context()
                context1.load_verify_locations(
                    cafile=config["Storm-webdav"]["Storm-webdav_CA"]
                )
                resp = httpx.get(
                    "https://"
                    + config["Storm-webdav"]["SERVER_ADDRESS"]
                    + ":"
                    + str(port)
                    + "/",
                    verify=context1,
                )
                if resp.status_code >= 200:
                    running = True
            except httpx.ConnectError:
                loops += 1
                logger.debug(
                    "Waiting for the webdav instance to start. This is check %d/%d.",
                    loops,
                    STARTUP_TIMEOUT,
                )

        async with condition:
            if state[user] == "STARTING":
                state[user] = "RUNNING"
            async with app.state.state_lock:
                app.state.session_state[user] = {
                    "pid": pid,
                    "port": port,
                    "created_at": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                    "last_accessed": datetime.datetime.now().strftime(
                        "%Y-%m-%d %H:%M:%S"
                    ),
                }
                await save_session_state()
            condition.notify()
            logger.info(
                "Storm-webdav instance for user %s is now running on port %d",
                user,
                port,
            )
            logger.debug(
                "The state of the storm-webdav server for user %s is %s",
                user,
                state[user],
            )

        return None, port, user

    else:
        async with condition:
            async with app.state.state_lock:
                port = app.state.session_state[user].get("port")
            logger.info(
                "Storm-webdav instance for user %s is already running on port %d",
                user,
                port,
            )
        return None, port, user


async def rewrite_response_headers(
    headers, from_host, from_port, to_host, to_port, skip_content_length: bool = False
):
    """Rewrite headers that contain URLs pointing to the internal service"""
    rewritten_headers = {}

    # Headers that commonly contain URLs that need rewriting
    url_headers = {
        "location",
        "content-location",
        "uri",
        "content-base",
        "link",
        "refresh",
        "access-control-allow-origin",
    }

    from_url_base = f"https://{from_host}:{from_port}"
    to_url_base = f"https://{to_host}:{to_port}"

    for name, value in headers.items():
        header_name_lower = name.lower()

        # Skip Content-Length if content was modified, as it's now incorrect
        if skip_content_length and header_name_lower == "content-length":
            logger.debug("Skipping Content-Length header due to content modification")
            continue

        if header_name_lower in url_headers and isinstance(value, str):
            # Replace the internal URL with the external teapot URL
            rewritten_value = value.replace(from_url_base, to_url_base)
            rewritten_headers[name] = rewritten_value

            if rewritten_value != value:
                logger.debug(
                    "Rewrote header %s: %s -> %s",
                    name,
                    value,
                    rewritten_value,
                )
        else:
            rewritten_headers[name] = value

    return rewritten_headers


async def rewrite_webdav_content(content_stream, from_host, from_port, headers):
    """Rewrite URLs in WebDAV XML response content"""
    from_url_base = f"https://{from_host}:{from_port}"

    # Read all content from the stream
    content = b""
    async for chunk in content_stream:
        content += chunk

    # Determine charset
    encoding = get_encoding_from_headers(headers)

    try:
        # Decode, replace URLs, and re-encode
        content_str = content.decode(encoding)
        pattern = re.compile(rf"(<d:href>){re.escape(from_url_base)}(/[^<]*)</d:href>")

        def repl(match):
            return f"{match.group(1)}{match.group(2)}</d:href>"

        rewritten_content = pattern.sub(repl, content_str)

        if rewritten_content != content_str:
            logger.debug(
                "Rewrote WebDAV content URLs by removing prefix %s in <d:href> tags",
                from_url_base,
            )

        return rewritten_content.encode(encoding)
    except UnicodeDecodeError:
        # If decoding fails, return original content
        logger.warning("Failed to decode response content for URL rewriting")
        return content


async def create_content_stream(content_bytes):
    """Create an async generator that yields the given content"""
    yield content_bytes


def get_encoding_from_headers(headers):
    content_type = headers.get("content-type", "")
    match = re.search(r"charset=([^\s;]+)", content_type, re.IGNORECASE)
    if match:
        return match.group(1).strip()
    return "utf-8"  # default fallback


@app.api_route(
    "/{filepath:path}",
    methods=[
        "HEAD",
        "GET",
        "PUT",
        "POST",
        "DELETE",
        "PROPFIND",
        "MKCOL",
        "COPY",
        "MOVE",
    ],
)
@flaat.is_authenticated()
async def root(request: Request):
    """
    This function serves as the root endpoint for the application.
    It authenticates users using the flaat library and handles requests
    accordingly.

    Parameters:
        filepath (str): The path requested by the client.
        request (Request): The HTTP request object.
        response (Response): The HTTP response object.

    Returns:
        StreamingResponse: The response to the client's request.
    """
    # get data from userinfo endpoint
    user_infos = flaat.get_user_infos_from_request(request)
    if not user_infos:
        raise HTTPException(status_code=403)

    logger.info("user's sub is: %s", user_infos["sub"])
    sub = user_infos.get("sub", None)
    logger.debug("user's issuer is: %s", user_infos["iss"])
    iss = user_infos.get("iss", None)
    if mapping == "VO":
        logger.debug(
            "User's eduperson entitlements are %s", user_infos["eduperson_entitlement"]
        )
        eduperson_entitlement = user_infos.get("eduperson_entitlement", None)
    else:
        eduperson_entitlement = None

    if not sub:
        # if there is no sub, user can not be authenticated
        raise HTTPException(status_code=403)

    # user is valid, so check if a storm instance is running for this sub
    redirect_host, redirect_port, local_user = await storm_webdav_state(
        sw_state, sw_condition, sub, iss, eduperson_entitlement
    )

    if not redirect_host and not redirect_port:
        # no mapping between federated and local user identity found
        raise HTTPException(status_code=403)
    if redirect_port == -1:
        logger.info("no instance for user %s created...", local_user)
        raise HTTPException(status_code=500, detail="Problem supporting user.")
    if not redirect_port:
        # no port returned, should not happen
        raise HTTPException(
            status_code=500, detail="Failed to establish internal connection."
        )
    if not redirect_host:
        redirect_host = "localhost"
    logger.debug(
        "redirect_host: %s, redirect_port: %d",
        redirect_host,
        redirect_port,
    )
    logger.debug("request path: %s", request.url.path)

    redirect_url = f"https://{redirect_host}:{redirect_port}{request.url.path}"
    logger.debug("redirect url is %s.", redirect_url)

    forwarded_headers = [
        (k, v) for (k, v) in request.headers.raw if k.lower() != b"host"
    ]

    forward_req = client.build_request(
        request.method,
        redirect_url,
        headers=forwarded_headers,
        content=request.stream(),
        timeout=15.0,
    )
    forward_resp = await client.send(forward_req, stream=True)

    # Get the original request host and port for URL rewriting
    original_host = request.url.hostname
    original_port = request.url.port

    if request.method.upper() == "HEAD":
        rewritten_headers = await rewrite_response_headers(
            forward_resp.headers,
            redirect_host,
            redirect_port,
            original_host,
            original_port,
            skip_content_length=False,
        )
        rewritten_content_bytes = b""
    else:
        response_body = await forward_resp.aread()
        if request.method.upper() == "PROPFIND":
            rewritten_content_bytes = await rewrite_webdav_content(
                create_content_stream(response_body),
                redirect_host,
                redirect_port,
                forward_resp.headers,
            )
        else:
            rewritten_content_bytes = response_body

        # Calculate new content-length
        content_length = len(rewritten_content_bytes)

        rewritten_headers = await rewrite_response_headers(
            forward_resp.headers,
            redirect_host,
            redirect_port,
            original_host,
            original_port,
            skip_content_length=(request.method.upper() == "PROPFIND"),
        )

        # Remove any old content-length headers (case insensitive)
        rewritten_headers = {
            k: v for k, v in rewritten_headers.items() if k.lower() != "content-length"
        }
        rewritten_headers["Content-Length"] = str(content_length)

    return StreamingResponse(
        create_content_stream(rewritten_content_bytes),
        status_code=forward_resp.status_code,
        headers=rewritten_headers,
        background=BackgroundTask(forward_resp.aclose),
    )


def main():
    """
    This function starts the Teapot application using uvicorn with SSL
    encryption. It specifies the path to the SSL key and certificate files.

    Returns:
        None
    """
    cert = config["Teapot"]["Teapot_ssl_certificate"]
    key = config["Teapot"]["Teapot_ssl_key"]

    uvicorn.run(
        app,
        host=teapot_host,
        port=teapot_port,
        ssl_keyfile=key,
        ssl_certfile=cert,
    )


if __name__ == "__main__":
    main()
