import subprocess

PORT = "8085"
PORT_MAIN = "8081"
HOST = "localhost"
STORM_URL = "https://" + HOST + ":" + PORT
MAIN_URL = "https://" + HOST + ":" + PORT_MAIN
TOKEN1 = subprocess.check_output("oidc-token test-user1", shell=True)
TOKEN2 = subprocess.check_output("oidc-token test-user2", shell=True)
HEADER1 = {"Authorization": ("Bearer " + str(TOKEN1, "ascii")).strip("\n")}
HEADER2 = {"Authorization": ("Bearer " + str(TOKEN2, "ascii")).strip("\n")}
HEADER4 = {"Authorization": "Bearer NOT_A_TOKEN"}
DATA = "/__w/teapot/teapot/robot/test_file"
