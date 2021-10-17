#! /bin/bash -x

# set -eu


generateUnitTestsSolution() {

    ## $1: Target Dir 
    ## $2: api_prefix
    ## $3: Cmd | Qry | Sub | Etl | Hub
    ## $4: img_prefix-cmd | -qry | -sub | -etl | -hub

    # Package
    mkdir -p $1
    cd $1

    dotnet new sln -n $2.UnitTests
    
    dotnet sln $2.UnitTests.sln add $internal/$2.Schema
    dotnet sln $2.UnitTests.sln add $internal/$2.Contract
    dotnet sln $2.UnitTests.sln add $internal/$2.Domain

    dotnet sln $2.UnitTests.sln add $internal/$2.Schema.UnitTests
    dotnet sln $2.UnitTests.sln add $internal/$2.Contract.UnitTests
    dotnet sln $2.UnitTests.sln add $internal/$2.Domain.UnitTests


    dotnet build $2.UnitTests.sln

}
