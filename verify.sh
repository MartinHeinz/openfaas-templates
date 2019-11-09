#!/bin/bash
set -e

CLI="faas-cli"
SUFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

build_template() {
    template=$1

    echo Building $template
    func_name=$template-$SUFIX
    $CLI new $func_name --lang $template 2>/dev/null 1>&2
    $CLI build -f $func_name.yml
}

verify() {
    image=$1
    tag_name=latest

    echo Verifying $template
    container=$(docker run -d -p 8080:8080 $func_name:$tag_name)
    sleep 5 # wait for slower templates to start
    output=$(curl -s -d "testing" http://127.0.0.1:8080)

    echo $image output: $output
    success=false
    if [ ! -z "$output" ]
    then # output was not empty = good template
        success=true
    fi

    echo Cleaning $image
    docker rm $container -f 2>/dev/null 1>&2
    docker rmi $func_name:$tag_name 2>/dev/null 1>&2

    if [ "$success" = false ]
    then
        echo $image template failed validation
        exit 1
    else
        echo $image template validation successful
    fi
}

# remove the generated files and folders if successful
function cleanup() {
    rm -rf *-$SUFIX *-$SUFIX.yml
    cd ../
    rm -rf *-$SUFIX *-$SUFIX.yml
}

trap cleanup EXIT  # Run clean-up function regardless of success or failure

if ! [ -x "$(command -v faas-cli)" ]; then
    HERE=`pwd`
    cd /tmp/
    curl -sSL https://cli.openfaas.com | sh
    CLI="/tmp/faas-cli"

    cd $HERE
fi

cli_version=$($CLI version --short-version)

echo Validating templates with faas-cli $cli_version

cd ./template

# verify each of the templates
for dir in ./*/
do
    dirname=${dir%*/}
    template=${dirname##*/}

    # skip arm templates
    case "$template" in
    *-arm* ) continue ;;
    esac

    pushd ../ 2>/dev/null 1>&2

    build_template $template
    verify $template

    popd 2>/dev/null 1>&2
done
