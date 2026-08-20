#!/usr/bin/env python3
"""Applique une migration SQL Starvolt via l'API Management Supabase.

Le token vit dans un fichier .supabase-pat* déposé par Greg (jamais dans la
commande ni committé). Un User-Agent explicite est requis, sinon Cloudflare
renvoie 403 (code 1010) sur l'agent par défaut de Python.
"""
import sys, json, os, re, glob, urllib.request, urllib.error

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
        sys.exit("usage: db-apply.py <fichier.sql> | -e \"SQL\"")
    sql = sys.argv[2] if sys.argv[1] == '-e' else open(sys.argv[1], encoding='utf-8').read()
    body = json.dumps({'query': sql}).encode('utf-8')
    req = urllib.request.Request(
        f'https://api.supabase.com/v1/projects/{REF}/database/query',
        data=body, method='POST')
    req.add_header('Content-Type', 'application/json')
    req.add_header('User-Agent', 'curl/8.4.0')
    req.add_header('Authorization', 'Bearer ' + token())
    try:
        with urllib.request.urlopen(req) as r:
            print('OK', r.status, r.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        print('ERREUR', e.code, e.read().decode('utf-8'))
        sys.exit(1)

if __name__ == '__main__':
    main()
