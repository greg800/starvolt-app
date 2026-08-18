-- Mind Vector — mémoriser le portrait, et ce que l'intéressé en dit.
--
-- Une ligne par couple (personne évaluée, auteur du classement) : Greg peut
-- dresser le portrait de Marie à partir de SES classements à lui, et Marie le
-- sien à partir des siens — ce sont deux portraits différents.
--
-- `signature` mémorise l'état qui a produit le texte : les réponses, le prompt
-- et le commentaire. Tant qu'elle ne bouge pas, on ressert le portrait stocké
-- au lieu de repayer un appel à l'IA.

create table if not exists public.mv_portraits (
  personne_id uuid not null references public.mv_personnes(id) on delete cascade,
  auteur_id   uuid not null references auth.users(id)          on delete cascade,
  texte       text not null,
  signature   text not null,
  commentaire text,
  updated_at  timestamptz not null default now(),
  primary key (personne_id, auteur_id)
);

alter table public.mv_portraits enable row level security;

-- Un portrait n'appartient qu'à celui qui l'a demandé.
drop policy if exists "mv_portraits lecture" on public.mv_portraits;
create policy "mv_portraits lecture" on public.mv_portraits
  for select to authenticated using (auteur_id = auth.uid());

drop policy if exists "mv_portraits ecriture" on public.mv_portraits;
create policy "mv_portraits ecriture" on public.mv_portraits
  for all to authenticated
  using      (auteur_id = auth.uid())
  with check (auteur_id = auth.uid());

comment on table public.mv_portraits is
  'Mind Vector — portrait rédigé par l''IA à partir des positions retenues, et commentaire de l''intéressé. Une ligne par (personne évaluée, auteur).';
comment on column public.mv_portraits.signature is
  'État ayant produit le texte (réponses + prompt + commentaire). Inchangée = on ressert le texte stocké.';
