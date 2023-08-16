#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

function run(){
    expand_functions

    local target="$PWD/built-binaries"

    for entry in ${MAPPING}
    do
        local function_name=$(echo $entry | cut -d '=' -f1)
        local binary_path=$(echo $entry | cut -d '=' -f2)
        echo "Executing: $function_name $binary_path $target"
        $function_name "repo/$binary_path" "$target"
    done
}

run
