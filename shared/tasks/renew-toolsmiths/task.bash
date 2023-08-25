#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR

function run(){
    bosh_target

    local message=$(curl -X POST "https://environments.toolsmiths.cf-app.com/pooled_gcp_engineering_environments/renew?api_token=$TOOLSMITHS_API_TOKEN&name=${TOOLSMITHS_ENVIRONMENT_NAME}")
    if  [[ "${message}" != *"Success"* ]]; then
        echo "Renew failed: $message"
        exit 1
    fi
}

run
