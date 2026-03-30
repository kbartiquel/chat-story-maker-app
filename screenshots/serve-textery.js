const http = require('http');
const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');

const PORT = 8081;
const ROOT = __dirname;

// MIME types
const MIME = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
};

let browser = null;

async function getBrowser() {
  if (!browser || !browser.connected) {
    if (browser) try { await browser.close(); } catch {}
    browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox'] });
  }
  return browser;
}

async function takeScreenshot(htmlFile, selector = '#screenshot') {
  const b = await getBrowser();
  const page = await b.newPage();

  const isIpad = selector.includes('ipad');
  const vw = isIpad ? 2048 : 1242;
  const vh = isIpad ? 2732 : 2688;
  await page.setViewport({ width: vw, height: vh, deviceScaleFactor: 1 });

  await page.goto(`http://localhost:${PORT}/${htmlFile}`, { waitUntil: 'networkidle0' });

  // Remove wrapper transforms for full-resolution capture
  await page.evaluate((sel) => {
    document.querySelectorAll('.iphone-wrapper, .ipad-wrapper').forEach(w => {
      w.style.transform = 'none';
      w.style.margin = '0';
    });
    document.querySelectorAll('.screenshot-col').forEach(col => {
      const target = col.querySelector(sel);
      if (!target) col.style.display = 'none';
    });
    const title = document.querySelector('.page-title');
    if (title) title.style.display = 'none';
    document.querySelectorAll('.btn-row').forEach(b => b.style.display = 'none');
    document.querySelectorAll('h3').forEach(h => h.style.display = 'none');
  }, selector);

  await new Promise(r => setTimeout(r, 1000));

  const el = await page.$(selector);
  if (!el) throw new Error(`Selector "${selector}" not found`);
  const pngBuffer = await el.screenshot({ type: 'png' });
  await page.close();
  return pngBuffer;
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  // Screenshot API endpoint
  if (url.pathname === '/api/screenshot') {
    const file = url.searchParams.get('file') || 'textery-screen1.html';
    const selector = url.searchParams.get('selector') || '#screenshot-iphone';
    const name = path.basename(file, '.html');
    try {
      console.log(`Generating screenshot for ${file} (${selector})...`);
      const png = await takeScreenshot(file, selector);
      res.writeHead(200, {
        'Content-Type': 'image/png',
        'Content-Disposition': `attachment; filename="${name}.png"`,
        'Content-Length': png.length,
      });
      res.end(png);
      console.log(`Done! ${name}.png (${png.length} bytes)`);
    } catch (e) {
      console.error('Screenshot error:', e);
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Error: ' + e.message);
    }
    return;
  }

  // Static file serving
  let filePath = path.join(ROOT, decodeURIComponent(url.pathname));
  if (url.pathname === '/') filePath = path.join(ROOT, 'textery-screen1.html');

  try {
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      filePath = path.join(filePath, 'index.html');
    }
    const data = fs.readFileSync(filePath);
    const ext = path.extname(filePath);
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
    res.end(data);
  } catch {
    res.writeHead(404);
    res.end('Not found');
  }
});

server.listen(PORT, () => {
  console.log(`\n  Textery Screenshot server running at http://localhost:${PORT}`);
  console.log(`  Pages:`);
  console.log(`    http://localhost:${PORT}/textery-screen1.html`);
  console.log(`    http://localhost:${PORT}/textery-screen2.html`);
  console.log(`    http://localhost:${PORT}/textery-screen3.html`);
  console.log(`    http://localhost:${PORT}/textery-screen4.html`);
  console.log(`    http://localhost:${PORT}/textery-screen5.html`);
  console.log(`  Click "Download PNG" for pixel-perfect export\n`);
});

process.on('SIGINT', async () => {
  if (browser) await browser.close();
  process.exit();
});
