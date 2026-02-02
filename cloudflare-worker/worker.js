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
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&family=Outfit:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --btc-orange: #f7931a;
      --btc-orange-dim: rgba(247, 147, 26, 0.15);
      --btc-orange-glow: rgba(247, 147, 26, 0.4);
      --bg-primary: #08080a;
      --bg-secondary: #0d0d10;
      --bg-card: rgba(255, 255, 255, 0.03);
      --bg-card-hover: rgba(255, 255, 255, 0.05);
      --border-subtle: rgba(255, 255, 255, 0.08);
      --border-orange: rgba(247, 147, 26, 0.25);
      --text-primary: #f0f0f0;
      --text-secondary: #888;
      --text-muted: #555;
      --terminal-green: #4ade80;
      --success: #22c55e;
      --radius-sm: 6px;
      --radius-md: 12px;
      --radius-lg: 16px;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    html {
      scroll-behavior: smooth;
    }

    body {
      font-family: 'Outfit', -apple-system, sans-serif;
      background: var(--bg-primary);
      color: var(--text-primary);
      min-height: 100vh;
      line-height: 1.6;
      overflow-x: hidden;
    }

    /* Animated grid background */
    body::before {
      content: '';
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background-image:
        linear-gradient(rgba(247, 147, 26, 0.03) 1px, transparent 1px),
        linear-gradient(90deg, rgba(247, 147, 26, 0.03) 1px, transparent 1px);
      background-size: 60px 60px;
      pointer-events: none;
      z-index: 0;
    }

    /* Radial glow from top */
    body::after {
      content: '';
      position: fixed;
      top: -50%;
      left: 50%;
      transform: translateX(-50%);
      width: 100%;
      max-width: 800px;
      height: 600px;
      background: radial-gradient(ellipse, var(--btc-orange-glow) 0%, transparent 70%);
      opacity: 0.15;
      pointer-events: none;
      z-index: 0;
    }

    .container {
      position: relative;
      z-index: 1;
      width: 100%;
      max-width: 720px;
      margin: 0 auto;
      padding: 1rem;
    }

    /* Header */
    .header {
      text-align: center;
      margin-bottom: 1rem;
      animation: fadeInDown 0.6s ease-out;
    }

    .logo {
      font-size: clamp(2rem, 8vw, 3rem);
      margin-bottom: 0.25rem;
      display: inline-block;
      animation: float 3s ease-in-out infinite;
      filter: drop-shadow(0 0 20px var(--btc-orange-glow));
    }

    h1 {
      font-family: 'Outfit', sans-serif;
      font-size: clamp(1.5rem, 5vw, 2rem);
      font-weight: 700;
      margin-bottom: 0.25rem;
      background: linear-gradient(135deg, var(--btc-orange) 0%, #ffa726 50%, var(--btc-orange) 100%);
      background-size: 200% auto;
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      animation: shimmer 3s linear infinite;
    }

    .subtitle {
      color: var(--text-secondary);
      font-size: clamp(0.8rem, 2.5vw, 0.95rem);
      font-weight: 400;
    }

    /* Cards */
    .card {
      background: var(--bg-card);
      border: 1px solid var(--border-subtle);
      border-radius: var(--radius-md);
      padding: 0.875rem;
      margin-bottom: 0.625rem;
      backdrop-filter: blur(10px);
      transition: all 0.3s ease;
      animation: fadeInUp 0.5s ease-out backwards;
    }

    .card:nth-child(1) { animation-delay: 0.1s; }
    .card:nth-child(2) { animation-delay: 0.15s; }
    .card:nth-child(3) { animation-delay: 0.2s; }
    .card:nth-child(4) { animation-delay: 0.25s; }

    .card:hover {
      background: var(--bg-card-hover);
      border-color: rgba(255, 255, 255, 0.12);
      transform: translateY(-2px);
    }

    .card--highlight {
      border-color: var(--border-orange);
      background: var(--btc-orange-dim);
    }

    .card--highlight:hover {
      border-color: rgba(247, 147, 26, 0.4);
      background: rgba(247, 147, 26, 0.12);
    }

    .card__header {
      display: flex;
      align-items: center;
      gap: 0.4rem;
      margin-bottom: 0.5rem;
    }

    .card__icon {
      font-size: 1rem;
    }

    .card__title {
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.7rem;
      font-weight: 600;
      color: var(--text-secondary);
      text-transform: uppercase;
      letter-spacing: 0.08em;
    }

    /* Command box - terminal style */
    .terminal {
      background: var(--bg-secondary);
      border: 1px solid var(--border-subtle);
      border-radius: var(--radius-sm);
      overflow: hidden;
    }

    .terminal__bar {
      display: flex;
      align-items: center;
      gap: 5px;
      padding: 0.4rem 0.6rem;
      background: rgba(255, 255, 255, 0.02);
      border-bottom: 1px solid var(--border-subtle);
    }

    .terminal__dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--text-muted);
    }

    .terminal__dot--red { background: #ff5f57; }
    .terminal__dot--yellow { background: #ffbd2e; }
    .terminal__dot--green { background: #28c840; }

    .terminal__body {
      display: flex;
      align-items: center;
      padding: 0.6rem 0.75rem;
      gap: 0.5rem;
      overflow-x: auto;
      -webkit-overflow-scrolling: touch;
    }

    .terminal__prompt {
      color: var(--btc-orange);
      font-family: 'JetBrains Mono', monospace;
      font-weight: 600;
      font-size: 0.85rem;
      flex-shrink: 0;
    }

    .terminal__command {
      font-family: 'JetBrains Mono', monospace;
      font-size: clamp(0.75rem, 2.5vw, 0.85rem);
      color: var(--terminal-green);
      white-space: nowrap;
      flex: 1;
      min-width: 0;
    }

    .copy-btn {
      background: var(--btc-orange);
      color: #000;
      border: none;
      padding: 0.4rem 0.75rem;
      border-radius: var(--radius-sm);
      cursor: pointer;
      font-family: 'Outfit', sans-serif;
      font-weight: 600;
      font-size: 0.8rem;
      transition: all 0.2s ease;
      flex-shrink: 0;
      min-height: 36px;
      min-width: 60px;
    }

    .copy-btn:hover {
      background: #ffa726;
      transform: scale(1.02);
    }

    .copy-btn:active {
      transform: scale(0.98);
    }

    .copy-btn--copied {
      background: var(--success);
    }

    .card__note {
      font-size: 0.7rem;
      color: var(--text-muted);
      text-align: center;
      margin-top: 0.4rem;
      line-height: 1.4;
    }

    /* Prerequisites card */
    .prereq {
      font-size: 0.8rem;
      color: var(--text-secondary);
    }

    .prereq__section {
      margin-bottom: 0.5rem;
    }

    .prereq__section:last-child {
      margin-bottom: 0;
    }

    .prereq__heading {
      font-weight: 600;
      color: var(--text-primary);
      margin-bottom: 0.25rem;
      font-size: 0.75rem;
    }

    .prereq__list {
      margin-left: 1rem;
      margin-bottom: 0;
    }

    .prereq__list li {
      margin-bottom: 0.2rem;
      line-height: 1.4;
    }

    .prereq__list a {
      color: var(--btc-orange);
      text-decoration: none;
      transition: opacity 0.2s;
    }

    .prereq__list a:hover {
      opacity: 0.8;
    }

    .prereq__code {
      display: inline-block;
      background: var(--bg-secondary);
      padding: 1px 6px;
      border-radius: var(--radius-sm);
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.7rem;
      margin-top: 2px;
    }

    /* Features grid */
    .features {
      display: grid;
      grid-template-columns: repeat(5, 1fr);
      gap: 0.5rem;
      margin-bottom: 0.75rem;
      animation: fadeInUp 0.5s ease-out 0.3s backwards;
    }

    .feature {
      background: var(--bg-card);
      border: 1px solid var(--border-subtle);
      border-radius: var(--radius-sm);
      padding: 0.5rem;
      text-align: center;
      transition: all 0.3s ease;
    }

    .feature:hover {
      background: var(--bg-card-hover);
      transform: translateY(-1px);
    }

    .feature__icon {
      font-size: 1.1rem;
      margin-bottom: 0.2rem;
    }

    .feature__title {
      font-weight: 600;
      font-size: 0.7rem;
      margin-bottom: 0.1rem;
    }

    .feature__desc {
      font-size: 0.6rem;
      color: var(--text-secondary);
      line-height: 1.3;
    }

    /* Footer links */
    .links {
      display: flex;
      justify-content: center;
      gap: 0.5rem;
      flex-wrap: wrap;
      animation: fadeInUp 0.5s ease-out 0.35s backwards;
    }

    .links a {
      display: flex;
      align-items: center;
      gap: 0.3rem;
      color: var(--text-secondary);
      text-decoration: none;
      font-size: 0.75rem;
      padding: 0.35rem 0.5rem;
      border-radius: var(--radius-sm);
      transition: all 0.2s ease;
      min-height: 32px;
    }

    .links a:hover {
      color: var(--btc-orange);
      background: var(--btc-orange-dim);
    }

    .links svg {
      width: 14px;
      height: 14px;
      flex-shrink: 0;
    }

    /* Animations */
    @keyframes fadeInDown {
      from {
        opacity: 0;
        transform: translateY(-20px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    @keyframes fadeInUp {
      from {
        opacity: 0;
        transform: translateY(20px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    @keyframes float {
      0%, 100% { transform: translateY(0); }
      50% { transform: translateY(-8px); }
    }

    @keyframes shimmer {
      to { background-position: 200% center; }
    }

    /* Tablet and up */
    @media (min-width: 640px) {
      .container {
        padding: 1.5rem;
      }

      .header {
        margin-bottom: 1.25rem;
      }

      .card {
        padding: 1rem;
        margin-bottom: 0.75rem;
      }

      .links {
        gap: 0.75rem;
      }
    }

    /* Desktop */
    @media (min-width: 1024px) {
      .container {
        padding: 2rem;
      }

      .card:hover {
        transform: translateY(-2px);
      }

      .feature:hover {
        transform: translateY(-2px);
      }
    }

    /* Tablet adjustments */
    @media (max-width: 640px) {
      .features {
        grid-template-columns: repeat(3, 1fr);
      }
    }

    /* Mobile-specific adjustments */
    @media (max-width: 480px) {
      .features {
        grid-template-columns: repeat(2, 1fr);
      }

      .features .feature:last-child {
        grid-column: span 2;
      }

      .terminal__body {
        flex-direction: column;
        align-items: stretch;
        gap: 0.5rem;
      }

      .terminal__prompt {
        display: none;
      }

      .copy-btn {
        width: 100%;
        min-height: 40px;
      }

      .card__note {
        font-size: 0.65rem;
      }

      .prereq__code {
        font-size: 0.65rem;
        word-break: break-all;
        white-space: normal;
      }
    }

    /* Reduced motion */
    @media (prefers-reduced-motion: reduce) {
      *, *::before, *::after {
        animation-duration: 0.01ms !important;
        transition-duration: 0.01ms !important;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <header class="header">
      <div class="logo">₿</div>
      <h1>OpenClaw + aibtc</h1>
      <p class="subtitle">Deploy your Bitcoin & Stacks AI agent in one command</p>
    </header>

    <main>
      <div class="card">
        <div class="card__header">
          <span class="card__icon">🚀</span>
          <h2 class="card__title">Quick Install (VPS)</h2>
        </div>
        <div class="terminal">
          <div class="terminal__bar">
            <span class="terminal__dot terminal__dot--red"></span>
            <span class="terminal__dot terminal__dot--yellow"></span>
            <span class="terminal__dot terminal__dot--green"></span>
          </div>
          <div class="terminal__body">
            <span class="terminal__prompt">$</span>
            <code class="terminal__command">curl -sSL sh.biwas.xyz | sh</code>
            <button class="copy-btn" onclick="copyCommand(this, 'curl -sSL sh.biwas.xyz | sh')">Copy</button>
          </div>
        </div>
        <p class="card__note">2GB RAM, 25GB disk • Ubuntu/Debian/CentOS • Installs Docker automatically</p>
      </div>

      <div class="card">
        <div class="card__header">
          <span class="card__icon">💻</span>
          <h2 class="card__title">Local (Docker Desktop)</h2>
        </div>
        <div class="terminal">
          <div class="terminal__bar">
            <span class="terminal__dot terminal__dot--red"></span>
            <span class="terminal__dot terminal__dot--yellow"></span>
            <span class="terminal__dot terminal__dot--green"></span>
          </div>
          <div class="terminal__body">
            <span class="terminal__prompt">$</span>
            <code class="terminal__command">curl -sSL sh.biwas.xyz/local | sh</code>
            <button class="copy-btn" onclick="copyCommand(this, 'curl -sSL sh.biwas.xyz/local | sh')">Copy</button>
          </div>
        </div>
        <p class="card__note">Requires Docker Desktop installed and running</p>
      </div>

      <div class="card card--highlight">
        <div class="card__header">
          <span class="card__icon">🔄</span>
          <h2 class="card__title">Existing Users — Update Skill</h2>
        </div>
        <div class="terminal">
          <div class="terminal__bar">
            <span class="terminal__dot terminal__dot--red"></span>
            <span class="terminal__dot terminal__dot--yellow"></span>
            <span class="terminal__dot terminal__dot--green"></span>
          </div>
          <div class="terminal__body">
            <span class="terminal__prompt">$</span>
            <code class="terminal__command">curl -sSL sh.biwas.xyz/update-skill.sh | sh</code>
            <button class="copy-btn" onclick="copyCommand(this, 'curl -sSL sh.biwas.xyz/update-skill.sh | sh')">Copy</button>
          </div>
        </div>
        <p class="card__note">Adds Moltbook social network • Daemon mode for wallet persistence • Restarts container</p>
      </div>

      <div class="card">
        <div class="card__header">
          <span class="card__icon">📋</span>
          <h2 class="card__title">Prerequisites</h2>
        </div>
        <div class="prereq">
          <div class="prereq__section">
            <p class="prereq__heading">You'll need:</p>
            <ul class="prereq__list">
              <li>OpenRouter API Key → <a href="https://openrouter.ai/keys" target="_blank">openrouter.ai/keys</a></li>
              <li>Telegram Bot Token → <a href="https://t.me/BotFather" target="_blank">@BotFather</a></li>
            </ul>
          </div>
          <div class="prereq__section">
            <p class="prereq__heading">For VPS deploy:</p>
            <ol class="prereq__list">
              <li>Generate SSH key:<br><code class="prereq__code">ssh-keygen -t ed25519</code></li>
              <li>Copy public key:<br><code class="prereq__code">cat ~/.ssh/id_ed25519.pub</code></li>
              <li>Create VPS on <a href="https://digitalocean.com" target="_blank">DigitalOcean</a>, <a href="https://hetzner.com" target="_blank">Hetzner</a>, or <a href="https://vultr.com" target="_blank">Vultr</a></li>
              <li>Choose Ubuntu 24.04, paste your public key</li>
              <li>SSH in:<br><code class="prereq__code">ssh root@your-vps-ip</code></li>
            </ol>
          </div>
        </div>
      </div>

      <div class="features">
        <div class="feature">
          <div class="feature__icon">⚡</div>
          <div class="feature__title">Bitcoin L1</div>
          <div class="feature__desc">Send BTC, balances, fees</div>
        </div>
        <div class="feature">
          <div class="feature__icon">🔗</div>
          <div class="feature__title">Stacks L2</div>
          <div class="feature__desc">STX, contracts, DeFi</div>
        </div>
        <div class="feature">
          <div class="feature__icon">💱</div>
          <div class="feature__title">DeFi</div>
          <div class="feature__desc">ALEX, Zest Protocol</div>
        </div>
        <div class="feature">
          <div class="feature__icon">💬</div>
          <div class="feature__title">Telegram</div>
          <div class="feature__desc">Chat with agent</div>
        </div>
        <div class="feature">
          <div class="feature__icon">🦞</div>
          <div class="feature__title">Moltbook</div>
          <div class="feature__desc">AI social network</div>
        </div>
      </div>

      <nav class="links">
        <a href="${GITHUB_REPO}" target="_blank">
          <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
          GitHub
        </a>
        <a href="${GITHUB_REPO}#readme" target="_blank">
          <svg viewBox="0 0 24 24" fill="currentColor"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6zm-1 2l5 5h-5V4zM6 20V4h6v6h6v10H6z"/></svg>
          Docs
        </a>
        <a href="https://github.com/aibtcdev/aibtc-mcp-server" target="_blank">
          <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
          aibtc-mcp
        </a>
        <a href="https://moltbook.com" target="_blank">
          <svg viewBox="0 0 24 24" fill="currentColor"><path d="M17 3H7c-1.1 0-2 .9-2 2v16l7-3 7 3V5c0-1.1-.9-2-2-2z"/></svg>
          Moltbook
        </a>
        <a href="https://openclaw.ai" target="_blank">
          <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
          OpenClaw
        </a>
      </nav>
    </main>
  </div>

  <script>
    function copyCommand(btn, text) {
      navigator.clipboard.writeText(text).then(() => {
        const original = btn.textContent;
        btn.textContent = 'Copied!';
        btn.classList.add('copy-btn--copied');
        setTimeout(() => {
          btn.textContent = original;
          btn.classList.remove('copy-btn--copied');
        }, 2000);
      }).catch(() => {
        // Fallback for older browsers
        const textarea = document.createElement('textarea');
        textarea.value = text;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        const original = btn.textContent;
        btn.textContent = 'Copied!';
        btn.classList.add('copy-btn--copied');
        setTimeout(() => {
          btn.textContent = original;
          btn.classList.remove('copy-btn--copied');
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
        scriptPath = '/local-setup.sh';
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
