-- Fix popup sécurité au login : n'afficher QUE le dernier audit, une seule fois.
--
-- Ancien comportement : la fonction renvoyait TOUS les checks non vus, un par un
-- (le plus récent d'abord). Un backlog d'anciens audits jamais marqués vus faisait
-- réapparaître un popup à chaque connexion (« 10 fois j'ai compris »).
--
-- Nouveau comportement : on ne regarde QUE le check le plus récent. On le renvoie
-- seulement s'il n'a pas encore été vu par l'admin courant. Une fois vu → plus rien,
-- jusqu'à ce qu'un NOUVEL audit (plus récent) soit lancé.
create or replace function public.get_unseen_security_check()
returns public.security_checks
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.security_checks;
begin
  if not exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','superadmin')) then
    return null;
  end if;
  -- Dernier audit terminé, tous types confondus.
  select * into r from public.security_checks
  where status = 'done'
  order by created_at desc limit 1;
  -- Ne le montrer que s'il n'a pas déjà été vu par cet admin.
  if r.id is null or (r.seen_by ? auth.uid()::text) then
    return null;
  end if;
  return r;
end;
$$;

grant execute on function public.get_unseen_security_check() to authenticated;
