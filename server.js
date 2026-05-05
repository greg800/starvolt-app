import http from 'http';
import fs   from 'fs';
import path  from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = process.env.PORT || 8080;

const mime = {
  '.html': 'text/html; charset=utf-8',
  '.css':  'text/css',
  '.js':   'application/javascript',
  '.json': 'application/json',
  '.png':  'image/png',
  '.ico':  'image/x-icon',
  '.svg':  'image/svg+xml',
  '.webmanifest': 'application/manifest+json',
};

http.createServer((req, res) => {
  const reqPath = req.url.split('?')[0]; // ignore query string

  // / → redirect vers /app
  if (reqPath === '/') {
    res.writeHead(301, { Location: '/app' });
    return res.end();
  }

  // /app et /app/ → servir starvolt.html
  if (reqPath === '/app' || reqPath === '/app/') {
    fs.readFile(path.join(__dirname, 'starvolt.html'), (err, data) => {
      if (err) { res.writeHead(404); return res.end('Not found'); }
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(data);
    });
    return;
  }

  // Tous les autres chemins → fichiers statiques (sw.js, manifest, images…)
  const file = path.join(__dirname, reqPath);
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); return res.end('Not found'); }
    const ext = path.extname(file);
    res.writeHead(200, { 'Content-Type': mime[ext] || 'text/plain' });
    res.end(data);
  });
}).listen(PORT, () => console.log(`Listening on ${PORT}`));
