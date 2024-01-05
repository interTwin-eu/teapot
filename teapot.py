#!/usr/bin/env python3

import anyio
import asyncio
import csv
import datetime
import errno
import httpx
import json
import logging
import os
import pathlib
import psutil
import socket
import subprocess
import uvicorn

from pwd import getpwnam
from stat import *

from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, Request, Response
from fastapi.security import HTTPBearer, HTTPBasicCredentials

from flaat.config import AccessLevel
from flaat.fastapi import Flaat
from flaat.requirements import HasSubIss

from os.path import exists

from starlette.responses import StreamingResponse
from starlette.background import BackgroundTask

github_host = str(
    subprocess.check_output("curl ifconfig.me -4", shell=True), encoding="utf-8"
)


# lifespan function for startup and shutdown functions
@asynccontextmanager
async def lifespan(app: FastAPI):
    # everything before the "yield" should be executed at startup.
    # check if json file for storing sessions exists, otherwise create it.
    await load_session_state()

    # set up task loop for stopping expired instances.
    # function runs an async while True loop and checks for expired instances.
    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
    task = loop.create_task(stop_expired_instances())

    yield

    # everything after the yield should be executed after shutdown
    handles = app.state.session_state.keys()
    for k in handles:
        await _stop_webdav_instance(k)
    if exists(SESSION_STORE_PATH):
        pathlib.unlink(SESSION_STORE_PATH)


# create fastAPI app and initialize flaat options
app = FastAPI(lifespan=lifespan)
flaat = Flaat()
security = HTTPBearer()

flaat.set_access_levels([AccessLevel("user", HasSubIss())])

flaat.set_trusted_OP_list(
    [
        "https://aai-demo.egi.eu/auth/realms/egi",
        "http://keycloak:8080/realms/test-realm",
        "https://keycloak.ci-cd-prep2.desy.de/realms/Testing",
    ]
)

# logging is important
LOGFILE = os.environ.get("TEAPOT_LOGFILE", "/var/lib/teapot/webdav/teapot.log")
LOGLEVEL = os.environ.get("TEAPOT_LOGLEVEL", "DEBUG").upper()
logging.basicConfig(filename=LOGFILE, level=logging.getLevelName(LOGLEVEL))
logger = logging.getLogger(__name__)

# globals
# TODO: load globals via config file on startup and reload on every run of stop_expired_instances,
# maybe rename function to "housekeeping" or the like.

SESSION_STORE_PATH = os.environ.get(
    "TEAPOT_SESSIONS", "/var/run/teapot/teapot_sessions.json"
)
APP_NAME = "teapot"
# one less than the first port that is going to be used by any storm webdav instance, should be above 1024
# as all ports below this are privileged and normal users will not be able to use them to run services.
STARTING_PORT = 32399
# toggle restarting teapot without deleting saved state and without terminating running webdav instances.
# N.B. will only consider the value set at startup of this app.
RESTART = os.environ.get("TEAPOT_RESTART", "False") == "True"
# instance timeout, instances are deleted after this time without being accessed.
# default: 10 minutes
INSTANCE_TIMEOUT_SEC = 600
# interval between instance timeout checks in stop_expired_instances
# default: 3 minutes
CHECK_INTERVAL_SEC = 180
# number of times that teapot will try to connect to a recently started instance
STARTUP_TIMEOUT = int(os.environ.get("TEAPOT_STARTUP_TIMEOUT", 30))
# standard mode for file creation, currently rwxr-x---
# directories and files are created with the corresponding os.mkdir, os.chmod, os.chown commands.
# those are using the bit patterns provided with the 'stat' module as below, combining them happens via bitwise OR
STANDARD_MODE = S_IRWXU | S_IRGRP | S_IXGRP
# session state is kept in this global dict for each username as primary key
# data stored within each subdict is
# pid, port, created_at, last_accessed
app.state.session_state = {}
# for each instance started, a process handle is kept with the username a
# primary key so instances can be stopped after a timeout and at shutdown
# they are not kept in the session state because saving them is not possible
app.state.process_handles = {}
# lock for the state. any write operation on the state should only be done
# in an "async with app.state_lock:" environment.
app.state.state_lock = anyio.Lock()
app.state.process_lock = anyio.Lock()


