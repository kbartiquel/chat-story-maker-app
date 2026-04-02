const http = require('http');
const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');

const PORT = 8082;
const ROOT = __dirname;

const MIME = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
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

async function takeScreenshot(htmlFile, selector = '#screenshot-iphone', viewportWidth = 1242, viewportHeight = 2688) {
  const b = await getBrowser();
  const page = await b.newPage();
  await page.setViewport({ width: viewportWidth, height: viewportHeight, deviceScaleFactor: 1 });
  await page.goto(`http://localhost:${PORT}/${htmlFile}`, { waitUntil: 'networkidle0' });

  await page.evaluate((sel) => {
    document.querySelectorAll('.iphone-wrapper, .ipad-wrapper').forEach(w => {
      w.style.transform = 'none';
      w.style.margin = '0';
    });
    const title = document.querySelector('.page-title');
    if (title) title.style.display = 'none';
    document.querySelectorAll('.btn-row, h3').forEach(el => el.style.display = 'none');
  }, selector);

  await new Promise(r => setTimeout(r, 800));
  const el = await page.$(selector);
  if (!el) throw new Error(`Selector "${selector}" not found in ${htmlFile}`);
  const pngBuffer = await el.screenshot({ type: 'png' });
  await page.close();
  return pngBuffer;
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  if (url.pathname === '/api/screenshot') {
    const file = url.searchParams.get('file');
    const selector = url.searchParams.get('selector') || '#screenshot-iphone';
    const viewportWidth = Number(url.searchParams.get('width')) || 1242;
    const viewportHeight = Number(url.searchParams.get('height')) || 2688;
    if (!file) {
      res.writeHead(400, { 'Content-Type': 'text/plain' });
      res.end('Missing file parameter');
      return;
    }
    try {
      const png = await takeScreenshot(file, selector, viewportWidth, viewportHeight);
      res.writeHead(200, {
        'Content-Type': 'image/png',
        'Content-Disposition': `attachment; filename="${path.basename(file, '.html')}.png"`,
        'Content-Length': png.length,
      });
      res.end(png);
    } catch (error) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end(`Error: ${error.message}`);
    }
    return;
  }

  let filePath = path.join(ROOT, decodeURIComponent(url.pathname));
  if (url.pathname === '/') filePath = path.join(ROOT, 'index.html');

  try {
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) filePath = path.join(filePath, 'index.html');
    const data = fs.readFileSync(filePath);
    res.writeHead(200, { 'Content-Type': MIME[path.extname(filePath)] || 'application/octet-stream' });
    res.end(data);
  } catch {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not found');
  }
});

server.listen(PORT, () => {
  console.log(`Textery iPhone screenshot server: http://localhost:${PORT}`);
  console.log(`Review gallery: http://localhost:${PORT}/index.html`);
  console.log(`iPad review gallery: http://localhost:${PORT}/index-ipad.html`);
});

process.on('SIGINT', async () => {
  if (browser) await browser.close();
  process.exit();
});
