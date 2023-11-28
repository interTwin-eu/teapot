import subprocess

PORT= '8085'
PORT_MAIN='8081'
HOST='131.169.234.115'
STORM_URL="https://"+HOST+":"+PORT
MAIN_URL="https://"+HOST+":"+PORT_MAIN
TOKEN1=subprocess.check_output("oidc-token test-kc1", shell=True)
TOKEN2=subprocess.check_output("oidc-token test-kc2", shell=True)
TOKEN3=subprocess.check_output("oidc-token test-kc3", shell=True)
HEADER1={"Authorization": ("Bearer "+str(TOKEN1, 'ascii')).strip("\n")}
HEADER2={"Authorization": ("Bearer "+str(TOKEN2, 'ascii')).strip("\n")}
HEADER3={"Authorization": ("Bearer "+str(TOKEN3, 'ascii')).strip("\n")}
HEADER4={"Authorization": "Bearer NOT_A_TOKEN"}
DATA='/home/dijana/TestFile1'
