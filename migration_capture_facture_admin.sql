-- Validation admin des factures : lecture des PDF + file de travail.

-- L'admin doit pouvoir relire la facture jointe pour valider la grille lue.
-- (Les clients ne voient que leurs propres fichiers, cf. migration précédente.)
drop policy if exists "factures read admin" on storage.objects;
create policy "factures read admin" on storage.objects
  for select to authenticated
  using (bucket_id = 'factures' and public.is_admin());

-- File de validation : brouillons à valider, avec de quoi juger sur pièces
-- (qui, quel fichier, quelle grille lue, à quel point on en est sûr).
create or replace function public.get_factures_a_valider()
returns table (
  extraction_id uuid, created_at timestamptz,
  prenom text, nom text, email text,
  fournisseur text, offre_nom text, type_tarif text, puissance_kva smallint,
  abo_mensuel numeric, prix_base numeric, prix_hp numeric, prix_hc numeric,
  conso_totale_kwh numeric, confiance jsonb, cle_offre text,
  tarif_id uuid, storage_key text, retention_until timestamptz,
  nb_concordantes bigint
)
language sql security definer set search_path = public as $$
  select e.id, e.created_at,
         p.prenom, p.nom, u.email,
         e.fournisseur, e.offre_nom, e.type_tarif, e.puissance_kva,
         e.abo_mensuel, e.prix_base, e.prix_hp, e.prix_hc,
         e.conso_totale_kwh, e.confiance, e.cle_offre,
         e.tarif_id, f.storage_key, f.retention_until,
         (select count(*) from public.factures_extractions e2
           where e2.cle_offre = e.cle_offre and e2.statut = 'brouillon') as nb_concordantes
  from public.factures_extractions e
  join public.factures f on f.id = e.facture_id
  left join public.profiles p on p.id = e.user_id
  left join auth.users u on u.id = e.user_id
  where e.statut = 'brouillon'
  order by e.created_at;
$$;
grant execute on function public.get_factures_a_valider() to authenticated;

comment on function public.get_factures_a_valider is
  'File de validation admin : extractions en brouillon. La promotion passe par l''edge function tarif-valider (qui notifie le client).';
