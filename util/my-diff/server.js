const http = require('http');
const fs = require('fs');
const path = require('path');

const port = Number(process.argv[2] || 8777);
const root = path.resolve(process.argv[3] || __dirname);
const host = '127.0.0.1';

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

const server = http.createServer((req, res) => {
  let rel = decodeURIComponent(req.url.split('?')[0]);
  if (rel === '/') rel = '/index.html';

  const file = path.join(root, path.normalize(rel).replace(/^[\\/]+/, ''));
  if (file !== root && !file.startsWith(root + path.sep)) {
    res.writeHead(403, { 'Content-Type': 'text/plain' });
    res.end('Forbidden');
    return;
  }

  fs.readFile(file, (err, data) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Not found');
      return;
    }
    res.writeHead(200, {
      'Content-Type': types[path.extname(file).toLowerCase()] || 'application/octet-stream',
      'Cache-Control': 'no-store'
    });
    res.end(data);
  });
});

server.on('error', err => {
  console.error('[my-diff] server error: ' + err.message);
  process.exit(1);
});

server.listen(port, host, () => {
  console.log('[my-diff] serving ' + root + ' at http://localhost:' + port + '/');
});

process.on('SIGTERM', () => server.close(() => process.exit(0)));
