#! /bin/bash -x

# set -eu


generateClientsSolution() {

    ## $1: Target Dir 
    ## $2: api_prefix
    ## $3: Cmd | Qry | Sub | Etl | Hub
    ## $4: img_prefix-cmd | -qry | -sub | -etl | -hub

    # Package
    mkdir -p $1
    cd $1

    dotnet new sln -n $2.Clients
    
    dotnet sln $2.Clients.sln add $internal/$2.Bogus
    dotnet sln $2.Clients.sln add $internal/$2.Schema
    dotnet sln $2.Clients.sln add $internal/$2.Contract
    

    dotnet sln $2.Clients.sln add $clients/$2.CLI.Infra
    dotnet sln $2.Clients.sln add $clients/$2.TUI.Infra

    dotnet sln $2.Clients.sln add $clients/$2.CLI
    dotnet sln $2.Clients.sln add $clients/$2.TUI

    dotnet build $2.Clients.sln

}
