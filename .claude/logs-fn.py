#!/usr/bin/env python3
"""Lit le journal des edge functions Supabase (Management API, analytics).

Usage : python3 .claude/logs-fn.py [minutes] [motif]
  minutes : fenêtre de temps à remonter (défaut 30)
  motif   : sous-chaîne à filtrer dans le message (optionnel)

Même montage token/User-Agent que db-apply.py : le token est déposé par Greg,
le script se contente de le lire. User-Agent explicite obligatoire, sinon
Cloudflare rend 403 code 1010.
"""
import json
import os
import re
import sys
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone

REF = "hkxkhwegqkapdbsisxwv"
RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def lire_token():
    pistes = [
        os.path.join(RACINE, ".claude", ".supabase-pat"),
        os.path.join(RACINE, ".claude:.supabase-pat.rtf"),
    ]
    for chemin in pistes:
        if not os.path.exists(chemin):
            continue
        with open(chemin, "rb") as f:
            brut = f.read().decode("utf-8", "replace")
        # Le fichier peut être du RTF : on retire le balisage puis on prend le
        # plus long identifiant restant, qui est le token.
        texte = re.sub(r"\\[a-zA-Z]+-?\d* ?", " ", brut)
        texte = texte.replace("{", " ").replace("}", " ")
        candidats = re.findall(r"[A-Za-z0-9_\-]{20,}", texte)
        if candidats:
            return max(candidats, key=len)
    raise SystemExit("Token Supabase introuvable (.claude/.supabase-pat).")


def main():
    minutes = int(sys.argv[1]) if len(sys.argv) > 1 else 30
    motif = sys.argv[2] if len(sys.argv) > 2 else None

    fin = datetime.now(timezone.utc)
    debut = fin - timedelta(minutes=minutes)
    sql = (
        "select id, timestamp, event_message, "
        "metadata.function_id as fid, metadata.level as niveau "
        "from function_logs cross join unnest(metadata) as metadata "
        "order by timestamp desc limit 200"
    )
    params = urllib.parse.urlencode({
        "sql": sql,
        "iso_timestamp_start": debut.isoformat().replace("+00:00", "Z"),
        "iso_timestamp_end": fin.isoformat().replace("+00:00", "Z"),
    })
    url = f"https://api.supabase.com/v1/projects/{REF}/analytics/endpoints/logs.all?{params}"
    req = urllib.request.Request(url, headers={
        "Authorization": "Bearer " + lire_token(),
        "User-Agent": "curl/8.4.0",
        "Accept": "application/json",
    })
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            corps = json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print("ERREUR", e.code, e.read().decode("utf-8", "replace")[:600])
        return

    lignes = corps.get("result", corps if isinstance(corps, list) else [])
    if not lignes:
        print(f"Aucune ligne de journal sur les {minutes} dernières minutes.")
        return
    for l in reversed(lignes):
        msg = str(l.get("event_message", "")).strip()
        if motif and motif.lower() not in msg.lower():
            continue
        ts = l.get("timestamp")
        if isinstance(ts, (int, float)):
            ts = datetime.fromtimestamp(ts / 1_000_000, timezone.utc).strftime("%H:%M:%S")
        print(f"{ts} [{l.get('niveau') or '-'}] {msg[:400]}")


if __name__ == "__main__":
    main()
