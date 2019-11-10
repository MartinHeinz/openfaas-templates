#!/bin/bash
set -e

function build_template() {
    template=$1

    echo Building $template
    func_name=$template-$suffix
    $CLI new $func_name --lang $template 2>/dev/null 1>&2
    $CLI build -f $func_name.yml
}

function verify() {
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

function verify_all() {
    echo Validating templates with faas-cli $cli_version

    # verify each of the templates
    for dir in ./template/*/
    do
        echo $dir
        dirname=${dir%*/}
        template=${dirname##*/}

        # skip arm templates
        case "$template" in
        *-arm* ) continue ;;
        esac

        pushd . 2>/dev/null 1>&2

        build_template $template
        verify $template

        popd 2>/dev/null 1>&2
    done

}

# remove the generated files and folders
function cleanup() {
    rm -rf *-$suffix *-$suffix.yml
    sed -i '$ d' .gitignore
    sed -i '$ d' .gitignore
}


CLI="faas-cli"
suffix=$3

if ! [ -x "$(command -v faas-cli)" ]; then
    HERE=`pwd`
    cd /tmp/
    curl -sSL https://cli.openfaas.com | sh
    CLI="/tmp/faas-cli"

    cd $HERE
fi

cli_version=$($CLI version --short-version)

trap cleanup EXIT  # Run clean-up function regardless of success or failure


# Check if the function exists (bash specific)
if declare -f "$1" > /dev/null
then
  # call arguments verbatim
  "$@"
else
  # Show a helpful error
  echo "'$1' is not a known function name" >&2
  exit 1
fi
