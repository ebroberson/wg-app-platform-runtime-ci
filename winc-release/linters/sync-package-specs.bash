#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

function run() {
  local repo_path=${1:?Provide a path to the repository}
  local exit_on_error=${2:-"false"}

  pushd "${repo_path}" > /dev/null

  GOOS=windows sync_package winc                  -app  code.cloudfoundry.org/winc/cmd/winc
  GOOS=windows sync_package winc-network-hns-acls -app  code.cloudfoundry.org/winc/cmd/winc-network
  GOOS=windows sync_package groot                 -app  code.cloudfoundry.org/groot-windows
  GOOS=windows sync_package diff-exporter         -app  code.cloudfoundry.org/diff-exporter
  GOOS=windows sync_package cert-injector         -app  code.cloudfoundry.org/cert-injector
  GOOS=windows sync_package certsplitter-fs       -app  code.cloudfoundry.org/certsplitter/cmd/certsplitter

  wait

  git diff --name-only packages/*/spec

  if [[ "$exit_on_error" == "true" ]]; then
    git_error_when_diff
  fi

  popd > /dev/null
}

function sync_package() {
  bosh_pkg=${1}

  shift

  (
  set -e

  cd packages/${bosh_pkg}

  {
    cat spec | grep -v '# gosub'

    for package in $(gosub list "$@"); do
      repo=$(echo ${2} | cut -f1-3 -d/)
      if [ -d "../../src/${repo}/Godeps/_workspace/src/${package}" ]; then
        package="${repo}/Godeps/_workspace/src/${package}"
      fi
      echo ${package} | sed -e 's/\(.*\)/  - \1\/*.go # gosub/g'
      if ls ../../src/${package}/*.s >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/*.s # gosub/g'
      fi
      if ls ../../src/${package}/**/*.c >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/**\/*.c # gosub/g'
      fi
      if ls ../../src/${package}/**/*.h >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/**\/*.h # gosub/g'
      fi
      if ls ../../src/${package}/**/*.binpb >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/**\/*.binpb # gosub/g'
      fi
    done
  } > spec.new

  mv spec.new spec
)
}


verify_binary gosub
run "$@"
