#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR
init_git_author

git clone ./source-branch ./merged-branch

cd merged-branch

git remote add local ../onto-branch
git fetch local
git checkout "local/${ONTO_BRANCH_NAME}"

git merge --no-edit "${SOURCE_BRANCH_NAME}"
