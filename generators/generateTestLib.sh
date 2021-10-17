#! /bin/bash

source ./_constants.sh


generateTestLib() {
    ## $1 Assembly Name
    dotnet new classlib -n $1
    cd $1
    rm -rf Class1.cs
    dotnet add package -n $testkit_sdk                  -v $sdk_version
    dotnet add package -n xunit.runner.visualstudio     -v 2.4.1
}
