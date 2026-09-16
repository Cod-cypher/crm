#!/bin/bash
# Builds Twenty on the server. Mirrors packages/twenty-docker/twenty/Dockerfile.
# Usage (on the server): /opt/twenty/deploy/build.sh
set -euo pipefail
export PATH=/opt/node-v24/bin:$PATH
export NX_DAEMON=false
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
cd /opt/twenty

echo "== yarn install $(date)"
yarn install --immutable

echo "== server build $(date)"
npx nx run twenty-server:lingui:extract
npx nx run twenty-server:lingui:compile
npx nx run twenty-emails:lingui:extract
npx nx run twenty-emails:lingui:compile
npx nx run twenty-server:build

echo "== front build $(date)"
npx nx run twenty-front:lingui:extract
npx nx run twenty-front:lingui:compile
# The Dockerfile uses 8192; the server has 7.6 GB RAM + 8 GB swap.
NODE_OPTIONS="--max-old-space-size=6144" npx nx build twenty-front

# The server serves the UI from dist/front, same as the Docker image.
rm -rf packages/twenty-server/dist/front
cp -r packages/twenty-front/build packages/twenty-server/dist/front

echo "== BUILD DONE $(date)"
