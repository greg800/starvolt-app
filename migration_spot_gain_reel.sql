-- Gain batterie réel : arbitrage optimisé avec TURPE (soutirage / injection)
-- et taxes, à côté du gain spot pur. plan_reel garde aussi les prix d'achat
-- (pa) et de vente (pv) horaires utilisés.
begin;
alter table public.spot_batterie_jours add column if not exists gain_reel numeric;
alter table public.spot_batterie_jours add column if not exists plan_reel jsonb;
alter table public.spot_batterie_params add column if not exists domaine text;

create or replace function public.get_spot_journalier()
returns json language sql stable security definer set search_path to 'public' as $function$
  select json_agg(json_build_object('d', d, 'p', p, 's', s, 'n', n, 'z', z, 'g', g, 'gr', gr))
  from (
    select hj.d,
           round(avg(hj.prix), 6)                as p,
           round(max(hj.prix) - min(hj.prix), 6) as s,
           count(*)::int                         as n,
           count(*) filter (where hj.prix < 0)::int as z,
           b.gain                                as g,
           b.gain_reel                           as gr
    from (
      select (ts_utc at time zone 'Europe/Paris')::date                 as d,
             extract(hour from ts_utc at time zone 'Europe/Paris')::int as h,
             avg(prix)                                                  as prix
      from prix_spot_historique
      group by 1, 2
    ) hj
    left join spot_batterie_jours b on b.jour = hj.d
    group by hj.d, b.gain, b.gain_reel
    order by hj.d
  ) t;
$function$;
commit;
