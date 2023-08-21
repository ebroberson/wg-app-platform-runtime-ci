#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR


function run(){
    bosh_target
    local release=$(bosh releases --json | jq -r --arg release "${RELEASE}" '.Tables[].Rows[] | select(.name == $release and (.version | contains("*"))) | .name + "/" + .version' | tr -d "*" | sort -V | tail -1)
    local stemcell=$(bosh stemcells --json | jq -r --arg os "${OS}" '.Tables[].Rows[] | select(.os | contains($os)) | select(.version | contains("*")) | .os + "/" + .version' | tr -d "*" | sort -V | tail -1)


    bosh export-release -d "${DEPLOYMENT}" "${release}" "${stemcell}"

}

run "$@"
