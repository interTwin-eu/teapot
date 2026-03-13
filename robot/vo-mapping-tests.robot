*** Settings ***

Library          RequestsLibrary
Variables        /__w/teapot/teapot/robot/variables.py

*** Keywords ***

Add TestFile USER1 DEFAULT AREA VO    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=201

Add TestFile USER2 DEFAULT AREA VO    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=201

Add TestFile USER1 DATA AREA VO    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=201

Add TestFile USER2 DATA AREA VO    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=201

Delete TestFile USER1 DEFAULT AREA VO     ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER1}      expected_status=204

Delete TestFile USER2 DEFAULT AREA VO     ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER2}      expected_status=204

Delete TestFile USER1 DATA AREA VO     ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER1}      expected_status=204

Delete TestFile USER2 DATA AREA VO     ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER2}      expected_status=204


*** Test Cases ***

GET USER1 VO
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER1}     expected_status=200

GET USER2 VO
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER2}     expected_status=200

GET NO TOKEN VO
    ${RESPONSE}=    GET    ${DEFAULT_AREA}                           expected_status=401

GET INVALID TOKEN VO
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER0}     expected_status=401


PUT REQUEST INVALID TOKEN VO
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER0}      expected_status=401

PUT REQUEST NO TOKEN VO
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}                            expected_status=401

PUT REQUEST USER1 VO
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=201
    [Teardown]    Delete TestFile USER1 DEFAULT AREA

PUT REQUEST USER2 VO
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=201
    [Teardown]    Delete TestFile USER2 DEFAULT AREA


GET FILE USER1 VO
    [Setup]     Add TestFile USER1 DEFAULT AREA
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile    headers=${HEADER1}     expected_status=200
    [Teardown]    Delete TestFile USER1 DEFAULT AREA

GET FILE USER2 VO
    [Setup]     Add TestFile USER2 DEFAULT AREA
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile    headers=${HEADER2}     expected_status=200
    [Teardown]    Delete TestFile USER2 DEFAULT AREA

GET FILE NO TOKEN VO
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile                           expected_status=401

GET FILE INVALID TOKEN VO
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile    headers=${HEADER0}     expected_status=401


DELETE REQUEST USER1 VO
    [Setup]     Add TestFile USER1 DEFAULT AREA
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER1}      expected_status=204

DELETE REQUEST USER2 VO
    [Setup]     Add TestFile USER2 DEFAULT AREA
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER2}      expected_status=204

DELETE REQUEST INVALID TOKEN VO
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER0}      expected_status=401


DELETE REQUEST NO TOKEN VO
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile                            expected_status=401


GET USER1 DATA_AREA VO
    ${RESPONSE}=    GET    ${DATA_AREA}/    headers=${HEADER1}     expected_status=200

GET USER2 DATA_AREA VO
    ${RESPONSE}=    GET    ${DATA_AREA}/   headers=${HEADER2}     expected_status=200

GET NO TOKEN DATA_AREA VO
    ${RESPONSE}=    GET    ${DATA_AREA}/                           expected_status=401

GET INVALID TOKEN DATA_AREA VO
    ${RESPONSE}=    GET    ${DATA_AREA}/    headers=${HEADER0}     expected_status=401


PUT REQUEST INVALID TOKEN DATA_AREA VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER0}      expected_status=401

PUT REQUEST NO TOKEN DATA_AREA VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}                            expected_status=401

PUT REQUEST USER1 DATA_AREA VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=201
    [Teardown]    Delete TestFile USER1 DATA AREA

PUT REQUEST USER2 DATA_AREA VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=201
    [Teardown]    Delete TestFile USER2 DATA AREA


GET FILE USER1 DATA_AREA VO
    [Setup]     Add TestFile USER1 DATA AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER1}     expected_status=200
    [Teardown]    Delete TestFile USER1 DATA AREA

GET FILE USER2 DATA_AREA VO
    [Setup]     Add TestFile USER2 DATA AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER2}     expected_status=200
    [Teardown]    Delete TestFile USER2 DATA AREA

GET FILE NO TOKEN DATA_AREA VO
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile                           expected_status=401

GET FILE INVALID TOKEN DATA_AREA VO
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER0}     expected_status=401


DELETE REQUEST USER1 DATA_AREA VO
    [Setup]     Add TestFile USER1 DATA AREA
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER1}      expected_status=204

DELETE REQUEST USER2 DATA_AREA VO
    [Setup]     Add TestFile USER2 DATA AREA
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER2}      expected_status=204

DELETE REQUEST INVALID TOKEN DATA_AREA VO
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER0}      expected_status=401

DELETE REQUEST NO TOKEN DATA_AREA VO
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile                            expected_status=401


PUT REQUEST USER1 DATA_AREA2 VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=500

PUT REQUEST USER2 DATA_AREA1 VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=500

GET FILE USER1 DATA_AREA2 VO
    [Setup]     Add TestFile USER2 DATA AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER1}     expected_status=500
    [Teardown]    Delete TestFile USER2 DATA AREA

GET FILE USER2 DATA_AREA1 VO
    [Setup]     Add TestFile USER1 DATA AREA
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER2}     expected_status=500
    [Teardown]    Delete TestFile USER1 DATA AREA

DELETE REQUEST USER1 DATA_AREA2 VO
    [Setup]     Add TestFile USER2 DATA AREA
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER1}      expected_status=500

DELETE REQUEST USER2 DATA_AREA1 VO
    [Setup]     Add TestFile USER1 DATA AREA
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER2}      expected_status=500

