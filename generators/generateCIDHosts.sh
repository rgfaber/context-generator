#! /bin/bash

generateCIDHosts() {
    cd $1
    cat >publish_hosts.yaml<<EOF
image: mcr.microsoft.com/dotnet/sdk

services:
  - name: docker:dind

variables:
    # CUSTOM VARIABLES
    ## PLEASE MAKE SURE THAT PKG-VERSION and API-VERSION are the same!
    ##  Please keep this value the same as the <Version> attribute in ./src/Directory.Build.props
    API_VERSION: 0.0.0.1
    API_NAME: $2 ## Pascal Case
    IMG_NAME: $3 ## MUST be lowercase per docker image rules
EOF
    cat >>publish_hosts.yaml<<'EOF'
    # CALCULATED VARIABLES AS PER ARCHITECTURE 
    CMD_IMG_TAG: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-cmd:${API_VERSION}
    QRY_IMG_TAG: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-qry:${API_VERSION}
    SUB_IMG_TAG: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-sub:${API_VERSION}
    ETL_IMG_TAG: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-etl:${API_VERSION}
    
    CLI_IMG_TAG: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-cli:${API_VERSION}
    TUI_IMG_TAG: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-tui:${API_VERSION}


    CMD_IMG_TAG_LATEST: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-cmd:latest
    QRY_IMG_TAG_LATEST: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-qry:latest
    SUB_IMG_TAG_LATEST: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-sub:latest
    ETL_IMG_TAG_LATEST: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-etl:latest
    
    CLI_IMG_TAG_LATEST: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-cli:latest
    TUI_IMG_TAG_LATEST: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-tui:latest

    # RELEASE ARTIFACTS
    CONTRACT_PKG: ${API_NAME}.Contract
    SCHEMA_PKG: ${API_NAME}.Schema
    CLIENTS_PKG: ${API_NAME}.Client.Infra

    QRY_HOST: ${API_NAME}.Qry     
    CMD_HOST: ${API_NAME}.Cmd
    SUB_HOST: ${API_NAME}.Sub
    ETL_HOST: ${API_NAME}.Etl
        
    
    CLI_EXE: ${API_NAME}.CLI
    TUI_EXE: ${API_NAME}.TUI

    DOCKER_DRIVER: overlay
    GIT_SUBMODULE_STRATEGY: recursive

stages:
  - publish_hosts
#   - test_images


before_script:
  - git submodule update --init
  - git submodule update --remote
  - chmod +x ./cid/*.sh

publish_cmd:
  stage: publish_hosts
  only:
    - master
  image: virtualstock/docker-git
  script:
    - ./cid/publish_cmd.sh
      
publish_qry:
  stage: publish_hosts
  only:
    - master
  image: virtualstock/docker-git
  script:
    - ./cid/publish_qry.sh

publish_etl:
  stage: publish_hosts
  only:
    - master
  image: virtualstock/docker-git
  script:
    - ./cid/publish_etl.sh

publish_sub:
  stage: publish_hosts
  only:
    - master
  image: virtualstock/docker-git
  script:
    - ./cid/publish_sub.sh
EOF
}
