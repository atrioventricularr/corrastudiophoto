#!/usr/bin/env bash
set -u

FAILURES=0
OUT_DIR="apps/desktop-electron/dist-installer"

echo "Corra Windows Installer Output Check"
echo "===================================="

if [ ! -d "$OUT_DIR" ]; then
  echo "❌ installer output dir"
  exit 1
fi

if find "$OUT_DIR" -maxdepth 2 -type f \( -name "*.exe" -o -name "*.msi" \) | grep -q .; then
  echo "✅ installer executable"
else
  echo "❌ installer executable"
  FAILURES=$((FAILURES + 1))
fi

if find "$OUT_DIR" -maxdepth 2 -type f -name "*portable*.exe" | grep -q .; then
  echo "✅ portable executable"
else
  echo "⚠️ portable executable not found"
fi

echo ""
find "$OUT_DIR" -maxdepth 2 -type f | sort

if [ "$FAILURES" -gt 0 ]; then
  exit 1
fi
