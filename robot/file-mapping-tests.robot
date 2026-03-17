*** Settings ***

Library          RequestsLibrary
Variables        /__w/teapot/teapot/robot/variables.py

*** Keywords ***

Add TestFile USER1 DEFAULT AREA    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=201

Add TestFile USER2 DEFAULT AREA    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=201

Add TestFile USER1 DATA AREA    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=201

Add TestFile USER2 DATA AREA    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=201

Delete TestFile USER1 DEFAULT AREA     ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER1}      expected_status=204

Delete TestFile USER2 DEFAULT AREA     ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER2}      expected_status=204

Delete TestFile USER1 DATA AREA     ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER1}      expected_status=204

Delete TestFile USER2 DATA AREA     ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER2}      expected_status=204


*** Test Cases ***

GET USER1
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER1}     expected_status=200

GET USER2
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER2}     expected_status=200

GET NO TOKEN
    ${RESPONSE}=    GET    ${DEFAULT_AREA}                           expected_status=401

GET INVALID TOKEN
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER0}     expected_status=401


PUT REQUEST INVALID TOKEN
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER0}      expected_status=401

PUT REQUEST NO TOKEN
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}                            expected_status=401

PUT REQUEST USER1
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=201
    [Teardown]    Delete TestFile USER1 DEFAULT AREA

PUT REQUEST USER2
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=201
    [Teardown]    Delete TestFile USER2 DEFAULT AREA


GET FILE USER1
    [Setup]     Add TestFile USER1 DEFAULT AREA
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile    headers=${HEADER1}     expected_status=200
    [Teardown]    Delete TestFile USER1 DEFAULT AREA

GET FILE USER2
    [Setup]     Add TestFile USER2 DEFAULT AREA
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile    headers=${HEADER2}     expected_status=200
    [Teardown]    Delete TestFile USER2 DEFAULT AREA

GET FILE NO TOKEN
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile                           expected_status=401

GET FILE INVALID TOKEN
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile    headers=${HEADER0}     expected_status=401


DELETE REQUEST USER1
    [Setup]     Add TestFile USER1 DEFAULT AREA
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER1}      expected_status=204

DELETE REQUEST USER2
    [Setup]     Add TestFile USER2 DEFAULT AREA
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER2}      expected_status=204

DELETE REQUEST INVALID TOKEN
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER0}      expected_status=401


DELETE REQUEST NO TOKEN
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile                            expected_status=401


GET USER1 DATA_AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/    headers=${HEADER1}     expected_status=200

GET USER2 DATA_AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/   headers=${HEADER2}     expected_status=200

GET NO TOKEN DATA_AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/                           expected_status=401

GET INVALID TOKEN DATA_AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/    headers=${HEADER0}     expected_status=401


PUT REQUEST INVALID TOKEN DATA_AREA
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER0}      expected_status=401

PUT REQUEST NO TOKEN DATA_AREA
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}                            expected_status=401

PUT REQUEST USER1 DATA_AREA
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=201
    [Teardown]    Delete TestFile USER1 DATA AREA

PUT REQUEST USER2 DATA_AREA
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=201
    [Teardown]    Delete TestFile USER2 DATA AREA


GET FILE USER1 DATA_AREA
    [Setup]     Add TestFile USER1 DATA AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER1}     expected_status=200
    [Teardown]    Delete TestFile USER1 DATA AREA

GET FILE USER2 DATA_AREA
    [Setup]     Add TestFile USER2 DATA AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER2}     expected_status=200
    [Teardown]    Delete TestFile USER2 DATA AREA

GET FILE NO TOKEN DATA_AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile                           expected_status=401

GET FILE INVALID TOKEN DATA_AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER0}     expected_status=401


DELETE REQUEST USER1 DATA_AREA
    [Setup]     Add TestFile USER1 DATA AREA
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER1}      expected_status=204

DELETE REQUEST USER2 DATA_AREA
    [Setup]     Add TestFile USER2 DATA AREA
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER2}      expected_status=204

DELETE REQUEST INVALID TOKEN DATA_AREA
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER0}      expected_status=401

DELETE REQUEST NO TOKEN DATA_AREA
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile                            expected_status=401


PUT REQUEST USER1 DATA_AREA2
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=500

PUT REQUEST USER2 DATA_AREA1
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=500

GET FILE USER1 DATA_AREA2
    [Setup]     Add TestFile USER2 DATA AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER1}     expected_status=404
    [Teardown]    Delete TestFile USER2 DATA AREA

GET FILE USER2 DATA_AREA1
    [Setup]     Add TestFile USER1 DATA AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER2}     expected_status=404
    [Teardown]    Delete TestFile USER1 DATA AREA

DELETE REQUEST USER1 DATA_AREA2
    [Setup]     Add TestFile USER2 DATA AREA
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER1}      expected_status=404

DELETE REQUEST USER2 DATA_AREA1
    [Setup]     Add TestFile USER1 DATA AREA
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER2}      expected_status=404

