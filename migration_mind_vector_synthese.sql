-- Mind Vector — synthèse d'un profil : toutes les réponses, tous auteurs.
--
-- L'image de synthèse compare, pour un profil, l'auto-diagnostic (le compte lui-
-- même) et les évaluations des invités. La policy de lecture de mv_reponses ne
-- montre à chacun QUE ses propres réponses ; on ouvre donc une fonction dédiée,
-- réservée au PROPRIÉTAIRE du profil et au superadmin, qui rend l'ensemble avec
-- le nom de chaque auteur. C'est le but même des invitations : le propriétaire
-- voit ce que les autres pensent de lui.

create or replace function public.mv_synthese(p_personne_id uuid)
returns table (node_id uuid, pos int, auteur_id uuid, nom text, is_self boolean)
language sql security definer set search_path = public as $$
  select r.node_id, r.pos, r.auteur_id,
         coalesce(nullif(trim(concat(pr.prenom, ' ', pr.nom)), ''), au.email, 'Anonyme') as nom,
         (mp.user_id is not null and mp.user_id = r.auteur_id) as is_self
    from public.mv_reponses r
    join public.mv_personnes mp on mp.id = r.personne_id
    left join public.profiles pr on pr.id = r.auteur_id
    left join auth.users au on au.id = r.auteur_id
   where r.personne_id = p_personne_id
     and (
       exists (select 1 from public.mv_personnes m2 where m2.id = p_personne_id and m2.user_id = auth.uid())
       or exists (select 1 from public.profiles p3 where p3.id = auth.uid() and p3.role = 'superadmin')
     );
$$;
grant execute on function public.mv_synthese(uuid) to authenticated;

comment on function public.mv_synthese(uuid) is
  'Mind Vector — toutes les réponses d''un profil (auto-diagnostic + invités), pour l''image de synthèse. Réservé au propriétaire du profil et au superadmin.';
