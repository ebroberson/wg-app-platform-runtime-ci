#!/bin/bash

set -eu
set -o pipefail
set -x

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR
init_git_author

git config --global --add safe.directory '*'
local ONTO_BRANCH_NAME="$(git -C ./onto-branch rev-parse --abbrev-ref HEAD)"
local SOURCE_BRANCH_NAME="$(git -C ./source-branch rev-parse --abbrev-ref HEAD)"
git clone ./source-branch ./merged-branch

cd merged-branch

git remote add local ../onto-branch
git fetch local
git checkout "local/${ONTO_BRANCH_NAME}"

git merge --no-edit "${SOURCE_BRANCH_NAME}"
