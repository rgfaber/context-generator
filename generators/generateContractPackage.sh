#! /bin/bash -x

# set -eu

source ./_constants.sh
source ./generateTestLib.sh
source ./generateContractConfigClass.sh 
source ./generateSchemaPackage.sh

generateContractPackage() {

    ## $1 : target directory
    ## $2 : API Prefix
    ## $3 : IDPrefix
    ## $4 : DB Name

    ## Generate Contract Classlib
    mkdir -p $1
    cd $1
    dotnet new classlib -n $2.Contract
    cd $1/$2.Contract
    rm -rf Class1.cs
    dotnet add package $schema_sdk  -v $sdk_version
    dotnet add package $swagger_sdk  -v $sdk_version
    dotnet add reference $1/$2.Schema
    generateContractConfigClass $2

    ## Generate Contract Unit Test
    mkdir -p $1
    cd $1
    generateTestLib $2.Contract.UnitTests
    cd $1/$2.Contract.UnitTests
    dotnet add reference $1/$2.Contract
}

