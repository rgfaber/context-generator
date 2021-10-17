#! /usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/generators
echo $SCRIPT_DIR


source $SCRIPT_DIR/generateSchemaPackage.sh
source $SCRIPT_DIR/generateContractPackage.sh
source $SCRIPT_DIR/generateDomainPackage.sh

source $SCRIPT_DIR/generateDockerfile.sh
source $SCRIPT_DIR/generateHostPackage.sh
source $SCRIPT_DIR/generateClientPackage.sh

source $SCRIPT_DIR/generatePackagesSolution.sh
source $SCRIPT_DIR/generateClientsSolution.sh

source $SCRIPT_DIR/generateRootSolution.sh

# source $SCRIPT_DIR/generateUnitTestsSolution.sh
# source $SCRIPT_DIR/generateIntegrationTestsSolution.sh
# source $SCRIPT_DIR/generateHostsSolution.sh
# source $SCRIPT_DIR/generateRootSolution.sh

source $SCRIPT_DIR/generateCIDRoot.sh
source $SCRIPT_DIR/generateCIDPackages.sh
source $SCRIPT_DIR/generateCIDHosts.sh
source $SCRIPT_DIR/generateCIDClients.sh



# source $SCRIPT_DIR/generateAcceptanceTestsSolution.sh

main() {

    target=${PWD}/$1
    internal=$target/internal
    hosts=$target/hosts
    clients=$target/clients
   
    clear
    
    echo $internal

    # internals
    generateSchemaPackage               $internal   MyTest   test   test-db
    generateContractPackage             $internal   MyTest   test   test-db
    generateDomainPackage               $internal   MyTest   test   test-db
    
    # hosts
    generateHostPackage                 $hosts      MyTest   Cmd    mytest-cmd
    generateHostPackage                 $hosts      MyTest   Qry    mytest-qry
    generateHostPackage                 $hosts      MyTest   Etl    mytest-etl
    generateHostPackage                 $hosts       MyTest   Sub    mytest-sub

    #clients
    generateClientPackage               $clients         MyTest   CLI    mytest-cli
    generateClientPackage               $clients         MyTest   TUI    mytest-tui

    # solutions
    # generatePackagesSolution            $target     MyTest

    # generateUnitTestsSolution           $target     MyTest

    # generateIntegrationTestsSolution    $target     MyTest

    # generateClientsSolution             $target     MyTest 
    # generateHostsSolution               $target     MyTest
    generateRootSolution                  $target     MyTest

    generateCIDRoot                       $target     MyTest    
    generateCIDPackages                   $target     
    generateCIDHosts                      $target     MyTest    mytest
    generateCIDClients                    $target     MyTest    mytest
}

main $1