#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR
init_git_author

VERSION=$(cat ./version/number)
if [ -z "$VERSION" ]; then
  echo "missing version number"
  exit 1
fi

CANDIDATE_DIR=$PWD/tarball
cd repo

set +x
if [[ -z "${GCP_BLOBSTORE_SERVICE_ACCOUNT_KEY}" ]]; then
  cat > ${PWD}/${RELEASE}/config/private.yml <<EOF
---
blobstore:
  options:
    secret_access_key: "${AWS_SECRET_ACCESS_KEY}"
    access_key_id: "${AWS_ACCESS_KEY_ID}"
EOF

  if [[ -n "${AWS_ASSUME_ROLE_ARN}" ]]; then
    cat >> ${PWD}/${RELEASE}/config/private.yml <<EOF
    assume_role_arn: "${AWS_ASSUME_ROLE_ARN}"
EOF
  fi
fi

if [[ -z ${AWS_ACCESS_KEY_ID} ]]; then
  FORMATTED_KEY="$(sed 's/^/      /' <(echo ${GCP_BLOBSTORE_SERVICE_ACCOUNT_KEY}))"
  cat > ${PWD}/${RELEASE}/config/private.yml <<EOF
---
blobstore:
  options:
    credentials_source: static
    json_key: |
${FORMATTED_KEY}
EOF
fi
set -x

echo "creating final release"
echo "release name:" ${RELEASE_NAME}
bosh -n create-release --final --version="$VERSION" --tarball  ../finalized-release-tarball/${RELEASE_NAME}-${VERSION}.tgz
git add -A
git commit -m "Release v${VERSION}"

cp -r . ../finalized-release-repo
