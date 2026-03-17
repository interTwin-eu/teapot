*** Settings ***

Library          RequestsLibrary
Variables        /__w/teapot/teapot/robot/variables.py

*** Keywords ***

Add TestFile USER1 DATA AREA1 VO    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=201

Add TestFile USER3 DATA AREA2 VO    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER3}      expected_status=201

Delete TestFile USER1 DATA AREA1 VO     ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER1}      expected_status=204

Delete TestFile USER3 DATA AREA2 VO     ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER3}      expected_status=204


*** Test Cases ***

GET NO TOKEN DATA_AREA VO
    ${RESPONSE}=    GET    ${DATA_AREA}/                           expected_status=401

GET INVALID TOKEN DATA_AREA VO
    ${RESPONSE}=    GET    ${DATA_AREA}/    headers=${HEADER0}     expected_status=401

GET USER1 DATA_AREA VO
    ${RESPONSE}=    GET    ${DATA_AREA}/    headers=${HEADER1}     expected_status=200

GET USER2 DATA_AREA VO
    ${RESPONSE}=    GET    ${DATA_AREA}/   headers=${HEADER2}     expected_status=200

GET USER3 DATA_AREA VO
    ${RESPONSE}=    GET    ${DATA_AREA}/   headers=${HEADER3}     expected_status=200

GET USER4 DATA_AREA VO
    ${RESPONSE}=    GET    ${DATA_AREA}/   headers=${HEADER4}     expected_status=403


PUT REQUEST NO TOKEN DATA_AREA1 VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}                            expected_status=401

PUT REQUEST INVALID TOKEN DATA_AREA1 VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER0}      expected_status=401

PUT REQUEST USER1 DATA_AREA1 VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=201
    [Teardown]    Delete TestFile USER1 DATA AREA1 VO

PUT REQUEST USER2 DATA_AREA1 VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=201
    [Teardown]    Delete TestFile USER1 DATA AREA1 VO

PUT REQUEST USER3 DATA_AREA1 VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER3}      expected_status=401

PUT REQUEST USER4 DATA_AREA1 VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER4}      expected_status=401

GET FILE NO TOKEN DATA_AREA1 VO
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile                           expected_status=401

GET FILE INVALID TOKEN DATA_AREA1 VO
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER0}     expected_status=401

GET FILE USER1 DATA_AREA1 VO
    [Setup]     Add TestFile USER1 DATA AREA1 VO
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER1}     expected_status=200
    [Teardown]    Delete TestFile USER1 DATA AREA1 VO

GET FILE USER2 DATA_AREA1 VO
    [Setup]     Add TestFile USER1 DATA AREA1 VO
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER2}     expected_status=200
    [Teardown]    Delete TestFile USER1 DATA AREA1 VO

GET FILE USER3 DATA_AREA1 VO
    [Setup]     Add TestFile USER1 DATA AREA1 VO
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER3}     expected_status=404
    [Teardown]    Delete TestFile USER1 DATA AREA1 VO

GET FILE USER4 DATA_AREA1 VO
    [Setup]     Add TestFile USER1 DATA AREA1 VO
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER4}     expected_status=404
    [Teardown]    Delete TestFile USER1 DATA AREA1 VO

DELETE REQUEST NO TOKEN DATA_AREA1 VO
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile                            expected_status=401

DELETE REQUEST INVALID TOKEN DATA_AREA1 VO
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER0}      expected_status=401

DELETE REQUEST USER1 DATA_AREA1 VO
    [Setup]     Add TestFile USER1 DATA AREA1 VO
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER1}      expected_status=204

DELETE REQUEST USER2 DATA_AREA1 VO
    [Setup]     Add TestFile USER1 DATA AREA1 VO
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER2}      expected_status=204

DELETE REQUEST USER3 DATA_AREA1 VO
    [Setup]     Add TestFile USER1 DATA AREA1 VO
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER3}      expected_status=401
    [Teardown]    Delete TestFile USER1 DATA AREA1 VO

DELETE REQUEST USER4 DATA_AREA1 VO
    [Setup]     Add TestFile USER1 DATA AREA1 VO
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER4}      expected_status=401
    [Teardown]    Delete TestFile USER1 DATA AREA1 VO


PUT REQUEST NO TOKEN DATA_AREA2 VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}                            expected_status=401

PUT REQUEST INVALID TOKEN DATA_AREA2 VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER0}      expected_status=401

PUT REQUEST USER1 DATA_AREA2 VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=401

PUT REQUEST USER2 DATA_AREA2 VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=401

PUT REQUEST USER3 DATA_AREA2 VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER3}      expected_status=201
    [Teardown]    Delete TestFile USER3 DATA AREA2 VO

PUT REQUEST USER4 DATA_AREA2 VO
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER4}      expected_status=401

GET FILE NO TOKEN DATA_AREA2 VO
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user2/TestFile                           expected_status=401

GET FILE INVALID TOKEN DATA_AREA2 VO
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER0}     expected_status=401

GET FILE USER1 DATA_AREA2 VO
    [Setup]     Add TestFile USER3 DATA AREA2 VO
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER1}     expected_status=404
    [Teardown]    Delete TestFile USER3 DATA AREA2 VO

GET FILE USER2 DATA_AREA2 VO
    [Setup]     Add TestFile USER3 DATA AREA2 VO
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER2}     expected_status=404
    [Teardown]    Delete TestFile USER3 DATA AREA2 VO

GET FILE USER3 DATA_AREA2 VO
    [Setup]     Add TestFile USER3 DATA AREA2 VO
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER3}     expected_status=200
    [Teardown]    Delete TestFile USER3 DATA AREA2 VO

GET FILE USER4 DATA_AREA2 VO
    [Setup]     Add TestFile USER3 DATA AREA2 VO
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER4}     expected_status=404
    [Teardown]    Delete TestFile USER3 DATA AREA2 VO

DELETE REQUEST NO TOKEN DATA_AREA2 VO
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile                            expected_status=401

DELETE REQUEST INVALID TOKEN DATA_AREA2 VO
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER0}      expected_status=401

DELETE REQUEST USER1 DATA_AREA2 VO
    [Setup]     Add TestFile USER3 DATA AREA2 VO
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER1}      expected_status=401
    [Teardown]    Delete TestFile USER3 DATA AREA2 VO

DELETE REQUEST USER2 DATA_AREA2 VO
    [Setup]     Add TestFile USER3 DATA AREA2 VO
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER2}      expected_status=401
    [Teardown]    Delete TestFile USER3 DATA AREA2 VO

DELETE REQUEST USER3 DATA_AREA2 VO
    [Setup]     Add TestFile USER3 DATA AREA2 VO
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER3}      expected_status=204

DELETE REQUEST USER4 DATA_AREA2 VO
    [Setup]     Add TestFile USER3 DATA AREA2 VO
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER4}      expected_status=401
    [Teardown]    Delete TestFile USER3 DATA AREA2 VO