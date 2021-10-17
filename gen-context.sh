#! /usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/generators
echo $SCRIPT_DIR


source $SCRIPT_DIR/generateSchemaPackage.sh
source $SCRIPT_DIR/generateContractPackage.sh
source $SCRIPT_DIR/generateDomainPackage.sh

source $SCRIPT_DIR/generateDockerfile.sh
source $SCRIPT_DIR/generateHostPackage.sh
source $SCRIPT_DIR/generateInfraPackage.sh

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
source $SCRIPT_DIR/prepareRepo.sh
source $SCRIPT_DIR/initializeVariables.sh


usage()
{
  echo
  echo 'Usage: ./gen-context.sh [OPTIONS]'
  echo
  echo '-u, --user          <YOUR NEXUS USER NAME>'
  echo '-p, --password      <YOUR NEXUS PASSWORD>' 
  echo '-n, --name          <API-PREFIX> (PascalCase)' 
  echo '-i, --image    <IMAGE-PREFIX> (lowercase)' 
  echo '-ip   <ID-PREFIX>'
  echo '-s    <SDK-VERSION> default:$sdk-version'
  echo '-c    <SDK-VERSION> default:$sdk-version'
  echo
  echo '-h    Usage' 
  echo 
  echo
}





# source $SCRIPT_DIR/generateAcceptanceTestsSolution.sh

main() {
    clear
    
    initializeVariables
    
    prepareRepo

    ## $1: Target Directory
    internal_dir=$target/src/internal
    unit_tests_dir=$target/tests/unit
    infra_dir=$target/src/infra
    hosts_dir=$target/src/hosts

    clients_dir=$target/src/clients

    integration_dir=$target/tests/integration
    acceptance_dir=$target/tests/acceptance

    echo $internal

    # internals
    generateSchemaPackage               $internal_dir     $api_prefix   $id_prefix   $img_prefix-db
    generateContractPackage             $internal_dir     $api_prefix   $id_prefix   $img_prefix-db
    generateDomainPackage               $internal_dir     $api_prefix   $id_prefix   $img_prefix-db

    # unit tests
    generateSchemaTests                 $unit_tests_dir   $api_prefix   $id_prefix   $img_prefix-db
    generateContractTests               $unit_tests_dir   $api_prefix   $id_prefix   $img_prefix-db
    generateDomainTests                 $unit_tests_dir   $api_prefix   $id_prefix   $img_prefix-db
    
    # infra packages
    generateInfraPackage                $infra_dir        $api_prefix   Cmd
    generateInfraPackage                $infra_dir        $api_prefix   Etl
    generateInfraPackage                $infra_dir        $api_prefix   Sub
    generateInfraPackage                $infra_dir        $api_prefix   Qry

    # integration tests
    generateIntegrationTests            $integration_dir  $api_prefix
    
    # hosts
    generateHostPackage                 $hosts_dir        $2   Cmd    $img_prefix-cmd
    generateHostPackage                 $hosts_dir        $2   Qry    $img_prefix-qry
    generateHostPackage                 $hosts_dir        $2   Etl    $img_prefix-etl
    generateHostPackage                 $hosts_dir        $2   Sub    $img_prefix-sub

    #clients
    generateClientPackage               $clients_dir      $2   CLI    $5-cli
    generateClientPackage               $clients_dir      $2   TUI    $5-tui

    generateAcceptanceTests             $acceptance_dir
    
    
    # solution
    generateRootSolution                $target     $2

    
    generateCIDRoot                     $target     $2    
}


target=$PWD
user=
password=

api_prefix=
img_prefix=
assy_suffix=
id_prefix=


while [ "$1" != "" ]; do
    case $1 in

       -a  | --api-name)            shift
                                    api_prefix="$1"
                                    ;;
       -u  | --user)                shift
                                    user="$1"
                                    ;;
       -p  | --password)            shift
                                    password="$1"
                                    ;;
       -i  | --img-prefix)          shift
                                    img_prefix="$1"
                                    ;;
       -ip | --id-prefix)           shift
                                    id_prefix="$1"
                                    ;;
       -s  | --sdk-version)         shift
                                    sdk_version="$1"
                                    ;;
       -c  | --cid-repo)            shift
                                    cid_repo="$1"
                                    ;;
       -h  | --help)                usage
                                    ;; 
        *)                          usage
                                    ;;
    esac
    shift
done
clear
if [[ "$user" != "" ]] && [[ "$password" != "" ]]  && [[ "$api_prefix" != "" ]] && [[ "$img_prefix" != "" ]] && [[ "$id_prefix" != "" ]]; then
  main
else
  usage
fi