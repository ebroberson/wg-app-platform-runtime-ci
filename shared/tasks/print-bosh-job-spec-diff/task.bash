#!/bin/bash

set -e -u
set -o pipefail

pushd repo > /dev/null
  old_version=$(git tag --sort=version:refname | grep -E "^v?[0-9]+\.[0-9]+\.[0-9]+$" | tail -1)
  new_version=$(git rev-parse HEAD)

  diff_string="$old_version..$new_version"
  echo "comparing $diff_string:"
  git --no-pager diff $diff_string jobs/*/spec | tee ../printed-bosh-job-diff/diff
popd > /dev/null
