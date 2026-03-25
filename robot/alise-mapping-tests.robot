*** Settings ***

Library          RequestsLibrary
Variables        /__w/teapot/teapot/robot/variables.py

*** Keywords ***

Add TestFile ALISE USER1 DEFAULT AREA    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER_A1}      expected_status=201

Add TestFile ALISE USER2 DEFAULT AREA    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER_A2}      expected_status=201

Add TestFile ALISE USER1 DATA AREA    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER_A1}      expected_status=201

Add TestFile ALISE USER2 DATA AREA    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER_A2}      expected_status=201

Delete TestFile ALISE USER1 DEFAULT AREA     ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER_A1}      expected_status=204

Delete TestFile ALISE USER2 DEFAULT AREA     ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER_A2}      expected_status=204

Delete TestFile ALISE USER1 DATA AREA     ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER_A1}      expected_status=204

Delete TestFile ALISE USER2 DATA AREA     ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER_A2}      expected_status=204


*** Test Cases ***

GET USER1 - ALISE
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER_A1}     expected_status=200

GET USER2 - ALISE
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER_A2}     expected_status=200

GET NO TOKEN - ALISE
    ${RESPONSE}=    GET    ${DEFAULT_AREA}                           expected_status=401

GET INVALID TOKEN - ALISE
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER0}     expected_status=401


PUT REQUEST INVALID TOKEN - ALISE
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER0}      expected_status=401

PUT REQUEST NO TOKEN - ALISE
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}                            expected_status=401

PUT REQUEST USER1 - ALISE
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER_A1}      expected_status=201
    [Teardown]    Delete TestFile ALISE USER1 DEFAULT AREA

PUT REQUEST USER2 - ALISE
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER_A2}      expected_status=201
    [Teardown]    Delete TestFile ALISE USER2 DEFAULT AREA


GET FILE USER1 - ALISE
    [Setup]     Add TestFile ALISE USER1 DEFAULT AREA
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile    headers=${HEADER_A1}     expected_status=200
    [Teardown]    Delete TestFile ALISE USER1 DEFAULT AREA

GET FILE USER2 - ALISE
    [Setup]     Add TestFile ALISE USER2 DEFAULT AREA
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile    headers=${HEADER_A2}     expected_status=200
    [Teardown]    Delete TestFile ALISE USER2 DEFAULT AREA

GET FILE NO TOKEN - ALISE
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile                           expected_status=401

GET FILE INVALID TOKEN - ALISE
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile    headers=${HEADER0}     expected_status=401


DELETE REQUEST USER1 - ALISE
    [Setup]     Add TestFile ALISE USER1 DEFAULT AREA
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER_A1}      expected_status=204

DELETE REQUEST USER2 - ALISE
    [Setup]     Add TestFile ALISE USER2 DEFAULT AREA
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER_A2}      expected_status=204

DELETE REQUEST INVALID TOKEN - ALISE
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER0}      expected_status=401


DELETE REQUEST NO TOKEN - ALISE
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile                            expected_status=401


GET ALISE USER1 DATA_AREA - ALISE
    ${RESPONSE}=    GET    ${DATA_AREA}/    headers=${HEADER_A1}     expected_status=200

GET ALISE USER2 DATA_AREA - ALISE
    ${RESPONSE}=    GET    ${DATA_AREA}/   headers=${HEADER_A2}     expected_status=200

GET NO TOKEN DATA_AREA - ALISE
    ${RESPONSE}=    GET    ${DATA_AREA}/                           expected_status=401

GET INVALID TOKEN DATA_AREA - ALISE
    ${RESPONSE}=    GET    ${DATA_AREA}/    headers=${HEADER0}     expected_status=401


PUT REQUEST INVALID TOKEN DATA_AREA - ALISE
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER0}      expected_status=401

PUT REQUEST NO TOKEN DATA_AREA - ALISE
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}                            expected_status=401

PUT REQUEST ALISE USER1 DATA_AREA - ALISE
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER_A1}      expected_status=201
    [Teardown]    Delete TestFile ALISE USER1 DATA AREA

PUT REQUEST ALISE USER2 DATA_AREA - ALISE
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER_A2}      expected_status=201
    [Teardown]    Delete TestFile ALISE USER2 DATA AREA


GET FILE ALISE USER1 DATA_AREA - ALISE
    [Setup]     Add TestFile ALISE USER1 DATA AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER_A1}     expected_status=200
    [Teardown]    Delete TestFile ALISE USER1 DATA AREA

GET FILE ALISE USER2 DATA_AREA - ALISE
    [Setup]     Add TestFile ALISE USER2 DATA AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER_A2}     expected_status=200
    [Teardown]    Delete TestFile ALISE USER2 DATA AREA

GET FILE NO TOKEN DATA_AREA - ALISE
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile                           expected_status=401

GET FILE INVALID TOKEN DATA_AREA - ALISE
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER0}     expected_status=401


DELETE REQUEST ALISE USER1 DATA_AREA - ALISE
    [Setup]     Add TestFile ALISE USER1 DATA AREA
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER_A1}      expected_status=204

DELETE REQUEST ALISE USER2 DATA_AREA - ALISE
    [Setup]     Add TestFile ALISE USER2 DATA AREA
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER_A2}      expected_status=204

DELETE REQUEST INVALID TOKEN DATA_AREA - ALISE
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER0}      expected_status=401

DELETE REQUEST NO TOKEN DATA_AREA - ALISE
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile                            expected_status=401


PUT REQUEST ALISE USER1 DATA_AREA2 - ALISE
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER_A1}      expected_status=500

PUT REQUEST ALISE USER2 DATA_AREA1 - ALISE
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER_A2}      expected_status=500

GET FILE ALISE USER1 DATA_AREA2 - ALISE
    [Setup]     Add TestFile ALISE USER2 DATA AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER_A1}     expected_status=404
    [Teardown]    Delete TestFile ALISE USER2 DATA AREA

GET FILE ALISE USER2 DATA_AREA1 - ALISE
    [Setup]     Add TestFile ALISE USER1 DATA AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER_A2}     expected_status=404
    [Teardown]    Delete TestFile ALISE USER1 DATA AREA

DELETE REQUEST ALISE USER1 DATA_AREA2 - ALISE
    [Setup]     Add TestFile ALISE USER2 DATA AREA
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER_A1}      expected_status=404

DELETE REQUEST ALISE USER2 DATA_AREA1 - ALISE
    [Setup]     Add TestFile ALISE USER1 DATA AREA
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER_A2}      expected_status=404

