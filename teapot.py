#!/usr/bin/env python3

import asyncio
import csv
import datetime
import errno
import json
import logging
import os
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
from fastapi import FastAPI, HTTPException, Request
from fastapi.security import HTTPBearer
from flaat.config import AccessLevel
from flaat.fastapi import Flaat
from flaat.requirements import HasSubIss
from starlette.background import BackgroundTask
from starlette.responses import StreamingResponse


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

    # everything before the "yield" should be executed at startup.
    await load_session_state()
    # function runs an async while True loop and checks for expired instances.
    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        loop.create_task(stop_expired_instances())

    yield

    # everything after the yield should be executed after shutdown
    handles = app.state.session_state.keys()
    for k in list(handles):
        await _stop_webdav_instance(k)
    session_store_path = Path(SESSION_STORE_PATH)
    if session_store_path.exists():
        session_store_path.unlink()

    await client.aclose()


# create fastAPI app and initialize flaat options
app = FastAPI(lifespan=lifespan)
flaat = Flaat()
security = HTTPBearer()

flaat.set_access_levels([AccessLevel("user", HasSubIss())])

flaat.set_trusted_OP_list(
    [
        "https://aai-demo.egi.eu/auth/realms/egi",
        "https://keycloak:8443/realms/test-realm",
    ]
)

# logging is important
LOGFILE = os.environ.get("TEAPOT_LOGFILE", "/var/log/teapot/teapot.log")
LOGLEVEL = os.environ.get("TEAPOT_LOGLEVEL", "INFO").upper()
logging.basicConfig(filename=LOGFILE, level=logging.getLevelName(LOGLEVEL))
logger = logging.getLogger(__name__)

# globals
# TO DO: load globals via config file on startup and reload on every run of
# stop_expired_instances, maybe rename function to "housekeeping" or the like.

SESSION_STORE_PATH = os.environ.get(
    "TEAPOT_SESSIONS", "/var/lib/teapot/webdav/teapot_sessions.json"
)
APP_NAME = "teapot"
# one less than the first port that is going to be used by any storm webdav
# instance, should be above 1024, as all ports below this are privileged and
# normal users will not be able to use them to run services.
STARTING_PORT = 32399
# toggle restarting teapot without deleting saved state and without
# terminating running webdav instances.
# N.B. will only consider the value set at startup of this app.
RESTART = os.environ.get("TEAPOT_RESTART", "False") == "True"
# instance timeout, instances are deleted after this time without being
# accessed.
# default: 10 minutes
INSTANCE_TIMEOUT_SEC = 600
# interval between instance timeout checks in stop_expired_instances
# default: 3 minutes
CHECK_INTERVAL_SEC = 180
# number of times that teapot will try to connect to a recently started
# instance
STARTUP_TIMEOUT = int(os.environ.get("TEAPOT_STARTUP_TIMEOUT", 30))
# standard mode for file creation, currently rwxr-x---
# directories and files are created with the corresponding os.mkdir, os.chmod,
# os.chown commands.
# those are using the bit patterns provided with the 'stat' module as below,
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

