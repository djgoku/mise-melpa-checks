#!/usr/bin/env bash
# Shared file-discovery helper for mise-melpa-checks tasks.
#
# Exports: melpa_discover_files
#
# Behavior:
#   - If $MELPA_CHECK_FILES is set, print its words one per line.
#   - Otherwise, print *.el in the current directory (maxdepth 1), excluding
#     test files, package files, autoloads, and flycheck temp files.

melpa_discover_files() {
  if [[ -n "${MELPA_CHECK_FILES:-}" ]]; then
    # Split on whitespace, one file per line.
    printf '%s\n' ${MELPA_CHECK_FILES}
    return 0
  fi
  find . -maxdepth 1 -name '*.el' -type f \
    -not -name '*-test.el' \
    -not -name '*-tests.el' \
    -not -name '*-pkg.el' \
    -not -name '*-autoloads.el' \
    -not -name 'flycheck_*' \
    | LC_ALL=C sort
}
