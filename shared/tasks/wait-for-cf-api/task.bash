#!/bin/bash

set -eo pipefail

export api_url="$(cat toolsmiths-env/metadata | jq -r .cf.api_url)"
function test_api { until curl -kf "https://$api_url"; do echo failed; sleep 1; done; }
export -f test_api
timeout 300 bash -c test_api