context = ssl.create_default_context()
context.load_verify_locations(
    cafile="/etc/pki/ca-trust/source/anchors/Teapot-testing.crt"
)
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

    Note: It's assumed that the `STANDARD_MODE` constant is defined elsewhere
    in the code.
    """
    if not exists(dir):
        try:
            os.mkdir(dir)
        except FileExistsError:
            # this info msg should never be triggered, right?
            logger.error(
                "Directory %s already exists, therefore this message \
                should not exist. Something is wrong...", dir)
        try:
            os.chmod(dir, mode)
        except OSError:
            logger.error("Could not chmod directory %s to %s.", dir, mode)


async def _create_user_dirs(username):
    # need to create
    # - /var/lib/APP_NAME/user-username
    # - /var/lib/APP_NAME/user-username/log
    # - /var/lib/APP_NAME/user-username/config
    # - /var/lib/APP_NAME/user-username/sa.d
    # - /var/lib/APP_NAME/user-username/tmp
    # need to check files for existence
    # - /etc/APP_NAME/storage-areas
    # - /etc/APP_NAME/user-mapping.csv

    logger.debug("creating user dirs...")
    config_dir = f"/etc/{APP_NAME}"
    if not exists(f"{config_dir}/storage-areas"):
        logger.error(
            "%s/storage-areas is missing. It should consist of two \
            variables per storage area: name of the storage area and root \
            path to the storage area's directory separated by a single \
            space.", config_dir)
        return False

    mapping_file = f"{config_dir}/user-mapping.csv"
    if not exists(mapping_file):
        logger.error(
            "%s does not exist. It should consist of two \
            variables per user: username and subject claim separated \
            by a single space.", mapping_file)
        return False

    app_dir = f"/var/lib/{APP_NAME}"
    if not exists(app_dir):
        logger.error("Parent %s directory does not exist.", APP_NAME)
        return False

    # creating user directories,
    # resort to explicit usage of chown and chmod
    # because the mask options might be ignored
    # on certain operating systems as per docs.

    uid = getpwnam(username).pw_uid
    gid = getpwnam(username).pw_gid
    logger.debug("user %s has uid %d and gid %d", username, uid, gid)

    user_dir = f"{app_dir}/user-{username}"

    user_log_dir = f"{user_dir}/log"
    user_tmp_dir = f"{user_dir}/tmp"
    user_sa_d_dir = f"{user_dir}/sa.d"
    user_config_dir = f"{user_dir}/config"

    dirs_to_create = [
        user_dir,
        user_log_dir,
        user_tmp_dir,
        user_sa_d_dir,
        user_config_dir,
    ]
    for dir in dirs_to_create:
        await makedir_chown_chmod(dir)

    with open(f"/usr/share/{APP_NAME}/storage_element.properties",
              "r", encoding="utf-8") as prop:
        second_part = prop.readlines()
    with open(f"{config_dir}/storage-areas", "r",
              encoding="utf-8") as storage_areas:
        for line in storage_areas:
            storage_area, path = line.split(" ")
            path_components = path.split("/")
            # check for different paths in storage-areas that need to be
            # corrected.
            if path_components[0] == "$HOME":
                path_components[0] = f"/home/{username}"
            path = os.path.join(*path_components)
            sa_properties_path = f"{user_sa_d_dir}/{storage_area}.properties"
            if not exists(sa_properties_path):
                with open(sa_properties_path, "w",
                          encoding="utf-8") as storage_area_properties:
                    first_part = f"name={storage_area}\nrootPath={path}" \
                        f"accessPoints=/{storage_area}_area\n\n"
                    storage_area_properties.write(first_part)
                    for line in second_part:
                        storage_area_properties.write(line)
                os.chmod(sa_properties_path, STANDARD_MODE)

    if not exists(f"{user_config_dir}/application.yml"):
        with open(f"{config_dir}/user-mapping.csv",
                  encoding="utf-8") as mapping:
            for line in mapping:
                if line.startswith(username):
                    sub = line.split(" ")[1]
                    break
        with open(f"{config_dir}/issuers", "r", encoding="utf-8") as issuers:
            issuers_part = issuers.readlines()
        with open("/usr/share/teapot/storage_authorizations", "r",
                  encoding="utf-8") as auths:
            authorization_part = "".join(auths.readlines())
        with open(f"{user_config_dir}/application.yml",
                  "a", encoding="utf-8") as application_yml:
            for line in issuers_part:
                application_yml.write(line)
            application_yml.write("storm:\n  authz:\n    policies:\n")
            with open(f"{config_dir}/storage-areas", "r",
                      encoding="utf-8") as storage_areas:
                for line in storage_areas:
                    storage_area = line.split(" ")[0]
                    application_yml.write(
                        authorization_part.replace("$sub", sub).replace(
                            "$storage_area", storage_area
                        )
                    )
    return True


async def _create_user_env(username, port):
    etc_dir = f"/etc/{APP_NAME}"
    user_dir = f"/var/lib/{APP_NAME}/user-{username}"
    storm_dir = f"/var/lib/{APP_NAME}/webdav"
    # make sure that .storm_profile is imported in the users shell init
    # by e.g. adding ". ~/.storm_profile" to the user's .bash_profile
    os.environ["STORM_WEBDAV_SERVER_ADDRESS"] = "localhost"
    os.environ["STORM_WEBDAV_HTTPS_PORT"] = f"{port}"
    os.environ["STORM_WEBDAV_HTTP_PORT"] = f"{port+1}"
    os.environ["STORM_WEBDAV_CERTIFICATE_PATH"] = f"{storm_dir}/localhost.crt"
    os.environ["STORM_WEBDAV_PRIVATE_KEY_PATH"] = f"{storm_dir}/localhost.key"
    os.environ["STORM_WEBDAV_TRUST_ANCHORS_DIR"] = "/etc/ssl/certs"
    os.environ["STORM_WEBDAV_TRUST_ANCHORS_REFRESH_INTERVAL"] = "86400"
    os.environ["STORM_WEBDAV_MAX_CONNECTIONS"] = "300"
    os.environ["STORM_WEBDAV_MAX_QUEUE_SIZE"] = "900"
    os.environ["STORM_WEBDAV_CONNECTOR_MAX_IDLE_TIME"] = "30000"
    os.environ["STORM_WEBDAV_SA_CONFIG_DIR"] = f"{user_dir}/sa.d"
    os.environ["STORM_WEBDAV_LOG"] = f"{user_dir}/log/server.log"
    os.environ["STORM_WEBDAV_ACCESS_LOG_CONFIGURATION"] = (
        f"{etc_dir}/logback-access.xml"
    )
    os.environ["STORM_WEBDAV_VO_MAP_FILES_ENABLE"] = "false"
    os.environ["STORM_WEBDAV_VO_MAP_FILES_REFRESH_INTERVAL"] = "21600"
    os.environ["STORM_WEBDAV_TPC_MAX_CONNECTIONS"] = "50"
    os.environ["STORM_WEBDAV_TPC_VERIFY_CHECKSUM"] = "false"
    os.environ["STORM_WEBDAV_REQUIRE_CLIENT_CERT"] = "false"
    os.environ["STORM_WEBDAV_TPC_USE_CONSCRYPT"] = "true"

    return True


async def _remove_user_env():
    keys_to_remove = [key for key in os.environ
                      if key.startswith("STORM_WEBDAV_")]
    for key in keys_to_remove:
        del os.environ[key]


async def _start_webdav_instance(username, port):
    res = await _create_user_dirs(username)
    if not res:
        logger.error("could not create user dirs for %s", username)
        return False

    logger.debug("creating user env...")
    res = await _create_user_env(username, port)
    if not res:
        logger.error("could not create user env for %s", username)
        return False

    env_pass = {key: value for key, value in os.environ.items()
                if key.startswith("STORM_WEBDAV_")}

    # starting subprocess with all necessary options now.
    # using os.setsid() as a function handle before execution should execute
    # the process in it's own process group
    # such that it can be managed on its own.

    logger.info("trying to start process for user %s", username)
    apppath = f"/var/lib/teapot/user-{username}/config/application.yml"
    cmd = ["sudo", "--preserve-env=" + ",".join(env_pass.keys()), "-u",
           username, "/usr/bin/java", "-jar",
           "/usr/share/java/storm-webdav/storm-webdav-server.jar",
           "-Xms2048m", "-Xmx2048m",
           "-Djava.security.egd=file:/dev/./urandom",
           f"-Djava.io.tmpdir=/var/lib/user-{username}/tmp",
           "-Dlogging.config=/etc/teapot/logback.xml",
           f"--spring.config.additional-location=optional:file:{apppath}"
           ]

    stdout_path = f"/var/lib/teapot/user-{username}/log/server.out"
    stderr_path = f"/var/lib/teapot/user-{username}/log/server.err"

    try:
        with open(stdout_path, "w", encoding="utf-8") as stdout_file, \
             open(stderr_path, "w", encoding="utf-8") as stderr_file:
            logger.info("cmd=%s", cmd)
            p = subprocess.Popen(cmd, start_new_session=True,
                                 stdout=stdout_file,
                                 stderr=stderr_file, env=env_pass)
    except subprocess.CalledProcessError as e:
        logger.error("Failed to start subprocess for user %s: %s", username,
                     str(e))
        return False

    # wait for it...
    await anyio.sleep(1)
    # poll the process to get rid of the zombiefied subprocess attached to
    # teapot
    p.poll()

    # we can remove all env vars for the user process from teapot now as they
    # were given to the forked process as a copy
    await _remove_user_env()

    # get the process pid for terminating it later.
    kill_proc = await _get_proc(cmd)

    # check process status and store the handle.
    if kill_proc.status() in [psutil.STATUS_RUNNING, psutil.STATUS_SLEEPING]:
        logger.debug(
            "start_webdav_instance: instance for user %s is running \
            under PID %d", username, kill_proc.pid)
        return kill_proc.pid
    else:
        logger.error(
            "_start_webdav_instance: instance for user %s could not \
            be started. pid was %d.", username, kill_proc.pid)
        # if there was a returncode, we wait for the process and terminate it.
        kill_proc.wait()
        return None


async def _get_proc(cmd):
    # Retry finding the process a few times with a small delay
    retries = 5
    delay = 1  # seconds

    if "--spring.config.additional-location" not in " ".join(cmd):
        raise RuntimeError(f"--spring.config.additional-location \
                           not found in cmd: {cmd}")

    target_cmd = " ".join(cmd[:cmd.index("--spring.config.additional-location"
                                         )])
    target_args = cmd[cmd.index("--spring.config.additional-location"):]

    for attempt in range(retries):
        for pid in psutil.pids():
            try:
                proc = psutil.Process(pid)
                cmdline = " ".join(proc.cmdline())
                if (target_cmd in cmdline and
                        all(arg in cmdline for arg in target_args)):
                    logger.info("PID found: %d", pid)
                    return proc
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue

        # If not found, wait a bit and retry
        logger.debug("Process not found, retrying... (%d/%d)", attempt + 1,
                     retries)
        await anyio.sleep(delay)

    # If still not found, log the command lines of all processes for debugging
    for pid in psutil.pids():
        try:
            proc = psutil.Process(pid)
            logger.debug("Process %d command line: %s", pid,
                         ' '.join(proc.cmdline()))
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue

    raise RuntimeError(f"process with full command {cmd} does not exist.")


async def _stop_webdav_instance(username):
    logger.info("Stopping webdav instance for user %s.", username)

    logger.debug(
        "_stop_webdav_instance: trying to acquire lock at %s",
        {datetime.datetime.now().isoformat()})
    async with app.state.state_lock:
        logger.debug(
            "_stop_webdav_instance: acquired lock at %s",
            {datetime.datetime.now().isoformat()})
        try:
            session = app.state.session_state.pop(username)
        except KeyError:
            logger.error(
                "_stop_webdav_instance: session state for user %s \
                  doesn't exist.", username)
            return -1

    # first naive workaround will be to just give sudo rights to teapot for
    # /usr/bin/kill
    # TO DO: find a safer way to accomplish this!
    # originally wanted to kill the process via os.killpg but the storm
    # process is running under the user's uid, so that is not possible
    # os.killpg(os.getpgid(p.pid), signal.SIGTERM)
    # now we run subprocess.Popen in the user context to let it terminate
    # the process in that user's context.
    # but as we don't want to let teapot be able to just kill any process
    # (by sudoers mechanism), we need to find a way around this,
    # maybe with a dedicated script that can only kill certain processes?

    pid = session.get("pid")

    if pid:
        logger.info("Stopping webdav instance with PID %d.", pid)
        try:
            kill_proc = subprocess.Popen(
                ["sudo", "-u", username, "/bin/kill", str(pid)])
            kill_exit_code = kill_proc.wait()
            if kill_exit_code != 0:
                logger.info("could not kill process with PID %d.", pid)
                exit_code = kill_exit_code
            else:
                logger.info("Successfully killed process with PID %d.", pid)
                exit_code = 0
        except subprocess.CalledProcessError as e:
            logger.error("Exception occurred while trying to kill process \
                          with PID %d: %s.", pid, e)
            exit_code = -1
    else:
        logger.info("No PID found.")
        exit_code = -1

    return exit_code


async def stop_expired_instances():
    """
    Checks for expired instances still running.

    TO DO: Incorporate config reload once implemented.

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
        logger.info("checking for expired instances")
        logger.debug(
            "stop_expired_instances: trying to acquire 'users' lock at %s",
            {datetime.datetime.now().isoformat()})
        async with app.state.state_lock:
            logger.debug(
                "stop_expired_instances: acquired 'users' lock at %s",
                {datetime.datetime.now().isoformat()})
            users = list(app.state.session_state.keys())
        now = datetime.datetime.now()
        for user in users:
            logger.debug(
                "stop_expired_instances: trying to acquire 'user_dict' \
                lock at %s", {datetime.datetime.now().isoformat()})
            async with app.state.state_lock:
                logger.debug(
                    "stop_expired_instances: acquired 'user_dict' lock at %s",
                    {datetime.datetime.now().isoformat()})
                user_dict = app.state.session_state.get(user, None)
            if user_dict is not None:
                last_accessed = user_dict.get("last_accessed", None)
                if last_accessed is not None:
                    diff = now - datetime.datetime.fromisoformat(last_accessed)
                    if diff.seconds >= INSTANCE_TIMEOUT_SEC:
                        res = await _stop_webdav_instance(user)
                        # TO DO: remove instance from session_state
                        if res != 0:
                            logger.error(
                                "Instance for user %s exited with code %s.",
                                user, str(res))
                        else:
                            logger.info(
                                "Instance for user %s has been terminated \
                                 after timeout.", user)
                else:
                    logger.error(
                        "_stop_expired_instances: Session for user %s \
                         does not have the property 'last_accessed'.", user)
            else:
                logger.error(
                    "_stop_expired_instances: No session object for user \
                     %s in session_state.", user)


