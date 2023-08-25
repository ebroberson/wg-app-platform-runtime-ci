#!/bin/bash

set -eu
set -o pipefail

VERSION=$(cat ./version/number)
if [ -z "$VERSION" ]; then
  echo "missing version number"
  exit 1
fi

cd repo

git remote add release-repo ../release-repo
git fetch release-repo

if [[ -n "$(git tag | grep -E "^v${VERSION}$")" ]]; then
  echo "git tag ${VERSION} already exists. Nothing has been tagged or commited. Fast failing..."
  exit 1
fi

if [[ -n "$(git rev-list HEAD..release-repo/release)" ]]; then
  echo "Release branch contains commits not on HEAD. Nothing has been tagged or commited. Fast failing..."
  exit 1
fi
