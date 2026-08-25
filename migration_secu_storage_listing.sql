-- Audit sécurité — bucket learn-images : couper le listing anonyme
--
-- Warning « Public Bucket Allows Listing » : le bucket est public ET une policy
-- SELECT sur storage.objects est ouverte au rôle `public`. N'importe qui pouvait
-- énumérer le contenu du bucket via POST /storage/v1/object/list/learn-images
-- avec la seule clé anon (elle est publique par design).
--
-- Le bucket reste `public = true` : l'endpoint /storage/v1/object/public/… sert
-- les fichiers sans passer par RLS, donc les images de la partie Comprendre
-- continuent de s'afficher. Seul le listing, qui lui applique RLS, se ferme.
--
-- Vérifié avant/après :
--   GET  /object/public/learn-images/<fichier>  → 200 dans les deux cas
--   POST /object/list/learn-images (clé anon)   → liste avant, [] après

alter policy "storage public read" on storage.objects to authenticated;
