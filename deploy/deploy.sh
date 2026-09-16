#!/bin/bash
# Deploys the pushed branch to the server: pull, build, migrate, restart.
# Usage (on the server): /opt/twenty/deploy/deploy.sh [branch]   (default: main)
set -euo pipefail
BRANCH="${1:-main}"
export PATH=/opt/node-v24/bin:$PATH
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
cd /opt/twenty

if [ -z "${DEPLOY_PULLED:-}" ]; then
  echo "== pulling origin/$BRANCH"
  git fetch origin "$BRANCH"
  # The server never holds real edits: the build's lingui:extract step rewrites
  # tracked .po files, so throw those away and match the pushed branch exactly.
  # (.env and build output are gitignored and survive this.)
  git checkout -f -B "$BRANCH" "origin/$BRANCH"
  git reset --hard "origin/$BRANCH"
  # The pull may have replaced this very script, and bash keeps running the old
  # copy it already opened. Re-run the freshly pulled version for the rest.
  DEPLOY_PULLED=1 exec bash /opt/twenty/deploy/deploy.sh "$BRANCH"
fi
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

# Boot takes ~30–60s (metadata cache warm-up), so poll instead of a fixed sleep.
for i in $(seq 1 36); do
  if curl -fsS http://127.0.0.1:3020/healthz >/dev/null 2>&1; then
    echo "== DEPLOYED $(git rev-parse --short HEAD)"
    exit 0
  fi
  sleep 5
done
echo "== HEALTH CHECK FAILED after 180s — check: pm2 logs twenty-server --lines 100"
exit 1
