#!/usr/bin/env bash
# analyze + test every pure-Dart package; keeps going after a failure and lists ALL failures at the end.
set -uo pipefail
failed=()
for p in aethryon_capability aethryon_net aethryon_log aethryon_platform aethryon_auth drive_core mail_core mail_imap aethryon_store; do
  echo "=== $p ==="
  ( cd "packages/$p" && dart pub get && dart analyze && { [ ! -d test ] || dart test; } ) || failed+=("$p")
done
if [ ${#failed[@]} -gt 0 ]; then
  echo "::error::FAILED PACKAGES: ${failed[*]}"
  exit 1
fi
echo "all pure-Dart packages passed"