async def _find_usable_port_no():
    used_ports = []
    logger.debug(
        "_find_usable_port_no: trying to acquire lock at %s",
        datetime.datetime.now().isoformat())
    async with app.state.state_lock:
        logger.debug(
            "_find_usable_port_no: acquired lock at %s",
            datetime.datetime.now().isoformat())
        users = app.state.session_state.keys()
        if users:
            for user in users:
                tmp_port = app.state.session_state[user].get("port", None)
                logger.debug(
                    "find_usable_port_no: use %s has an instance running \
                     on port %d.", user, tmp_port)
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
                "Missing port number for running instances, can not determine \
                    fitting port number."
            )
            port = None
            # should not happen :grimacing:
        return port


async def _test_port(port):
    # function to recursively find an open port recursively.
    # TO DO: enhance by adding a list of reserved ports that will be skipped
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        logger.debug("_test_port: binding to port %d for testing", port)
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
    `SESSION_STORE_PATH` in append mode and writes the current session state
    as a JSON object. The encoding used for writing is UTF-8.

    Note:
    Ensure that the application's state lock is acquired before calling this
    function to prevent concurrent writes to the session store.
    """
    async with app.state.state_lock:
        with open(SESSION_STORE_PATH, "a", encoding="utf-8") as f:
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

    Note:
    Ensure that the application's state lock is acquired before calling this
    function to prevent concurrent reads from the session store.

    Raises:
        Any error raised by `open()` when attempting to open the file for
        reading, or when `json.load()` encounters an error while deserializing
        the JSON data from the session store.
    """
    async with app.state.state_lock:
        if not exists(SESSION_STORE_PATH):
            app.state.session_state = {}
            with open(SESSION_STORE_PATH, "w", encoding="utf-8") as f:
                pass
        else:
            with open(SESSION_STORE_PATH, "r", encoding="utf-8") as f:
                try:
                    app.state.session_state = json.load(f)
                except json.decoder.JSONDecodeError:
                    app.state.session_state = {}


