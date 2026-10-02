-- Prix spot : heures locales d'une fenêtre quelconque de l'historique
-- Sert les panneaux de comparaison de la heatmap (même fenêtre de 12 mois,
-- décalée d'une ou plusieurs années). Clés courtes pour alléger le JSON
-- (≈ 8 800 lignes par fenêtre) : m = mois, j = jour, h = heure, p = prix €/kWh.
-- Heure légale France ; l'heure doublée d'octobre est moyennée. Fenêtre bornée
-- à 370 jours : au-delà, la requête renvoie null plutôt que des mégaoctets.
create or replace function public.get_spot_horaire_periode(p_debut date, p_fin date)
returns json
language sql stable security definer set search_path to 'public'
as $$
  select case when p_fin - p_debut > 370 then null else (
    select json_agg(json_build_object('m', m, 'j', j, 'h', h, 'p', p))
    from (
      select extract(month from tl)::int as m,
             extract(day   from tl)::int as j,
             extract(hour  from tl)::int as h,
             round(avg(prix), 6)         as p
      from (select ts_utc at time zone 'Europe/Paris' as tl, prix from prix_spot_historique) s
      where tl::date between p_debut and p_fin
      group by 1, 2, 3
      order by 1, 2, 3
    ) t) end;
$$;
grant  execute on function public.get_spot_horaire_periode(date, date) to authenticated;
revoke execute on function public.get_spot_horaire_periode(date, date) from anon, public;
