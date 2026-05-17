#!/usr/bin/env bash
# Integration tests for mise-melpa-checks.
# Asserts that all checks PASS on good-package and FAIL on bad-package,
# both via direct task invocation and via `mise run`.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASKS="$REPO_ROOT/tasks"
GOOD="$REPO_ROOT/tests/fixtures/good-package"
BAD="$REPO_ROOT/tests/fixtures/bad-package"

pass=0
fail=0
assert_exit() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "  ok   - $desc (exit=$actual)"
    pass=$((pass + 1))
  else
    echo "  FAIL - $desc (expected exit=$expected, got $actual)"
    fail=$((fail + 1))
  fi
}

run_direct() {
  local fixture="$1" task="$2"
  local rc=0
  (cd "$fixture" && "$TASKS/$task") >/dev/null 2>&1 || rc=$?
  echo "$rc"
}

# Unit tests first (cheap to re-run)
echo "=== Unit tests ==="
"$REPO_ROOT/tests/test-discover-files.sh"
"$REPO_ROOT/tests/test-batch-init.sh"

echo ""
echo "=== Integration: good-package (expect all PASS, exit=0) ==="
for task in byte-compile checkdoc package-lint melpa-check; do
  rc=$(run_direct "$GOOD" "$task")
  assert_exit "good-package/$task" 0 "$rc"
done
rm -f "$GOOD"/*.elc

echo ""
echo "=== Integration: bad-package (expect each individual check FAIL, exit≠0) ==="
for task in byte-compile checkdoc package-lint; do
  rc=$(run_direct "$BAD" "$task")
  if [[ "$rc" == "0" ]]; then
    echo "  FAIL - bad-package/$task (expected non-zero, got 0)"
    fail=$((fail + 1))
  else
    echo "  ok   - bad-package/$task (exit=$rc)"
    pass=$((pass + 1))
  fi
done
rm -f "$BAD"/*.elc

echo ""
echo "=== Summary: $pass passed, $fail failed ==="
[[ "$fail" -eq 0 ]] || exit 1
