#!/usr/bin/env bash
# analyze + test every pure-Dart package. Fails on the first error.
set -euo pipefail
for p in aethryon_capability aethryon_net aethryon_log aethryon_platform aethryon_auth drive_core mail_core mail_imap; do
  echo "=== $p ==="
  pushd "packages/$p" >/dev/null
  dart pub get
  dart analyze
  if [ -d test ]; then dart test; fi
  popd >/dev/null
done
