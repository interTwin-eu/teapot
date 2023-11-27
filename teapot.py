#!/usr/bin/env python3

import os
import csv
import httpx
import logging
import uvicorn
import time

from fastapi import Depends, FastAPI, Request, Response
from fastapi.security import HTTPBearer, HTTPBasicCredentials

from flaat.config import AccessLevel
from flaat.fastapi import Flaat
from flaat.requirements import HasSubIss

from starlette.responses import StreamingResponse
from starlette.background import BackgroundTask

import subprocess
from os.path import exists

# create fastAPI app and initialize flaat options
app = FastAPI()
flaat = Flaat()
security = HTTPBearer()

HOST = str(subprocess.check_output("curl ifconfig.me", shell=True), encoding="utf-8")

flaat.set_access_levels([AccessLevel("user", HasSubIss())])

flaat.set_trusted_OP_list(
    [
        "https://aai-demo.egi.eu/auth/realms/egi",
        "http://keycloak:8080/realms/test-realm",
    ]
)

# logging is important
LOGLEVEL = os.environ.get("STORM_LOGLEVEL", "INFO").upper()
logging.basicConfig(
    filename="/var/lib/teapot/webdav/teapot.log", level=logging.getLevelName(LOGLEVEL)
)
logger = logging.getLogger(__name__)


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
    # get the mapping for the federated user from the sub-claim
    local_user = await _map_fed_to_local(sub)
    if not local_user:
        # local user is unknown, we cannot start or check anything.
        return None, None
    # now check if an instance is running by possibly checking `ps faux | grep local-username  # noqa: E501
    # currently just mocking the return values
    if exists("/var/lib/teapot/user-" + local_user + "/server.pid"):
        with open(
            "/var/lib/teapot/user-" + local_user + "/server.pid", "r"
        ) as pid_file:
            pid = pid_file.read()
        with open(
            "/var/lib/teapot/user-" + local_user + "/server.port", "r"
        ) as port_file:
            port = port_file.read().rstrip()
        logger.info(
            f"StoRM-WebDAV instance for {local_user} is running on port {port}."
        )  # noqa: E501
    else:
        port = 8085
        subprocess.run(
            ["sudo", "/usr/share/teapot/webdav-automation.sh", local_user, str(port)]
        )  # noqa: E501
        with open(
            "/var/lib/teapot/user-" + local_user + "/server.pid", "r"
        ) as pid_file:
            pid = pid_file.read()  # noqa: F841
        running = False
        while not running:
            time.sleep(1)
            try:
                resp = httpx.get(f"https://{HOST}:{port}/")
                if resp.status_code == 403 or resp.status_code == 200:
                    running = True
            except:
                pass

        logger.info(f"Storm-WebDAV instance for {local_user} started on port {port}.")
    return None, port


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
    redirect_host, redirect_port = await _return_or_create_storm_instance(sub)

    if not redirect_host and not redirect_port:
        # no mapping between federated and local user identity found
        return 403
    if not redirect_port:
        # no port returned, should not happen
        return 500
    if not redirect_host:
        redirect_host = HOST
    logger.info(f"redirect_host: {redirect_host}, redirect_port: {redirect_port}")

    logger.info(f"request path: {request.url.path}")

    storage_prefix = "default_area"
    redirect_path = f"{storage_prefix}{request.url.path}"
    redirect_url = f"https://{redirect_host}:{redirect_port}/{redirect_path}"
    # redirect_url = httpx.URL(scheme=request.url.scheme, host=redirect_host, port=redirect_port, path=redirect_path)  # noqa: E501
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

    # if yes, forward the request to this instance; if no, create an instance and then forward the request. forwarding happens via _reverse_proxy()  # noqa: E501


if __name__ == "__main__":
    key = "/var/lib/teapot/webdav/localhost.key"
    cert = "/var/lib/teapot/webdav/localhost.crt"
    uvicorn.run(app, host="0.0.0.0", port=8081, ssl_keyfile=key, ssl_certfile=cert)
