-- Parcours automatique (« tapis roulant ») — texte court présenté à l'utilisateur
-- guidé pas à pas, juste avant de lui proposer de mettre l'offre dans son panier.
-- Peut contenir des variables {eco} {facture} {apres} {pct} {invest} {delai}
-- {roi} {prenom}, remplacées côté app par les valeurs calculées pour son site.
ALTER TABLE offres ADD COLUMN IF NOT EXISTS texte_auto text;

COMMENT ON COLUMN offres.texte_auto IS
  'Texte court du parcours automatique. Variables : {eco} {facture} {apres} {pct} {invest} {delai} {roi} {prenom}.';
