*** Settings ***
Library          RequestsLibrary
Variables        /__w/teapot/teapot/robot/variables.py


*** Test Cases ***

Authentification
    [Tags]         authentication
    ${RESPONSE}=    GET    ${MAIN_URL}    headers=${HEADER1}    verify=${false}    expected_status=200

WRONG TOKEN
    ${RESPONSE}=    GET    ${MAIN_URL}    headers=${HEADER2}    verify=${false}    expected_status=403 

NO TOKEN
    ${RESPONSE}=    GET    ${MAIN_URL}                          verify=${false}    expected_status=401 

INVALID TOKEN
    ${RESPONSE}=    GET    ${MAIN_URL}    headers=${HEADER4}    verify=${false}    expected_status=500

PUT REQUEST INVALID TOKEN
    ${RESPONSE}=    PUT    ${MAIN_URL}/TestFile1    data=${DATA}    headers=${HEADER4}    verify=${false}     expected_status=500

PUT REQUEST WRONG TOKEN
    ${RESPONSE}=    PUT    ${MAIN_URL}/TestFile1    data=${DATA}    headers=${HEADER2}    verify=${false}     expected_status=403

PUT REQUEST NO TOKEN
    ${RESPONSE}=    PUT    ${MAIN_URL}/TestFile1    data=${DATA}                          verify=${false}     expected_status=401

PUT REQUEST DEFAULT SA
    ${RESPONSE}=    PUT    ${MAIN_URL}/TestFile1    data=${DATA}    headers=${HEADER1}    verify=${false}     expected_status=201


DELETE REQUEST
    ${RESPONSE}=    DELETE    ${MAIN_URL}/TestFile1    headers=${HEADER1}    verify=${false}     expected_status=204

DELETE REQUEST INVALID TOKEN
    ${RESPONSE}=    DELETE    ${MAIN_URL}/TestFile1    headers=${HEADER4}    verify=${false}     expected_status=500

DELETE REQUEST WRONG TOKEN
    ${RESPONSE}=    DELETE    ${MAIN_URL}/TestFile1    headers=${HEADER2}    verify=${false}     expected_status=403

DELETE REQUEST NO TOKEN
    ${RESPONSE}=    DELETE    ${MAIN_URL}/TestFile1                          verify=${false}     expected_status=401


