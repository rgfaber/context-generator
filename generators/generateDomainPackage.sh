#! /bin/bash -x

# set -eu

source ./_constants.sh
source ./generateTestLib.sh



generateDomainPackage() {

    ## $1 : target directory
    ## $2 : API Prefix
    ## $3 : IDPrefix
    ## $4 : DB Name

    ## Generate Domain Classlib
    mkdir -p $1
    cd $1
    dotnet new classlib -n $2.Domain
    cd $1/$2.Domain
    rm -rf Class1.cs
    dotnet add package $schema_sdk  -v $sdk_version
    dotnet add package $domain_sdk  -v $sdk_version
    dotnet add reference $1/$2.Contract
    
    mkdir -p $1
    cd $1
    generateTestLib $2.Domain.UnitTests
    cd $1/$2.Domain.UnitTests
    dotnet add reference $1/$2.Domain
}


