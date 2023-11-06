*** Settings ***
Library          RequestsLibrary
Variables        robot/variables.py


*** Test Cases ***

Authentification
    [Tags]         authentication
    ${RESPONSE}=    GET    ${STORM_URL}/default_area    headers=${HEADER1}    verify=${false}    expected_status=200

WRONG TOKEN
    ${RESPONSE}=    GET    ${STORM_URL}/default_area    headers=${HEADER2}    verify=${false}    expected_status=403 

NO TOKEN
    ${RESPONSE}=    GET    ${STORM_URL}/default_area                          verify=${false}    expected_status=401 

INVALID TOKEN
    ${RESPONSE}=    GET    ${STORM_URL}/default_area    headers=${HEADER4}    verify=${false}    expected_status=500


@EXTRA SA:
    ${RESPONSE}=    GET    ${STORM_URL}/extra_area    headers=${HEADER1}    verify=${false}    expected_status=200

WRONG TOKEN @Extra SA
    ${RESPONSE}=    GET    ${STORM_URL}/extra_area    headers=${HEADER2}    verify=${false}    expected_status=403

NO TOKEN @Extra SA
    ${RESPONSE}=    GET    ${STORM_URL}/extra_area                          verify=${false}    expected_status=401

INVALID TOKEN @Extra SA
    ${RESPONSE}=    GET    ${STORM_URL}/extra_area    headers=${HEADER4}    verify=${false}    expected_status=500


PUT REQUEST EXTRA SA
    ${RESPONSE}=    PUT    ${STORM_URL}/extra_area/TestFile1    data=${DATA}    headers=${HEADER1}    verify=${false}       expected_status=201

PUT REQUEST INVALID TOKEN
    ${RESPONSE}=    PUT    ${STORM_URL}/default_area/TestFile1    data=${DATA}    headers=${HEADER4}    verify=${false}     expected_status=500

PUT REQUEST WRONG TOKEN
    ${RESPONSE}=    PUT    ${STORM_URL}/default_area/TestFile1    data=${DATA}    headers=${HEADER2}    verify=${false}     expected_status=403

PUT REQUEST NO TOKEN
    ${RESPONSE}=    PUT    ${STORM_URL}/default_area/TestFile1    data=${DATA}                          verify=${false}     expected_status=401

PUT REQUEST DEFAULT SA
    ${RESPONSE}=    PUT    ${STORM_URL}/default_area/TestFile1    data=${DATA}    headers=${HEADER1}    verify=${false}     expected_status=201


DELETE REQUEST
    ${RESPONSE}=    DELETE    ${STORM_URL}/default_area/TestFile1    headers=${HEADER1}    verify=${false}     expected_status=204

DELETE REQUEST INVALID TOKEN
    ${RESPONSE}=    DELETE    ${STORM_URL}/default_area/TestFile1    headers=${HEADER4}    verify=${false}     expected_status=500

DELETE REQUEST WRONG TOKEN
    ${RESPONSE}=    DELETE    ${STORM_URL}/default_area/TestFile1    headers=${HEADER2}    verify=${false}     expected_status=403

DELETE REQUEST NO TOKEN
    ${RESPONSE}=    DELETE    ${STORM_URL}/default_area/TestFile1                          verify=${false}     expected_status=401

DELETE REQUEST @EXTRA SA
    ${RESPONSE}=    DELETE    ${STORM_URL}/extra_area/TestFile1    headers=${HEADER1}    verify=${false}     expected_status=204

