-- Prix spot : historique horaire complet + 12 mois glissants dérivés
--
-- Jusqu'ici prix_spot (8 784 lignes clés sur mois/jour/heure) était importé
-- directement depuis un xlsx « année type ». On garde cette table — tout le
-- chiffrage de l'app la lit via get_spot_json() — mais elle devient une vue
-- matérialisée à la main de prix_spot_historique : pour chaque (mois, jour),
-- le jour exploitable le plus récent de l'historique, soit les 365 derniers
-- jours connus glissants (le 29 février vient de la dernière année bissextile).
--
-- Unité : €/kWh partout, comme avant (le CSV source est en €/MWh, converti à
-- l'import). Heure légale France (Europe/Paris) pour mois/jour/heure : aux
-- changements d'heure, l'heure doublée d'octobre est moyennée et l'heure
-- absente de mars reprend l'heure voisine.

-- ── 1. Historique horaire ───────────────────────────────────────────────────
create table if not exists public.prix_spot_historique (
  ts_utc timestamptz primary key,
  prix   numeric not null              -- €/kWh
);
alter table public.prix_spot_historique enable row level security;

drop policy if exists admin_all on public.prix_spot_historique;
create policy admin_all on public.prix_spot_historique
  for all to authenticated
  using ((select is_admin())) with check ((select is_admin()));

-- ── 2. Colonnes dérivées ────────────────────────────────────────────────────
alter table public.prix_spot add column if not exists annee integer;

alter table public.spot_metadata
  add column if not exists periode_debut date,   -- historique : premier jour connu
  add column if not exists periode_fin   date,   -- historique : dernier jour connu
  add column if not exists fenetre_debut date,   -- 12 mois glissants : du …
  add column if not exists fenetre_fin   date;   -- … au

-- ── 3. get_spot_json : expose l'année source de chaque jour ────────────────
create or replace function public.get_spot_json()
returns json
language sql stable security definer set search_path to 'public'
as $$
  select json_agg(row_to_json(t))
  from (select mois, jour, heure, prix, annee from prix_spot order by mois, jour, heure) t;
$$;

-- ── 4. Synthèse mensuelle (vue historique) ─────────────────────────────────
-- n = nombre d'heures connues dans le mois : permet de signaler un mois partiel.
create or replace function public.get_spot_mensuel()
returns json
language sql stable security definer set search_path to 'public'
as $$
  select json_agg(row_to_json(t))
  from (
    select extract(year  from tl)::int as annee,
           extract(month from tl)::int as mois,
           round(avg(prix), 6)         as prix,
           count(*)::int               as n
    from (select ts_utc at time zone 'Europe/Paris' as tl, prix from prix_spot_historique) s
    group by 1, 2
    order by 1, 2
  ) t;
$$;

-- ── 5. Reconstruction des 12 mois glissants ────────────────────────────────
-- Appelée par l'écran admin après chaque import. Sans JWT (appel serveur via
-- l'API Management) la garde est levée : c'est le chemin de la migration.
create or replace function public.rebuild_prix_spot_glissant()
returns json
language plpgsql security definer set search_path to 'public'
as $$
declare
  n_hist int; n_spot int;
  p_deb date; p_fin date; f_deb date; f_fin date;
begin
  if current_setting('request.jwt.claims', true) is not null and not is_admin() then
    raise exception 'Réservé aux administrateurs';
  end if;

  delete from prix_spot where mois between 1 and 12;

  insert into prix_spot (mois, jour, heure, prix, annee)
  with hj as (                       -- une ligne par (jour local, heure locale)
    select (ts_utc at time zone 'Europe/Paris')::date                    as d,
           extract(hour from ts_utc at time zone 'Europe/Paris')::int    as heure,
           avg(prix)                                                     as prix
    from prix_spot_historique
    group by 1, 2
  ), jours as (                      -- jours exploitables : au moins 22 heures connues
    select d from hj group by d having count(*) >= 22
  ), choix as (                      -- pour chaque (mois, jour), le plus récent
    select distinct on (extract(month from d), extract(day from d)) d
    from jours
    order by extract(month from d), extract(day from d), d desc
  ), grille as (
    select c.d, g.h as heure from choix c cross join generate_series(0, 23) as g(h)
  )
  select extract(month from g.d)::int,
         extract(day   from g.d)::int,
         g.heure,
         round(coalesce(hj.prix,
                        (select p.prix from hj p
                          where p.d = g.d and p.heure <> g.heure
                          order by abs(p.heure - g.heure) limit 1)), 6),
         extract(year from g.d)::int
  from grille g
  left join hj on hj.d = g.d and hj.heure = g.heure;

  select count(*) into n_spot from prix_spot;
  select count(*),
         min((ts_utc at time zone 'Europe/Paris')::date),
         max((ts_utc at time zone 'Europe/Paris')::date)
    into n_hist, p_deb, p_fin from prix_spot_historique;
  select min(make_date(annee, mois, jour)), max(make_date(annee, mois, jour))
    into f_deb, f_fin from prix_spot where annee is not null and not (mois = 2 and jour = 29);

  insert into spot_metadata (id) values (1) on conflict (id) do nothing;
  update spot_metadata
     set last_update = now(), rows_count = n_hist,
         periode_debut = p_deb, periode_fin = p_fin,
         fenetre_debut = f_deb, fenetre_fin = f_fin
   where id = 1;

  return json_build_object('historique', n_hist, 'prix_spot', n_spot,
                           'periode_debut', p_deb, 'periode_fin', p_fin,
                           'fenetre_debut', f_deb, 'fenetre_fin', f_fin);
end;
$$;

-- ── 6. Convention audit : SECURITY DEFINER fermées à anon ──────────────────
grant  execute on function public.get_spot_mensuel()            to authenticated;
grant  execute on function public.rebuild_prix_spot_glissant()  to authenticated;
revoke execute on function public.get_spot_mensuel()            from anon, public;
revoke execute on function public.rebuild_prix_spot_glissant()  from anon, public;
revoke execute on function public.get_spot_json()               from anon, public;
grant  execute on function public.get_spot_json()               to authenticated;
