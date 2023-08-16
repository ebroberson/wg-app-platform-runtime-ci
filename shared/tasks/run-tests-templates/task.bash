#!/bin/bash

set -eu
set -o pipefail

pushd repo > /dev/null
    bundle install
    bundle exec rspec spec
popd > /dev/null
