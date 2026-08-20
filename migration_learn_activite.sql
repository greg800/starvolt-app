-- Module Comprendre : un sujet peut « remonter » son résultat dans le
-- Tableau de bord — activité (admin). Colonne + RPC de lecture agrégée.

-- 1) Marqueur sur le sujet
alter table public.learn_subjects
  add column if not exists remonter_activite boolean not null default false;

-- 2) Résultats par personne pour les sujets marqués « à remonter ».
--    correct = nb de questions du sujet − nb de questions encore ratées
--    (failed_question_ids reflète l'état courant, révisions comprises).
create or replace function public.get_learn_activite()
returns table(user_id uuid, subject_id uuid, correct int, total int)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden';
  end if;
  return query
  select p.user_id,
         p.subject_id,
         greatest(0, t.total - coalesce(array_length(p.failed_question_ids, 1), 0))::int as correct,
         t.total::int as total
  from public.user_learn_progress p
  join public.learn_subjects s
    on s.id = p.subject_id and s.remonter_activite = true
  cross join lateral (
    select count(*)::int as total
    from public.learn_questions q
    where q.subject_id = p.subject_id
  ) t;
end;
$$;

grant execute on function public.get_learn_activite() to authenticated;
