-- Mind Vector — révoquer un évaluateur emporte ses évaluations.
--
-- Retirer quelqu'un de la liste des invités ne supprimait que son DROIT
-- d'évaluer : ses réponses restaient en base, donc visibles dans la vue
-- hélicoptère et comptées par l'analyse. Révoquer veut dire « ton avis ne
-- compte plus » : les réponses, la précision déclarée et le portrait qu'il
-- avait tiré du profil partent avec l'invitation.
--
-- La suppression se joue en base et non à l'écran : elle doit valoir quel que
-- soit le chemin par lequel l'invitation disparaît (bouton, appel direct,
-- cascade). SECURITY DEFINER car le titulaire du profil n'a pas le droit
-- d'effacer les lignes d'un autre auteur — la policy d'écriture de mv_reponses
-- exige `auteur_id = auth.uid()`.

create or replace function public.mv_acces_purge()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  delete from public.mv_reponses
   where personne_id = old.personne_id and auteur_id = old.evaluateur_id;
  delete from public.mv_precisions
   where personne_id = old.personne_id and auteur_id = old.evaluateur_id;
  delete from public.mv_portraits
   where personne_id = old.personne_id and auteur_id = old.evaluateur_id;
  return old;
end $$;

revoke execute on function public.mv_acces_purge() from anon, public;

drop trigger if exists mv_acces_purge_trg on public.mv_acces;
create trigger mv_acces_purge_trg
  after delete on public.mv_acces
  for each row execute function public.mv_acces_purge();

-- ── Reprise de l'existant ──────────────────────────────────────────────────
-- Les invitations déjà révoquées ont laissé leurs réponses derrière elles.
-- Deux cas légitimes n'ont PAS d'invitation et doivent survivre :
--   · le titulaire du profil — c'est son auto-évaluation ;
--   · un admin ou superadmin — la policy d'écriture l'autorise nommément à
--     classer qui il veut, sans passer par une invitation. Sans cette
--     exception, la passe de nettoyage effacerait les évaluations que Greg a
--     saisies sur les profils des autres.
-- Reste donc exactement ce qu'on vise : un compte ordinaire qui a répondu et
-- qui n'est plus invité.
create temp table mv_orphelins as
select r.personne_id, r.auteur_id
  from public.mv_reponses r
  join public.mv_personnes mp on mp.id = r.personne_id
  left join public.profiles pr on pr.id = r.auteur_id
 where (mp.user_id is null or mp.user_id <> r.auteur_id)
   and coalesce(pr.role, '') not in ('admin', 'superadmin')
   and not exists (select 1 from public.mv_acces a
                    where a.personne_id = r.personne_id and a.evaluateur_id = r.auteur_id)
 group by r.personne_id, r.auteur_id;

delete from public.mv_reponses r using mv_orphelins o
 where r.personne_id = o.personne_id and r.auteur_id = o.auteur_id;
delete from public.mv_precisions p using mv_orphelins o
 where p.personne_id = o.personne_id and p.auteur_id = o.auteur_id;
delete from public.mv_portraits t using mv_orphelins o
 where t.personne_id = o.personne_id and t.auteur_id = o.auteur_id;

comment on function public.mv_acces_purge() is
  'Mind Vector — à la révocation d''une invitation, efface les réponses, la précision et le portrait de l''évaluateur sur ce profil.';
