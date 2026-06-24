#!/usr/bin/env bash
set -euo pipefail

export CORRA_APP_NAME="${CORRA_APP_NAME:-Corra Booth}"
export CORRA_APP_VERSION="${CORRA_APP_VERSION:-0.9.0-rc.1}"
export CORRA_RELEASE_CHANNEL="${CORRA_RELEASE_CHANNEL:-rc}"
export CORRA_BUILD_ID="${CORRA_BUILD_ID:-$(date +%Y%m%d%H%M%S)}"
export CORRA_COMMIT="${CORRA_COMMIT:-$(git rev-parse --short HEAD 2>/dev/null || echo unknown)}"
export CORRA_BUILT_AT="${CORRA_BUILT_AT:-$(date -Iseconds)}"

echo "CORRA_APP_NAME=$CORRA_APP_NAME"
echo "CORRA_APP_VERSION=$CORRA_APP_VERSION"
echo "CORRA_RELEASE_CHANNEL=$CORRA_RELEASE_CHANNEL"
echo "CORRA_BUILD_ID=$CORRA_BUILD_ID"
echo "CORRA_COMMIT=$CORRA_COMMIT"
echo "CORRA_BUILT_AT=$CORRA_BUILT_AT"