async def makedir_chown_chmod(dir, uid, gid, mode=STANDARD_MODE):
    if not exists(dir):
        try:
            os.mkdir(dir)
        except FileExistsError:
            # this info msg should never be triggered, right?
            logger.error(
                f"Directory {dir} already exists, therefore this message should not exist. Something is wrong..."
            )
        try:
            os.chmod(dir, mode)
        except:
            logger.error(f"Could not chmod directory {dir} to {mode}.")
        # try:
        #    os.chown(dir, uid, gid)
        # except PermissionError:
        #    logger.error(f"Could not chown directory {dir}, not allowed to change ownership to {uid}, {gid}.")


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

    logger.debug(f"creating user dirs...")
    config_dir = f"/etc/{APP_NAME}"
    if not exists(f"{config_dir}/storage-areas"):
        logger.error(
            f"{config_dir}/storage-areas is missing. It should consist of two variables per storage area: name of the storage area and root path to the storage area's directory separated by a single space."
        )
        return False

    mapping_file = f"{config_dir}/user-mapping.csv"
    if not exists(mapping_file):
        logger.error(
            f"{mapping_file} does not exist. It should consist of two variables per user: username and subject claim separated by a single space."
        )
        return False

    app_dir = f"/var/lib/{APP_NAME}"
    if not exists(app_dir):
        logger.error(f"Parent {APP_NAME} directory does not exist.")
        return False

    # creating user directories,
    # resort to explicit usage of chown and chmod
    # because the mask options might be ignored
    # on certain operating systems as per docs.

    uid = getpwnam(username).pw_uid
    gid = getpwnam(username).pw_gid
    logger.debug(f"user {username} has uid {uid} and gid {gid}")

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
        await makedir_chown_chmod(dir, uid, gid)

    with open(f"/usr/share/{APP_NAME}/storage_element.properties", "r") as prop:
        second_part = prop.readlines()
    with open(f"{config_dir}/storage-areas", "r") as storage_areas:
        for line in storage_areas:
            storage_area, path = line.split(" ")
            path_components = path.split("/")
            # check for different paths in storage-areas that need to be corrected.
            if path_components[0] == "$HOME":
                path_components[0] = f"/home/{username}"
            path = os.path.join(*path_components)
            sa_properties_path = f"{user_sa_d_dir}/{storage_area}.properties"
            if not exists(sa_properties_path):
                with open(sa_properties_path, "w") as storage_area_properties:
                    first_part = f"name={storage_area}\nrootPath={path}\naccessPoints=/{storage_area}_area\n\n"
                    storage_area_properties.write(first_part)
                    for line in second_part:
                        storage_area_properties.write(line)
                os.chmod(sa_properties_path, STANDARD_MODE)
                # os.makedirs(path)
                # os.chmod(path, STANDARD_MODE)

    if not exists(f"{user_config_dir}/application.yml"):
        with open(f"{config_dir}/user-mapping.csv") as mapping:
            for line in mapping:
                if line.startswith(username):
                    sub = line.split(" ")[1]
                    break
        with open(f"{config_dir}/issuers.yml", "r") as issuers:
            issuers_part = issuers.readlines()
        with open(f"/usr/share/teapot/storage_authorizations.yml", "r") as auths:
            authorization_part = "".join(auths.readlines())
        with open(f"{user_config_dir}/application.yml", "a") as application_yml:
            for line in issuers_part:
                application_yml.write(line)
            application_yml.write("storm:\n  authz:\n    policies:\n")
            with open(f"{config_dir}/storage-areas", "r") as storage_areas:
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

    os.environ[
        "STORM_WEBDAV_JVM_OPTS"
    ] = "-Xms2048m -Xmx2048m -Djava.security.egd=file:/dev/./urandom"
    os.environ["STORM_WEBDAV_SERVER_ADDRESS"] = github_host
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
    os.environ[
        "STORM_WEBDAV_JAR"
    ] = "/usr/share/java/storm-webdav/storm-webdav-server.jar"

    os.environ["STORM_WEBDAV_LOG"] = f"{user_dir}/log/server.log"
    os.environ["STORM_WEBDAV_OUT"] = f"{user_dir}/log/server.out"
    os.environ["STORM_WEBDAV_ERR"] = f"{user_dir}/log/server.err"

    os.environ["STORM_WEBDAV_LOG_CONFIGURATION"] = f"{etc_dir}/logback.xml"
    os.environ[
        "STORM_WEBDAV_ACCESS_LOG_CONFIGURATION"
    ] = f"{etc_dir}/logback-access.xml"
    os.environ["STORM_WEBDAV_VO_MAP_FILES_ENABLE"] = "false"
    os.environ["STORM_WEBDAV_VO_MAP_FILES_REFRESH_INTERVAL"] = "21600"
    os.environ["STORM_WEBDAV_TPC_MAX_CONNECTIONS"] = "50"
    os.environ["STORM_WEBDAV_TPC_VERIFY_CHECKSUM"] = "false"
    os.environ["STORM_WEBDAV_REQUIRE_CLIENT_CERT"] = "false"
    os.environ["STORM_WEBDAV_TPC_USE_CONSCRYPT"] = "true"

    return True


