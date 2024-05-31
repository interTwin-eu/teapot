*** Settings ***

Library          RequestsLibrary
Variables        /__w/teapot/teapot/robot/variables.py

*** Keywords ***

Add Test File USER1     ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile2    data=${DATA}    headers=${HEADER1}    expected_status=201

Add Test File USER2     ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile2    data=${DATA}    headers=${HEADER2}    expected_status=201

Delete Test File1 USER1     ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile1    headers=${HEADER1}    expected_status=204

Delete Test File1 USER2     ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile1    headers=${HEADER2}    expected_status=204

Delete Test File2 USER1     ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile2    headers=${HEADER1}    expected_status=204

Delete Test File2 USER2     ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile2    headers=${HEADER2}    expected_status=204


Add Test File USER1 EXTRA AREA    ${RESPONSE}=    PUT    ${EXTRA_AREA}/TestFile2    data=${DATA}    headers=${HEADER1}    expected_status=201

Add Test File USER2 EXTRA AREA     ${RESPONSE}=    PUT    ${EXTRA_AREA}/TestFile2    data=${DATA}    headers=${HEADER2}    expected_status=201

Delete Test File1 USER1 EXTRA AREA     ${RESPONSE}=    DELETE    ${EXTRA_AREA}/TestFile1    headers=${HEADER1}    expected_status=204

Delete Test File1 USER2 EXTRA AREA     ${RESPONSE}=    DELETE    ${EXTRA_AREA}/TestFile1    headers=${HEADER2}    expected_status=204

Delete Test File2 USER1 EXTRA AREA     ${RESPONSE}=    DELETE    ${EXTRA_AREA}/TestFile2    headers=${HEADER1}    expected_status=204

Delete Test File2 USER2 EXTRA AREA     ${RESPONSE}=    DELETE    ${EXTRA_AREA}/TestFile2    headers=${HEADER2}    expected_status=204

*** Test Cases ***

GET USER1
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER1}    verify=${false}    expected_status=200

GET USER2
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER2}    verify=${false}    expected_status=200

GET NO TOKEN
    ${RESPONSE}=    GET    ${DEFAULT_AREA}                          verify=${false}    expected_status=403 

GET INVALID TOKEN
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER3}    verify=${false}    expected_status=401


PUT REQUEST INVALID TOKEN
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile1    data=${DATA}    headers=${HEADER3}    expected_status=401

PUT REQUEST NO TOKEN
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile1    data=${DATA}                          expected_status=403

PUT REQUEST USER1
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile1    data=${DATA}    headers=${HEADER1}    expected_status=201
    [Teardown]    Delete Test File1 USER1

PUT REQUEST USER2
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile1    data=${DATA}    headers=${HEADER2}    expected_status=201
    [Teardown]    Delete Test File1 USER2


GET FILE USER1
    [Setup]     Add Test File USER1
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile2    headers=${HEADER1}    verify=${false}    expected_status=200
    [Teardown]    Delete Test File2 USER1

GET FILE USER2
    [Setup]     Add Test File USER2
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile2    headers=${HEADER2}    verify=${false}    expected_status=200
    [Teardown]    Delete Test File2 USER2

GET FILE NO TOKEN
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile2                          verify=${false}    expected_status=403

GET FILE INVALID TOKEN
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile2    headers=${HEADER3}    verify=${false}    expected_status=401


DELETE REQUEST USER1
    [Setup]     Add Test File USER1
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile2    headers=${HEADER1}    expected_status=204

DELETE REQUEST USER2
    [Setup]     Add Test File USER2
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile2    headers=${HEADER2}    expected_status=204

DELETE REQUEST INVALID TOKEN
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile2    headers=${HEADER3}    expected_status=401

DELETE REQUEST NO TOKEN
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile2                          expected_status=403


GET USER1 EXTRA_AREA
    ${RESPONSE}=    GET    ${EXTRA_AREA}    headers=${HEADER1}    verify=${false}    expected_status=200

GET USER2 EXTRA_AREA
    ${RESPONSE}=    GET    ${EXTRA_AREA}    headers=${HEADER2}    verify=${false}    expected_status=200

GET NO TOKEN EXTRA_AREA
    ${RESPONSE}=    GET    ${EXTRA_AREA}                          verify=${false}    expected_status=403 

GET INVALID TOKEN EXTRA_AREA
    ${RESPONSE}=    GET    ${EXTRA_AREA}    headers=${HEADER3}    verify=${false}    expected_status=401


PUT REQUEST INVALID TOKEN EXTRA_AREA
    ${RESPONSE}=    PUT    ${EXTRA_AREA}/TestFile1    data=${DATA}    headers=${HEADER3}    expected_status=401

PUT REQUEST NO TOKEN EXTRA_AREA
    ${RESPONSE}=    PUT    ${EXTRA_AREA}/TestFile1    data=${DATA}                          expected_status=403

PUT REQUEST USER1 EXTRA_AREA
    ${RESPONSE}=    PUT    ${EXTRA_AREA}/TestFile1    data=${DATA}    headers=${HEADER1}    expected_status=201
    [Teardown]    Delete Test File1 USER1 EXTRA AREA

PUT REQUEST USER2 EXTRA_AREA
    ${RESPONSE}=    PUT    ${EXTRA_AREA}/TestFile1    data=${DATA}    headers=${HEADER2}    expected_status=201
    [Teardown]    Delete Test File1 USER2 EXTRA AREA


GET FILE USER1 EXTRA_AREA
    [Setup]     Add Test File USER1 EXTRA AREA
    ${RESPONSE}=    GET    ${EXTRA_AREA}/TestFile2    headers=${HEADER1}    verify=${false}    expected_status=200
    [Teardown]    Delete Test File2 USER1 EXTRA AREA

GET FILE USER2 EXTRA_AREA
    [Setup]     Add Test File USER2 EXTRA AREA
    ${RESPONSE}=    GET    ${EXTRA_AREA}/TestFile2    headers=${HEADER2}    verify=${false}    expected_status=200
    [Teardown]    Delete Test File2 USER2 EXTRA AREA

GET FILE NO TOKEN EXTRA_AREA
    ${RESPONSE}=    GET    ${EXTRA_AREA}/TestFile2                          verify=${false}    expected_status=403 

GET FILE INVALID TOKEN EXTRA_AREA
    ${RESPONSE}=    GET    ${EXTRA_AREA}/TestFile2    headers=${HEADER3}    verify=${false}    expected_status=401


DELETE REQUEST USER1 EXTRA_AREA
    [Setup]     Add Test File USER1 EXTRA AREA
    ${RESPONSE}=    DELETE    ${EXTRA_AREA}/TestFile2    headers=${HEADER1}    expected_status=204

DELETE REQUEST USER2 EXTRA_AREA
    [Setup]     Add Test File USER2 EXTRA AREA
    ${RESPONSE}=    DELETE    ${EXTRA_AREA}/TestFile2    headers=${HEADER2}    expected_status=204

DELETE REQUEST INVALID TOKEN EXTRA_AREA
    ${RESPONSE}=    DELETE    ${EXTRA_AREA}/TestFile2    headers=${HEADER3}    expected_status=401

DELETE REQUEST NO TOKEN EXTRA_AREA
    ${RESPONSE}=    DELETE    ${EXTRA_AREA}/TestFile2                          expected_status=403
