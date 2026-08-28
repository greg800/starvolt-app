-- Mind Vector — la synthèse s'ouvre aux profils publics.
--
-- `mv_synthese` était réservée au propriétaire du profil et au superadmin :
-- l'image de synthèse servait à voir ce que ses invités pensent de soi, et
-- montrer ça à un tiers aurait trahi l'intention. Un profil PUBLIC n'a rien de
-- tout ça — une personne morale n'a pas de `user_id`, donc personne ne la
-- possède, donc seul un superadmin en voyait les positions. Les 36 positions du
-- Rassemblement national étaient invisibles à tout le monde d'autre, alors que
-- la RLS de `mv_reponses` les laisse déjà lire (elle s'ouvre sur `est_public`).
--
-- La documentation d'une organisation publique n'est pas un jugement porté sur
-- quelqu'un : c'est le matériau qui permet à chacun de situer ses propres
-- positions. La garde reste entière pour les profils privés.

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
       -- profil public : lisible par tout compte connecté
       exists (select 1 from public.mv_personnes m1 where m1.id = p_personne_id and m1.est_public)
       -- ou son titulaire
       or exists (select 1 from public.mv_personnes m2 where m2.id = p_personne_id and m2.user_id = auth.uid())
       -- ou un superadmin
       or exists (select 1 from public.profiles p3 where p3.id = auth.uid() and p3.role = 'superadmin')
     );
$$;
grant execute on function public.mv_synthese(uuid) to authenticated;

comment on function public.mv_synthese(uuid) is
  'Mind Vector — toutes les réponses d''un profil (auto-diagnostic + invités), pour l''image de synthèse. Profils publics : ouverts à tout compte connecté. Profils privés : titulaire et superadmin seulement.';
