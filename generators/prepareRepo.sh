#! /bin/bash

prepareRepo() {
    ### Install the SpecFlow Templates
    cd $target
    dotnet new --install SpecFlow.Templates.DotNet::3.9.8
    dotnet nuget remove source 'M5x SDK Nugets'
    dotnet nuget remove source 'Logatron Nugets'
    dotnet nuget add    source "$sdk_nugets_url"       -n 'M5x SDK Nugets'     -u "$user" -p "$password" --store-password-in-clear-text
    dotnet nuget add    source "$logatron_nugets_url"  -n 'Logatron Nugets'    -u "$user" -p "$password" --store-password-in-clear-text
    
    git branch develop

    rm -rf $target/.git/modules/cid
    rm -rf $target/cid

    git submodule add       $cid_repo
    git submodule update    --init
    git submodule update    --remote
}
