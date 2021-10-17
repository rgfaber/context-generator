#! /bin/bash -x

# set -eu

###################################################################
### FUNCTIONS
###################################################################


generateHostPackage() {

    ## $1: Target Dir 
    ## $2: api_prefix
    ## $3: Cmd | Qry | Sub | Etl | Hub
    ## $4: img_prefix-cmd | -qry | -sub | -etl | -hub

    # Package
    mkdir -p $1
    cd $1
    dotnet new classlib -n $2.$3.Infra
    cd $1/$2.$3.Infra
    rm -rf Class1.cs
    dotnet add package      $schema_sdk  -v $sdk_version
    dotnet add package      $infra_sdk   -v $sdk_version
    dotnet add reference    $internal/$2.Domain
   
    # Integration Test
    mkdir -p $1
    cd $1
    generateTestLib $2.$3.IntegrationTests
    dotnet add reference $1/$2.$3.Infra

    # Host
    mkdir -p $1
    cd $1
    generateWebApi $2.$3 $4
    cd $1/$2.$3
    dotnet add reference $1/$2.$3.Infra

    ./build.sh

    # docker build -f Dockerfile .

}

generateWebApi() {
    dotnet new webapi --no-https --auth None --no-openapi -n $1
    cd $1
    rm -rf Controllers
    rm -rf WeatherForecast.cs
    generateDockerfile hosts $1
    generateLocalDockerfile $1
    generateBuildSh $1 $2
    generateRunSh $2
}