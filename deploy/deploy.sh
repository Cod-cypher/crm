#!/bin/bash
# Deploys the pushed branch to the server: pull, build, migrate, restart.
# Usage (on the server): /opt/twenty/deploy/deploy.sh [branch]   (default: main)
set -euo pipefail
BRANCH="${1:-main}"
export PATH=/opt/node-v24/bin:$PATH
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
cd /opt/twenty

echo "== pulling origin/$BRANCH"
git fetch origin "$BRANCH"
git checkout -B "$BRANCH" "origin/$BRANCH"
git log --oneline -1

nice -n 10 ./deploy/build.sh

cd packages/twenty-server
# Same sequence as packages/twenty-docker/twenty/entrypoint.sh
if [ "$(sudo -u postgres psql -d twenty -tAc "SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'core')")" != "t" ]; then
  yarn database:init:prod
fi
yarn command:prod cache:flush || echo "WARN: cache flush failed"
yarn command:prod upgrade
yarn command:prod cache:flush || echo "WARN: cache flush failed"
yarn command:prod cron:register:all || echo "WARN: cron registration failed"

cd /opt/twenty
pm2 startOrReload deploy/ecosystem.config.cjs --update-env
pm2 save

sleep 10
curl -fsS http://127.0.0.1:3020/healthz && echo && echo "== DEPLOYED $(git rev-parse --short HEAD)"
