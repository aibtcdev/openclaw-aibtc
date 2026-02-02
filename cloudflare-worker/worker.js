/**
 * Cloudflare Worker for sh.biwas.xyz
 *
 * - Browser visit → Shows landing page with copy buttons
 * - curl/wget → Serves the setup script
 */

const GITHUB_RAW = 'https://raw.githubusercontent.com/biwasxyz/openclaw-aibtc/main';
const GITHUB_REPO = 'https://github.com/biwasxyz/openclaw-aibtc';

const HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>OpenClaw + aibtc | Bitcoin Agent Setup</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
      background: linear-gradient(135deg, #0f0f0f 0%, #1a1a2e 100%);
      color: #fff;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 2rem;
    }

    .container {
      max-width: 700px;
      width: 100%;
    }

    .logo {
      font-size: 4rem;
      margin-bottom: 1rem;
      text-align: center;
    }

    h1 {
      font-size: 2.5rem;
      text-align: center;
      margin-bottom: 0.5rem;
      background: linear-gradient(90deg, #f7931a, #ff9500);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }

    .subtitle {
      text-align: center;
      color: #888;
      margin-bottom: 2rem;
      font-size: 1.1rem;
    }

    .card {
      background: rgba(255,255,255,0.05);
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 12px;
      padding: 1.5rem;
      margin-bottom: 1.5rem;
    }

    .card h2 {
      font-size: 1rem;
      color: #888;
      margin-bottom: 1rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }

    .command-box {
      display: flex;
      align-items: center;
      background: #0d0d0d;
      border-radius: 8px;
      padding: 1rem;
      font-family: 'SF Mono', Monaco, 'Courier New', monospace;
      font-size: 0.95rem;
      overflow-x: auto;
    }

    .command-box code {
      flex: 1;
      color: #4ade80;
      white-space: nowrap;
    }

    .copy-btn {
      background: #f7931a;
      color: #000;
      border: none;
      padding: 0.5rem 1rem;
      border-radius: 6px;
      cursor: pointer;
      font-weight: 600;
      font-size: 0.85rem;
      margin-left: 1rem;
      transition: all 0.2s;
      white-space: nowrap;
    }

    .copy-btn:hover {
      background: #ff9500;
      transform: scale(1.05);
    }

    .copy-btn.copied {
      background: #4ade80;
    }

    .features {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 1rem;
      margin-bottom: 2rem;
    }

    .feature {
      background: rgba(255,255,255,0.03);
      border-radius: 8px;
      padding: 1rem;
      text-align: center;
    }

    .feature-icon {
      font-size: 1.5rem;
      margin-bottom: 0.5rem;
    }

    .feature-title {
      font-weight: 600;
      margin-bottom: 0.25rem;
    }

    .feature-desc {
      font-size: 0.85rem;
      color: #888;
    }

    .links {
      display: flex;
      justify-content: center;
      gap: 1.5rem;
      flex-wrap: wrap;
    }

    .links a {
      color: #888;
      text-decoration: none;
      display: flex;
      align-items: center;
      gap: 0.5rem;
      transition: color 0.2s;
    }

    .links a:hover {
      color: #f7931a;
    }

    .requirements {
      font-size: 0.9rem;
      color: #666;
      text-align: center;
      margin-top: 1rem;
    }

    @media (max-width: 600px) {
      h1 { font-size: 1.8rem; }
      .command-box { flex-direction: column; gap: 1rem; }
      .copy-btn { margin-left: 0; width: 100%; }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">₿</div>
    <h1>OpenClaw + aibtc</h1>
    <p class="subtitle">Deploy your Bitcoin & Stacks AI agent in one command</p>

    <div class="card">
      <h2>🚀 Quick Install</h2>
      <div class="command-box">
        <code>curl -sSL sh.biwas.xyz | sh</code>
        <button class="copy-btn" onclick="copyCommand(this, 'curl -sSL sh.biwas.xyz | sh')">Copy</button>
      </div>
      <p class="requirements">Works on any VPS (Ubuntu, Debian, CentOS) • Installs Docker automatically</p>
    </div>

    <div class="card">
      <h2>💻 Local (Docker Desktop)</h2>
      <div class="command-box">
        <code>curl -sSL sh.biwas.xyz/local | sh</code>
        <button class="copy-btn" onclick="copyCommand(this, 'curl -sSL sh.biwas.xyz/local | sh')">Copy</button>
      </div>
    </div>

    <div class="features">
      <div class="feature">
        <div class="feature-icon">⚡</div>
        <div class="feature-title">Bitcoin L1</div>
        <div class="feature-desc">Send BTC, check balances, fees</div>
      </div>
      <div class="feature">
        <div class="feature-icon">🔗</div>
        <div class="feature-title">Stacks L2</div>
        <div class="feature-desc">STX, smart contracts, DeFi</div>
      </div>
      <div class="feature">
        <div class="feature-icon">💱</div>
        <div class="feature-title">DeFi</div>
        <div class="feature-desc">ALEX swaps, Zest lending</div>
      </div>
      <div class="feature">
        <div class="feature-icon">💬</div>
        <div class="feature-title">Telegram</div>
        <div class="feature-desc">Chat with your agent</div>
      </div>
    </div>

    <div class="links">
      <a href="${GITHUB_REPO}" target="_blank">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
        GitHub
      </a>
      <a href="${GITHUB_REPO}#readme" target="_blank">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6zm-1 2l5 5h-5V4zM6 20V4h6v6h6v10H6z"/></svg>
        Docs
      </a>
      <a href="https://github.com/aibtcdev/aibtc-mcp-server" target="_blank">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
        aibtc-mcp
      </a>
      <a href="https://openclaw.ai" target="_blank">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
        OpenClaw
      </a>
    </div>
  </div>

  <script>
    function copyCommand(btn, text) {
      navigator.clipboard.writeText(text).then(() => {
        const original = btn.textContent;
        btn.textContent = 'Copied!';
        btn.classList.add('copied');
        setTimeout(() => {
          btn.textContent = original;
          btn.classList.remove('copied');
        }, 2000);
      });
    }
  </script>
</body>
</html>`;

function isCurl(request) {
  const ua = request.headers.get('user-agent') || '';
  return ua.toLowerCase().includes('curl') ||
         ua.toLowerCase().includes('wget') ||
         ua.toLowerCase().includes('httpie');
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname;

    // Serve HTML for browsers
    if (!isCurl(request) && (path === '/' || path === '')) {
      return new Response(HTML, {
        headers: { 'content-type': 'text/html; charset=utf-8' }
      });
    }

    // Serve scripts for curl/wget
    let scriptPath;
    switch (path) {
      case '/':
      case '/vps':
        scriptPath = '/vps-setup.sh';
        break;
      case '/local':
        scriptPath = '/setup.sh';
        break;
      default:
        scriptPath = path;
    }

    try {
      const response = await fetch(GITHUB_RAW + scriptPath);

      if (!response.ok) {
        return new Response('Script not found', { status: 404 });
      }

      return new Response(await response.text(), {
        headers: {
          'content-type': 'text/plain; charset=utf-8',
          'cache-control': 'public, max-age=300',
        },
      });
    } catch (error) {
      return new Response('Error fetching script', { status: 500 });
    }
  },
};
