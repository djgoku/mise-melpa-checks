#!/usr/bin/env bash
# Unit test for lib/discover-files.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../lib/discover-files.sh
source "$SCRIPT_DIR/../lib/discover-files.sh"

fail() { echo "FAIL: $1"; exit 1; }

# Test 1: MELPA_CHECK_FILES override words are emitted one per line
result=$(MELPA_CHECK_FILES="a.el b.el" melpa_discover_files)
expected=$'a.el\nb.el'
[[ "$result" == "$expected" ]] || fail "override returned: $result"

# Test 2: Auto-discovery filters test/pkg/autoloads files
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
touch "$tmpdir/main.el" \
      "$tmpdir/main-test.el" \
      "$tmpdir/main-tests.el" \
      "$tmpdir/main-pkg.el" \
      "$tmpdir/main-autoloads.el" \
      "$tmpdir/flycheck_main.el"
result=$(cd "$tmpdir" && melpa_discover_files)
[[ "$result" == "./main.el" ]] || fail "discovery returned: $result"

# Test 3: Multiple top-level .el files are all returned, sorted
tmpdir2=$(mktemp -d)
trap 'rm -rf "$tmpdir" "$tmpdir2"' EXIT
touch "$tmpdir2/zebra.el" "$tmpdir2/alpha.el"
result=$(cd "$tmpdir2" && melpa_discover_files)
expected=$'./alpha.el\n./zebra.el'
[[ "$result" == "$expected" ]] || fail "multi-file returned: $result"

echo "PASS: discover-files"
