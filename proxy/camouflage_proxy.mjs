#!/usr/bin/env node
import http from 'node:http';
import https from 'node:https';
import { URL } from 'node:url';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const PORT = Number(process.env.FUCKCC_PROXY_PORT || 19283);
const HOST = process.env.FUCKCC_PROXY_HOST || '127.0.0.1';
const HOME = process.env.FUCKCC_HOME || path.join(os.homedir(), '.fuckcc');
const STATE = path.join(HOME, 'proxy.state.json');

function loadUpstream() {
  let u = process.env.FUCKCC_UPSTREAM || '';
  if (!u) {
    try {
      const p = path.join(os.homedir(), '.clawgod', 'provider.json');
      if (fs.existsSync(p)) {
        const j = JSON.parse(fs.readFileSync(p, 'utf8'));
        u = j.baseURL || '';
      }
    } catch {}
  }
  if (!u) u = process.env.ANTHROPIC_BASE_URL || '';
  if (!u) u = 'https://api.anthropic.com';
  return String(u).replace(/\/$/, '');
}

const UPSTREAM = loadUpstream();
let upstreamUrl;
try {
  const raw = UPSTREAM.includes('://') ? UPSTREAM : 'https://' + UPSTREAM;
  upstreamUrl = new URL(raw);
} catch (e) {
  console.error('invalid FUCKCC_UPSTREAM:', UPSTREAM);
  process.exit(1);
}

const isHttps = upstreamUrl.protocol === 'https:';
const lib = isHttps ? https : http;
const listenUrl = 'http://' + HOST + ':' + PORT;

function writeState(extra = {}) {
  try {
    fs.mkdirSync(HOME, { recursive: true });
    fs.writeFileSync(
      STATE,
      JSON.stringify(
        {
          pid: process.pid,
          host: HOST,
          port: PORT,
          listen: listenUrl,
          upstream: UPSTREAM,
          startedAt: new Date().toISOString(),
          ...extra,
        },
        null,
        2
      )
    );
  } catch {}
}

function clearState() {
  try {
    if (fs.existsSync(STATE)) fs.unlinkSync(STATE);
  } catch {}
}

const server = http.createServer((req, res) => {
  const incoming = req.url || '/';
  const basePath = upstreamUrl.pathname.replace(/\/$/, '');
  let targetPath = incoming;
  if (basePath && basePath !== '/') {
    if (!incoming.startsWith(basePath + '/') && incoming !== basePath) {
      targetPath = basePath + (incoming.startsWith('/') ? incoming : '/' + incoming);
    }
  }
  const headers = { ...req.headers };
  headers.host = upstreamUrl.host;
  delete headers['proxy-connection'];
  delete headers['connection'];
  delete headers['x-forwarded-for'];
  delete headers['x-real-ip'];
  delete headers['x-forwarded-host'];
  delete headers['x-forwarded-proto'];
  delete headers['cf-connecting-ip'];
  delete headers['true-client-ip'];
  delete headers['x-client-ip'];
  if (process.env.FUCKCC_FORCE_ACCEPT_LANG !== '0') {
    headers['accept-language'] = process.env.FUCKCC_ACCEPT_LANG || 'en-US,en;q=0.9';
  }
  const opts = {
    protocol: upstreamUrl.protocol,
    hostname: upstreamUrl.hostname,
    port: upstreamUrl.port || (isHttps ? 443 : 80),
    path: targetPath + (upstreamUrl.search || ''),
    method: req.method,
    headers,
    timeout: Number(process.env.FUCKCC_PROXY_TIMEOUT_MS || 600000),
  };
  const preq = lib.request(opts, (pres) => {
    const outHeaders = { ...pres.headers };
    res.writeHead(pres.statusCode || 502, outHeaders);
    pres.pipe(res);
  });
  preq.on('error', (err) => {
    if (!res.headersSent) {
      res.writeHead(502, { 'content-type': 'application/json' });
    }
    res.end(
      JSON.stringify({
        error: 'fuckcc proxy upstream error',
        message: String(err.message || err),
        upstream: UPSTREAM,
      })
    );
  });
  req.pipe(preq);
});

server.on('error', (e) => {
  console.error('[fuckcc-proxy] listen error:', e.message);
  process.exit(1);
});

server.listen(PORT, HOST, () => {
  writeState();
  console.log('[fuckcc-proxy] listen  ' + listenUrl);
  console.log('[fuckcc-proxy] upstream ' + UPSTREAM);
  console.log('[fuckcc-proxy] Claude ANTHROPIC_BASE_URL=' + listenUrl);
  console.log('[fuckcc-proxy] state   ' + STATE);
});

function shutdown() {
  clearState();
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(0), 1500).unref();
}
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