async def _map_fed_to_local(sub):
    # this func returns the local username for a federated user or None
    # for this prototype it could just be read from a mapping file on the
    # local file system. in this naive implementation, it is expected that
    # the mapping file has the format
    #
    #   federated-sub-claim,local-username
    #
    # without headers and only the first hit for a federated sub claim is
    # returned. like this, it is possible to match different subs to a
    # local username but not the other way around.

    with open("/etc/teapot/user-mapping.csv", "r",
              encoding="utf-8") as mapping_file:
        mappingreader = csv.reader(mapping_file, delimiter=" ")
        for row in mappingreader:
            logger.info("from mapping file: %s", row)
            if row[1] == sub:
                logger.info("found local user %s", row[0])
                return row[0]
    return None


async def _return_or_create_storm_instance(sub):
    # returns redirect_host and redirect port for sub.

    # get the mapping for the federated user from the sub-claim
    local_user = await _map_fed_to_local(sub)
    if not local_user:
        # local user is unknown, we cannot start or check anything.
        return None, None, None

    # now check if an instance is running by checking the global state
    if local_user in app.state.session_state.keys():
        logger.debug(
            "_return_or_create_storm_instance: trying to acquire 'get' lock \
             at %s", datetime.datetime.now().isoformat())
        async with app.state.state_lock:
            logger.debug(
                "_return_or_create_storm_instance: acquired 'get' lock at \
                    %s", datetime.datetime.now().isoformat())
            port = app.state.session_state[local_user].get("port", None)
            app.state.session_state[local_user]["last_accessed"] = str(
                datetime.datetime.now()
            )
        logger.info(
            "StoRM-WebDAV instance for %s is running on port %d", local_user,
            port)
    else:
        # if no instance is running, start it. but first, it has to be checked
        # if the directories exist, if not, they need to be created.
        # also, we need to write the env vars into a .bash_profile for the
        # user, so they are there when the webdav-instance is started.
        # the port, pid, storage_area and directory will be managed within
        # an sqlite database here in teapot. no external scripts anymore
        # to keep the state and its management in one place.
        logger.debug("no instance running for user %s yet, starting \
                     now.", local_user)
        port = await _find_usable_port_no()
        pid = await _start_webdav_instance(local_user, port)
        if not pid:
            logger.error(
                "something went wrong while starting instance for user %s.",
                local_user)
            return None, -1, local_user
        logger.debug(
            "_return_or_create_storm_instance: trying to acquire 'set' lock \
             at %s", datetime.datetime.now().isoformat())
        async with app.state.state_lock:
            logger.debug(
                "_return_or_create_storm_instance: acquired 'set' lock at %s",
                datetime.datetime.now().isoformat())
            app.state.session_state[local_user] = {
                "pid": pid,
                "port": port,
                "created_at": datetime.datetime.now(),
                "last_accessed": str(datetime.datetime.now()),
            }
        running = False
        loops = 0
        while not running:
            await anyio.sleep(1)
            if loops >= STARTUP_TIMEOUT:
                logger.info(
                    "instance for user %s not reachable after %d tries... \
                        stop trying.", local_user, STARTUP_TIMEOUT)
                logger.debug(
                    "_return_or_create_storm_instance: trying to acquire \
                    'pop' lock at %s", datetime.datetime.now().isoformat())
                async with app.state.state_lock:
                    logger.debug(
                        "_return_or_create_storm_instance: acquired 'pop'\
                         lock at %s", datetime.datetime.now().isoformat())
                    app.state.session_state.pop(local_user)
                return None, -1, local_user
            try:
                logger.debug(
                    "checking if instance for user {local_user} is listening \
                        on port %d.", port)
                context1 = ssl.create_default_context()
                context1.load_verify_locations(
                    cafile="/etc/pki/ca-trust/source/anchors/localhost.crt")
                resp = httpx.get(f"https://localhost:{port}/", verify=context1)
                if resp.status_code >= 200:
                    running = True
            except httpx.ConnectError:
                loops += 1
                logger.debug(
                    "_return_or_create: trying to reach instance, try \
                     %d/%d...", loops, STARTUP_TIMEOUT)

        logger.info("Storm-WebDAV instance for %s started on port %d.",
                    local_user, port)
    return None, port, local_user


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

    logger.info("user_info is: %s", user_infos['sub'])
    sub = user_infos.get("sub", None)
    if not sub:
        # if there is no sub, user can not be authenticated
        raise HTTPException(status_code=403)
    # user is valid, so check if a storm instance is running for this sub
    redirect_host, redirect_port, local_user = \
        await _return_or_create_storm_instance(sub)

    # REVISIT: should these errors be thrown from
    # _return_or_create_storm_instance?
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
    logger.info("redirect_host: %s, redirect_port: %d", redirect_host,
                redirect_port)
    logger.info("request path: %s", request.url.path)

    redirect_url = f"https://{redirect_host}:{redirect_port}{request.url.path}"
    logger.info("redirect_url is formed as %s.", redirect_url)

    forward_req = client.build_request(
        request.method,
        redirect_url,
        headers=request.headers.raw,
        content=request.stream(),
        timeout=15.0,
    )
    forward_resp = await client.send(forward_req, stream=True)
    return StreamingResponse(
        forward_resp.aiter_raw(),
        status_code=forward_resp.status_code,
        headers=forward_resp.headers,
        background=BackgroundTask(forward_resp.aclose),
    )


def main():
    """
    This function starts the Teapot application using uvicorn with SSL
    encryption. It specifies the path to the SSL key and certificate files.

    Returns:
        None
    """
    key = "/var/lib/teapot/webdav/teapot.key"
    cert = "/var/lib/teapot/webdav/teapot.crt"

    uvicorn.run(app, host="teapot", port=8081, ssl_keyfile=key,
                ssl_certfile=cert)


if __name__ == "__main__":
    main()
