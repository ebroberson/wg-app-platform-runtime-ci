#!/bin/bash

set -eu
set -o pipefail

: "${GLOB:?Need to set GLOB}"

for f in ${GLOB}
do
  ls $f
  cp $f ./aggregated-files/"${PREFIX}$(basename $f)"
done
