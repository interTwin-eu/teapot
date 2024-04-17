import subprocess

TEAPOT_URL = "https://teapot:8081"
DEFAULT_AREA = "https://teapot:8081/default_area"
EXTRA_AREA = "https://teapot:8081/extra_area"
TOKEN1 = subprocess.check_output("oidc-token test-user1", shell=True)
TOKEN2 = subprocess.check_output("oidc-token test-user2", shell=True)
HEADER1 = {"Authorization": ("Bearer " + str(TOKEN1, "ascii")).strip("\n")}
HEADER2 = {"Authorization": ("Bearer " + str(TOKEN2, "ascii")).strip("\n")}
HEADER3 = {"Authorization": "Bearer NOT_A_TOKEN"}
DATA = "Hello! This is a test. "
