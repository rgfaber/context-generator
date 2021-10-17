#! /bin/bash

generateCIDClients() {
    cd $1
    cat >publish_clients.yaml<<EOF
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
    cat >>publish_clients.yaml<<'EOF'
    # CALCULATED VARIABLES AS PER ARCHITECTURE 
   
    CLI_IMG_TAG: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-cli:${API_VERSION}
    TUI_IMG_TAG: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-tui:${API_VERSION}
    CLI_IMG_TAG_LATEST: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-cli:latest
    TUI_IMG_TAG_LATEST: ${LOGATRON_DOCKER_URL}/${IMG_NAME}-tui:latest
   
    CLI_EXE: ${API_NAME}.CLI
    TUI_EXE: ${API_NAME}.TUI
    DOCKER_DRIVER: overlay
    GIT_SUBMODULE_STRATEGY: recursive

stages:
  - publish_clients
#   - test_images


before_script:
  - git submodule update --init
  - git submodule update --remote
  - chmod +x ./cid/*.sh

publish_cli:
  stage: publish_clients
  only:
    - master
  image: virtualstock/docker-git
  script:
    - ./cid/publish_cli.sh


publish_tui:
  stage: publish_clients
  only:
    - master
  image: virtualstock/docker-git
  script:
    - ./cid/publish_tui.sh



EOF
}
