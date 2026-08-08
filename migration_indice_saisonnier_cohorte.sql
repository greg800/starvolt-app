-- Indice saisonnier de COHORTE pour l'extrapolation des mois manquants.
--
-- Quand un contrat ENEDIS a moins d'un an, completeYear (edge switchgrid-v0)
-- reconstruit les mois jamais mesurés à partir d'un indice saisonnier de
-- référence. L'indice générique codé en dur convient mal à certains foyers :
-- un logement chauffé au gaz a une courbe bien plus PLATE (électricité = base),
-- et l'indice générique surestimait son hiver de +34 % sur nos essais.
--
-- Cette fonction dérive l'indice des sites RÉELS ayant le même type de chauffage
-- et une année complète mesurée. Chaque site est normalisé par sa propre moyenne
-- annuelle avant d'être moyenné : un gros consommateur ne domine pas la courbe.
--
-- Ne renvoie qu'un agrégat (12 nombres + effectif) : aucune donnée individuelle
-- ne sort. Réservée au service_role (appelée par l'edge function).

create or replace function public.get_season_index(p_chauffage text)
returns table(mois int, indice numeric, nb_sites int)
language sql
stable
security definer
set search_path to 'public'
as $$
  with base as (
    select s.id, s.conso_profil
    from sites s
    where s.conso_profil is not null
      and s.conso_source = 'loadcurve'
      and s.conso_coverage >= 0.95            -- mesure réelle, pas d'extrapolation
      and jsonb_array_length(s.conso_profil) = 8784
      and s.flex_chauffage is not distinct from p_chauffage
  ),
  jours as (
    select b.id,
           extract(month from (date '2024-01-01' + d))::int as mois,
           (select sum((b.conso_profil->>(d * 24 + h))::numeric)
              from generate_series(0, 23) h) as wh
    from base b, generate_series(0, 365) d
  ),
  par_mois as (
    select id, mois, avg(wh) as moy_jour, count(*)::numeric as nb_jours
    from jours group by 1, 2
  ),
  annuel as (
    select id, sum(moy_jour * nb_jours) / 366 as moy_an from par_mois group by 1
  ),
  norm as (
    select p.id, p.mois, p.moy_jour / nullif(a.moy_an, 0) as idx
    from par_mois p join annuel a using (id)
  )
  select n.mois, round(avg(n.idx), 4) as indice, count(distinct n.id)::int as nb_sites
  from norm n group by n.mois order by n.mois;
$$;

revoke all on function public.get_season_index(text) from public;
revoke all on function public.get_season_index(text) from anon;
revoke all on function public.get_season_index(text) from authenticated;
-- Explicite : seule l'edge function (service_role) appelle cette RPC.
grant execute on function public.get_season_index(text) to service_role;
