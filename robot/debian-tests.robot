*** Settings ***

Library          RequestsLibrary
Variables        /__w/teapot/teapot/robot/variables.py

*** Keywords ***

Add TestFile USER1 DEFAULT AREA DEB    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=201

Add TestFile USER2 DEFAULT AREA DEB    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=201

Add TestFile USER1 DATA AREA DEB    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=201

Add TestFile USER2 DATA AREA DEB    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=201

Delete TestFile USER1 DEFAULT AREA DEB     ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER1}      expected_status=204

Delete TestFile USER2 DEFAULT AREA DEB     ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER2}      expected_status=204

Delete TestFile USER1 DATA AREA DEB     ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER1}      expected_status=204

Delete TestFile USER2 DATA AREA DEB     ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER2}      expected_status=204


*** Test Cases ***

GET USER1 DEB
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER1}     expected_status=200

GET USER2 DEB
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER2}     expected_status=200

GET NO TOKEN DEB
    ${RESPONSE}=    GET    ${DEFAULT_AREA}                           expected_status=401

GET INVALID TOKEN DEB
    ${RESPONSE}=    GET    ${DEFAULT_AREA}    headers=${HEADER0}     expected_status=401


PUT REQUEST INVALID TOKEN DEB
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER0}      expected_status=401

PUT REQUEST NO TOKEN DEB
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}                            expected_status=401

PUT REQUEST USER1 DEB
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=201
    [Teardown]    Delete TestFile USER1 DEFAULT AREA DEB

PUT REQUEST USER2 DEB
    ${RESPONSE}=    PUT    ${DEFAULT_AREA}/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=201
    [Teardown]    Delete TestFile USER2 DEFAULT AREA DEB


GET FILE USER1 DEB
    [Setup]     Add TestFile USER1 DEFAULT AREA DEB
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile    headers=${HEADER1}     expected_status=200
    [Teardown]    Delete TestFile USER1 DEFAULT AREA DEB

GET FILE USER2 DEB
    [Setup]     Add TestFile USER2 DEFAULT AREA DEB
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile    headers=${HEADER2}     expected_status=200
    [Teardown]    Delete TestFile USER2 DEFAULT AREA DEB

GET FILE NO TOKEN DEB
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile                           expected_status=401

GET FILE INVALID TOKEN DEB
    ${RESPONSE}=    GET    ${DEFAULT_AREA}/TestFile    headers=${HEADER0}     expected_status=401


DELETE REQUEST USER1 DEB
    [Setup]     Add TestFile USER1 DEFAULT AREA DEB
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER1}      expected_status=204

DELETE REQUEST USER2 DEB
    [Setup]     Add TestFile USER2 DEFAULT AREA DEB
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER2}      expected_status=204

DELETE REQUEST INVALID TOKEN DEB
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile    headers=${HEADER0}      expected_status=401


DELETE REQUEST NO TOKEN DEB
    ${RESPONSE}=    DELETE    ${DEFAULT_AREA}/TestFile                            expected_status=401


GET USER1 DATA_AREA DEB
    ${RESPONSE}=    GET    ${DATA_AREA}/    headers=${HEADER1}     expected_status=200

GET USER2 DATA_AREA DEB
    ${RESPONSE}=    GET    ${DATA_AREA}/   headers=${HEADER2}     expected_status=200

GET NO TOKEN DATA_AREA DEB
    ${RESPONSE}=    GET    ${DATA_AREA}/                           expected_status=401

GET INVALID TOKEN DATA_AREA DEB
    ${RESPONSE}=    GET    ${DATA_AREA}/    headers=${HEADER0}     expected_status=401


PUT REQUEST INVALID TOKEN DATA_AREA DEB
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER0}      expected_status=401

PUT REQUEST NO TOKEN DATA_AREA DEB
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}                            expected_status=401

PUT REQUEST USER1 DATA_AREA DEB
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=201
    [Teardown]    Delete TestFile USER1 DATA AREA DEB

PUT REQUEST USER2 DATA_AREA DEB
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=201
    [Teardown]    Delete TestFile USER2 DATA AREA DEB


GET FILE USER1 DATA_AREA DEB
    [Setup]     Add TestFile USER1 DATA AREA DEB
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER1}     expected_status=200
    [Teardown]    Delete TestFile USER1 DATA AREA DEB

GET FILE USER2 DATA_AREA DEB
    [Setup]     Add TestFile USER2 DATA AREA DEB
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER2}     expected_status=200
    [Teardown]    Delete TestFile USER2 DATA AREA DEB

GET FILE NO TOKEN DATA_AREA DEB
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile                           expected_status=401

GET FILE INVALID TOKEN DATA_AREA DEB
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER0}     expected_status=401


DELETE REQUEST USER1 DATA_AREA DEB
    [Setup]     Add TestFile USER1 DATA AREA DEB
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER1}      expected_status=204

DELETE REQUEST USER2 DATA_AREA DEB
    [Setup]     Add TestFile USER2 DATA AREA DEB
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER2}      expected_status=204

DELETE REQUEST INVALID TOKEN DATA_AREA DEB
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER0}      expected_status=401

DELETE REQUEST NO TOKEN DATA_AREA DEB
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile                            expected_status=401


PUT REQUEST USER1 DATA_AREA2 DEB
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user2/TestFile    data=${DATA}    headers=${HEADER1}      expected_status=500

PUT REQUEST USER2 DATA_AREA1 DEB
    ${RESPONSE}=    PUT    ${DATA_AREA}/test-user1/TestFile    data=${DATA}    headers=${HEADER2}      expected_status=500

GET FILE USER1 DATA_AREA2 DEB
    [Setup]     Add TestFile USER2 DATA AREA DEB
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER1}     expected_status=404
    [Teardown]    Delete TestFile USER2 DATA AREA DEB

GET FILE USER2 DATA_AREA1 DEB
    [Setup]     Add TestFile USER1 DATA AREA DEB
    ${RESPONSE}=    GET    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER2}     expected_status=404
    [Teardown]    Delete TestFile USER1 DATA AREA DEB

DELETE REQUEST USER1 DATA_AREA2 DEB
    [Setup]     Add TestFile USER2 DATA AREA DEB
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user2/TestFile    headers=${HEADER1}      expected_status=404

DELETE REQUEST USER2 DATA_AREA1 DEB
    [Setup]     Add TestFile USER1 DATA AREA DEB
    ${RESPONSE}=    DELETE    ${DATA_AREA}/test-user1/TestFile    headers=${HEADER2}      expected_status=404

