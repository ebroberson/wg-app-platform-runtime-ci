#!/bin/bash

set -eu
set -o pipefail

pushd repo > /dev/null
  go_version=$(git log -1 --oneline --grep="Update Go version file to" | sed -En 's/.*Update Go version file to go(.*)/\1/p')
popd > /dev/null

new_version="$(cat version/number)"
old_version="$(cat previous-github-release/tag)"
cat >> built-release-notes/notes.md <<EOF
## Changes

- FIXME: enter release notes here

EOF

if [[ -s bosh-job-diff/diff ]]; then
  cat >> built-release-notes/notes.md <<EOF
## Bosh Job Spec changes:

\`\`\`diff
$(cat bosh-job-diff/diff)

\`\`\`
EOF
fi

cat >> built-release-notes/notes.md <<EOF
## ✨  Built with go $go_version

**Full Changelog**: https://github.com/cloudfoundry/$RELEASE_NAME/compare/$old_version...v$new_version

EOF


cat >> built-release-notes/notes.md <<EOF
## Resources

- [Download release v$new_version from bosh.io](https://bosh.io/releases/github.com/cloudfoundry/$RELEASE_NAME?version=$new_version).
EOF

echo "Results: "
cat built-release-notes/notes.md

