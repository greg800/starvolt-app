import http from 'http';
import fs   from 'fs';
import path  from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = process.env.PORT || 8080;

// Numéro de build = SHA court du commit déployé (fourni par Railway au runtime).
// Injecté dans le HTML à la place du jeton %BUILD_ID%, pour que le journal des
// erreurs sache sur quelle version chaque bug est survenu. Repli : 'dev'.
const BUILD_ID = (process.env.RAILWAY_GIT_COMMIT_SHA
  || process.env.SOURCE_VERSION
  || process.env.GIT_COMMIT
  || '').slice(0, 7) || 'dev';
const injectBuild = (html) => html.split('%BUILD_ID%').join(BUILD_ID);

const mime = {
  '.html': 'text/html; charset=utf-8',
  '.css':  'text/css',
  '.js':   'application/javascript',
  '.json': 'application/json',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.ico':  'image/x-icon',
  '.svg':  'image/svg+xml',
  '.webmanifest': 'application/manifest+json',
};

// En-têtes de sécurité appliqués à toutes les réponses (défense en profondeur).
// Pas de CSP ici : l'app transpile le JSX dans le navigateur (Babel standalone),
// ce qui impose 'unsafe-eval' et 'unsafe-inline' → une CSP en aurait la valeur
// fortement réduite ; à traiter séparément si on retire Babel du runtime.
const SECURITY_HEADERS = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'SAMEORIGIN',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Strict-Transport-Security': 'max-age=15552000',
};

http.createServer((req, res) => {
  // Serveur de fichiers statiques en lecture seule : seules GET et HEAD ont un sens.
  // Toute autre méthode (POST/PUT/DELETE…) est refusée (405) — réduction de surface.
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.writeHead(405, { ...SECURITY_HEADERS, 'Allow': 'GET, HEAD' });
    return res.end('Method Not Allowed');
  }

  const reqPath = req.url.split('?')[0];

  // / et /app → servir starvolt.html (app.starvolt.fr est la racine)
  if (reqPath === '/' || reqPath === '/app' || reqPath === '/app/') {
    fs.readFile(path.join(__dirname, 'starvolt.html'), 'utf-8', (err, data) => {
      if (err) { res.writeHead(404); return res.end('Not found'); }
      res.writeHead(200, { ...SECURITY_HEADERS, 'Content-Type': 'text/html; charset=utf-8' });
      res.end(injectBuild(data));
    });
    return;
  }

  // Tous les autres chemins → fichiers statiques (sw.js, manifest, images…)
  // On décode puis on vérifie que le chemin résolu reste dans __dirname
  // (protection path traversal : GET /../../etc/passwd doit être refusé).
  let decoded;
  try { decoded = decodeURIComponent(reqPath); }
  catch { res.writeHead(400); return res.end('Bad request'); }

  const file = path.resolve(__dirname, '.' + decoded);
  if (file !== __dirname && !file.startsWith(__dirname + path.sep)) {
    res.writeHead(403); return res.end('Forbidden');
  }

  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); return res.end('Not found'); }
    const ext = path.extname(file);
    res.writeHead(200, { ...SECURITY_HEADERS, 'Content-Type': mime[ext] || 'text/plain' });
    res.end(ext === '.html' ? injectBuild(data.toString('utf-8')) : data);
  });
}).listen(PORT, () => console.log(`Listening on ${PORT}`));
