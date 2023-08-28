#!/bin/bash

set -eEu
set -o pipefail


THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/bosh-helpers.bash"
unset THIS_FILE_DIR

function run() {
  init_git_author

  local version=$(cat ./version/number)
  if [ -z "$version" ]; then
    echo "missing version number"
    exit 1
  fi

  cd repo
  local private_yml="./config/private.yml"

  set +x
  if [[ -n "${GCP_BLOBSTORE_SERVICE_ACCOUNT_KEY}" ]]; then
    debug "Using GCP"
    local formatted_key="$(sed 's/^/      /' <(echo ${GCP_BLOBSTORE_SERVICE_ACCOUNT_KEY}))"
    cat > $private_yml <<EOF
---
blobstore:
  options:
    credentials_source: static
    json_key: |
${formatted_key}
EOF
  fi

  if [[ -n ${AWS_ACCESS_KEY_ID} ]]; then
    debug "Using AWS Access Key"
    cat > $private_yml <<EOF
---
blobstore:
  options:
    secret_access_key: "${AWS_SECRET_ACCESS_KEY}"
    access_key_id: "${AWS_ACCESS_KEY_ID}"
EOF
  fi

  if [[ -n "${AWS_ASSUME_ROLE_ARN}" ]]; then
    debug "Using AWS Role ARN"
    cat > $private_yml <<EOF
    assume_role_arn: "${AWS_ASSUME_ROLE_ARN}"
EOF
  fi

  set -x

  echo "creating final release"
  local release_name="$(yq -r .final_name < ./config/final.yml)"
  echo "release name:" ${release_name}
  bosh -n create-release --final --version="$version" --tarball  ../finalized-release-tarball/${release_name}-${version}.tgz
  git add -A
  git commit -m "Release v${version}"

  cp -r . ../finalized-release-repo
}

trap 'err_reporter $LINENO' ERR
run "$@"
