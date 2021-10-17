#! /bin/bash -x

# set -eu

generateContractConfig() {
 
  cd $target_dir/src/internal/$1.Contract

  cat > Config.cs <<EOF
namespace $1.Contract
{
    public static class Config
    {

        public static class Errors
        {
            public const string ApiError = "$1.ApiError";
            public const string ServiceError = "$1.ApiError";
            public const string WebError = "$1.WebError";
        }


        public static class Hopes
        {
            public const string Initialize = "$1.Initialize";
        }

        public static class Facts
        {
            public const string Initialized = "$1.Initialized";            
        }


        public static class HopeEndpoints
        {
            public const string Initialize = "/initialize";
        }

        
        public static class QueryEndpoints
        {
            public const string First20 = "/first-20";
            public const string ById = "/by-id";
        }
        
    }
}  
EOF
}


generateSchemaRoot() {
  cd $target_dir/src/internal/$1.Schema
  cat> Root.cs <<EOF
using M5x.DEC.Schema;

namespace $1.Schema
{
    public record Root : IStateEntity<Schema.Aggregate.ID>
    {
        public Root()
        {
        }

        // TODO: Add Root Components

        public static Root CreateNew(// TODO: )
        {
            return new(dischargeReport, workOrder);
        }

        public string Id { get; set; }
        public string Prev { get; set; }
        public AggregateInfo AggregateInfo { get; set; }
    }
}
EOF

}





generateGitlabCI() {
    ce $target_dir
    cat >.gitlab-ci.yml<<EOF
image: mcr.microsoft.com/dotnet/sdk

services:
  - name: docker:dind

variables:
    # CUSTOM VARIABLES
    ## PLEASE MAKE SURE THAT PKG-VERSION and API-VERSION are the same!
    ##  Please keep this value the same as the <Version> attribute in ./src/Directory.Build.props
    API_VERSION: 0.0.0.1
    API_NAME: $1 ## Pascal Case
    IMG_NAME: $2 ## MUST be lowercase per docker image rules
EOF
    cat >>.gitlab-ci.yml<<'EOF'
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
  - unit_tests   
  - build_pkg
  - cleanup_pkg
  - publish_pkg
  - test_pkg_pub
  - build_images
  - publish_images
  - test_images
  - integration_tests
  - acceptance_tests


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
        
## BUILD HOSTS
build_hosts:
  stage: build_images
  only:
    - master
  script:
    - ./cid/build_hosts.sh
  dependencies:
    - publish_pkg
  artifacts:
    paths:
      - ./CMD
      - ./ETL
      - ./QRY
      - ./SUB
    expire_in: 30 min

## BUILD CLIENTS
build_clients:
  stage: build_images
  only:
    - master
  script:
    - ./cid/build_clients.sh
  dependencies:
    - publish_pkg
  artifacts:
    paths:
      - ./CLI
      - ./TUI
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

publish_images:
  stage: publish_images
  dependencies:
    - build_hosts
    - build_clients
  only:
    - master
  image: virtualstock/docker-git
  script:
    - ./cid/publish_images.sh

#############################################
## TEST IMAGES
#############################################
test_imgs:
  stage: test_images
  image: virtualstock/docker-git
  only:
    - master
  dependencies:
    - publish_images
  script:
    - ./cid/test_images.sh


##########################################################
## Unit Tests
##########################################################
# schema_tests:
#   stage: unit_tests
#   script:
#     - ./cid/run_unit_tests.sh ./tests/unit/${SCHEMA_TEST_PKG}
#   allow_failure: true
#   artifacts:
#     paths:
#       - ./UNIT-RES
#     expire_in: 24 hours

# contract_tests:
#   stage: unit_tests
#   script:
#     - ./cid/run_unit_tests.sh ./tests/unit/${CONTRACT_TEST_PKG}
#   allow_failure: true
#   artifacts:
#     paths:
#       - ./UNIT-RES
#     expire_in: 24 hours

# domain_tests:
#   stage: unit_tests
#   script:
#     - ./cid/run_unit_tests.sh ./tests/unit/${DOMAIN_TEST_PKG}
#   allow_failure: true
#   artifacts:
#     paths:
#       - ./UNIT-RES
#     expire_in: 24 hours

## Check: https://git.macula.io/help/ci/unit_test_reports

schema_tests:
  stage: unit_tests
  script:
    - ./cid/run_junit_tests.sh ./tests/unit/${SCHEMA_TEST_PKG}
  allow_failure: true
  artifacts:
    paths:
      - ./**/*test-result.xml
    reports:
      junit:
        - ./**/*test-result.xml
    expire_in: 24 hours

contract_tests:
  stage: unit_tests
  script:
    - ./cid/run_junit_tests.sh ./tests/unit/${CONTRACT_TEST_PKG}
  allow_failure: true
  artifacts:
    paths:
      - ./**/*test-result.xml
    reports:
      junit:
        - ./**/*test-result.xml
    expire_in: 24 hours

domain_tests:
  stage: unit_tests
  script:
    - ./cid/run_junit_tests.sh ./tests/unit/${DOMAIN_TEST_PKG}
  allow_failure: true
  artifacts:
    paths:
      - ./**/*test-result.xml
    reports:
      junit:
        - ./**/*test-result.xml
    expire_in: 24 hours

##########################################################
## Integration Tests
##########################################################

int_tests:
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



buildHostContainers() {
    cd $target_dir/src/hosts/$1.Cmd
    ./build.sh
    cd $target_dir/src/hosts/$1.Qry
    ./build.sh
    cd $target_dir/src/hosts/$1.Sub
    ./build.sh
    cd $target_dir/src/hosts/$1.Etl
    ./build.sh
}

buildClientContainers() {
    cd $target_dir/src/clients/$1.CLI
    ./build.sh
    cd $target_dir/src/clients/$1.TUI
    ./build.sh
}




generateDeploy() {
    mkdir -p $target_dir/deploy
    cd $target_dir/deploy 
    generateBackendDeploy cmd
    generateBackendDeploy qry
    generateBackendDeploy sub
    generateBackendDeploy etl
    generateClientDeploy cli
    generateClientDeploy tui
    cd $target_dir
}


generateAcceptanceTests() {
  mkdir -p $target_dir/tests/acceptance
  cd $target_dir/tests/acceptance 
  dotnet new classlib -n $1.AcceptanceTests
  cd $target_dir/tests/acceptance/$1.AcceptanceTests
  dotnet new specflowproject -n $1.AcceptanceTests --force
  cd $target_dir
}



generateCLI() {
  mkdir -p $target_dir/src/clients
  cd $target_dir/src/clients
  generateConsole $1.CLI $2-cli
  cd $target_dir/src/clients/$1.CLI
  dotnet add reference ../$1.Client.Infra
  cd $target_dir    
}

generateTUI() {
  mkdir -p $target_dir/src/clients
  cd $target_dir/src/clients
  generateConsole $1.TUI $2-tui
  cd $target_dir/src/clients/$1.TUI
  dotnet add reference ../$1.Client.Infra
  cd $target_dir    
}





prepareRepo() {
    ### Install the SpecFlow Templates
    cd $target_dir
    dotnet new --install SpecFlow.Templates.DotNet::3.9.8
    dotnet nuget remove source 'M5x SDK Nugets'
    dotnet nuget remove source 'Logatron Nugets'
    dotnet nuget add source "$sdk_nugets_url" -n 'M5x SDK Nugets' -u "$user" -p "$password" --store-password-in-clear-text
    dotnet nuget add source "$logatron_nugets_url" -n 'Logatron Nugets' -u "$user" -p "$password" --store-password-in-clear-text
    
    git branch develop

    rm -rf $target_dir/.git/modules/cid
    rm -rf $target_dir/cid

    git submodule add $cid_repo
    git submodule update --init
    git submodule update --remote
}


assemblePackageSolution() {
  cd $target_dir
  dotnet new sln -n     $1.pkg
  addInternals          $1.pkg.sln
  addInfra              $1.root.sln
  addHosts              $1.root.sln
  addClients            $1.root.sln
  addBogus              $1.root.sln
  addUnitTests          $1.root.sln
  addIntegrationTests   $1.root.sln
  addAcceptanceTests    $1.root.sln
}




generateTest() {
    dotnet new classlib -n "$1"
    cd $1
    rm -rf Class1.cs
    dotnet add package -n $testkit_sdk                  -v $sdk_version
    dotnet add package -n xunit.runner.visualstudio     -v 2.4.1
}


generateSchemaConfig() {
    cd $target_dir/internal/$1.Schema
    cat >Constants.cs<<EOF
namespace $1.Schema
{
    public static class Constants
    {

        public static class Hopes
        {
            public const string Initialize = "$1.Initialize";
        }

        public static class Facts
        {
            public const string Initialized = "$1.Initialized";
        }


        public static class Attributes
        {
            public const string IDPrefix = "$2";
            public const string DbName = "$3-db";
        }

        public static class Errors
        {
            public const string ServiceError = "$1.ServiceError";
            public const string DomainError = "$1.DomainError";
            public const string WebError = "$1.WebError";
            public const string ApiError = "$1.ApiError";            
            public const string Exception = "$1.Exception";
        }


        public static class Statuses
        {
            public const string Unknown = "$1.Unknown";
            public const string Initialized = "$1.Initialized";
        }
    }
}
EOF
}

generateSchemaAggregateID() {
    cd $target_dir/internal/$1.Schema
    cat >Aggregate.cs<<EOF
using System;
using System.Runtime.Serialization;
using M5x.DEC.Schema;


namespace $1.Schema
{
    public static class Aggregate
    {
        
        [Flags]
        public enum Status
        {
            [EnumMember(Value = Constants.Statuses.Unknown)]Unknown = 0,
            [EnumMember(Value = Constants.Statuses.Initialized)]Initialized = 1
        }   
        
        
        [IDPrefix(Constants.Attributes.IDPrefix)]
        public record ID : Identity<ID>
        {
            public ID(string value) : base(value)
            {
            }

            public ID() : base(New.Value)
            {
            }

            public static ID CreateNew(string id)
            {
                return With(id);
            }
            
            
        }
        
    }
}
EOF
}


generateSchemaPackage() {
   
    # generate schema classlib
    mkdir -p $target_dir/internal
    cd $target_dir/internal
    dotnet new classlib -n $1.Schema
    cd $target_dir/internal/$1.Schema
    rm -rf Class1.cs
    dotnet add package        $schema_sdk  -v $sdk_version
    generateSchemaConfig      $api_prefix     $id_prefix  $img_prefix
    generateSchemaAggregateID $api_prefix  

    # Schema Bogus Generators
    mkdir -p $target_dir/internal
    cd $target_dir/internal
    dotnet new classlib -n $1.Schema.Bogus
    cd $target_dir/internal/$1.Schema.Bogus
    rm -rf Class1.cs
    dotnet add package $bogus_sdk  -v $sdk_version
    dotnet add reference $target_dir/schema/$1.Schema

    ## generate schema test
    mkdir -p $target_dir/schema
    cd $target_dir/schema
    dotnet new classlib -n $1.Schema.UnitTests
    cd $target_dir/internal/$1.Schema.UnitTests
    rm -rf Class1.cs
    dotnet add package -n $testkit_sdk                  -v $sdk_version
    dotnet add package -n xunit.runner.visualstudio     -v 2.4.1

}




generateContractPackage() {
    
    ## Generate Contract Classlib
    mkdir -p $target_dir/internal
    cd $target_dir/internal
    dotnet new classlib -n $1.Contract
    cd $target_dir/internal/$1.Contract
    rm -rf Class1.cs
    dotnet add package $schema_sdk  -v $sdk_version
    dotnet add package $swagger_sdk  -v $sdk_version
    dotnet add reference $target_dir/internal/$1.Schema
    generateContractConfig $1

    ## Generate Contract Unit Test
    mkdir -p $target_dir/internal
    cd $target_dir/internal
    generateTest $1.Contract.UnitTests
    cd $target_dir/internal/$1.Contract.UnitTests
    dotnet add reference $target_dir/internal/$1.Contract
}


generateDomainPackage() {

    ## Generate Domain Classlib
    mkdir -p $target_dir/internal
    cd $target_dir/internal
    dotnet new classlib -n $1.Domain
    cd $target_dir/internal/$1.Domain
    rm -rf Class1.cs
    dotnet add package $schema_sdk  -v $sdk_version
    dotnet add package $domain_sdk  -v $sdk_version
    dotnet add reference $target_dir/internal/$1.Contract
    
    # generateDomainAggregate
    # generateDomainRepo

    mkdir -p $target_dir/internal
    cd $target_dir/internal
    generateTest $1.Domain.UnitTests
    dotnet add reference $target_dir/src/internal/$1.Domain
}


generateCmdInfra() {
    # Package
    mkdir -p $target_dir/src/hosts
    cd $target_dir/src/hosts
    dotnet new classlib -n $1.Cmd.Infra
    cd $target_dir/src/hosts/$1.Cmd.Infra
    rm -rf Class1.cs
    
    dotnet add package $schema_sdk  -v $sdk_version
    dotnet add package $infra_sdk  -v $sdk_version

    dotnet add reference $target_dir/src/internal/$1.Domain
   
    # UnitTest
    mkdir -p $target_dir/tests/integration
    cd $target_dir/tests/integration
    generateTest $1.Cmd.Infra.IntegrationTests
    dotnet add reference $target_dir/src/hosts/$1.Cmd.Infra

    # Host
    mkdir -p $target_dir/src/hosts
    cd $target_dir/src/hosts
    generateHost $1.Cmd $2-cmd
    cd $target_dir/src/hosts/$1.Cmd
    dotnet add reference $target_dir/src/hosts/$1.Cmd.Infra
}


generateQryInfra() {
    # Package
    mkdir -p $target_dir/src/hosts
    cd $target_dir/src/hosts
    dotnet new classlib -n $1.Qry.Infra
    cd $target_dir/src/hosts/$1.Qry.Infra
    rm -rf Class1.cs
    
    dotnet add reference $target_dir/src/internal/$1.Contract
    dotnet add package $schema_sdk  -v $sdk_version
    dotnet add package $infra_sdk  -v $sdk_version
   
    # UnitTest
    mkdir -p $target_dir/tests/integration
    cd $target_dir/tests/integration
    generateTest $1.Qry.Infra.IntegrationTests
    dotnet add reference $target_dir/src/hosts/$1.Qry.Infra

    # Host
    mkdir -p $target_dir/src/hosts
    cd $target_dir/src/hosts
    generateHost $1.Qry $2-qry
    cd $target_dir/src/hosts/$1.Qry
    dotnet add reference $target_dir/src/hosts/$1.Qry.Infra
}

generateEtlInfra() {
    # Package
    mkdir -p $target_dir/src/hosts
    cd $target_dir/src/hosts
    dotnet new classlib -n $1.Etl.Infra
    cd $target_dir/src/hosts/$1.Etl.Infra
    rm -rf Class1.cs
    
    dotnet add reference $target_dir/src/internal/$1.Contract
    dotnet add package $schema_sdk  -v $sdk_version
    dotnet add package $infra_sdk   -v $sdk_version
   
    # UnitTest
    mkdir -p $target_dir/tests/integration
    cd $target_dir/tests/integration
    generateTest $1.Etl.Infra.IntegrationTests
    dotnet add reference $target_dir/src/hosts/$1.Etl.Infra

    # Host
    mkdir -p $target_dir/src/hosts
    cd $target_dir/src/hosts
    generateHost "$1.Etl" "$2-etl"
    cd $target_dir/src/hosts/$1.Etl
    dotnet add reference $target_dir/src/hosts/$1.Etl.Infra
}

generateSubInfra() {
    # Package
    mkdir -p $target_dir/src/hosts
    cd $target_dir/src/hosts
    dotnet new classlib -n $1.Sub.Infra
    cd $target_dir/src/hosts/$1.Sub.Infra
    rm -rf Class1.cs
    
    dotnet add reference $target_dir/src/internal/$1.Contract
    dotnet add package $schema_sdk  -v $sdk_version
    dotnet add package $infra_sdk  -v $sdk_version
   
    # UnitTest
    mkdir -p $target_dir/tests/integration
    cd $target_dir/tests/integration
    generateTest $1.Sub.Infra.IntegrationTests
    dotnet add reference $target_dir/src/hosts/$1.Sub.Infra

    # Host
    mkdir -p $target_dir/src/hosts
    cd $target_dir/src/hosts
    generateHost "$1.Sub" "$2-sub"
    cd $target_dir/src/hosts/$1.Sub
    dotnet add reference $target_dir/src/hosts/$1.Sub.Infra
}


generateClientInfra() {
    # Package
    mkdir -p $target_dir/src/clients
    cd $target_dir/src/clients
    dotnet new classlib -n $1.Client.Infra
    cd $target_dir/src/clients/$1.Client.Infra
    rm -rf Class1.cs
    
    dotnet add reference $target_dir/src/internal/$1.Contract
    dotnet add package $schema_sdk  -v $sdk_version
    dotnet add package $infra_sdk  -v $sdk_version
   
    # UnitTest
    mkdir -p $target_dir/tests/integration
    cd $target_dir/tests/integration
    generateTest $1.Client.Infra.IntegrationTests
    dotnet add reference $target_dir/src/clients/$1.Client.Infra
}




generatePackage() {
    dotnet new classlib -n "$api_prefix.$1"
    cd "$api_prefix.$1"
    rm -rf Class1.cs
}



generateBackendDeploy() {
cat >deploy-$1.yaml<<EOF
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: $img_prefix-S1
spec:
  components:
    - name: backend-$1
      type: backend
      properties:
        image: $registry/$img_prefix-$1
        # cmd:
        #   - dotnet
        #   - $api_prefix.Cmd.Dll
EOF
}


generateClientDeploy() {
cat >deploy-$1.yaml<<EOF
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: $img_prefix-S1
spec:
  components:
    - name: client-$1
      type: client
      properties:
        image: $registry/$img_prefix-$1
        # cmd:
        #   - dotnet
        #   - $api_prefix.Cmd.Dll
EOF
}



generateBuildSh() {
cat >build.sh<<EOF
#! /bin/bash

set -eu

shopt -s expand_aliases
 
cp ~/.kube/config .

dotnet publish ${1}.csproj --runtime centos.8-x64 --self-contained -c Release -o ./app

echo 'Building ${1} Service'
docker build . -f local.Dockerfile -t local/${2}

rm -rf config
rm -rf ./app

echo 'finished!'
echo 'You may now run the container using: ./run.sh'
EOF
chmod +x *.sh
}


generateRunSh() {
cat >run.sh<<EOF
#! /bin/bash

set -eu

shopt -s expand_aliases

docker run --rm -it --network host local/${1}
EOF
chmod +x *.sh
}


generateDockerfile() {
  cat >Dockerfile<<EOF
FROM mcr.microsoft.com/dotnet/runtime AS base
COPY . /app
WORKDIR /app
ENV ASPNETCORE_URLS http://+:5197
EXPOSE 5197
ENTRYPOINT ["dotnet", "$1.dll"]
EOF
echo 'done'
}

generateLocalDockerfile() {
    cat >local.Dockerfile<<EOF
FROM mcr.microsoft.com/dotnet/runtime AS base
COPY ./app /app
COPY config /root/.kube/config
WORKDIR /app
ENV ASPNETCORE_URLS http://+:5197
EXPOSE 5197
ENTRYPOINT ["dotnet", "$1.dll"]
EOF
echo 'done'
}


generateHost() {
    dotnet new webapi --no-https --auth None --no-openapi -n "$1"
    cd "$1"
    rm -rf Controllers
    rm -rf WeatherForecast.cs
    generateDockerfile "$1"
    generateLocalDockerfile "$1"
    generateBuildSh "$1" "$2"
    generateRunSh "$2"
}


generateConsole() {
    mkdir -p $target_dir/src/clients
    cd $target_dir/src/clients
    dotnet new console -n "$1"
    cd "$1"
    dotnet add package -n $art_sdk -v $sdk_version
    generateDockerfile "$1"
    generateLocalDockerfile "$1"
    generateBuildSh "$1" "$2"
    generateRunSh "$2"
}


usage()
{
  echo
  echo 'Usage: ./init-context.sh [OPTIONS]'
  echo
  echo '-u    <YOUR NEXUS USER NAME>'
  echo '-p    <YOUR NEXUS PASSWORD>' 
  echo '-n    <API-PREFIX> (PascalCase)' 
  echo '-i    <IMAGE-PREFIX> (lowercase)' 
  echo '-ip   <ID-PREFIX>'
  echo '-s    <SDK-VERSION> default:$sdk-version'
  echo
  echo '-h    Usage' 
  echo 
  echo
}

###########################################################################
###    MAIN
##########################################################################

  while [ "$1" != "" ]; do
    case $1 in

       -n  | --name )        shift
                             api_prefix="$1"
                             ;;
       -u  | --user )        shift
                             user="$1"
                             ;;
       -p  | --password)     shift
                             password="$1"
                             ;;
       -i  | --image)        shift
                             img_prefix="$1"
                             ;;
       -ip | --id-prefix)    shift
                             id_prefix="$1"
                             ;;
       -s  | --sdk-version)  shift
                             sdk_version="$1"
                             ;;
       -h  | --help)         usage
                             ;; 
        * )                  usage
                             ;;
    esac
    shift
  done

  clear

  if [[ "$user" != "" ]] && [[ "$password" != "" ]]  && [[ "$api_prefix" != "" ]] ; then

    prepareRepo



