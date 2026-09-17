-- Audit code du 2026-09-17 : le bucket feedback-attachments (privé) acceptait
-- n'importe quel type de fichier, sans limite de taille, de la part de tout
-- compte connecté. Le formulaire n'accepte que png/jpeg/gif/webp/pdf : on
-- aligne le bucket dessus, avec le même plafond que le bucket factures (10 Mo),
-- pour fermer l'abus de stockage (coût) et le dépôt de fichiers arbitraires.
update storage.buckets
   set file_size_limit    = 10485760,
       allowed_mime_types = array['image/png','image/jpeg','image/gif','image/webp','application/pdf']
 where id = 'feedback-attachments';
