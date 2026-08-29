-- Mind Vector — rubrique « Politique » : 16 sujets clivants ajoutés
-- et classement de La France insoumise, du Rassemblement national
-- et de Place publique sur chacun. Position 1 = extrême A, position 5 = extrême B.
begin;

-- Retraites : à quel âge s'arrêter ?
insert into mv_nodes (id, parent_id, label, ordre) values ('cebe2cec-59f6-4e60-8f61-a3868abaa8ce', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$Retraites : à quel âge s'arrêter ?$mv$, 13) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 1, $mv$[67 ans]$mv$, $mv$On vit plus vieux, on travaille plus longtemps : **67 ans**, et l'âge suit ensuite l'espérance de vie automatiquement. C'est de l'arithmétique, pas de l'idéologie. Sans ça, le système saute.$mv$),
  ('cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 2, $mv$[64, on tient]$mv$, $mv$La réforme à **64 ans** s'applique, point. On aménage les carrières longues et la pénibilité, mais reculer sur l'âge, c'est refiler la facture aux jeunes qui paieront deux fois.$mv$),
  ('cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 3, $mv$[63 et on gèle]$mv$, $mv$On gèle le curseur autour de **63 ans** et on rééquilibre autrement : emploi des seniors, assiette des cotisations, durée. L'âge légal n'est pas le seul levier, juste le plus brutal.$mv$),
  ('cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 4, $mv$[62 + pénibilité]$mv$, $mv$Retour à **62 ans**, et vrai départ anticipé pour ceux qui ont commencé tôt ou usé leur corps. Un maçon et un cadre n'ont pas la même espérance de vie en bonne santé, c'est mesuré.$mv$),
  ('cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 5, $mv$[60 ans, point]$mv$, $mv$**60 ans** avec 40 annuités. La productivité a explosé en quarante ans : la richesse existe, c'est son partage qui coince. La retraite, c'est du temps de vie qu'on rend aux gens.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 5, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 4, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 3, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- Sécurité et justice : punir ou prévenir ?
insert into mv_nodes (id, parent_id, label, ordre) values ('09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$Sécurité et justice : punir ou prévenir ?$mv$, 14) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 1, $mv$[Tolérance zéro]$mv$, $mv$**Peines planchers**, prison ferme dès le premier vrai délit, fin des aménagements automatiques. Ce qui dissuade, c'est une sanction certaine et rapide, pas un discours sur les causes.$mv$),
  ('09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 2, $mv$[Fermeté d'abord]$mv$, $mv$On alourdit les peines pour les violences et le trafic, on construit des places de prison. La prévention viendra après, quand **l'ordre sera revenu** dans les quartiers qui l'ont perdu.$mv$),
  ('09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 3, $mv$[Les deux jambes]$mv$, $mv$Fermeté sur les faits graves, prévention sur le reste : **moitié sanction, moitié social**. Une justice qui ne fait que punir échoue, une justice qui ne punit jamais aussi.$mv$),
  ('09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 4, $mv$[Réinsérer]$mv$, $mv$La prison fabrique des récidivistes. On mise sur les **peines alternatives**, l'éducateur, le travail d'intérêt général, et on garde l'enfermement pour ceux qui sont vraiment dangereux.$mv$),
  ('09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 5, $mv$[Traiter les causes]$mv$, $mv$La délinquance vient de **la misère et de l'échec scolaire**, pas de la mollesse des juges. Écoles, éducateurs, logement : on désarme la violence en amont, pas en remplissant les prisons.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 5, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 1, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 4, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- Europe : nation ou fédération ?
insert into mv_nodes (id, parent_id, label, ordre) values ('70ee0d0d-f993-4d74-ae3c-966e24d3c08d', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$Europe : nation ou fédération ?$mv$, 15) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 1, $mv$[La France d'abord]$mv$, $mv$La loi française prime, point final. On reprend la main sur nos frontières, notre budget et notre énergie. Bruxelles propose, **Paris décide**, et personne d'autre.$mv$),
  ('70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 2, $mv$[Europe des nations]$mv$, $mv$Oui à la coopération, non à la fédération. On garde l'euro et le marché commun, mais on refuse tout nouveau transfert de souveraineté et on **désobéit** aux règles absurdes.$mv$),
  ('70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 3, $mv$[Utile, pas plus]$mv$, $mv$L'Europe est un bon outil quand elle sert : commerce, climat, recherche, énergie. On avance dossier par dossier, sans grand soir fédéral ni sortie fracassante.$mv$),
  ('70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 4, $mv$[Europe puissance]$mv$, $mv$Il faut une Europe qui protège : **budget commun**, dette commune, industrie et défense intégrées. Seul, aucun pays européen ne pèse face aux États-Unis ou à la Chine.$mv$),
  ('70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 5, $mv$[États-Unis d'Europe]$mv$, $mv$Une vraie fédération : gouvernement européen élu, impôt européen, **majorité qualifiée partout**. La souveraineté d'un pays de 68 millions d'habitants est devenue une fiction confortable.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 2, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 1, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 5, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- Impôts : baisser ou redistribuer ?
insert into mv_nodes (id, parent_id, label, ordre) values ('488be11b-5a34-4231-9562-60ee78628488', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$Impôts : baisser ou redistribuer ?$mv$, 16) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('488be11b-5a34-4231-9562-60ee78628488', 1, $mv$[Moins d'impôts]$mv$, $mv$**Flat tax** et baisse générale des prélèvements. On est champions du monde de l'impôt et la pauvreté n'a pas reculé pour autant : rendre l'argent marche mieux que le redistribuer.$mv$),
  ('488be11b-5a34-4231-9562-60ee78628488', 2, $mv$[Alléger d'abord]$mv$, $mv$Priorité à la baisse des impôts de production et des charges. On garde la progressivité, mais **aucune taxe nouvelle** : on coupe d'abord dans la dépense publique.$mv$),
  ('488be11b-5a34-4231-9562-60ee78628488', 3, $mv$[Stabilité fiscale]$mv$, $mv$Ni hausse ni baisse générale : on arrête surtout de changer les règles tous les ans. On rend l'impôt lisible et on chasse les niches, à rendement constant.$mv$),
  ('488be11b-5a34-4231-9562-60ee78628488', 4, $mv$[Plus progressif]$mv$, $mv$On rétablit des **tranches hautes** vraiment progressives et on ferme les niches des plus aisés. L'impôt paie l'école et l'hôpital, ce n'est pas une punition.$mv$),
  ('488be11b-5a34-4231-9562-60ee78628488', 5, $mv$[Redistribution max]$mv$, $mv$**Quatorze tranches**, impôt fortement progressif, contribution exceptionnelle des très hauts revenus. Quand 1 % capte l'essentiel des gains, redistribuer n'est pas idéologique, c'est réparer.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', '488be11b-5a34-4231-9562-60ee78628488', 5, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', '488be11b-5a34-4231-9562-60ee78628488', 2, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', '488be11b-5a34-4231-9562-60ee78628488', 4, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- Climat : s'adapter ou tout transformer ?
insert into mv_nodes (id, parent_id, label, ordre) values ('8818ade6-57a1-4f11-9540-ad14d31ccc9f', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$Climat : s'adapter ou tout transformer ?$mv$, 17) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('8818ade6-57a1-4f11-9540-ad14d31ccc9f', 1, $mv$[La techno suffira]$mv$, $mv$L'innovation et le marché régleront le climat : nucléaire, captage du carbone, rendements. Contraindre les gens, c'est de **l'écologie punitive** qui n'a jamais fait baisser une émission.$mv$),
  ('8818ade6-57a1-4f11-9540-ad14d31ccc9f', 2, $mv$[Adapter surtout]$mv$, $mv$Le réchauffement est déjà là : priorité à l'eau, aux digues, aux forêts, aux villes vivables l'été. On adapte le pays **avant** de bouleverser la façon de produire.$mv$),
  ('8818ade6-57a1-4f11-9540-ad14d31ccc9f', 3, $mv$[Carotte et bâton]$mv$, $mv$Un peu de norme, un peu de marché : prix du carbone, aides à la rénovation, objectifs clairs. On transforme **par étapes**, sans casser l'industrie ni les ménages.$mv$),
  ('8818ade6-57a1-4f11-9540-ad14d31ccc9f', 4, $mv$[Planifier vraiment]$mv$, $mv$L'État fixe la trajectoire secteur par secteur, avec des **contraintes chiffrées** et l'argent en face. Le marché seul n'a jamais atteint une cible climatique, nulle part.$mv$),
  ('8818ade6-57a1-4f11-9540-ad14d31ccc9f', 5, $mv$[Bifurcation]$mv$, $mv$On sort du productivisme : **planification écologique** contraignante, fin des productions les plus polluantes, sobriété organisée. Le climat ne négocie pas ses délais.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 5, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 1, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 4, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- Pouvoir d'achat : détaxer ou encadrer ?
insert into mv_nodes (id, parent_id, label, ordre) values ('eede8f9e-375f-4966-9ee6-8fb579a71d08', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$Pouvoir d'achat : détaxer ou encadrer ?$mv$, 18) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('eede8f9e-375f-4966-9ee6-8fb579a71d08', 1, $mv$[Moins de taxes]$mv$, $mv$Le pouvoir d'achat se gagne en **baissant la TVA et les charges**, pas en décrétant les prix. Chaque euro de taxe en moins, c'est un euro rendu à celui qui travaille.$mv$),
  ('eede8f9e-375f-4966-9ee6-8fb579a71d08', 2, $mv$[Détaxer l'essentiel]$mv$, $mv$**TVA à 0 %** sur l'énergie et les produits de première nécessité, primes défiscalisées. On agit sur la facture, tout de suite, sans toucher au bulletin de paie.$mv$),
  ('eede8f9e-375f-4966-9ee6-8fb579a71d08', 3, $mv$[Un peu des deux]$mv$, $mv$Quelques baisses de taxes ciblées, quelques coups de pouce salariaux, et une surveillance des marges de la distribution. **Ni tout marché, ni tout État**.$mv$),
  ('eede8f9e-375f-4966-9ee6-8fb579a71d08', 4, $mv$[Encadrer les prix]$mv$, $mv$On **encadre les prix** de l'alimentation de base, de l'énergie et des loyers, et on indexe les salaires quand l'inflation dérape. Le marché ne s'autorégule pas sur le vital.$mv$),
  ('eede8f9e-375f-4966-9ee6-8fb579a71d08', 5, $mv$[Salaires et prestations]$mv$, $mv$On augmente **directement** salaires, minima sociaux et pensions, et on bloque les prix des produits de première nécessité. Le pouvoir d'achat est un rapport de force.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 5, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 2, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 4, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- Travail : coût du travail ou salaires ?
insert into mv_nodes (id, parent_id, label, ordre) values ('0f917c25-ffd5-43f6-a052-ed655209f4a0', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$Travail : coût du travail ou salaires ?$mv$, 19) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('0f917c25-ffd5-43f6-a052-ed655209f4a0', 1, $mv$[Libérer le travail]$mv$, $mv$On baisse les charges, on assouplit la rupture du contrat, on laisse négocier au niveau de l'entreprise. Un emploi trop cher, c'est un emploi qui **part ailleurs** ou qui ne naît pas.$mv$),
  ('0f917c25-ffd5-43f6-a052-ed655209f4a0', 2, $mv$[Compétitivité d'abord]$mv$, $mv$Allègements sur les bas salaires, heures supplémentaires défiscalisées, écart net entre travailler et ne pas travailler. La **valeur travail** doit redevenir payante.$mv$),
  ('0f917c25-ffd5-43f6-a052-ed655209f4a0', 3, $mv$[Donnant-donnant]$mv$, $mv$Des aides aux entreprises, oui, mais **conditionnées** à l'emploi et aux salaires. Les gains de productivité se partagent entre la marge et la fiche de paie.$mv$),
  ('0f917c25-ffd5-43f6-a052-ed655209f4a0', 4, $mv$[Salaires en hausse]$mv$, $mv$SMIC nettement revalorisé, conférence salariale annuelle, égalité femmes-hommes réellement appliquée. Les salaires ont **décroché** des profits, il faut rattraper.$mv$),
  ('0f917c25-ffd5-43f6-a052-ed655209f4a0', 5, $mv$[1600 € et 32 h]$mv$, $mv$**SMIC à 1 600 € net**, semaine de 32 heures, droits sociaux renforcés. La richesse produite doit revenir à ceux qui la produisent, pas aux actionnaires.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 5, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 3, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 4, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- Aides sociales : conditionner ou garantir ?
insert into mv_nodes (id, parent_id, label, ordre) values ('8e6056f1-fd0c-4f43-abeb-677dc71026de', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$Aides sociales : conditionner ou garantir ?$mv$, 20) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('8e6056f1-fd0c-4f43-abeb-677dc71026de', 1, $mv$[Priorité nationale]$mv$, $mv$La solidarité va d'abord à ceux qui ont **cotisé**. On ferme le robinet aux inactifs volontaires et on réserve les prestations non contributives aux nationaux.$mv$),
  ('8e6056f1-fd0c-4f43-abeb-677dc71026de', 2, $mv$[Aide contre effort]$mv$, $mv$Le RSA se mérite : **heures d'activité obligatoires**, contrôle réel, dégressivité dans le temps. La solidarité oui, l'assistanat sans contrepartie non.$mv$),
  ('8e6056f1-fd0c-4f43-abeb-677dc71026de', 3, $mv$[Ciblée et contrôlée]$mv$, $mv$On garde un filet large, avec des contrôles sérieux contre la fraude et un accompagnement vers l'emploi. **Ni chasse aux pauvres, ni guichet ouvert**.$mv$),
  ('8e6056f1-fd0c-4f43-abeb-677dc71026de', 4, $mv$[Versement automatique]$mv$, $mv$On **verse automatiquement** les aides auxquelles chacun a droit. Le vrai scandale, c'est le non-recours, pas la fraude : un droit ne devrait pas dépendre du courage administratif.$mv$),
  ('8e6056f1-fd0c-4f43-abeb-677dc71026de', 5, $mv$[Droits universels]$mv$, $mv$Protection **universelle et inconditionnelle** : santé, logement, revenu minimum décent pour tout résident. Un droit conditionné n'est plus un droit, c'est une récompense.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 5, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 1, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 4, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- Défense : Ukraine, Russie, OTAN
insert into mv_nodes (id, parent_id, label, ordre) values ('f69e2a49-451e-4c3f-b1d8-83a35d6aa334', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$Défense : Ukraine, Russie, OTAN$mv$, 21) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 1, $mv$[Ukraine jusqu'au bout]$mv$, $mv$Soutien **maximal** à Kiev — armes, argent, formation — et défense européenne intégrée. Si la Russie gagne là-bas, elle recommence ailleurs, et ce sera plus près de chez nous.$mv$),
  ('f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 2, $mv$[Réarmer l'Europe]$mv$, $mv$On monte le budget de défense, on produit obus et munitions en Europe, on aide l'Ukraine sans envoyer de troupes. **Dissuader coûte moins cher que subir**.$mv$),
  ('f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 3, $mv$[Fermes et prudents]$mv$, $mv$On aide l'Ukraine et on se réarme, mais on garde la main sur chaque engagement et on soutient toute négociation crédible. Ni naïveté, ni surenchère.$mv$),
  ('f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 4, $mv$[L'armée française]$mv$, $mv$On réarme **la France**, pas une armée européenne sans chef ni budget. Aide à l'Ukraine mesurée, refus des livraisons qui nous entraîneraient dans la guerre.$mv$),
  ('f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 5, $mv$[Non-alignement]$mv$, $mv$Sortie du commandement intégré de l'OTAN, **refus de l'escalade**, paix négociée. La France doit parler à tout le monde, pas s'aligner sur Washington.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 5, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 4, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 1, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- Prestations sociales : les Français d'abord ?
insert into mv_nodes (id, parent_id, label, ordre) values ('72bcbe3e-95cc-497a-8722-fc693f20619f', '7c260791-6892-4b46-b604-29df30c330f2', $mv$Prestations sociales : les Français d'abord ?$mv$, 2) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('72bcbe3e-95cc-497a-8722-fc693f20619f', 1, $mv$[Priorité nationale]$mv$, $mv$Allocations, logement social, aides : **priorité absolue aux Français**. On ne peut pas financer la solidarité de la terre entière quand nos retraités comptent chaque euro.$mv$),
  ('72bcbe3e-95cc-497a-8722-fc693f20619f', 2, $mv$[Après cinq ans]$mv$, $mv$Accès aux prestations non contributives seulement après **cinq ans de travail** en France. On accueille, mais on ne verse pas dès le jour de l'arrivée.$mv$),
  ('72bcbe3e-95cc-497a-8722-fc693f20619f', 3, $mv$[Cotiser puis toucher]$mv$, $mv$Règle simple : qui cotise a droit, quelle que soit sa nationalité. Pour le non-contributif, une **durée de résidence** raisonnable, la même pour tout le monde.$mv$),
  ('72bcbe3e-95cc-497a-8722-fc693f20619f', 4, $mv$[Résider, c'est avoir droit]$mv$, $mv$Un travailleur étranger paie les mêmes impôts et les mêmes cotisations : il doit avoir **les mêmes droits**. Trier par passeport fabrique des citoyens à moitié.$mv$),
  ('72bcbe3e-95cc-497a-8722-fc693f20619f', 5, $mv$[Égalité totale]$mv$, $mv$**Mêmes droits pour tous les résidents**, sans condition de nationalité ni d'ancienneté. La dignité ne se découpe pas en tranches administratives.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', '72bcbe3e-95cc-497a-8722-fc693f20619f', 5, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', '72bcbe3e-95cc-497a-8722-fc693f20619f', 1, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', '72bcbe3e-95cc-497a-8722-fc693f20619f', 4, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- Agriculture : produire ou transformer ?
insert into mv_nodes (id, parent_id, label, ordre) values ('a5eafabd-1790-4e41-b6fe-e74b341f585f', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$Agriculture : produire ou transformer ?$mv$, 22) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('a5eafabd-1790-4e41-b6fe-e74b341f585f', 1, $mv$[Produire d'abord]$mv$, $mv$On **supprime les normes** qui étouffent les fermes et on assume la production. La France doit nourrir, pas importer ce qu'elle s'interdit de cultiver chez elle.$mv$),
  ('a5eafabd-1790-4e41-b6fe-e74b341f585f', 2, $mv$[Simplifier, protéger]$mv$, $mv$Moins de contraintes, des prix garantis, des **clauses miroirs** aux frontières. On sécurise le revenu des agriculteurs avant de leur ajouter des exigences.$mv$),
  ('a5eafabd-1790-4e41-b6fe-e74b341f585f', 3, $mv$[Transition négociée]$mv$, $mv$On réduit les intrants **au rythme des solutions disponibles**, avec accompagnement et sans interdiction sèche. Ni statu quo, ni virage à marche forcée.$mv$),
  ('a5eafabd-1790-4e41-b6fe-e74b341f585f', 4, $mv$[Agroécologie financée]$mv$, $mv$Objectifs contraignants de baisse des pesticides, mais l'État finance la conversion. **La haie et le bio ne doivent pas ruiner** celui qui s'y met.$mv$),
  ('a5eafabd-1790-4e41-b6fe-e74b341f585f', 5, $mv$[Sortie des pesticides]$mv$, $mv$Interdiction des pesticides de synthèse, **relocalisation**, fin de l'élevage industriel. L'agriculture doit soigner les sols et l'eau, pas les épuiser pour un rendement.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 5, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 1, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 4, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- École : mérite ou égalité ?
insert into mv_nodes (id, parent_id, label, ordre) values ('4788e43e-8c98-417a-870a-03854f9388d9', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$École : mérite ou égalité ?$mv$, 23) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('4788e43e-8c98-417a-870a-03854f9388d9', 1, $mv$[Autorité et mérite]$mv$, $mv$**Uniforme, discipline, notes, redoublement**, filières sélectives dès le collège. L'école doit élever le niveau et reconnaître les meilleurs, pas nier les différences.$mv$),
  ('4788e43e-8c98-417a-870a-03854f9388d9', 2, $mv$[Les fondamentaux]$mv$, $mv$Priorité au lire-écrire-compter, évaluations nationales, autorité du professeur restaurée. L'égalitarisme a **baissé le niveau** de tout le monde, à commencer par les plus pauvres.$mv$),
  ('4788e43e-8c98-417a-870a-03854f9388d9', 3, $mv$[Exigence et soutien]$mv$, $mv$De l'exigence et de l'autorité, mais du soutien pour ceux qui décrochent. On évalue sans humilier, on oriente sans condamner à quatorze ans.$mv$),
  ('4788e43e-8c98-417a-870a-03854f9388d9', 4, $mv$[Réduire les écarts]$mv$, $mv$Classes dédoublées en éducation prioritaire, **mixité sociale** organisée, professeurs revalorisés. Le déterminisme social français est l'un des pires de l'OCDE.$mv$),
  ('4788e43e-8c98-417a-870a-03854f9388d9', 5, $mv$[École de l'égalité]$mv$, $mv$**Moyens massifs**, fin de la sélection précoce, mixité imposée au public comme au privé, gratuité réelle. L'école doit corriger les inégalités, pas les certifier.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', '4788e43e-8c98-417a-870a-03854f9388d9', 5, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', '4788e43e-8c98-417a-870a-03854f9388d9', 1, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', '4788e43e-8c98-417a-870a-03854f9388d9', 4, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- Logement : marché ou intervention publique ?
insert into mv_nodes (id, parent_id, label, ordre) values ('0ef32e3d-16a2-466d-81a6-d7ec4e92a277', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$Logement : marché ou intervention publique ?$mv$, 24) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 1, $mv$[Libérer le foncier]$mv$, $mv$On **déverrouille le permis de construire** et on allège la fiscalité du bailleur. La pénurie vient du blocage de l'offre, pas de la méchanceté des propriétaires.$mv$),
  ('0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 2, $mv$[Construire, inciter]$mv$, $mv$Simplifier les normes, aider l'accession à la propriété, rassurer ceux qui louent leur bien. **Plus d'offre** fera baisser les loyers mieux qu'un plafond décrété.$mv$),
  ('0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 3, $mv$[Offre et garde-fous]$mv$, $mv$On construit beaucoup **et** on encadre les abus : meublés touristiques, passoires thermiques, loyers en zone tendue. Les deux leviers, pas un seul.$mv$),
  ('0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 4, $mv$[Encadrer les loyers]$mv$, $mv$Encadrement des loyers généralisé, mobilisation des logements vides, quotas de logement social relevés. Se loger n'est pas un placement, c'est un **besoin**.$mv$),
  ('0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 5, $mv$[Logement public massif]$mv$, $mv$**200 000 logements sociaux par an**, blocage des loyers, garantie universelle des loyers. Le marché a eu quarante ans pour régler la crise, il l'a aggravée.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', '0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 5, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', '0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 2, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', '0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 4, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- Famille : encourager la natalité ?
insert into mv_nodes (id, parent_id, label, ordre) values ('63b1e42a-a939-43c6-a5c5-c57e7b1209b5', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$Famille : encourager la natalité ?$mv$, 25) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 1, $mv$[Nataliste assumé]$mv$, $mv$La France doit **faire des enfants** : quotient familial généreux, allocations dès le premier, salaire parental. Sans naissances, pas de retraites, et pas de pays.$mv$),
  ('63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 2, $mv$[Soutenir les familles]$mv$, $mv$On revalorise les allocations et le congé parental, on ouvre des places de crèche. Ce n'est pas de l'idéologie : **beaucoup de couples veulent un enfant de plus** et renoncent.$mv$),
  ('63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 3, $mv$[Aider sans pousser]$mv$, $mv$L'État aide les familles qui existent, sans se fixer d'objectif de naissances. Crèches et congés oui, injonction démographique non.$mv$),
  ('63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 4, $mv$[Égalité d'abord]$mv$, $mv$L'aide va à l'enfant, pas au modèle familial : **individualiser** les droits, partager le congé parental, soutenir massivement les familles monoparentales.$mv$),
  ('63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 5, $mv$[Neutralité totale]$mv$, $mv$Faire un enfant est un **choix privé**, jamais une politique publique. On aide les personnes selon leurs revenus, pas selon leur nombre d'enfants.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', '63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 4, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', '63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 1, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', '63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 3, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- Institutions : exécutif fort ou pouvoir au peuple ?
insert into mv_nodes (id, parent_id, label, ordre) values ('106b1aff-a35e-47d3-b657-7b23676de380', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$Institutions : exécutif fort ou pouvoir au peuple ?$mv$, 26) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('106b1aff-a35e-47d3-b657-7b23676de380', 1, $mv$[Un chef qui décide]$mv$, $mv$Exécutif fort, 49.3 assumé, ordonnances quand il le faut. **Trop de veto tue l'action** : le pays a besoin qu'on tranche, pas qu'on palabre deux ans.$mv$),
  ('106b1aff-a35e-47d3-b657-7b23676de380', 2, $mv$[Stabilité d'abord]$mv$, $mv$On garde la Vᵉ République, avec une **dose de proportionnelle** et des référendums à l'initiative du président. L'instabilité coûte très cher au pays.$mv$),
  ('106b1aff-a35e-47d3-b657-7b23676de380', 3, $mv$[Rééquilibrer]$mv$, $mv$Plus de contrôle pour le Parlement, moins de 49.3, proportionnelle partielle, référendums encadrés. On corrige les excès sans refonder tout le régime.$mv$),
  ('106b1aff-a35e-47d3-b657-7b23676de380', 4, $mv$[Parlement souverain]$mv$, $mv$Le Parlement fait la loi et renverse le gouvernement : **proportionnelle intégrale**, non-cumul strict, droit d'amendement respecté. Le président n'est pas un monarque élu.$mv$),
  ('106b1aff-a35e-47d3-b657-7b23676de380', 5, $mv$[VIᵉ République]$mv$, $mv$Assemblée constituante, **référendum d'initiative citoyenne** en toutes matières, révocation des élus. La souveraineté doit redescendre au peuple, en continu.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', '106b1aff-a35e-47d3-b657-7b23676de380', 5, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', '106b1aff-a35e-47d3-b657-7b23676de380', 3, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', '106b1aff-a35e-47d3-b657-7b23676de380', 4, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

-- Patrimoine et capital : protéger ou taxer ?
insert into mv_nodes (id, parent_id, label, ordre) values ('67d2ce30-3b8f-46d8-9f37-44dee0099e96', '700a2061-efc1-439f-a3f8-79c8bb41deab', $mv$Patrimoine et capital : protéger ou taxer ?$mv$, 27) on conflict (id) do nothing;
insert into mv_positions (node_id, pos, titre, content) values
  ('67d2ce30-3b8f-46d8-9f37-44dee0099e96', 1, $mv$[Ne pas taxer le capital]$mv$, $mv$**Flat tax à 30 % maximum**, pas d'ISF, droits de succession allégés. Le capital est mobile : le taxer trop, c'est le voir partir et perdre l'usine avec lui.$mv$),
  ('67d2ce30-3b8f-46d8-9f37-44dee0099e96', 2, $mv$[Encourager l'investissement]$mv$, $mv$On protège l'épargne, on allège la transmission, on réserve les avantages à l'investissement productif. **Transmettre à ses enfants n'est pas voler**.$mv$),
  ('67d2ce30-3b8f-46d8-9f37-44dee0099e96', 3, $mv$[Aligné sur le travail]$mv$, $mv$Le capital est taxé **comme le travail**, ni plus ni moins. Ni cadeau, ni punition : la même règle pour un salaire et pour un dividende, c'est tout.$mv$),
  ('67d2ce30-3b8f-46d8-9f37-44dee0099e96', 4, $mv$[Impôt sur la fortune]$mv$, $mv$Retour d'un **ISF élargi**, dividendes au barème, fin des niches sur les grandes successions. Le patrimoine a explosé pendant que les salaires stagnaient.$mv$),
  ('67d2ce30-3b8f-46d8-9f37-44dee0099e96', 5, $mv$[Taxer les fortunes]$mv$, $mv$Impôt fortement progressif sur la fortune, **héritage plafonné**, taxation des rachats d'actions. À la troisième génération, la rente n'a plus rien de méritant.$mv$)
on conflict (node_id, pos) do update set titre = excluded.titre, content = excluded.content;
insert into mv_reponses (personne_id, node_id, pos, auteur_id) values
  ('477b88ea-e1ab-4c90-b37c-2520b0ddc5e5', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 5, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('dee30bd6-2da4-4afd-9dc1-e926777373ad', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 2, '98628a67-0aa0-41d3-ac92-815894449546'),
  ('f58aa768-a85e-4539-a2c8-b09e7b1517bd', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 4, '98628a67-0aa0-41d3-ac92-815894449546')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos;

commit;
