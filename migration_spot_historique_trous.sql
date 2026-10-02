-- Prix spot : combler les trous de l'historique par interpolation linéaire
--
-- Le CSV source (Ember) a deux trous en 2026 : les 1er août et 1er octobre
-- n'ont pas leurs 0 h et 1 h locales. Plutôt que de recopier l'heure voisine
-- au moment de reconstruire les 12 mois glissants, on complète l'historique
-- lui-même : chaque heure absente entre la première et la dernière heure connue
-- reçoit la valeur interpolée linéairement entre l'heure connue qui précède et
-- celle qui suit. Les lignes ainsi créées sont marquées interpole = true ; un
-- import ultérieur de la vraie valeur les écrase (upsert avec interpole = false).

alter table public.prix_spot_historique
  add column if not exists interpole boolean not null default false;

create or replace function public.combler_trous_spot_historique()
returns integer
language plpgsql security definer set search_path to 'public'
as $$
declare n int;
begin
  insert into prix_spot_historique (ts_utc, prix, interpole)
  with bornes as (
    select min(ts_utc) as a, max(ts_utc) as b from prix_spot_historique
  ), grille as (
    select generate_series(a, b, interval '1 hour') as ts from bornes
  ), manquantes as (
    select g.ts from grille g
    left join prix_spot_historique h on h.ts_utc = g.ts
    where h.ts_utc is null
  ), voisins as (
    select m.ts,
      (select ts_utc from prix_spot_historique where ts_utc < m.ts and not interpole order by ts_utc desc limit 1) as tp,
      (select prix   from prix_spot_historique where ts_utc < m.ts and not interpole order by ts_utc desc limit 1) as pp,
      (select ts_utc from prix_spot_historique where ts_utc > m.ts and not interpole order by ts_utc asc  limit 1) as tn,
      (select prix   from prix_spot_historique where ts_utc > m.ts and not interpole order by ts_utc asc  limit 1) as pn
    from manquantes m
  )
  select ts,
         round(pp + (pn - pp) * extract(epoch from (ts - tp)) / extract(epoch from (tn - tp)), 6),
         true
  from voisins
  where tp is not null and tn is not null
  on conflict (ts_utc) do nothing;
  get diagnostics n = row_count;
  return n;
end;
$$;

-- Le rebuild comble d'abord les trous. L'heure légale absente de mars (2 h
-- n'existe pas) reprend la moyenne de ses voisines 1 h et 3 h.
create or replace function public.rebuild_prix_spot_glissant()
returns json
language plpgsql security definer set search_path to 'public'
as $$
declare
  n_hist int; n_spot int; n_interp int; n_combles int;
  p_deb date; p_fin date; f_deb date; f_fin date;
begin
  if current_setting('request.jwt.claims', true) is not null and not is_admin() then
    raise exception 'Réservé aux administrateurs';
  end if;

  n_combles := combler_trous_spot_historique();

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
                        (select avg(p.prix) from hj p
                          where p.d = g.d and p.heure in (g.heure - 1, g.heure + 1)),
                        (select p.prix from hj p
                          where p.d = g.d and p.heure <> g.heure
                          order by abs(p.heure - g.heure) limit 1)), 6),
         extract(year from g.d)::int
  from grille g
  left join hj on hj.d = g.d and hj.heure = g.heure;

  select count(*) into n_spot from prix_spot;
  select count(*), count(*) filter (where interpole),
         min((ts_utc at time zone 'Europe/Paris')::date),
         max((ts_utc at time zone 'Europe/Paris')::date)
    into n_hist, n_interp, p_deb, p_fin from prix_spot_historique;
  select min(make_date(annee, mois, jour)), max(make_date(annee, mois, jour))
    into f_deb, f_fin from prix_spot where annee is not null and not (mois = 2 and jour = 29);

  insert into spot_metadata (id) values (1) on conflict (id) do nothing;
  update spot_metadata
     set last_update = now(), rows_count = n_hist,
         periode_debut = p_deb, periode_fin = p_fin,
         fenetre_debut = f_deb, fenetre_fin = f_fin
   where id = 1;

  return json_build_object('historique', n_hist, 'interpolees', n_interp, 'comblees', n_combles,
                           'prix_spot', n_spot,
                           'periode_debut', p_deb, 'periode_fin', p_fin,
                           'fenetre_debut', f_deb, 'fenetre_fin', f_fin);
end;
$$;

grant  execute on function public.combler_trous_spot_historique() to authenticated;
revoke execute on function public.combler_trous_spot_historique() from anon, public;
