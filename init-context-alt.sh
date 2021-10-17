#! /bin/bash -x

# set -eu

###########################################################################
## INITIALIZATION
###########################################################################
target_dir=$PWD
registry=registry.macula.io
user=
password=
api_prefix=
img_prefix=
assy_suffix=
img_suffix=
id_prefix=

cid_repo=../../cid.git

sdk_version=1.9.0

schema_sdk=M5x.DEC.Schema
domain_sdk=M5x.DEC
infra_sdk=M5x.DEC.Infra
testkit_sdk=M5x.DEC.TestKit
art_sdk=M5x.AsciiArt
swagger_sdk=M5x.Swagger
bogus_sdk=M5x.Bogus

sdk_nugets_url=https://nexus.macula.io/repository/macula-nugets/

logatron_nugets_url=https://nexus.macula.io/repository/logatron-nugets/
logatron_oci_url=https://nexus.macula.io/repository/logatron-oci/

source ./generators/generateGitlabCiYaml.sh
source ./generators/generateSchemaPackage.sh

###################################################################
### FUNCTIONS
###################################################################



buildSolution() {
    cd $target_dir
    dotnet build $1
}


buildHostContainers() {
    cd $target_dir/hosts/$1.Cmd
    ./build.sh
    cd $target_dir/hosts/$1.Qry
    ./build.sh
    cd $target_dir/hosts/$1.Sub
    ./build.sh
    cd $target_dir/hosts/$1.Etl
    ./build.sh
}

buildClientContainers() {
    cd $target_dir/clients/$1.CLI
    ./build.sh
    cd $target_dir/clients/$1.TUI
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
  mkdir -p $target_dir/acceptance
  cd $target_dir/acceptance 
  dotnet new classlib -n $1.AcceptanceTests
  cd $target_dir/acceptance/$1.AcceptanceTests
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


generateBogus() {
    
    mkdir -p $target_dir/tests/bogus/

    # Schema Bogus Generators
    cd $target_dir/tests/bogus
    dotnet new classlib -n $1.Schema.Bogus
    cd $target_dir/tests/bogus/$1.Schema.Bogus
    rm -rf Class1.cs
    dotnet add package $bogus_sdk  -v $sdk_version
    dotnet add reference $target_dir/src/internal/$1.Schema
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
    mkdir -p $target_dir/internal
    cd $target_dir/internal
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
    
    cd $target_dir/internal/$1.Contract
    ./generators/generateContractConfig.sh $1

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


generateInfra() {
    ## $1: api_prefix
    ## $2: Cmd | Qry | Sub | Etl | Hub
    ## $3: img_prefix-cmd | -qry | -sub | -etl | -hub


    # Package
    mkdir -p $target_dir/infra
    cd $target_dir/infra
    dotnet new classlib -n $1.$2.Infra
    cd $target_dir/infra/$1.$2.Infra
    rm -rf Class1.cs
    dotnet add package $schema_sdk  -v $sdk_version
    dotnet add package $infra_sdk  -v $sdk_version
    dotnet add reference $target_dir/internal/$1.Domain
   
    # Integration Test
    mkdir -p $target_dir/infra
    cd $target_dir/infra
    generateTest $1.$2.IntegrationTests
    dotnet add reference $target_dir/infra/$1.$2.Infra

    # Host
    mkdir -p $target_dir/infra
    cd $target_dir/infra
    generateHost $1.$2 $3
    cd $target_dir/infra/$1.$2
    dotnet add reference $target_dir/infra/$1.$2.Infra
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
    mkdir -p $target_dir/clients
    cd $target_dir/clients
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
cd $target_dir
generateGitlabCIYaml $api_prefix $img_prefix


#############################################
###           INTERNAL Artifacts          ###
############################################# 

generateSchemaPackage       $api_prefix
generateContract            $api_prefix
generateDomain              $api_prefix


#############################################
###           BOGUS Artifacts          ###
############################################# 

generateBogus      $api_prefix

#############################################
###           Infra Aritfacts               ###
############################################# 

generateInfra     $api_prefix   Cmd  $img_prefix-cmd
generateInfra     $api_prefix   Qry  $img_prefix-qry
generateInfra     $api_prefix   Etl  $img_prefix-etl
generateInfra     $api_prefix   Sub  $img_prefix-sub

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
    
    dotnet sln "$1" add "internal/$api_prefix.Schema"
    dotnet sln "$1" add "internal/$api_prefix.Contract"
    dotnet sln "$1" add "internal/$api_prefix.Domain"
}


addHosts() {
    cd $target_dir
    dotnet sln "$1" add "hosts/$api_prefix.Cmd.Infra"
    dotnet sln "$1" add "hosts/$api_prefix.Cmd"
    dotnet sln "$1" add "hosts/$api_prefix.Qry.Infra"
    dotnet sln "$1" add "hosts/$api_prefix.Qry"
    dotnet sln "$1" add "hosts/$api_prefix.Sub.Infra"
    dotnet sln "$1" add "hosts/$api_prefix.Sub"
    dotnet sln "$1" add "hosts/$api_prefix.Etl.Infra"    
    dotnet sln "$1" add "hosts/$api_prefix.Etl"
}



addClients() {
    cd $target_dir
    dotnet sln "$1" add "clients/$api_prefix.CLI"
    dotnet sln "$1" add "clients/$api_prefix.TUI"
}


addUnitTests() {
    cd $target_dir
    dotnet sln "$1" add $target_dir/internal/$api_prefix.Schema.UnitTests
    dotnet sln "$1" add $target_dir/internal/$api_prefix.Contract.UnitTests
    dotnet sln "$1" add $target_dir/internal/$api_prefix.Domain.UnitTests
}

addAcceptanceTests() {
    dotnet sln "$1" add "tests/acceptance/$api_prefix.AcceptanceTests"
}

addIntegrationTests() {
    dotnet sln "$1" add "hosts/$api_prefix.Client.Infra.IntegrationTests"
    dotnet sln "$1" add "hosts/$api_prefix.Cmd.Infra.IntegrationTests"
    dotnet sln "$1" add "hosts/$api_prefix.Etl.Infra.IntegrationTests"
    dotnet sln "$1" add "hosts/$api_prefix.Qry.Infra.IntegrationTests"
    dotnet sln "$1" add "hosts/$api_prefix.Sub.Infra.IntegrationTests"    
}



assembleRootSolution() {
  cd $target_dir
  dotnet new sln -n     $1.root
  addInternals          $1.root.sln
  addHosts              $1.root.sln
  addClients            $1.root.sln

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
buildSolution $api_prefix.root.sln

# ./push.sh "init repo"

  else
    usage
  fi