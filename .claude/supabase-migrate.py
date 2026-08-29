#!/usr/bin/env python3
"""Applique une migration SQL Starvolt via l'API Management Supabase.

Le PAT vit dans .claude/.supabase-pat (jamais dans la ligne de commande ni
committé), la commande reste donc stable et allow-listée une fois pour toutes :
  python3 .claude/supabase-migrate.py <fichier.sql>
  python3 .claude/supabase-migrate.py -e "select 1;"
"""
import sys, json, os, re, glob, urllib.request, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
REF  = os.environ.get('SUPABASE_PROJECT_REF', 'hkxkhwegqkapdbsisxwv')

def pat():
    # Accepte n'importe quel fichier .supabase-pat* déposé par Greg, y compris un
    # .rtf enregistré par TextEdit : on retire le balisage RTF puis on retient le
    # plus long identifiant (le token). Claude n'écrit jamais le token lui-même.
    for f in glob.glob(os.path.join(HERE, '.supabase-pat')) + glob.glob(os.path.join(HERE, '.supabase-pat.*')):
        try:
            brut = open(f, encoding='utf-8', errors='ignore').read()
        except OSError:
            continue
        txt = re.sub(r'\\[a-zA-Z]+-?\d* ?', ' ', brut)   # commandes RTF \xxx
        txt = re.sub(r'[{}\\;]', ' ', txt)               # accolades et échappements
        runs = re.findall(r'[A-Za-z0-9_-]{30,}', txt)
        if runs:
            return max(runs, key=len)
    sys.exit("Token introuvable : déposez-le dans .claude/.supabase-pat (le .rtf de TextEdit est accepté).")

def main():
    if len(sys.argv) < 2:
        sys.exit("usage: supabase-migrate.py <fichier.sql> | -e \"SQL\"")
    if sys.argv[1] == '-e':
        sql = sys.argv[2] if len(sys.argv) > 2 else ''
    else:
        sql = open(sys.argv[1], encoding='utf-8').read()
    body = json.dumps({'query': sql}).encode('utf-8')
    req = urllib.request.Request(
        f'https://api.supabase.com/v1/projects/{REF}/database/query',
        data=body, method='POST',
        headers={'Authorization': f'Bearer {pat()}', 'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req) as r:
            print('OK', r.status, r.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        print('ERREUR', e.code, e.read().decode('utf-8'))
        sys.exit(1)

if __name__ == '__main__':
    main()
