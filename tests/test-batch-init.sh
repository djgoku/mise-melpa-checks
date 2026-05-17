#!/usr/bin/env bash
# Verifies lib/batch-init.el sets up an ephemeral package env and installs package-lint.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INIT="$SCRIPT_DIR/../lib/batch-init.el"

fail() { echo "FAIL: $1"; exit 1; }

# Run emacs -Q with batch-init.el and probe that package-lint is loadable
# and that the cache dir is set under MISE_CACHE_DIR.
tmpcache=$(mktemp -d)
trap 'rm -rf "$tmpcache"' EXIT

MISE_CACHE_DIR="$tmpcache" "${EMACS:-emacs}" -Q --batch \
  -l "$INIT" \
  --eval "(if (require 'package-lint nil t) (kill-emacs 0) (kill-emacs 1))" \
  || fail "package-lint not loadable after batch-init"

# Verify the cache dir was populated under MISE_CACHE_DIR
[[ -d "$tmpcache/melpa-checks/elpa" ]] || fail "cache dir not created under MISE_CACHE_DIR"

echo "PASS: batch-init"
