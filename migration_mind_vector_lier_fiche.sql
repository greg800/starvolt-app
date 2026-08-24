-- Mind Vector — rattacher une fiche « ajoutée à la main » quand la personne
-- crée enfin son compte.
--
-- Une fiche manuelle a user_id NULL. Si quelqu'un s'inscrit avec la même adresse
-- e-mail, on lie la fiche à son compte (user_id) : elle sort de la zone
-- « ajoutées à la main » et devient un profil comme les autres, en gardant toutes
-- les réponses déjà saisies (mv_reponses via personne_id) et les invitations.

create or replace function public.mv_lier_fiche_manuelle()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.mv_personnes
     set user_id = new.id
   where id = (
     select id from public.mv_personnes
      where user_id is null and lower(email) = lower(new.email)
      order by created_at limit 1
   );
  return new;
end $$;

drop trigger if exists mv_lier_fiche on auth.users;
create trigger mv_lier_fiche after insert on auth.users
  for each row execute function public.mv_lier_fiche_manuelle();
