#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR


function run(){
    local task_tmp_dir="${1:?provide temp dir for task}"
    shift 1

    bosh_target
    bosh -d "${DEPLOYMENT_NAME}" run-errand "${ERRAND_NAME}" --keep-alive --download-logs
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
run $task_tmp_dir "$@"
