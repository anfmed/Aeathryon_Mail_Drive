#!/usr/bin/env bash
# Installs Flutter from the official repository (no third-party action).
# FLUTTER_REF defaults to "stable". PIN IT to an exact tag after the first green
# run (supply-chain rule, docs/DEPENDENCY_GATE.md). Current stable tag: UNVERIFIED.
set -euo pipefail
REF="${FLUTTER_REF:-stable}"
git clone --depth 1 --branch "$REF" https://github.com/flutter/flutter.git "$HOME/flutter"
BIN="$HOME/flutter/bin"
if command -v cygpath >/dev/null 2>&1; then BIN="$(cygpath -w "$BIN")"; fi
echo "$BIN" >> "$GITHUB_PATH"
"$HOME/flutter/bin/flutter" --version
