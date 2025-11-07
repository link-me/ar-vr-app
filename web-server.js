const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 9091;
// Prefer serving Godot HTML5 export if present, otherwise fall back to demo
const BUILD_ROOT = path.join(__dirname, 'godot', 'web', 'build');
const DEMO_ROOT = path.join(__dirname, 'godot', 'web');
const ROOT = fs.existsSync(path.join(BUILD_ROOT, 'index.html')) ? BUILD_ROOT : DEMO_ROOT;

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm'
};

const server = http.createServer((req, res) => {
  const reqPath = decodeURIComponent(req.url.split('?')[0]);
  let filePath = path.join(ROOT, reqPath);
  if (reqPath === '/' || reqPath === '') {
    filePath = path.join(ROOT, 'index.html');
  }
  // Prevent path traversal
  if (!filePath.startsWith(ROOT)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }
  fs.stat(filePath, (err, stat) => {
    if (err || !stat.isFile()) {
      res.writeHead(404);
      res.end('Not Found');
      return;
    }
    const ext = path.extname(filePath).toLowerCase();
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
    fs.createReadStream(filePath).pipe(res);
  });
});

server.listen(PORT, '127.0.0.1', () => {
  const url = `http://127.0.0.1:${PORT}/`;
  console.log(`Static server running at ${url} serving ${ROOT}`);
});