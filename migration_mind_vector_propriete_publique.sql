-- « Financement du salaire universel » : la propriété publique entre dans l'échelle.
--
-- L'échelle opposait « taxer les robots » à « chaque citoyen actionnaire » et
-- laissait hors champ la réponse de LFI et du PCF — l'État propriétaire des
-- machines (grand secteur public de l'IA, nationalisations). Ces deux partis
-- étaient donc rangés du côté de l'impôt, ce qui les trahissait.
--
-- ⚠️ Une 6ᵉ position est impossible : `mv_positions_pos_check` borne pos à 1..5,
-- et tout l'écran est bâti sur cinq cases (calcul de taille du texte, grille de
-- la vue hélicoptère, parcours au doigt). On refond donc les cinq.
--
-- Le nouvel axe glisse de la propriété COLLECTIVE à la propriété INDIVIDUELLE :
--   1 l'État possède les machines · 2 personne ne change de propriétaire, on
--   taxe · 3 moitié-moitié · 4 le fonds citoyen d'abord · 5 chacun actionnaire.
-- Les positions 1 et 5 restent franchement opposées, comme l'exige la maison.
begin;

update mv_positions set titre = $p$[Les machines à l'État]$p$, updated_at = now(),
  content = $p$Si les machines produisent la richesse, elles doivent appartenir à **la collectivité**. Grand secteur public de l'IA, infrastructures nationalisées. Le profit tombe dans le budget commun, pas dans des parts distribuées à chacun.$p$
  where node_id = '2b99e9f9-fafb-410e-9269-a3b8dfe1ee57' and pos = 1;

update mv_positions set titre = $p$[Taxer et redistribuer]$p$, updated_at = now(),
  content = $p$Que le privé possède les machines, soit — mais alors **on taxe les robots et les géants du numérique**, et on redistribue en revenu universel. La justice sociale passe par l'impôt. Pas besoin d'inventer un montage actionnarial.$p$
  where node_id = '2b99e9f9-fafb-410e-9269-a3b8dfe1ee57' and pos = 2;

update mv_positions set titre = $p$[Moitié-moitié]$p$, updated_at = now(),
  content = $p$Les deux logiques se valent. **50% redistribution fiscale, 50% capital citoyen.** L'impôt garantit un socle tout de suite, le fonds monte en puissance à mesure que l'IA produit. Ni pur RSA amélioré, ni pur actionnariat populaire.$p$
  where node_id = '2b99e9f9-fafb-410e-9269-a3b8dfe1ee57' and pos = 3;

update mv_positions set titre = $p$[Fonds citoyen d'abord]$p$, updated_at = now(),
  content = $p$L'avenir c'est **posséder les machines**, pas quémander une redistribution, et pas non plus les confier à l'État. Un fonds citoyen qui capte 5 puis 20% des investissements productifs. Un peu d'impôt en filet, mais le dividende devient la vraie source.$p$
  where node_id = '2b99e9f9-fafb-410e-9269-a3b8dfe1ee57' and pos = 4;

update mv_positions set titre = $p$[100% copropriétaires]$p$, updated_at = now(),
  content = $p$La seule vraie réponse : **chaque citoyen actionnaire des machines**. Zéro taxe robot, zéro RSA déguisé, et surtout pas un État propriétaire. Un fonds qui absorbe le capital productif jusqu'à ce que le dividende remplace le salaire.$p$
  where node_id = '2b99e9f9-fafb-410e-9269-a3b8dfe1ee57' and pos = 5;

-- Le PCF rejoint LFI en position 1 : les deux veulent que les machines
-- appartiennent à la collectivité, ce que l'ancienne échelle ne permettait pas
-- de dire. Les huit autres partis ne bougent pas — le sens des positions 2 à 5
-- est inchangé pour eux.
update mv_recherches set pos = 1, taux = 70, cherche_le = now(),
  extrait = $p$Propriété publique des moyens de production et grand service public de l'énergie et de l'industrie : la richesse produite par les machines doit revenir à la collectivité, pas à des porteurs de parts individuels.$p$
  where node_id = '2b99e9f9-fafb-410e-9269-a3b8dfe1ee57'
    and personne_id = (select id from mv_personnes where nom = 'Parti communiste français' and type_entite = 'morale');

update mv_recherches set taux = 75, cherche_le = now(),
  extrait = $p$Création d'un grand secteur PUBLIC du numérique et de l'IA, mobilisation de l'épargne nationale pour des centres de calcul souverains et des infrastructures publiques. La réponse de LFI est la propriété publique des machines, doublée de la taxe Zucman.$p$
  where node_id = '2b99e9f9-fafb-410e-9269-a3b8dfe1ee57'
    and personne_id = (select id from mv_personnes where nom = 'La france Insoumise' and type_entite = 'morale');

update mv_reponses set pos = 1, updated_at = now()
  where node_id = '2b99e9f9-fafb-410e-9269-a3b8dfe1ee57'
    and personne_id = (select id from mv_personnes where nom = 'Parti communiste français' and type_entite = 'morale');

commit;