async def _remove_user_env():
    for key in os.environ.keys():
        if key.startswith("STORM_WEBDAV_"):
            del os.environ[key]


async def _start_webdav_instance(username, port):
    res = await _create_user_dirs(username)
    if not res:
        logger.error(f"could not create user dirs for {username}")
        return False
    logger.debug(f"creating user env...")
    res = await _create_user_env(username, port)
    if not res:
        logger.error(f"could not create user env for {username}")
        return False

    # as a dict for subprocess.Popen
    # env_pass = {key: value for key,value in os.environ.items() if key.startswith("STORM_WEBDAV_")}

    # add STORM_WEBDAV_* env vars to a list that can be passed to the sudo command and be preserved for the forked process
    env_pass = [key for key in os.environ.keys() if key.startswith("STORM_WEBDAV_")]

    # starting subprocess with all necessary options now.
    # using os.setsid() as a function handle before execution should execute the process in it's own process group
    # such that it can be managed on its own.
    logger.info(f"trying to start process for user {username}.")
    full_cmd = f"sudo -b -u {username} --preserve-env={','.join(env_pass)} /usr/bin/java -jar $STORM_WEBDAV_JAR $STORM_WEBDAV_JVM_OPTS \
    -Djava.io.tmpdir=/var/lib/user-{username}/tmp \
    -Dlogging.config=$STORM_WEBDAV_LOG_CONFIGURATION \
     1>$STORM_WEBDAV_OUT 2>$STORM_WEBDAV_ERR \
    --spring.config.additional-location=optional:file:/var/lib/{APP_NAME}/user-{username}/config/application.yml&"

    logger.info(f"full_cmd={full_cmd}")

    p = subprocess.Popen(
    full_cmd,
    shell=True,
    preexec_fn=os.setsid
    )

    # wait for it...
    await anyio.sleep(1)
    # poll the process to get rid of the zombiefied subprocess attached to teapot
    p.poll()

    #sudo -b --preserve-env={','.join(env_pass)} -u {username} 
    # we can remove all env vars for the user process from teapot now as they were given to the forked process as a copy
    await _remove_user_env()

    # get rid of additional whitespace and trailing "&" from cmdline
    full_cmd=" ".join(full_cmd.split())[:-1]
    # get the process pid for terminating it later.
    kill_proc =  await _get_proc(full_cmd)

    # poll process to determine whether it is running and set returncode if exited.
    # if the process has not exited yet, the returncode will be "None"
    kill_proc.poll()
    ret = p.returncode
    if ret in [None, 0]:
        logger.debug(
            f"start_webdav_instance: instance for user {username} is running under PID {kill_proc.pid}."
        )
        async with app.state.process_lock:
            app.state.process_handles["username"] = kill_proc
        return kill_proc.pid
    else:
        logger.error(
            f"_start_webdav_instance: instance for user {username} could not be started. pid was {p.pid}, returncode of instance was {ret}"
        )
        # if there was a returncode, we wait for the process and terminate it.
        kill_proc.wait()
        return None

async def _get_proc(full_cmd):
    # here we are simply looking through all processes and try to find a match for the full command 
    # that was issued to start the instance in question. then return the process handle.
    # it should contain the process that is running as root and forked the storm instance for
    # the user themselves.
    # looking through all processes seems a bit overkill but at the moment this is the only
    # halfway surefire method I could find to accomplish this task.
    # shamelessly stolen from 
    # https://codereview.stackexchange.com/questions/183091/start-a-sub-process-with-sudo-as-head-of-new-process-group-kill-it-after-time
    for pid in psutil.pids():
        proc = psutil.Process(pid)
        if full_cmd == proc.cmdline():
            return proc
    raise RuntimeError(f"process with for full command {full_cmd} does not exist.")

