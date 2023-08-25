#!/bin/bash

set -eu
set -o pipefail

for f in input-*
do
  ls $f
  cp -r $f/* ./combined-dirs/
done
