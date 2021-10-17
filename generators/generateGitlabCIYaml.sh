#! /bin/bash


generateGitlabCIYaml() {
cat >.gitlab-ci.yaml<<'EOF'
image: mcr.microsoft.com/dotnet/sdk

services:
  - name: docker:dind

variables:
    # CUSTOM VARIABLES
    ## PLEASE MAKE SURE THAT PKG-VERSION and API-VERSION are the same!
    ##  Please keep this value the same as the <Version> attribute in ./src/Directory.Build.props
    API_VERSION: 0.0.0.1
    API_NAME: ${api_prefix}
    IMG_NAME: ${img_prefix} ## MUST be lowercase per docker image rules
   
    # CALCULATED VARIABLES AS PER ARCHITECTURE 
    CMD_IMG_TAG: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-cmd:${API_VERSION}
    QRY_IMG_TAG: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-qry:${API_VERSION}
    SUB_IMG_TAG: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-sub:${API_VERSION}
    ETL_IMG_TAG: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-etl:${API_VERSION}


    CMD_IMG_TAG_LATEST: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-cmd:latest
    QRY_IMG_TAG_LATEST: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-qry:latest
    SUB_IMG_TAG_LATEST: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-sub:latest
    ETL_IMG_TAG_LATEST: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-etl:latest

    # RELEASE ARTIFACTS
    QRY_HOST: ${API_NAME}.Qry     
    CMD_HOST: ${API_NAME}.Cmd
    SUB_HOST: ${API_NAME}.Sub
    ETL_HOST: ${API_NAME}.Etl
    
    CONTRACT_PKG: ${API_NAME}.Contract
    SCHEMA_PKG: ${API_NAME}.Schema
    CLIENTS_PKG: ${API_NAME}.Clients
    
    CLI_EXE: ${API_NAME}.CLI

    # TEST ARTIFACTS
    SCHEMA_TEST_PKG: ${API_NAME}.Schema.UnitTests
    DATA_TEST_PKG: ${API_NAME}.Data.UnitTests
    CONTRACT_TEST_PKG: ${API_NAME}.Contract.UnitTests
    DOMAIN_TEST_PKG: ${API_NAME}.Domain.UnitTests
    BDD_TEST_PKG: ${API_NAME}.AcceptanceTests
    CLIENTS_TEST_PKG: ${API_NAME}.Clients.IntegrationTests

    DOCKER_DRIVER: overlay
    GIT_SUBMODULE_STRATEGY: recursive

stages:
  - build_pkg
  - cleanup_pkg
  - publish_pkg
  - test_pkg_pub
  - unit_tests   
  - build_hosts
  - publish_hosts
  - test_hosts
  - integration_tests
  - acceptance_tests
  # - deploy_hosts


before_script:

  - git submodule update --init
  - git submodule update --remote
  - chmod +x ./cid/*.sh


#   - testpub

#############################################
## BUILD JOBS
#############################################

## BUILD PACKAGES
build_pkg:
  stage: build_pkg
  script:
    - ./cid/build_pkg.sh
  artifacts:
    paths:
      - ./PKG
    expire_in: 30 min

## CLEANUP PACKAGES
cleanup_pkg:
  stage: cleanup_pkg
  only:
    - master
  dependencies:
    - build_pkg
  script:
    - ./cid/cleanup_pkg_repo.sh

## TEST PACKAGE  PUBLICATION
test_pkg_pub:
  stage: test_pkg_pub
  only:
    - master
  dependencies:
    - publish_pkg
  script:
    - ./cid/test_pkg_pub.sh
        
#  BUILD QUERY HOST
build_qry:
  stage: build_hosts
  only:
    - master
  script: 
    - ./cid/build_qry.sh
  dependencies:
      - publish_pkg
  artifacts:
    paths:
      - ./QRY
    expire_in: 30 min

# BUILD COMMAND HOST
build_cmd:
  stage: build_hosts
  only:
    - master
  script:
      - ./cid/build_cmd.sh
  dependencies:
      - publish_pkg
  artifacts:
    paths:
      - ./CMD
    expire_in: 30 min


# BUILD SUB HOST
build_sub:
  stage: build_hosts
  only:
    - master
  script:
      - ./cid/build_sub.sh
  dependencies:
      - publish_pkg
  artifacts:
    paths:
      - ./SUB
    expire_in: 30 min

# BUILD ETL HOST
build_etl:
  stage: build_hosts
  only:
    - master
  script:
      - ./cid/build_etl.sh
  dependencies:
      - publish_pkg
  artifacts:
    paths:
      - ./ETL
    expire_in: 30 min
    

#############################################
## PUBLISHING JOBS
#############################################

publish_pkg:
  stage: publish_pkg
  only:
    - master
  dependencies:
    - build_pkg
  script: 
    - ./cid/publish_pkg.sh


publish_etl:
  stage: publish_hosts
  dependencies:
    - build_etl
  only:
    - master
  image: virtualstock/docker-git
  script: 
    - ./cid/publish_etl.sh

publish_qry:
  stage: publish_hosts
  dependencies:
    - build_qry
  only:
    - master
  image: virtualstock/docker-git
  script: 
    - ./cid/publish_qry.sh

publish_cmd:
  stage: publish_hosts
  dependencies:
    - build_cmd
  only:
    - master
  image: virtualstock/docker-git
  script: 
    - ./cid/publish_cmd.sh

publish_sub:
  stage: publish_hosts
  dependencies:
    - build_sub
  only:
    - master
  image: virtualstock/docker-git
  script: 
    - ./cid/publish_sub.sh


#############################################
## TEST HOSTS
#############################################

test_qry:
  stage: test_hosts
  image: virtualstock/docker-git
  only:
    - master
  dependencies:
      - publish_qry
  script:
    - ./cid/test_qry_pub.sh

test_cmd:
  stage: test_hosts
  image: virtualstock/docker-git
  only:
    - master
  dependencies:
    - publish_cmd
  script:
    - ./cid/test_cmd_pub.sh


test_sub:
  stage: test_hosts
  image: virtualstock/docker-git
  only:
    - master
  dependencies:
    - publish_sub
  script:
    - ./cid/test_sub_pub.sh

test_etl:
  stage: test_hosts
  image: virtualstock/docker-git
  only:
    - master
  dependencies:
    - publish_etl
  script:
    - ./cid/test_etl_pub.sh



##########################################################
## Unit Tests
##########################################################
schema_tests:
  stage: unit_tests
  script:
    - ./cid/run_unit_tests.sh ./tests/unit/${SCHEMA_TEST_PKG}
  allow_failure: true
  artifacts:
    paths:
      - ./UNIT-RES
    expire_in: 24 hours

contract_tests:
  stage: unit_tests
  script:
    - ./cid/run_unit_tests.sh ./tests/unit/${CONTRACT_TEST_PKG}
  allow_failure: true
  artifacts:
    paths:
      - ./UNIT-RES
    expire_in: 24 hours

domain_tests:
  stage: unit_tests
  script:
    - ./cid/run_unit_tests.sh ./tests/unit/${DOMAIN_TEST_PKG}
  allow_failure: true
  artifacts:
    paths:
      - ./UNIT-RES
    expire_in: 24 hours


##########################################################
## Integration Tests
##########################################################


client_tests:
  stage: integration_tests
script:
    - ./cid/run_integration_tests.sh ./tests/integration/${CLIENTS_TEST_PKG}
  allow_failure: true
  only: 
    - master
  artifacts:
    paths:
      - ./INT-RES
    expire_in: 24 hours


##########################################################
## Acceptance Tests
##########################################################

bdd_tests:
  stage: acceptance_tests
  script:
    - ./cid/run_acceptance_tests.sh ./tests/acceptance/${BDD_TEST_PKG}
  allow_failure: true
  only: 
    - master
  artifacts:
    paths:
      - ./ACC-RES
    expire_in: 24 hours
EOF    
}