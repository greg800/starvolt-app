-- Mind Vector — accès réglable par rôle.
--
-- La clé rejoint la zone « menus » des permissions. Elle est semée à false
-- partout SAUF admin/superadmin : le vérificateur de permissions est
-- volontairement « fail-open » (clé absente = visible), donc sans ce seed la
-- page s'ouvrirait à tout le monde dès l'ajout de la case.

update public.app_roles
   set permissions = jsonb_set(
         permissions,
         '{menus,mind_vector}',
         to_jsonb(key in ('admin','superadmin')),
         true)
 where permissions ? 'menus';