#############################################
###           PROJECT DIR ARTIFACTS       ###
############################################# 

generateGitlabCI $api_prefix $img_prefix


#############################################
###           INTERNAL Artifacts          ###
############################################# 

generateSchemaPackage      $api_prefix
generateContract    $api_prefix
generateDomain      $api_prefix


#############################################
###           BOGUS Artifacts          ###
############################################# 

generateBogus      $api_prefix

#############################################
###           Infra Aritfacts               ###
############################################# 

generateCmdInfra     $api_prefix     $img_prefix
generateQryInfra     $api_prefix     $img_prefix
generateEtlInfra     $api_prefix     $img_prefix
generateSubInfra     $api_prefix     $img_prefix

generateClientInfra  $api_prefix     $img_prefix
generateCLI          $api_prefix     $img_prefix
generateTUI          $api_prefix     $img_prefix

#############################################
###         QUALITY ASSURANCE             ###
############################################# 

### Behaviour 

generateAcceptanceTests  $api_prefix

### ADD LIBRARIES TO SLN

addInternals() {
    cd $target_dir
    
    dotnet sln "$1" add "src/internal/$api_prefix.Schema"
    dotnet sln "$1" add "src/internal/$api_prefix.Contract"
    dotnet sln "$1" add "src/internal/$api_prefix.Domain"
}

