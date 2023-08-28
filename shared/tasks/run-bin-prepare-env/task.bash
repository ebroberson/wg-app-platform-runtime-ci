#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/cf-helpers.bash"
unset THIS_FILE_DIR

function run(){
    local task_tmp_dir="${1:?provide temp dir for task}"
    shift 1

    expand_functions

    bosh_target
    cf_target
    cf_create_tcp_domain

    pushd "repo" > /dev/null
    ./bin/prepare-env.bash "$@"
    popd > /dev/null

    pushd "cf-deployment" > /dev/null
    git checkout ${CF_MANIFEST_VERSION}
    popd > /dev/null
    cp -r cf-deployment versioned-cf-deployment

    cat <<EOF > prepared-env/vars.yml
---
CF_ADMIN_PASSWORD: "${CF_ADMIN_PASSWORD}"
CF_ENVIRONMENT_NAME: "${CF_ENVIRONMENT_NAME}"
CF_SYSTEM_DOMAIN: "${CF_SYSTEM_DOMAIN}"
CF_TCP_DOMAIN: "${CF_TCP_DOMAIN}"
CF_MANIFEST_VERSION: "${CF_MANIFEST_VERSION}"
EOF
}

function cleanup() {
    rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
run $task_tmp_dir "$@"
