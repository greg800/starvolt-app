-- Descriptions des fournisseurs (contenu fourni par Greg, mis en page).
-- Les variantes de casse et les noms courts/longs presents dans
-- tarifs_electricite.fournisseur pointent sur le meme texte : sans cela, une
-- grille portant « Gedia » n'afficherait rien alors que « GEDIA » est renseigne.
insert into public.fournisseurs_description (fournisseur, description, updated_at, updated_by)
values
  ('Alpiq', '## Le spécialiste des gros consommateurs
Il joue sur les marchés de gros, pas vraiment le fournisseur de quartier.

- **Son point fort** — très solide sur l’électricité professionnelle, avec une vraie expertise de producteur et de fournisseur.
- **Son point faible** — un positionnement moins évident pour le grand public, et moins local que certains alternatifs.', now(), 'import xlsx'),
  ('Alterna', '## Une cinquantaine d’entreprises locales dans le même bateau
Sans que chacune y perde son ancrage territorial.

- **Son point fort** — production renouvelable, offres locales et modèle issu des entreprises locales de distribution.
- **Son point faible** — une notoriété nationale qui reste loin derrière EDF ou les gros alternatifs.', now(), 'import xlsx'),
  ('EDF', '## Le paquebot nucléaire français
Difficile à battre quand on parle de puissance industrielle et de capacité de production.

- **Son point fort** — il maîtrise une grande partie de son approvisionnement, avec le Tarif Bleu pour les particuliers.
- **Son point faible** — une machine lourde, forcément moins agile qu’une petite fintech de l’électricité.', now(), 'import xlsx'),
  ('Ekwateur', '## Le vert, bien avant tout le monde
Il en avait fait son terrain de jeu quand personne ne s’y intéressait encore.

- **Son point fort** — offres renouvelables, digital et capacité à proposer des modèles assez originaux.
- **Son point faible** — une histoire tarifaire parfois mouvementée, et un modèle moins intégré industriellement que les grands énergéticiens.', now(), 'import xlsx'),
  ('Elmy', '## L’alternatif qui veut maîtriser la chaîne
Plutôt que simplement revendre des électrons.

- **Son point fort** — production renouvelable, fourniture et développement de projets bas carbone réunis dans le même groupe.
- **Son point faible** — il reste beaucoup plus petit qu’EDF, Engie ou TotalEnergies en moyens industriels.', now(), 'import xlsx'),
  ('Enercoop', '## L’anti-EDF assumé
Une coopérative où les producteurs renouvelables et les clients sont au cœur du modèle.

- **Son point fort** — la traçabilité, et l’achat direct auprès de nombreux producteurs français.
- **Son point faible** — cette exigence peut coûter plus cher qu’une offre purement optimisée sur le prix.', now(), 'import xlsx'),
  ('Engie', '## Le vieux géant du gaz en costume électrique
Il a sérieusement musclé sa partie électricité.

- **Son point fort** — la taille, le portefeuille d’offres, la production renouvelable et les services énergétiques.
- **Son point faible** — celui des géants : beaucoup de puissance, mais pas l’agilité d’un pure player numérique.', now(), 'import xlsx'),
  ('Eni', '## Le pétrolier-gazier italien qui a changé de terrain
Pour lui, l’énergie ne s’arrête plus aux stations-service.

- **Son point fort** — le groupe maîtrise une large chaîne de valeur et développe aussi renouvelables, services et mobilité.
- **À savoir** — pour la fourniture en France, la marque grand public est désormais surtout portée par Plenitude.', now(), 'import xlsx'),
  ('Frank energy', '## L’électricité au plus près de son vrai prix de marché
Une idée simple, assumée jusqu’au bout.

- **Son point fort** — un intérêt évident pour les clients capables de déplacer leurs consommations.
- **Son point faible** — un prix dynamique expose davantage aux variations du marché qu’une offre fixe.', now(), 'import xlsx'),
  ('Gaz de Bordeaux', '## Un nom de gazier, des offres d’électricien
Il vend désormais de l’électricité partout en France — le nom n’a pas reçu le mémo.

- **Son point fort** — un acteur historique, local à l’origine, avec aujourd’hui des offres nationales compétitives et de l’électricité verte.
- **Son point faible** — une image encore très « gazier » malgré son virage électrique.', now(), 'import xlsx'),
  ('Gedia', '## Le fournisseur local qui n’est pas devenu une multinationale
Énergie, réseau et territoire y restent très liés.

- **Son point fort** — la proximité avec les collectivités et la maîtrise d’un écosystème local.
- **Son point faible** — une échelle et une capacité d’innovation plus limitées que celles des grands acteurs nationaux.', now(), 'import xlsx'),
  ('GEDIA', '## Le fournisseur local qui n’est pas devenu une multinationale
Énergie, réseau et territoire y restent très liés.

- **Son point fort** — la proximité avec les collectivités et la maîtrise d’un écosystème local.
- **Son point faible** — une échelle et une capacité d’innovation plus limitées que celles des grands acteurs nationaux.', now(), 'import xlsx'),
  ('GEG', '## L’acteur énergétique grenoblois
Il combine production, distribution et fourniture.

- **Son point fort** — il maîtrise une partie de la chaîne et investit dans les renouvelables.
- **Son point faible** — une empreinte nationale et une force de frappe commerciale inférieures aux mastodontes.', now(), 'import xlsx'),
  ('Happ-e by Engie', '## ENGIE qui a mis un sweat-shirt
Une marque plus digitale et plus simple, lancée par le groupe.

- **Son point fort** — parcours en ligne, offres lisibles et adossement à la puissance d’ENGIE.
- **Son point faible** — derrière la façade agile, ce n’est pas vraiment un petit fournisseur indépendant.', now(), 'import xlsx'),
  ('Ilek', '## Il vous présente le producteur, pas un vague « courant vert »

- **Son point fort** — électricité renouvelable française, producteurs identifiés et approche très orientée circuit court.
- **Son point faible** — cette exigence de traçabilité ne lui permet pas toujours d’être le champion du prix.', now(), 'import xlsx'),
  ('La BelleEnergie', '## Le contrat d’électricité en menu à composer
Prix, durée, origine, producteur : tout se choisit.

- **Son point fort** — cette personnalisation, autour d’une électricité verte française et de prix fixes.
- **Son point faible** — une échelle qui reste modeste face aux gros fournisseurs nationaux.', now(), 'import xlsx'),
  ('La Bellenergie', '## L’électricité verte aussi simple qu’un abonnement téléphonique

- **Son point fort** — des prix fixes pouvant aller jusqu’à trois ans, une électricité verte française et un service client de proximité.
- **Son point faible** — un acteur de taille intermédiaire, avec moins de puissance industrielle qu’un géant.', now(), 'import xlsx'),
  ('Llum', '## L’Occitanie plutôt que toute la France
Un fournisseur local qui assume son terrain de jeu.

- **Son point fort** — la proximité : une électricité renouvelable et des producteurs du territoire, hydraulique, solaire et méthanisation.
- **Son point faible** — une couverture et une taille plus réduites.', now(), 'import xlsx'),
  ('LLUM', '## L’Occitanie plutôt que toute la France
Un fournisseur local qui assume son terrain de jeu.

- **Son point fort** — la proximité : une électricité renouvelable et des producteurs du territoire, hydraulique, solaire et méthanisation.
- **Son point faible** — une couverture et une taille plus réduites.', now(), 'import xlsx'),
  ('Mint', '## La carte du prix et du digital
Et il la joue particulièrement bien.

- **Son point fort** — des offres simples à souscrire, souvent agressives commercialement, avec une composante renouvelable selon les contrats.
- **Son point faible** — le modèle d’un fournisseur agile et commercial, plus que d’un producteur intégré.', now(), 'import xlsx'),
  ('Mint Énergie', '## La carte du prix et du digital
Et il la joue particulièrement bien.

- **Son point fort** — des offres simples à souscrire, souvent agressives commercialement, avec une composante renouvelable selon les contrats.
- **Son point faible** — le modèle d’un fournisseur agile et commercial, plus que d’un producteur intégré.', now(), 'import xlsx'),
  ('Octopus', '## L’électricité traitée comme un logiciel
Données, tarification intelligente et pilotage, plutôt qu’une simple facture.

- **Son point fort** — sa technologie Kraken et son savoir-faire sur les offres flexibles, notamment pour les véhicules électriques et la consommation pilotée.
- **Son point faible** — un modèle plus complexe à comprendre quand on veut juste « le prix du kWh ».', now(), 'import xlsx'),
  ('Octopus Energy', '## L’électricité traitée comme un logiciel
Données, tarification intelligente et pilotage, plutôt qu’une simple facture.

- **Son point fort** — sa technologie Kraken et son savoir-faire sur les offres flexibles, notamment pour les véhicules électriques et la consommation pilotée.
- **Son point faible** — un modèle plus complexe à comprendre quand on veut juste « le prix du kWh ».', now(), 'import xlsx'),
  ('Ohm', '## Le trublion qui joue avec les prix
Quand les autres ressortent encore la même vieille recette.

- **Son point fort** — des offres originales, une forte culture du prix et pas mal d’outils digitaux.
- **Son point faible** — un acteur beaucoup moins intégré industriellement qu’EDF ou TotalEnergies.', now(), 'import xlsx'),
  ('Ohm Énergie', '## Le trublion qui joue avec les prix
Quand les autres ressortent encore la même vieille recette.

- **Son point fort** — des offres originales, une forte culture du prix et pas mal d’outils digitaux.
- **Son point faible** — un acteur beaucoup moins intégré industriellement qu’EDF ou TotalEnergies.', now(), 'import xlsx'),
  ('Papernest', '## À l’origine, un gestionnaire de contrats
Pas un producteur d’électricité, mais un spécialiste de la gestion et de la comparaison des contrats.

- **Son point fort** — son acquisition digitale et sa capacité à simplifier le changement de fournisseur.
- **À savoir** — c’est tout l’intérêt d’un partenariat ; pour la production d’électricité, il faut regarder ailleurs.', now(), 'import xlsx'),
  ('Papernest Energie', '## De « je vous trouve un fournisseur » à « je suis le fournisseur »

- **Son point fort** — expérience digitale, acquisition client et gestion simplifiée des contrats.
- **Son point faible** — une activité de fourniture encore beaucoup plus jeune que celle des acteurs historiques.', now(), 'import xlsx'),
  ('Plenitude', '## Eni sous une marque tournée vers le client
Une façon plus moderne de vendre l’énergie.

- **Son point fort** — électricité, gaz, renouvelables, mobilité et services énergétiques dans un même écosystème.
- **Son point faible** — malgré son image de nouvel entrant, il reste adossé à un très gros groupe énergétique.', now(), 'import xlsx'),
  ('Primeo', '## Le suisse venu jouer le prix en France
Et il le fait sérieusement.

- **Son point fort** — un approvisionnement solide, une bonne capacité d’achat et des offres souvent très compétitives.
- **Son point faible** — une marque encore moins connue du grand public que les poids lourds français.', now(), 'import xlsx'),
  ('Primeo Energie', '## Le suisse venu jouer le prix en France
Et il le fait sérieusement.

- **Son point fort** — un approvisionnement solide, une bonne capacité d’achat et des offres souvent très compétitives.
- **Son point faible** — une marque encore moins connue du grand public que les poids lourds français.', now(), 'import xlsx'),
  ('Sobry', '## Pourquoi payer l’électricité au même prix toute la journée ?
Sa réponse tient en deux mots : prix dynamiques.

- **Son point fort** — faire profiter ses clients des moments où le marché est moins cher.
- **Son point faible** — il faut accepter les variations de prix, et avoir des consommations pilotables.', now(), 'import xlsx'),
  ('Symphonics', '## Fourniture, batterie, consommation et flexibilité pilotées ensemble
Il refuse de les séparer.

- **Son point fort** — cette intégration, avec agrégation et pilotage intelligent des équipements.
- **Son point faible** — très prometteur pour les clients flexibles, mais encore jeune face aux fournisseurs installés depuis des décennies.', now(), 'import xlsx'),
  ('Sélia', '## Le territoire plutôt que le gigantisme
Un fournisseur local, et qui l’assume.

- **Son point fort** — son ancrage régional et son lien avec les écosystèmes énergétiques locaux.
- **Son point faible** — sa taille limite sa puissance marketing et sa capacité à multiplier les offres sophistiquées.', now(), 'import xlsx'),
  ('TotalEnergies', '## La tronçonneuse quand les autres ont un couteau suisse
Moyens, production et présence internationale.

- **Son point fort** — son intégration industrielle et sa capacité à proposer électricité, gaz, solaire, mobilité et services.
- **Son point faible** — une grosse machine, moins spécialisée et moins « pure player » numérique qu’Octopus ou Sobry.', now(), 'import xlsx'),
  ('Urban Solar', '## Le solaire urbain et l’autoconsommation
Son terrain de jeu, revendiqué.

- **Son point fort** — stockage virtuel, valorisation du surplus et offres pensées autour des producteurs photovoltaïques.
- **Son point faible** — un positionnement très spécialisé, moins pertinent pour qui cherche simplement le fournisseur le moins cher.', now(), 'import xlsx'),
  ('Énergie d''Ici', '## Du barrage à votre facture, au plus court
Il achète directement auprès de producteurs associés, avec une forte dominante hydroélectrique et un ancrage local.

- **Son point fort** — un circuit court, très lisible.
- **Son point faible** — forcément moins diversifié et moins puissant qu’un grand fournisseur national.', now(), 'import xlsx')
on conflict (fournisseur) do update
  set description = excluded.description,
      updated_at  = now(),
      updated_by  = 'import xlsx';
