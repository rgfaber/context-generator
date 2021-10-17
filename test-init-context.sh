#! /bin/bash

api_prefix=My.TryOut
img_prefix=my-tryout
id_prefix=Mt
sdk_version=1.8.51
target_dir=$PWD

cleanup() {
    cd $target_dir
    rm -rf ./BLD  
    rm -rf ./src
    rm -rf ./tests
    rm -rf $api_prefix.root.sln
    rm -rf .gitlab-ci.yml
    ./push.sh "cleanup"
}

./init-context.sh -u $CID_USER -p $CID_PWD -n $api_prefix -i $img_prefix -ip $id_prefix  -s $sdk_version

# cleanup
