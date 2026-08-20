-- Mind Vector — supprimer un compte efface aussi son profil et ce qui s'y rattache.
--
-- La fiche mv_personnes d'un compte était en ON DELETE SET NULL : supprimer le
-- compte laissait la fiche orpheline, donc les invitations à évaluer ce profil
-- (mv_acces.personne_id) et les classements le concernant (mv_reponses) restaient
-- en base. On passe en CASCADE : supprimer le compte supprime sa fiche, ce qui
-- emporte ses invitations et les réponses qui la visent — conforme à « supprimer
-- ce compte et toutes les données associées ».

alter table public.mv_personnes drop constraint if exists mv_personnes_user_id_fkey;
alter table public.mv_personnes
  add constraint mv_personnes_user_id_fkey
  foreign key (user_id) references auth.users(id) on delete cascade;
