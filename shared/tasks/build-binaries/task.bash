#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
if [[ -n "${DEFAULT_PARAMS:-}" ]]; then
    . <("$THIS_FILE_DIR/../../../shared/helpers/extract-default-params-for-task.bash" "${DEFAULT_PARAMS}")
fi
unset THIS_FILE_DIR

function run(){
    expand_functions

    export GOFLAGS="-buildvcs=false"

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
