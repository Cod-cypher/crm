// PM2 process definitions for Twenty CRM (crm.optimizeindex.com).
// Start/refresh with: pm2 startOrReload /opt/twenty/deploy/ecosystem.config.cjs && pm2 save
//
// Twenty needs Node 24; the other apps on this server run on the system Node 22,
// so both processes pin their own interpreter instead of changing /usr/bin/node.
// Config comes from packages/twenty-server/.env on the server (see deploy/server.env.example).
const NODE = "/opt/node-v24/bin/node";
const CWD = "/opt/twenty/packages/twenty-server";

module.exports = {
  apps: [
    {
      name: "twenty-server",
      cwd: CWD,
      script: "dist/main.js",
      interpreter: NODE,
      exec_mode: "fork",
      instances: 1,
      autorestart: true,
      max_memory_restart: "1500M",
      env: { NODE_ENV: "production" },
    },
    {
      // BullMQ worker (emails, workflows, calendar/mail sync). Same as `yarn worker:prod`.
      name: "twenty-worker",
      cwd: CWD,
      script: "dist/queue-worker/queue-worker.js",
      interpreter: NODE,
      exec_mode: "fork",
      instances: 1,
      autorestart: true,
      max_memory_restart: "1024M",
      env: { NODE_ENV: "production" },
    },
  ],
};
