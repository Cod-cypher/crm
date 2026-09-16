# Deploying the CRM (crm.optimizeindex.com)

This repo is the source of truth: Twenty CRM v2.40.0 source plus this `deploy/` folder.
You change code here, push, and the server pulls and builds it.

## Where it runs

| What | Where |
|---|---|
| Server | `root@167.233.120.70` (same box as optimizeindex.com) |
| Code checkout | `/opt/twenty` (clone of this repo) |
| Runtime | Node 24 at `/opt/node-v24` (the other sites keep system Node 22) |
| Processes | PM2: `twenty-server` (port 3020), `twenty-worker` |
| Config | `/opt/twenty/packages/twenty-server/.env`, see `server.env.example` |
| Database | Postgres 18, role + db `twenty` |
| Queue/cache | Redis on 127.0.0.1:6379 |
| Uploads | `/opt/twenty-data/storage` |
| Web | nginx `crm.optimizeindex.conf` → 127.0.0.1:3020, certbot SSL |
| Mail | SMTP via `mail.optimizeindex.com:465` (mailcow) |

## Deploying a change

```bash
git push origin main
ssh root@167.233.120.70 /opt/twenty/deploy/deploy.sh
```

`deploy.sh` pulls `main`, builds (about 20–40 minutes, mostly the frontend), runs
migrations, reloads PM2 and checks `/healthz`. To deploy another branch, pass its
name: `deploy.sh my-branch`.

## Useful commands (on the server)

```bash
pm2 ls
pm2 logs twenty-server --lines 100
pm2 logs twenty-worker --lines 100
pm2 restart twenty-server twenty-worker
curl -s http://127.0.0.1:3020/healthz
```

## Upgrading Twenty

Import the new upstream tag into this repo as a normal commit. Resolve conflicts with
any local customizations, then push and deploy. `deploy.sh` runs the `upgrade` command.
