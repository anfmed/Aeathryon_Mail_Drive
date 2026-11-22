#!/usr/bin/env bash
# Lists every resolved runtime dependency. Non-blocking for now; Phase 4 turns
# unreviewed entries into a hard failure (docs/DEPENDENCY_GATE.md).
set -uo pipefail
out="dependency_report.txt"; : > "$out"
for p in packages/* apps/*; do
  [ -f "$p/pubspec.yaml" ] || continue
  echo "## $p" >> "$out"
  (cd "$p" && (flutter pub get >/dev/null 2>&1 || dart pub get >/dev/null 2>&1); dart pub deps --style=list --no-dev 2>/dev/null) >> "$out"
done
sort -u "$out" | grep -E '^- ' | sed 's/ .*//' | sort -u > resolved_packages.txt || true
echo "Resolved runtime packages: $(wc -l < resolved_packages.txt)"
grep -vxFf docs/dependency_allowlist.txt resolved_packages.txt | sed 's/^/UNREVIEWED: /' || true
