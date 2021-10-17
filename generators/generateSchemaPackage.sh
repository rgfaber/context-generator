#! /bin/bash -x

# set -eu

source $SCRIPT_DIR/_constants.sh
source $SCRIPT_DIR/generateTestLib.sh
source $SCRIPT_DIR/generateSchemaRootClass.sh
source $SCRIPT_DIR/generateSchemaConstants.sh


generateSchemaPackage() {

    ## $1 : target directory
    ## $2 : API Prefix
    ## $3 : IDPrefix
    ## $4 : DB Name
    # generate schema classlib
    mkdir -p $1
    cd $1
    dotnet new classlib -n $2.Schema
    cd $1/$2.Schema
    rm -rf Class1.cs
    dotnet add package              $schema_sdk  -v $sdk_version
    generateSchemaConstants         $2              $3        $4
    generateSchemaRootClass         $2              $3        $4  

    # Schema Bogus Generators
    mkdir -p $1
    cd $1
    dotnet new classlib             -n $2.Bogus
    cd $1/$2.Bogus
    rm -rf Class1.cs
    dotnet add package $bogus_sdk   -v $sdk_version
    dotnet add reference $1/$2.Schema

    ## generate schema test
    mkdir -p $1
    cd $1
    generateTestLib $2.Schema.UnitTests
    cd $1/$2.Schema.UnitTests
    dotnet add reference $1/$2.Schema
}

