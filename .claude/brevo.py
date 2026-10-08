#!/usr/bin/env python3
"""Appels à l'API Brevo (ex-Sendinblue) pour Starvolt.

La clé vit dans .claude/.brevo-key, déposée par Greg via pbpaste (jamais dans
la ligne de commande ni committée). Un User-Agent explicite évite les refus
de type Cloudflare sur l'agent par défaut de Python.

  python3 .claude/brevo.py account
  python3 .claude/brevo.py senders
  python3 .claude/brevo.py send <expediteur> <destinataire> "<sujet>" "<texte>"
  python3 .claude/brevo.py sms <expediteur 11 car.> <33612345678> "<texte>"
"""
import sys, json, os, urllib.request, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
API  = 'https://api.brevo.com/v3'

def cle():
    try:
        k = open(os.path.join(HERE, '.brevo-key'), encoding='utf-8').read().strip()
    except OSError:
        sys.exit("Clé introuvable : déposez-la dans .claude/.brevo-key")
    if not k:
        sys.exit("Fichier .claude/.brevo-key vide")
    return k

def appel(methode, chemin, corps=None):
    data = json.dumps(corps).encode('utf-8') if corps is not None else None
    req = urllib.request.Request(API + chemin, data=data, method=methode)
    req.add_header('api-key', cle())
    req.add_header('accept', 'application/json')
    req.add_header('User-Agent', 'curl/8.4.0')
    if data is not None:
        req.add_header('content-type', 'application/json')
    try:
        with urllib.request.urlopen(req) as r:
            txt = r.read().decode('utf-8')
            print('OK', r.status, txt)
    except urllib.error.HTTPError as e:
        print('ERREUR', e.code, e.read().decode('utf-8'))
        sys.exit(1)

def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cmd = sys.argv[1]
    if cmd == 'account':
        appel('GET', '/account')
    elif cmd == 'senders':
        appel('GET', '/senders')
    elif cmd == 'send' and len(sys.argv) == 6:
        _, _, exp, dest, sujet, texte = sys.argv
        appel('POST', '/smtp/email', {
            'sender': {'email': exp, 'name': 'Starvolt'},
            'to': [{'email': dest}],
            'subject': sujet,
            'textContent': texte,
        })
    elif cmd == 'sms' and len(sys.argv) == 5:
        # Expéditeur : 11 caractères alphanumériques max (contrainte opérateurs).
        # Destinataire au format international sans « + » : 33612345678.
        _, _, exp, dest, texte = sys.argv
        appel('POST', '/transactionalSMS/sms', {
            'sender': exp,
            'recipient': dest.lstrip('+').replace(' ', ''),
            'content': texte,
            'type': 'transactional',
        })
    else:
        sys.exit(__doc__)

if __name__ == '__main__':
    main()
