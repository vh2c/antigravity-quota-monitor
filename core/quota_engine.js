#!/usr/bin/env node
/**
 * Antigravity Quota Engine (Cross-platform: macOS & Windows)
 * Developed by VH2C • https://vh2c.com.br
 * 
 * Discovers the local running Antigravity Language Server process,
 * extracts dynamic port and CSRF token, and fetches real-time model quotas.
 */

const { exec } = require('child_process');
const http = require('http');
const https = require('https');
const util = require('util');

const execAsync = util.promisify(exec);

const RPC_SUMMARY_PATH = '/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary';
const RPC_USER_STATUS_PATH = '/exa.language_server_pb.LanguageServerService/GetUserStatus';

const DEFAULT_METADATA_BODY = {
  metadata: {
    ideName: 'antigravity',
    extensionName: 'antigravity-quota-monitor',
    locale: 'en'
  }
};

function extractCsrfToken(commandLine) {
  if (!commandLine || typeof commandLine !== 'string') return null;
  const match = commandLine.match(/--csrf_token(?:=|\s+)["']?([a-z0-9_-]{8,})["']?/i);
  return match ? match[1] : null;
}

function extractCliPorts(commandLine) {
  if (!commandLine || typeof commandLine !== 'string') return [];
  const ports = [];
  const patterns = [
    /--hub[_-]port(?:=|\s+)["']?(\d{2,5})["']?/gi,
    /--extension[_-]server[_-]port(?:=|\s+)["']?(\d{2,5})["']?/gi,
    /--port(?:=|\s+)["']?(\d{2,5})["']?/gi
  ];
  for (const regex of patterns) {
    for (const match of commandLine.matchAll(regex)) {
      const p = parseInt(match[1], 10);
      if (p > 0 && p <= 65535 && !ports.includes(p)) {
        ports.push(p);
      }
    }
  }
  return ports;
}

function formatTimeRemaining(resetTimeString) {
  if (!resetTimeString) return '';
  const resetDate = new Date(resetTimeString);
  if (Number.isNaN(resetDate.getTime()) || resetDate.getFullYear() < 2020) return '';
  const now = new Date();
  const diffMs = resetDate - now;
  if (diffMs <= 0) return 'Pronto';
  const totalMinutes = Math.floor(diffMs / (1000 * 60));
  const hours = Math.floor(totalMinutes / 60);
  const mins = totalMinutes % 60;
  if (hours > 24) {
    const days = Math.floor(hours / 24);
    const remHours = hours % 24;
    return `${days}d ${remHours}h`;
  }
  if (hours > 0) return `${hours}h ${mins}m`;
  return `${mins}m`;
}

class QuotaEngine {
  constructor() {
    this.platform = process.platform;
  }

  async findProcesses() {
    const candidates = [];
    try {
      if (this.platform === 'win32') {
        const cmd = 'powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.Name -match \'language_server|agy\' } | Select-Object ProcessId, CommandLine | ConvertTo-Json"';
        const { stdout } = await execAsync(cmd, { timeout: 5000 });
        let items = JSON.parse(stdout || '[]');
        if (!Array.isArray(items)) items = [items];
        for (const item of items) {
          const pid = item.ProcessId;
          const cmdLine = item.CommandLine || '';
          const token = extractCsrfToken(cmdLine);
          if (pid && token) {
            candidates.push({ pid, commandLine: cmdLine, csrfToken: token });
          }
        }
      } else {
        const cmd = 'ps -eo pid,command | grep -E "language_server|agy" | grep -v grep';
        const { stdout } = await execAsync(cmd, { timeout: 4000 });
        for (const line of stdout.split('\n')) {
          const match = line.trim().match(/^(\d+)\s+(.+)$/);
          if (match) {
            const pid = parseInt(match[1], 10);
            const cmdLine = match[2];
            const token = extractCsrfToken(cmdLine);
            if (token) {
              candidates.push({ pid, commandLine: cmdLine, csrfToken: token });
            }
          }
        }
      }
    } catch (e) {
      // Fallback
    }
    return candidates;
  }

  async getPorts(pid, commandLine) {
    const ports = extractCliPorts(commandLine);
    try {
      if (this.platform === 'win32') {
        const { stdout } = await execAsync(`netstat -ano | findstr "${pid}"`, { timeout: 3000 });
        const lines = stdout.split('\n');
        for (const line of lines) {
          const parts = line.trim().split(/\s+/);
          if (parts[1] && parts[parts.length - 1] === String(pid)) {
            const m = parts[1].match(/:(\d+)$/);
            if (m) {
              const p = parseInt(m[1], 10);
              if (p > 1024 && !ports.includes(p)) ports.push(p);
            }
          }
        }
      } else {
        const { stdout } = await execAsync(`lsof -nP -p ${pid} -a -iTCP -sTCP:LISTEN 2>/dev/null`, { timeout: 3000 });
        for (const line of stdout.split('\n')) {
          const m = line.match(/:(\d+)\s+\(LISTEN\)/);
          if (m) {
            const p = parseInt(m[1], 10);
            if (!ports.includes(p)) ports.push(p);
          }
        }
      }
    } catch (e) {}

    // Fallbacks
    const defaults = [58014, 58013, 53530, 53527, 53529, 53533, 53534];
    for (const d of defaults) {
      if (!ports.includes(d)) ports.push(d);
    }
    return ports;
  }

  requestRpc(port, token, path, body, useHttps = false) {
    return new Promise((resolve) => {
      const data = JSON.stringify(body || DEFAULT_METADATA_BODY);
      const options = {
        hostname: '127.0.0.1',
        port: port,
        path: path,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(data),
          'x-codeium-csrf-token': token
        },
        timeout: 3000,
        rejectUnauthorized: false
      };

      const lib = useHttps ? https : http;
      const req = lib.request(options, (res) => {
        let respData = '';
        res.on('data', chunk => respData += chunk);
        res.on('end', () => {
          if (res.statusCode === 200) {
            try {
              resolve({ ok: true, data: JSON.parse(respData) });
            } catch (err) {
              resolve({ ok: false, error: 'JSON parse error' });
            }
          } else {
            resolve({ ok: false, status: res.statusCode });
          }
        });
      });

      req.on('error', (err) => resolve({ ok: false, error: err.message }));
      req.on('timeout', () => { req.destroy(); resolve({ ok: false, error: 'timeout' }); });
      req.write(data);
      req.end();
    });
  }

  async fetchQuota() {
    const candidates = await this.findProcesses();
    if (candidates.length === 0) {
      throw new Error('Nenhum processo do Antigravity em execução.');
    }

    for (const cand of candidates) {
      const ports = await this.getPorts(cand.pid, cand.commandLine);
      for (const port of ports) {
        // Probe with GetUserStatus
        for (const isHttps of [false, true]) {
          const userRes = await this.requestRpc(port, cand.csrfToken, RPC_USER_STATUS_PATH, {}, isHttps);
          if (userRes.ok) {
            // Found working port & protocol!
            const summaryRes = await this.requestRpc(port, cand.csrfToken, RPC_SUMMARY_PATH, {}, isHttps);
            return this.normalize(summaryRes.data || {}, userRes.data || {});
          }
        }
      }
    }
    throw new Error('Não foi possível conectar ao RPC local do Antigravity.');
  }

  normalize(quotaData, userData) {
    const userStatus = userData.userStatus || {};
    const planInfo = userStatus.planStatus?.planInfo || {};

    const groups = [];
    const qPayload = quotaData.response || quotaData;
    const rawGroups = qPayload.groups || [];
    for (const g of rawGroups) {
      const gItem = {
        name: g.displayName || 'Modelos',
        description: g.description || '',
        buckets: []
      };
      for (const b of (g.buckets || [])) {
        const pct = Math.round((b.remainingFraction ?? 1) * 100);
        const timeStr = formatTimeRemaining(b.resetTime);
        gItem.buckets.push({
          id: b.bucketId || '',
          name: b.displayName || 'Limite',
          remaining_pct: pct,
          reset_in: timeStr,
          reset_time: b.resetTime || null,
          detail: timeStr ? `Reseta em ${timeStr}` : ''
        });
      }
      if (gItem.buckets.length > 0) groups.push(gItem);
    }

    return {
      account: userStatus.email || 'Conta Antigravity',
      userName: userStatus.name || 'Usuário',
      plan: planInfo.planName || 'Pro',
      groups: groups,
      updated_at: new Date().toLocaleTimeString('pt-BR')
    };
  }
}

if (require.main === module) {
  const engine = new QuotaEngine();
  engine.fetchQuota().then(res => {
    console.log(JSON.stringify(res, null, 2));
  }).catch(err => {
    console.error(JSON.stringify({ error: err.message }));
    process.exit(1);
  });
}

module.exports = { QuotaEngine };
