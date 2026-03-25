import subprocess

TEAPOT_URL = "https://teapot:8081"
DEFAULT_AREA = "https://teapot:8081/default"
DATA_AREA = "https://teapot:8081/data"
TOKEN1 = subprocess.check_output("oidc-token test-user1", shell=True)
TOKEN2 = subprocess.check_output("oidc-token test-user2", shell=True)
TOKEN3 = subprocess.check_output("oidc-token test-user3", shell=True)
TOKEN4 = subprocess.check_output("oidc-token test-user4", shell=True)
TOKEN_A1 = subprocess.check_output("oidc-token alise-user1", shell=True)
TOKEN_A2 = subprocess.check_output("oidc-token alise-user2", shell=True)
HEADER0 = {"Authorization": "Bearer NOT_A_TOKEN"}
HEADER1 = {"Authorization": "Bearer " + str(TOKEN1, "ascii").strip()}
HEADER2 = {"Authorization": "Bearer " + str(TOKEN2, "ascii").strip()}
HEADER3 = {"Authorization": "Bearer " + str(TOKEN3, "ascii").strip()}
HEADER4 = {"Authorization": "Bearer " + str(TOKEN4, "ascii").strip()}
HEADER_A1 = {"Authorization": "Bearer " + str(TOKEN_A1, "ascii").strip()}
HEADER_A2 = {"Authorization": "Bearer " + str(TOKEN_A2, "ascii").strip()}
DATA = "A" * 1024
