#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR

function run(){
    local task_tmp_dir="${1:?provide temp dir for task}"
    shift 1

    expand_functions

    IFS=$'\n'
    for entry in $(find built-binaries -name "*.bash");
    do
        echo "Sourcing: $entry"
        debug "$(cat $entry)"
        source "${entry}"
    done
    unset IFS

    local env_file="$(mktemp -p ${task_tmp_dir} -t 'XXXXX-env.bash')"
    expand_envs "${env_file}"
    . "${env_file}"


    pushd "repo/$DIR"  > /dev/null
    expand_verifications
    ./bin/test.bash "$@"
    popd  > /dev/null
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
run $task_tmp_dir "$@"