async def _stop_webdav_instance(username):
    logger.info(f"Stopping webdav instance for user {username}.")

    async with app.state.process_lock:
        try:
            p = app.state.process_handles.pop(username)
        except KeyError as e:
            logger.error(
                f"_stop_webdav_instance: Process handle for user {username} doesn't exist."
            )
            return -1

    # first naive workaround will be to just give sudo rights to teapot for /usr/bin/kill
    # TODO: find a safer way to accomplish this!
    # originally wanted to kill the process via os.killpg but the storm process is running under the user's uid, so that is not possible
    # os.killpg(os.getpgid(p.pid), signal.SIGTERM)
    # now we run subprocess.Popen in the user context to let it terminate the process in that user's context.
    # but as we don't want to let teapot be able to just kill any process (by sudoers mechanism), we need to find a way around this,
    # maybe with a dedicated script that can only kill certain processes
    # n.b.: while spawning an instance with sudo --preserve-env, a process with the list on env vars is created in root's context as well
    #       how do we kill that together with the storm instance here?

    pid = os.getpgid(p.pid)
    kill_proc = subprocess.Popen(f"sudo -u {username} kill {pid}")
    kill_exit_code = kill_proc.wait()
    if kill_exit_code != 0:
        # what now?
        logger.info(f"could not kill process with PID {pid}.")

    exit_code = p.wait()

    return exit_code

async def stop_expired_instances():
    # checks for expired instances still running
    # TODO: incorporate config reload once implemented.
    while True:
        await asyncio.sleep(CHECK_INTERVAL_SEC)
        logger.info("checking for expired instances")
        async with app.state.state_lock:
            users = app.state.session_state.keys()
            now = datetime.datetime.now()
            for user in users:
                user_dict = app.state.session_state.get(user, None)
                if user_dict is not None:
                    last_accessed = user_dict.get("last_accessed", None)
                    if last_accessed is not None:
                        diff = now - datetime.datetime.fromisoformat(last_accessed)
                        if diff.seconds >= INSTANCE_TIMEOUT_SEC:
                            res = await _stop_webdav_instance(user)
                            # TODO: remove instance from session_state
                            if res != 0:
                                logger.error(
                                    f"Instance for user {user} exited with code {res}."
                                )
                            else:
                                logger.info(
                                    f"Instance for user {user} has been terminated after timeout."
                                )
                    else:
                        logger.error(
                            f"_stop_expired_instances: Session for user {user} does not have the property 'last_accessed'."
                        )
                else:
                    logger.error(
                        f"_stop_expired_instances: No session object for user {user} in session_state."
                    )


async def _find_usable_port_no():
    used_ports = []
    async with app.state.state_lock:
        users = app.state.session_state.keys()
        if users:
            for user in users:
                tmp_port = app.state.session_state[user].get("port", None)
                logger.debug(
                    f"find_usable_port_no: use {user} has an instance running on port {tmp_port}."
                )
                used_ports.append(tmp_port)
        else:
            # if there are no instances running yet, we want the ports to start from 32400
            logger.debug(f"no port in use by teapot, using {STARTING_PORT}")
            used_ports = [STARTING_PORT]

        if not None in used_ports:
            max_used = max(used_ports) + 1
            logger.debug(f"testing port {max_used}")
            port = await _test_port(max_used)
        else:
            logger.error(
                "Missing port number for running instances, can not determine fitting port number."
            )
            port = None
            # should not happen :grimacing:
        return port


async def _test_port(port):
    # function to recursively find an open port recursively.
    # TODO: enhance by adding a list of reserved ports that will be skipped
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        logger.debug(f"_test_port: binding to port {port} for testing")
        s.bind(("127.0.0.1", port))
    except socket.error as e:
        if e.errno == errno.EADDRINUSE:
            logger.debug(f"Port {port} is already in use")
            port = await _test_port(port + 1)
        else:
            logger.error(f"Error while testing ports: {e}")
            port = await _test_port(port + 1)
    finally:
        s.close()
    return port


async def save_session_state():
    async with app.state.state_lock:
        with open(SESSION_STORE_PATH, "a") as f:
            json.dump(app.state.session_state, f)


async def load_session_state():
    async with app.state.state_lock:
        if not exists(SESSION_STORE_PATH):
            app.state.session_state = {}
            with open(SESSION_STORE_PATH, "w") as f:
                pass
        else:
            with open(SESSION_STORE_PATH, "r") as f:
                try:
                    app.state.session_state = json.load(f)
                except json.decoder.JSONDecodeError as e:
                    app.state.session_state = {}


