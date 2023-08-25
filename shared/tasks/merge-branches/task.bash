#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
unset THIS_FILE_DIR
init_git_author

function run(){
    git config --global --add safe.directory '*'
    local onto_branch_name="$(git -C ./onto-branch rev-parse --abbrev-ref HEAD)"
    local source_branch_name="$(git -C ./source-branch rev-parse --abbrev-ref HEAD)"
    git clone ./source-branch ./merged-branch

    cd merged-branch

    git remote add local ../onto-branch
    git fetch local
    git checkout "local/${onto_branch_name}"

    git merge --no-edit "${source_branch_name}"
}

run
