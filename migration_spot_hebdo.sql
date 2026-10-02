-- Prix spot : synthèse hebdomadaire (vue historique une ligne par semaine)
-- Semaine ISO : la semaine 1 est celle qui contient le 4 janvier, et appartient
-- à l'année ISO (les derniers jours de décembre peuvent tomber en S1 de l'année
-- suivante, les premiers de janvier en S52/S53 de la précédente). n = heures connues.
create or replace function public.get_spot_hebdo()
returns json
language sql stable security definer set search_path to 'public'
as $$
  select json_agg(row_to_json(t))
  from (
    select extract(isoyear from tl)::int as annee,
           extract(week    from tl)::int as semaine,
           round(avg(prix), 6)           as prix,
           count(*)::int                 as n
    from (select ts_utc at time zone 'Europe/Paris' as tl, prix from prix_spot_historique) s
    group by 1, 2
    order by 1, 2
  ) t;
$$;
grant  execute on function public.get_spot_hebdo() to authenticated;
revoke execute on function public.get_spot_hebdo() from anon, public;
