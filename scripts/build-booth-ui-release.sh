#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/corra-release-env.sh

export VITE_CORRA_APP_VERSION="$CORRA_APP_VERSION"
export VITE_CORRA_RELEASE_CHANNEL="$CORRA_RELEASE_CHANNEL"
export VITE_CORRA_BUILD_ID="$CORRA_BUILD_ID"
export VITE_CORRA_COMMIT="$CORRA_COMMIT"
export VITE_CORRA_BUILT_AT="$CORRA_BUILT_AT"

pnpm --filter @corra/booth-ui exec tsc --noEmit --pretty false
pnpm --filter @corra/booth-ui build
