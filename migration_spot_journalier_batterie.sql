-- Prix spot : indicateurs journaliers (prix moyen, spread, gains batterie)
--
-- La vue historique agrège désormais côté client une seule série journalière
-- (get_spot_journalier : ≈ 4 300 lignes) en mois, semaines ISO ou jours, pour
-- l'indicateur choisi. Les RPC mensuelle et hebdomadaire deviennent inutiles.
--
-- Gains batterie : l'optimisation (programme de charge/décharge horaire qui
-- maximise la recette d'arbitrage sur les prix HT du jour) est calculée dans
-- le navigateur de l'admin quand les paramètres changent ou qu'un import ajoute
-- des jours, puis stockée ici — le reste du temps on lit la base.

-- ── 1. Paramètres de la batterie (une seule ligne) ──────────────────────────
create table if not exists public.spot_batterie_params (
  id            integer primary key default 1 check (id = 1),
  capacite_kwh  numeric not null,
  puissance_kw  numeric not null,          -- charge et décharge, côté réseau
  cycles_jour   numeric not null,          -- énergie déchargée max / jour = cycles × capacité
  rendement_ar  numeric not null,          -- aller-retour, 0,81 = 81 %
  calcule_le    timestamptz
);
alter table public.spot_batterie_params enable row level security;
drop policy if exists admin_all on public.spot_batterie_params;
create policy admin_all on public.spot_batterie_params
  for all to authenticated using ((select is_admin())) with check ((select is_admin()));

-- ── 2. Résultat par jour ─────────────────────────────────────────────────────
-- plan = { "p": [24 prix €/kWh], "e": [24 kWh côté réseau, + achat / − vente] }
create table if not exists public.spot_batterie_jours (
  jour  date primary key,
  gain  numeric not null,                  -- € HT, recettes de vente − coût d'achat
  plan  jsonb not null
);
alter table public.spot_batterie_jours enable row level security;
drop policy if exists admin_all on public.spot_batterie_jours;
create policy admin_all on public.spot_batterie_jours
  for all to authenticated using ((select is_admin())) with check ((select is_admin()));

-- ── 3. Série journalière ─────────────────────────────────────────────────────
-- d = jour local, p = prix moyen €/kWh, s = spread (max − min) €/kWh,
-- n = heures connues, g = gain batterie € (null tant que non calculé).
create or replace function public.get_spot_journalier()
returns json
language sql stable security definer set search_path to 'public'
as $$
  select json_agg(json_build_object('d', d, 'p', p, 's', s, 'n', n, 'g', g))
  from (
    select hj.d,
           round(avg(hj.prix), 6)                as p,
           round(max(hj.prix) - min(hj.prix), 6) as s,
           count(*)::int                         as n,
           b.gain                                as g
    from (
      select (ts_utc at time zone 'Europe/Paris')::date                 as d,
             extract(hour from ts_utc at time zone 'Europe/Paris')::int as h,
             avg(prix)                                                  as prix
      from prix_spot_historique
      group by 1, 2
    ) hj
    left join spot_batterie_jours b on b.jour = hj.d
    group by hj.d, b.gain
    order by hj.d
  ) t;
$$;

-- ── 4. Les 24 prix de chaque jour, pour l'optimiseur ────────────────────────
-- [{ d, p:[24] }] ; une heure locale absente (mars) vaut null.
create or replace function public.get_spot_jours_horaires()
returns json
language sql stable security definer set search_path to 'public'
as $$
  select json_agg(json_build_object('d', d, 'p', p) order by d)
  from (
    select hj.d, array_agg(hj.prix order by g.h) as p
    from (select distinct (ts_utc at time zone 'Europe/Paris')::date as d from prix_spot_historique) j
    cross join generate_series(0, 23) as g(h)
    left join (
      select (ts_utc at time zone 'Europe/Paris')::date                 as d,
             extract(hour from ts_utc at time zone 'Europe/Paris')::int as h,
             round(avg(prix), 6)                                        as prix
      from prix_spot_historique
      group by 1, 2
    ) hj on hj.d = j.d and hj.h = g.h
    group by hj.d
    having hj.d is not null
  ) t;
$$;

-- ── 5. Ménage et convention audit ───────────────────────────────────────────
drop function if exists public.get_spot_mensuel();
drop function if exists public.get_spot_hebdo();
grant  execute on function public.get_spot_journalier()     to authenticated;
grant  execute on function public.get_spot_jours_horaires() to authenticated;
revoke execute on function public.get_spot_journalier()     from anon, public;
revoke execute on function public.get_spot_jours_horaires() from anon, public;
