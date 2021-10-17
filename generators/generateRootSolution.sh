#! /bin/bash -x

# set -eu


generateRootSolution() {

    ## $1: Target Dir 
    ## $2: api_prefix
    ## $3: Cmd | Qry | Sub | Etl | Hub
    ## $4: img_prefix-cmd | -qry | -sub | -etl | -hub

    # Package
    mkdir -p $1
    cd $1

    dotnet new sln -n $2.root
    
    dotnet sln $2.root.sln add $internal/$2.Bogus
    dotnet sln $2.root.sln add $internal/$2.Schema
    dotnet sln $2.root.sln add $internal/$2.Contract
    dotnet sln $2.root.sln add $internal/$2.Domain

    dotnet sln $2.root.sln add $hosts/$2.Cmd.Infra
    dotnet sln $2.root.sln add $hosts/$2.Qry.Infra
    dotnet sln $2.root.sln add $hosts/$2.Etl.Infra
    dotnet sln $2.root.sln add $hosts/$2.Sub.Infra


    dotnet sln $2.root.sln add $hosts/$2.Cmd
    dotnet sln $2.root.sln add $hosts/$2.Qry
    dotnet sln $2.root.sln add $hosts/$2.Etl
    dotnet sln $2.root.sln add $hosts/$2.Sub


    dotnet sln $2.root.sln add $clients/$2.CLI.Infra
    dotnet sln $2.root.sln add $clients/$2.TUI.Infra

    dotnet sln $2.root.sln add $clients/$2.CLI
    dotnet sln $2.root.sln add $clients/$2.TUI

    dotnet build $2.root.sln

}