addInfra() {
    cd $target_dir
    dotnet sln "$1" add "src/hosts/$api_prefix.Cmd.Infra"
    dotnet sln "$1" add "src/hosts/$api_prefix.Qry.Infra"
    dotnet sln "$1" add "src/hosts/$api_prefix.Etl.Infra"
    dotnet sln "$1" add "src/hosts/$api_prefix.Sub.Infra"
    dotnet sln "$1" add "src/clients/$api_prefix.Client.Infra"
}

addHosts() {
    cd $target_dir
    dotnet sln "$1" add "src/hosts/$api_prefix.Cmd"
    dotnet sln "$1" add "src/hosts/$api_prefix.Qry"
    dotnet sln "$1" add "src/hosts/$api_prefix.Sub"
    dotnet sln "$1" add "src/hosts/$api_prefix.Etl"
}

addBogus() {
    cd $target_dir
    dotnet sln "$1" add "tests/bogus/$api_prefix.Schema.Bogus"
    dotnet sln "$1" add "tests/bogus/$api_prefix.Contract.Bogus"
}


addClients() {
    cd $target_dir
    dotnet sln "$1" add "src/clients/$api_prefix.CLI"
    dotnet sln "$1" add "src/clients/$api_prefix.TUI"
}


addUnitTests() {
    cd $target_dir
    dotnet sln "$1" add $target_dir/tests/unit/$api_prefix.Schema.UnitTests
    dotnet sln "$1" add $target_dir/tests/unit/$api_prefix.Contract.UnitTests
    dotnet sln "$1" add $target_dir/tests/unit/$api_prefix.Domain.UnitTests
}