async def _map_fed_to_local(sub):
    # this func returns the local username for a federated user or None
    # for this prototype it could just be read from a mapping file on the local file system.  # noqa: E501
    # in this naive implementation, it is expected that the mapping file has the format
    #
    #   federated-sub-claim,local-username
    #
    # without headers and only the first hit for a federated sub claim is returned.
    # like this, it is possible to match different subs to a local username but not the other way around.  # noqa: E501

    with open("/etc/teapot/user-mapping.csv", "r") as mapping_file:
        mappingreader = csv.reader(mapping_file, delimiter=" ")
        for row in mappingreader:
            logger.info(f"from mapping file: {row}")
            if row[1] == sub:
                logger.info(f"found local user {row[0]}.")
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
        async with app.state.state_lock:
            port = app.state.session_state[local_user].get("port", None)
            app.state.session_state[local_user]["last_accessed"] = str(
                datetime.datetime.now()
            )
        logger.info(
            f"StoRM-WebDAV instance for {local_user} is running on port {port}."
        )  # noqa: E501
    else:
        # if no instance is running, start it. but first, it has to be checked if the directories exist, if not, they need to be created.
        # also, we need to write the env vars into a .bash_profile for the user, so they are there when the webdav-instance is started.
        # the port, pid, storage_area and directory will be managed within an sqlite database here in teapot.
        # no external scripts anymore to keep the state and its management in one place.
        logger.debug(f"no instance running for user {local_user} yet, starting now.")
        port = await _find_usable_port_no()
        pid = await _start_webdav_instance(local_user, port)
        if not pid:
            logger.error(
                f"something went wrong while starting instance for user {local_user}."
            )
            return None, -1, local_user
        async with app.state.state_lock:
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
                    f"instance for user {local_user} not reachable after {STARTUP_TIMEOUT} tries... stop trying."
                )
                async with app.state.state_lock:
                    app.state.session_state.pop(local_user)
                return None, -1, local_user
            try:
                logger.debug(
                    f"checking if instance for user {local_user} is listening on port {port}."
                )
                resp = httpx.get(f"https://localhost:{port}/", verify=False)
                if resp.status_code >= 200:
                    running = True
            except httpx.ConnectError as e:
                loops += 1
                logger.debug(
                    f"_return_or_create: trying to reach instance, try {loops}/{STARTUP_TIMEOUT}..."
                )

        logger.info(f"Storm-WebDAV instance for {local_user} started on port {port}.")
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
async def root(
    filepath: str,
    request: Request,
    response: Response,
    credentials: HTTPBasicCredentials = Depends(security),
):  # noqa: E501
    # get data from userinfo endpoint
    user_infos = flaat.get_user_infos_from_request(request)
    if not user_infos:
        return 403

    logger.info(f"user_info is: {user_infos['sub']}")
    sub = user_infos.get("sub", None)
    if not sub:
        # if there is no sub, user can not be authenticated
        return 403
    # user is valid, so check if a storm instance is running for this sub
    redirect_host, redirect_port, local_user = await _return_or_create_storm_instance(
        sub
    )

    if not redirect_host and not redirect_port:
        # no mapping between federated and local user identity found
        return 403
    if redirect_port == -1:
        logger.info(f"no instance for user {local_user} created...")
        return 500
    if not redirect_port:
        # no port returned, should not happen
        return 500
    if not redirect_host:
        redirect_host = "localhost"
    logger.info(f"redirect_host: {redirect_host}, redirect_port: {redirect_port}")
    logger.info(f"request path: {request.url.path}")

    redirect_url = f"https://{redirect_host}:{redirect_port}{request.url.path}"
    logger.info(f"redirect_url is formed as {redirect_url}.")

    async with httpx.AsyncClient(verify=False) as client:
        forward_req = client.build_request(
            request.method,
            redirect_url,
            headers=request.headers.raw,
            content=request.stream(),
        )
        forward_resp = await client.send(forward_req, stream=True)
        return StreamingResponse(
            forward_resp.aiter_raw(),
            status_code=forward_resp.status_code,
            headers=forward_resp.headers,
            background=BackgroundTask(forward_resp.aclose),
        )


def main():
    key = "/var/lib/teapot/webdav/localhost.key"
    cert = "/var/lib/teapot/webdav/localhost.crt"

    uvicorn.run(app, host="0.0.0.0", port=8081, ssl_keyfile=key, ssl_certfile=cert)


if __name__ == "__main__":
    main()
