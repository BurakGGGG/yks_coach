#!/usr/bin/env bash
# Single verification entry point for YKS Coach.
#
# Runs every automated check that gates a commit or a release: Flutter static
# analysis and tests, plus Cloud Functions lint/test and Firestore Rules tests
# once those packages exist. Intended to be the one command CI and humans run.
#
# Usage: ./tool/verify.sh   (or: make verify)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

step() {
  echo
  echo "▶ $*"
  "$@"
}

step flutter analyze
step flutter test

if [ -f functions/package.json ]; then
  step npm --prefix functions run lint
  step npm --prefix functions test
fi

if [ -f test/firestore/package.json ]; then
  step npm --prefix test/firestore test
fi

echo
echo "✓ All verification steps passed."
