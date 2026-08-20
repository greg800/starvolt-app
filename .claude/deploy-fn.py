#!/usr/bin/env python3
"""Déploie une edge function Supabase via l'API Management (multipart).

Usage : python3 .claude/deploy-fn.py <slug> [chemin/index.ts]
Le token est lu dans un fichier .supabase-pat* (jamais dans la commande).
Un User-Agent explicite est requis (Cloudflare 1010 sinon).
"""
import sys, os, re, glob, json, uuid, urllib.request, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
REF  = os.environ.get('SUPABASE_PROJECT_REF', 'hkxkhwegqkapdbsisxwv')

def token():
    cands = (glob.glob(os.path.join(HERE, '.supabase-pat'))
             + glob.glob(os.path.join(HERE, '.supabase-pat.*'))
             + glob.glob(os.path.join(ROOT, '*supabase-pat*')))
    for f in cands:
        try:
            brut = open(f, encoding='utf-8', errors='ignore').read()
        except OSError:
            continue
        txt = re.sub(r'\\[a-zA-Z]+-?\d* ?', ' ', brut)
        txt = re.sub(r'[{}\\;]', ' ', txt)
        runs = re.findall(r'[A-Za-z0-9_-]{30,}', txt)
        if runs:
            return max(runs, key=len)
    sys.exit("Token introuvable dans un fichier .supabase-pat*.")

def main():
    if len(sys.argv) < 2:
        sys.exit("usage: deploy-fn.py <slug> [index.ts]")
    slug = sys.argv[1]
    path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, 'supabase', 'functions', slug, 'index.ts')
    code = open(path, encoding='utf-8').read()
    metadata = json.dumps({'entrypoint_path': 'index.ts', 'name': slug, 'verify_jwt': True})

    boundary = '----starvolt' + uuid.uuid4().hex
    def part(name, filename, ctype, content):
        return (f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"'
                + (f'; filename="{filename}"' if filename else '')
                + f'\r\nContent-Type: {ctype}\r\n\r\n{content}\r\n')
    body = (part('metadata', None, 'application/json', metadata)
            + part('file', 'index.ts', 'application/typescript', code)
            + f'--{boundary}--\r\n').encode('utf-8')

    req = urllib.request.Request(
        f'https://api.supabase.com/v1/projects/{REF}/functions/deploy?slug={slug}',
        data=body, method='POST')
    req.add_header('Content-Type', f'multipart/form-data; boundary={boundary}')
    req.add_header('User-Agent', 'curl/8.4.0')
    req.add_header('Authorization', 'Bearer ' + token())
    try:
        with urllib.request.urlopen(req) as r:
            print('OK', r.status, r.read().decode('utf-8')[:400])
    except urllib.error.HTTPError as e:
        print('ERREUR', e.code, e.read().decode('utf-8')[:800])
        sys.exit(1)

if __name__ == '__main__':
    main()
