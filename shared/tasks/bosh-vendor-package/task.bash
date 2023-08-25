#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR
init_git_author

if [[ -z "${GCP_BLOBSTORE_SERVICE_ACCOUNT_KEY}" ]]; then
  cat > ${PWD}/repo/config/private.yml <<EOF
---
blobstore:
  options:
    secret_access_key: "${AWS_SECRET_ACCESS_KEY}"
    access_key_id: "${AWS_ACCESS_KEY_ID}"
EOF

  if [[ -n "${AWS_ASSUME_ROLE_ARN}" ]]; then
    cat >> ${PWD}/repo/config/private.yml <<EOF
    assume_role_arn: "${AWS_ASSUME_ROLE_ARN}"
EOF
  fi
fi

if [[ -z ${AWS_ACCESS_KEY_ID} ]]; then
  FORMATTED_KEY="$(sed 's/^/      /' <(echo ${GCP_BLOBSTORE_SERVICE_ACCOUNT_KEY}))"
  cat > ${PWD}/repo/config/private.yml <<EOF
---
blobstore:
  options:
    credentials_source: static
    json_key: |
${FORMATTED_KEY}
EOF
fi
set -x

pushd repo
  if [[ -n "${PACKAGE_PREFIX}" ]]; then
    bosh vendor-package "${PACKAGE}" ../package-release --prefix "${PACKAGE_PREFIX}"
  else
    bosh vendor-package "${PACKAGE}" ../package-release
  fi

  if [[ -n $(git status --porcelain) ]]; then
    echo "changes detected, will commit..."
    git add --all
    git commit -m "Upgrade ${PACKAGE}"

    git log -1 --color | cat
  else
   echo "no changes in repo, no commit necessary"
  fi
popd

shopt -s dotglob
cp -R repo/* vendored-repo/
