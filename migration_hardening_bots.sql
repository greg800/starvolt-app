-- ════════════════════════════════════════════════════════════════════════════
-- Durcissement anti-bot (audit du 2026-08-07)
--
-- 1. Module « Comprendre » : l'écriture était ouverte à TOUT compte connecté
--    (policy FOR ALL USING auth.role()='authenticated'). Comme l'inscription
--    n'a ni captcha ni confirmation d'email, un robot pouvait créer un compte
--    et supprimer les 17 sujets / 101 questions. → écriture réservée aux admins.
--
-- 2. RPC SECURITY DEFINER sans garde interne, accordées à `anon` : lisibles
--    avec la seule clé anon publique (présente dans le source de la page).
--    → garde is_admin() + retrait du GRANT anon.
--
-- NON TOUCHÉ volontairement :
--    - `public read learn_*` (lecture publique du contenu pédagogique : voulu) ;
--    - `get_roles` : appelée par CHAQUE utilisateur au login pour charger ses
--      permissions → reste ouverte aux `authenticated`, on retire juste `anon` ;
--    - `get_default_role` : appelée pendant l'inscription et ne renvoie qu'une
--      clé de rôle → laissée accessible, pour ne pas casser le signup si la
--      confirmation d'email est réactivée (plus de session à cet instant).
-- ════════════════════════════════════════════════════════════════════════════

begin;

-- ─── 1) Module « Comprendre » : écriture admin uniquement ───────────────────
-- La lecture reste couverte par les policies « public read learn_* » (USING true).

drop policy if exists "auth write learn_groups"    on public.learn_groups;
drop policy if exists "auth write learn_subjects"  on public.learn_subjects;
drop policy if exists "auth write learn_questions" on public.learn_questions;
drop policy if exists "auth write learn_choices"   on public.learn_choices;

create policy "admin write learn_groups" on public.learn_groups
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "admin write learn_subjects" on public.learn_subjects
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "admin write learn_questions" on public.learn_questions
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "admin write learn_choices" on public.learn_choices
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ─── 2) Gardes sur les RPC admin ────────────────────────────────────────────
-- Passage de LANGUAGE sql à plpgsql pour pouvoir lever l'exception.
-- Signatures (noms + types des colonnes de sortie) STRICTEMENT identiques :
-- le client lit ces champs par nom.
-- `#variable_conflict use_column` : les paramètres de sortie (email, nom,
-- prenom…) portent le nom de colonnes de la requête — on tranche en faveur
-- de la colonne.

create or replace function public.get_factures_a_valider()
returns table(extraction_id uuid, created_at timestamptz, prenom text, nom text,
              email text, fournisseur text, offre_nom text, type_tarif text,
              puissance_kva smallint, abo_mensuel numeric, prix_base numeric,
              prix_hp numeric, prix_hc numeric, conso_totale_kwh numeric,
              confiance jsonb, cle_offre text, tarif_id uuid, storage_key text,
              retention_until timestamptz, nb_concordantes bigint)
language plpgsql
security definer
set search_path to 'public'
as $function$
#variable_conflict use_column
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  return query
    -- u.email est varchar(255) : le cast explicite est OBLIGATOIRE ici. En
    -- LANGUAGE sql (version d'origine) le cast implicite vers text passait ;
    -- RETURN QUERY en plpgsql est strict et lève 42804 sans lui.
    select e.id, e.created_at,
           p.prenom, p.nom, u.email::text,
           e.fournisseur, e.offre_nom, e.type_tarif, e.puissance_kva,
           e.abo_mensuel, e.prix_base, e.prix_hp, e.prix_hc,
           e.conso_totale_kwh, e.confiance, e.cle_offre,
           e.tarif_id, f.storage_key, f.retention_until,
           (select count(*) from public.factures_extractions e2
             where e2.cle_offre = e.cle_offre and e2.statut = 'brouillon') as nb_concordantes
    from public.factures_extractions e
    join public.factures f on f.id = e.facture_id
    left join public.profiles p on p.id = e.user_id
    left join auth.users u on u.id = e.user_id
    where e.statut = 'brouillon'
    order by e.created_at;
end;
$function$;

create or replace function public.get_prompt_files()
returns setof public.ai_prompt_files
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  return query select * from public.ai_prompt_files order by feature, created_at;
end;
$function$;

-- ─── 3) Retrait des GRANT `anon` superflus ──────────────────────────────────
-- Ces trois RPC n'ont aucun sens sans session ouverte.

revoke execute on function public.get_factures_a_valider() from anon;
revoke execute on function public.get_prompt_files()       from anon;
revoke execute on function public.get_roles()              from anon;

commit;
