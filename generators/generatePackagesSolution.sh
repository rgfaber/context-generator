#! /bin/bash -x

# set -eu


generatePackagesSolution() {

    ## $1: Target Dir 
    ## $2: api_prefix
    ## $3: Cmd | Qry | Sub | Etl | Hub
    ## $4: img_prefix-cmd | -qry | -sub | -etl | -hub

    # Package
    mkdir -p $1
    cd $1

    dotnet new sln -n $2.Packages
    
    dotnet sln $2.Packages.sln add $internal/$2.Schema
    dotnet sln $2.Packages.sln add $internal/$2.Schema.Bogus
    dotnet sln $2.Packages.sln add $internal/$2.Contract
    dotnet sln $2.Packages.sln add $internal/$2.Domain

    dotnet build $2.Packages.sln

}
