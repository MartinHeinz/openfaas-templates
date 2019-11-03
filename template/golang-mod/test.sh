#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

# Collect test targets
SRC_DIRS="function"
TARGETS=$(for d in "$SRC_DIRS"; do echo ./$d/...; done)

# Run tests
echo "Running tests:"
go test -installsuffix "static" ${TARGETS} 2>&1
echo

# Collect all `.go` files and run `gofmt` against them. If some need formatting - print them.
echo -n "Checking gofmt: "
ERRS=$(find "$SRC_DIRS" -type f -name \*.go | xargs gofmt -l 2>&1 || true)
if [ -n "${ERRS}" ]; then
    echo "FAIL - the following files need to be gofmt'ed:"
    for e in ${ERRS}; do
        echo "    $e"
    done
    echo
    exit 1
fi
echo "PASS"
echo

# Run `go vet` against all targets. If problems are found - print them.
echo -n "Checking go vet: "
ERRS=$(go vet ${TARGETS} 2>&1 || true)
if [ -n "${ERRS}" ]; then
    echo "FAIL"
    echo "${ERRS}"
    echo
    exit 1
fi
echo "PASS"
echo
