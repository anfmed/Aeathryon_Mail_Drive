#!/usr/bin/env bash
# analyze + widget-test the Flutter packages and apps; lists ALL failures at the end.
set -uo pipefail
failed=()
for d in packages/aethryon_design packages/aethryon_secure_store_flutter packages/aethryon_host_flutter packages/aethryon_brand apps/drive_app apps/mail_app; do
  echo "=== $d ==="
  ( cd "$d" && flutter pub get && flutter analyze --no-fatal-infos && { [ ! -d test ] || flutter test -r expanded; } ) || failed+=("$d")
done
if [ ${#failed[@]} -gt 0 ]; then
  echo "::error::FAILED: ${failed[*]}"
  exit 1
fi
echo "all Flutter packages/apps passed"
