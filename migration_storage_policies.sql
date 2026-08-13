-- Audit code 2026-08-13 — durcissement des policies Storage.
--
-- Deux trous du même genre que celui corrigé sur les tables learn_* le
-- 2026-08-07 : la permission s'arrêtait à « être connecté », alors que le
-- besoin réel est « être admin ».
--
-- 1) feedback-attachments : le bucket a été passé en privé le 2026-06-10 parce
--    que les pièces jointes sont des captures d'écran d'utilisateurs, donc
--    potentiellement personnelles. Mais la policy de lecture visait TOUT compte
--    authentifié : n'importe quel inscrit pouvait lister le bucket et lire les
--    captures de tous les autres. Le bucket était privé pour le monde, pas pour
--    les utilisateurs. Seul l'écran admin « Retours » lit ces fichiers
--    (createSignedUrls) → is_admin().
--
-- 2) learn-images : écrire/écraser/supprimer les illustrations du module
--    Comprendre était ouvert à tout compte authentifié. Les seuls appelants
--    (uploadLearnImage) vivent dans AdminLearnSubjectEditScreen. La lecture
--    reste publique : c'est du contenu pédagogique affiché à tous.

-- 1) Lecture des pièces jointes de feedback : admins seulement.
drop policy if exists "fb read" on storage.objects;
create policy "fb read admin" on storage.objects
  for select to authenticated
  using (bucket_id = 'feedback-attachments' and public.is_admin());

-- 2) Écritures sur learn-images : admins seulement.
drop policy if exists "auth upload learn" on storage.objects;
create policy "admin upload learn" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'learn-images' and public.is_admin());

drop policy if exists "auth update learn" on storage.objects;
create policy "admin update learn" on storage.objects
  for update to authenticated
  using (bucket_id = 'learn-images' and public.is_admin());

drop policy if exists "auth delete learn" on storage.objects;
create policy "admin delete learn" on storage.objects
  for delete to authenticated
  using (bucket_id = 'learn-images' and public.is_admin());
