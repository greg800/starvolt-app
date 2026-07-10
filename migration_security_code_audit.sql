-- ═══════════════════════════════════════════════════════════════════════════
-- Cyber-sécurité — volet AUDIT CODE (hors base), piloté par Claude Code
-- Ajoute : colonne agent (qui + version de Claude), trigger_type 'code',
--          prompt copiable éditable (feature 'cyber_security_code').
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. Colonne « agent » : qui a fait la vérification + version de Claude.
--    (cron/manuel base : reste vide ; audit code : « Claude Code · claude-opus-4-x »)
alter table public.security_checks add column if not exists agent text;

-- 2. Autoriser trigger_type 'code' (audit du dépôt réalisé par Claude Code).
alter table public.security_checks drop constraint if exists security_checks_trigger_type_check;
alter table public.security_checks add constraint security_checks_trigger_type_check
  check (trigger_type in ('cron','manual','code'));

-- 3. Prompt copiable à coller dans Claude Code (éditable via set_ai_prompt).
--    Contient la procédure exacte + l'instruction d'enregistrer le résultat en base.
insert into public.ai_prompts (feature, label, system_prompt)
values (
  'cyber_security_code',
  'Cyber-sécurité — audit code (Claude Code)',
  E'Audit de cybersécurité Starvolt — VOLET CODE (hors base de données).\n\nContexte : l''audit de la BASE est déjà automatisé (cron mensuel + edge function security-check, page admin Cyber-sécurité). Toi (Claude Code) tu fais le volet que ce cron ne peut PAS voir, car il n''a pas accès au dépôt git : le CODE.\n\nProcédure à suivre :\n1. Lis le prompt de référence en base : table ai_prompts, feature=''cyber_security'' — familles 5 à 10 = les vérifications manuelles attendues.\n2. Audite le dépôt sur ces points :\n   - Secrets en dur dans le code versionné (service_role, PAT, clés API, tokens).\n   - server.js : path traversal, en-têtes de sécurité, méthodes autorisées.\n   - Client (starvolt.html) : dangerouslySetInnerHTML / innerHTML / eval → risque XSS.\n   - Edge functions Deno (supabase/functions/*) : chaque fonction vérifie le JWT ET le rôle avant toute action sensible ; pas de secret exposé.\n   - Buckets Storage : privés si données personnelles ; URLs signées à durée limitée.\n   - Dépendances CDN : versions épinglées.\n3. Corrige ce qui peut l''être. Si tu touches au frontend ou aux fonctions, pousse via GitHub (déploiement habituel).\n4. ENREGISTRE le résultat dans Starvolt en insérant UNE ligne dans public.security_checks (via l''endpoint SQL Supabase avec le PAT, comme une migration) avec :\n   - trigger_type = ''code''\n   - status = ''done''\n   - severity = ''ok'' | ''info'' | ''warn'' | ''critical'' (le pire constat)\n   - found = ce qui a été trouvé (du plus grave au moins grave, ou « Rien d''anormal côté code. »)\n   - fixed = ce qui a été corrigé (et poussé), sinon « Aucune correction. »\n   - watch_next = à surveiller au prochain passage\n   - report_md = rapport lisible (markdown léger : ### titres, - listes, **gras**)\n   - triggered_by = ''Grégory (Claude Code)''\n   - agent = ''Claude Code · '' suivi de TON identifiant de modèle EXACT (ex. claude-opus-4-8)\n5. Résume-moi en clair ce que tu as trouvé, corrigé, et ce qui reste à surveiller.\n\nLe rapport apparaîtra automatiquement dans l''historique de la page Cyber-sécurité et en popup à chaque admin/superadmin à sa prochaine connexion.'
)
on conflict (feature) do nothing;
