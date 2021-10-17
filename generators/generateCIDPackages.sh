#! /bin/bash

generateCIDPackages() {
    cd $1
    cat > publish_packages.yaml <<EOF
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

    cat >>publish_packages.ymal<<'EOF'
    # CALCULATED VARIABLES AS PER ARCHITECTURE 

    SCHEMA_PKG: ${API_NAME}.Contract
    CONTRACT_PKG: ${API_NAME}.Contract
    SCHEMA_PKG: ${API_NAME}.Schema

    DOCKER_DRIVER: overlay
    GIT_SUBMODULE_STRATEGY: recursive

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
EOF
}