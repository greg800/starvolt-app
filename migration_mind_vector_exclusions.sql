-- Mind Vector — écarter les branches sans objet pour une personne.
--
-- Toutes les questions ne concernent pas tout le monde : inutile d'interroger
-- sur le secteur des ENR quelqu'un qui n'y travaille pas. On mémorise donc, par
-- personne, les branches à ne pas lui présenter. Une branche écartée emporte
-- toute sa descendance.

alter table public.mv_personnes
  add column if not exists exclusions jsonb not null default '[]'::jsonb;

comment on column public.mv_personnes.exclusions is
  'Ids des sujets (et donc de leurs descendants) à ne pas présenter à cette personne.';

-- Chacun doit pouvoir régler SA propre navigation : sans cette policy, seul un
-- admin pouvait modifier une fiche, et un utilisateur n'aurait jamais pu écarter
-- une branche qui ne le concerne pas.
drop policy if exists "mv_personnes fiche perso maj" on public.mv_personnes;
create policy "mv_personnes fiche perso maj" on public.mv_personnes
  for update to authenticated
  using      (user_id = auth.uid())
  with check (user_id = auth.uid());