addAcceptanceTests() {
    dotnet sln "$1" add "tests/acceptance/$api_prefix.AcceptanceTests"
}

addIntegrationTests() {
    dotnet sln "$1" add "tests/integration/$api_prefix.Client.Infra.IntegrationTests"
    dotnet sln "$1" add "tests/integration/$api_prefix.Cmd.Infra.IntegrationTests"
    dotnet sln "$1" add "tests/integration/$api_prefix.Etl.Infra.IntegrationTests"
    dotnet sln "$1" add "tests/integration/$api_prefix.Qry.Infra.IntegrationTests"
    dotnet sln "$1" add "tests/integration/$api_prefix.Sub.Infra.IntegrationTests"    
}



assembleRootSolution() {
  cd $target_dir
  dotnet new sln -n     $1.root
  addInternals          $1.root.sln
  addInfra              $1.root.sln
  addHosts              $1.root.sln
  addClients            $1.root.sln
  addBogus              $1.root.sln
  addUnitTests          $1.root.sln
  addIntegrationTests   $1.root.sln
  addAcceptanceTests    $1.root.sln
}




#############################################
###           ADD SOLUTIONS                ###
#############################################
## root solution 
assembleRootSolution $api_prefix

### OAM FOLDER    ##
buildOAM




###################################################################
##                       TESTING                                 ##
###################################################################
buildHostContainers $api_prefix
buildClientContainers $api_prefix


###########################
### BUILD ROOT SOLUTION  ##
###########################
cd $target_dir
./generators/buildSolution.sh $api_prefix.root.sln

# ./push.sh "init repo"

  else
    usage
  fi