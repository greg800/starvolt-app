-- Tarif par défaut : la grille de repli quand on ne sait pas quel tarif
-- applique un utilisateur (offre inconnue, facture illisible, tarif archivé).
-- Sans elle, ces sites restaient sans tarif et leurs économies étaient
-- calculées sur une constante codée en dur.

alter table public.tarifs_electricite
  add column if not exists par_defaut boolean not null default false;

-- Un seul tarif par défaut, garanti par la base : deux valeurs true seraient
-- silencieusement départagées par l'ordre de lecture, donc imprévisibles.
create unique index if not exists tarifs_un_seul_defaut
  on public.tarifs_electricite (par_defaut) where par_defaut;

-- Bascule atomique : on retire l'ancien AVANT de poser le nouveau, sinon
-- l'index unique rejette l'écriture. En deux requêtes côté client, une coupure
-- entre les deux laisserait la base sans aucun tarif par défaut.
create or replace function public.set_tarif_defaut(p_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.profiles
                  where id = auth.uid() and role in ('admin','superadmin')) then
    raise exception 'forbidden';
  end if;
  update public.tarifs_electricite set par_defaut = false where par_defaut;
  update public.tarifs_electricite set par_defaut = true  where id = p_id;
end $$;
grant execute on function public.set_tarif_defaut(uuid) to authenticated;

-- Archivage d'un tarif : il sort de l'affichage, garde sa date de fin, et les
-- sites qui l'utilisaient basculent sur le tarif par défaut — sinon leur
-- facture ne serait plus calculable.
create or replace function public.archiver_tarif(p_id uuid)
returns table (sites_reaffectes int, tarif_defaut uuid)
language plpgsql security definer set search_path = public as $$
declare
  v_defaut uuid;
  v_nb int := 0;
begin
  if not exists (select 1 from public.profiles
                  where id = auth.uid() and role in ('admin','superadmin')) then
    raise exception 'forbidden';
  end if;
  if exists (select 1 from public.tarifs_electricite where id = p_id and par_defaut) then
    raise exception 'Le tarif par défaut ne peut pas être archivé. Désignez-en un autre d''abord.';
  end if;

  select id into v_defaut from public.tarifs_electricite where par_defaut limit 1;

  update public.tarifs_electricite
     set actif = false, date_fin = coalesce(date_fin, current_date)
   where id = p_id;

  if v_defaut is not null then
    with maj as (
      update public.sites set tarif_id = v_defaut where tarif_id = p_id returning 1
    ) select count(*)::int into v_nb from maj;
  end if;

  return query select v_nb, v_defaut;
end $$;
grant execute on function public.archiver_tarif(uuid) to authenticated;

comment on column public.tarifs_electricite.par_defaut is
  'Grille de repli appliquée quand le tarif réel du site est inconnu. Un seul true possible (index unique partiel).';
