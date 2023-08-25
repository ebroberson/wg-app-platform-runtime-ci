#!/bin/bash

set -eu
set -o pipefail

ROOT=${PWD}
DATE=$(date '+%Y-%m-%d %H:%M:%S')

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR
init_git_author

pushd repo

  RELEASE_TARBALL_PATH=${ROOT}/release.tgz
  bosh create-release --tarball="${RELEASE_TARBALL_PATH}"

  mkdir -p docs
  version=$(tar -Oxz "packages/${PACKAGE}.tgz" < "${RELEASE_TARBALL_PATH}" | tar z --list | grep -ohE 'go[0-9]\.[0-9]{1,2}\.[0-9]{0,2}')
  echo "This file was updated by CI on ${DATE}" > docs/go.version
  echo "$version" >> docs/go.version

  if [[ -n $(git status --porcelain) ]]; then
    echo "changes detected, will commit..."
    git add --all
    git commit -m "Update Go version file to ${version}"

    git log -1 --color | cat
  else
   echo "no changes in repo, no commit necessary"
  fi
popd


shopt -s dotglob
cp -R repo/* modified-repo/

