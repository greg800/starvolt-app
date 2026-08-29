-- Les Républicains : positions recherchées à la main (Claude, 2026-08-29).
-- Chaque ligne porte sa source et son taux de certitude dans mv_recherches ;
-- la réponse elle-même est marquée origine='recherche', comme celles trouvées
-- par l'action public_position — l'œil de l'écran ouvre donc la fiche de source.
begin;

-- Retraites : à quel âge s'arrêter ? → position 1 (90 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 1, 90, $lr$https://www.franceinfo.fr/elections/presidentielle/retraites-contrairement-a-beaucoup-d-autres-j-assumerai-le-fait-de-repousser-l-age-legal-lance-bruno-retailleau-candidat-lr-a-l-election-presidentielle_8166161.html$lr$, $lr$Franceinfo — Retailleau assume de repousser l'âge légal$lr$, $lr$Retailleau défend le report de l'âge légal à 65 ans et propose d'indexer l'âge de départ sur l'espérance de vie : « j'assumerai le fait de repousser l'âge légal ».$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Sécurité et justice : punir ou prévenir ? → position 1 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 1, 85, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Peines planchers pour les récidivistes, prison ferme dès le premier délit grave, abaissement de la minorité pénale à 16 ans, quartiers spécialisés pour les détenus dangereux.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Europe : nation ou fédération ? → position 2 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 2, 85, $lr$https://www.elyseescope.com/candidat/bruno-retailleau/europe$lr$, $lr$ÉlyséeScope — Retailleau et l'Europe$lr$, $lr$Europe des nations, subsidiarité stricte, souveraineté législative française sur l'immigration et la sécurité, opposition au fédéralisme, mais coopération acceptée en matière de défense.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Impôts : baisser ou redistribuer ? → position 1 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '488be11b-5a34-4231-9562-60ee78628488', 1, 75, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Baisse de 15 milliards d'euros de charges patronales, refus de l'impôt sur la fortune et de nouvelles contributions ; priorité à la réduction de la dépense plutôt qu'à la redistribution.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '488be11b-5a34-4231-9562-60ee78628488', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Climat : s'adapter ou tout transformer ? → position 2 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 2, 85, $lr$https://republicains.fr/actualites/2026/08/09/face-au-rechauffement-climatique-adapter-la-france-plutot-que-punir/$lr$, $lr$Les Républicains — « Adapter la France plutôt que punir » (09/08/2026)$lr$, $lr$« Adapter la France plutôt que punir » : écologie de l'adaptation et de la technologie contre « l'écologie punitive », suspension des ZFE, abandon de l'interdiction du thermique en 2035. Retailleau refuse par ailleurs le climatoscepticisme : « nous sommes déjà à 1,4 °C, c'est une mesure objective ».$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Pouvoir d'achat : détaxer ou encadrer ? → position 1 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 1, 65, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Le pouvoir d'achat passe par la baisse des charges et des prélèvements et par l'augmentation du temps de travail, pas par l'encadrement des prix ni par la hausse administrée des salaires.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Travail : coût du travail ou salaires ? → position 1 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 1, 85, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Baisse de 15 milliards de charges patronales pour les PME, augmentation du temps de travail au-delà de 35 heures, simplification des procédures de licenciement.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Aides sociales : conditionner ou garantir ? → position 2 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 2, 85, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Plafonnement de l'ensemble des prestations sociales à 70 % du SMIC et 15 heures d'activité hebdomadaires obligatoires pour les bénéficiaires du RSA.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Défense : Ukraine, Russie, OTAN → position 2 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 2, 75, $lr$https://politique-france.info/articles/retailleau-en-ukraine-un-virage-strategique-avant-2027$lr$, $lr$Retailleau à Kyiv, mai 2026$lr$, $lr$Déplacement à Kyiv en mai 2026 : « le combat des Ukrainiens est aussi le nôtre, celui de la liberté et de la souveraineté ». Soutien affirmé et réarmement, mais prudence assumée sur l'adhésion de l'Ukraine à l'Union et sur l'OTAN.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Prestations sociales : les Français d'abord ? → position 2 (90 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '72bcbe3e-95cc-497a-8722-fc693f20619f', 2, 90, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Délai de cinq ans de résidence et de travail avant l'accès des étrangers aux prestations sociales ; durcissement du regroupement familial.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '72bcbe3e-95cc-497a-8722-fc693f20619f', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Agriculture : produire ou transformer ? → position 1 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 1, 85, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Dérégulation agricole : suppression d'agences de contrôle environnemental et alignement des normes françaises sur le minimum européen.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- École : mérite ou égalité ? → position 1 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '4788e43e-8c98-417a-870a-03854f9388d9', 1, 85, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Une école et une société fondées sur le mérite, l'effort, la transmission et les valeurs collectives.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '4788e43e-8c98-417a-870a-03854f9388d9', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Logement : marché ou intervention publique ? → position 2 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 2, 70, $lr$https://www.lejdd.fr/politique/crise-demographique-retailleau-promet-un-plan-choc-pour-relancer-les-naissances-172836$lr$, $lr$Le JDD — plan natalité de Bruno Retailleau (avril 2026)$lr$, $lr$Faciliter l'accès au logement social pour les ménages modestes et permettre aux primo-accédants de déduire une partie des intérêts d'emprunt de leur impôt sur le revenu.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Famille : encourager la natalité ? → position 1 (90 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 1, 90, $lr$https://www.lejdd.fr/politique/crise-demographique-retailleau-promet-un-plan-choc-pour-relancer-les-naissances-172836$lr$, $lr$Le JDD — plan natalité de Bruno Retailleau (avril 2026)$lr$, $lr$Plan de relance de la natalité : « revenu familial » de 240 € par mois dès le premier enfant, congé de naissance, solutions de garde. Coût annoncé 40,3 milliards d'euros.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Institutions : exécutif fort ou pouvoir au peuple ? → position 1 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '106b1aff-a35e-47d3-b657-7b23676de380', 1, 80, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Opposition à une VIᵉ République, défense du 49.3, refus de la proportionnelle. Sa première action annoncée est une révision de la Constitution, par le haut.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '106b1aff-a35e-47d3-b657-7b23676de380', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Patrimoine et capital : protéger ou taxer ? → position 1 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 1, 85, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Opposition explicite à l'impôt sur la fortune et aux contributions sur les successions.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Immigration, pour ou contre ? → position 2 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '695341fc-7cd7-4c6e-b878-d158c856c748', 2, 80, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Réduction de l'immigration légale, fin du droit du sol, expulsion systématique des étrangers en situation irrégulière, délit de séjour irrégulier, naturalisation plus difficile.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '695341fc-7cd7-4c6e-b878-d158c856c748', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Nucléaire versus renouvelable → position 2 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'ac84a7ca-ae6a-4f46-8a1d-38a0c5b95f8d', 2, 75, $lr$https://republicains.fr/actualites/2026/08/09/face-au-rechauffement-climatique-adapter-la-france-plutot-que-punir/$lr$, $lr$Les Républicains — « Adapter la France plutôt que punir » (09/08/2026)$lr$, $lr$Le nucléaire est au cœur de la stratégie énergétique défendue ; Retailleau dénonce le subventionnement de l'éolien quand l'électricité se vend à prix négatif, « du gaspillage d'argent public ».$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'ac84a7ca-ae6a-4f46-8a1d-38a0c5b95f8d', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Déployer le nouveau nucléaire → position 2 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'bc398a58-4367-4dda-96aa-f0d15d47dd7b', 2, 70, $lr$https://republicains.fr/actualites/2026/08/09/face-au-rechauffement-climatique-adapter-la-france-plutot-que-punir/$lr$, $lr$Les Républicains — « Adapter la France plutôt que punir » (09/08/2026)$lr$, $lr$Défense du nucléaire et de la souveraineté énergétique, contre les « dogmes verts » ; relance assumée du parc, sans pour autant exclure toute autre production.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'bc398a58-4367-4dda-96aa-f0d15d47dd7b', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Production d'électricité → position 1 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '2836f26c-a14a-4f56-8673-7f74cbb99bed', 1, 65, $lr$https://republicains.fr/actualites/2026/08/09/face-au-rechauffement-climatique-adapter-la-france-plutot-que-punir/$lr$, $lr$Les Républicains — « Adapter la France plutôt que punir » (09/08/2026)$lr$, $lr$Stratégie centrée sur le parc nucléaire national, donc sur une production centralisée, et critique du soutien public à la production décentralisée intermittente.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '2836f26c-a14a-4f56-8673-7f74cbb99bed', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Renouvelables → position 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '500c6ae5-dfa5-4d65-9e10-3ee34b019775', 2, 55, $lr$https://republicains.fr/actualites/2026/08/09/face-au-rechauffement-climatique-adapter-la-france-plutot-que-punir/$lr$, $lr$Les Républicains — « Adapter la France plutôt que punir » (09/08/2026)$lr$, $lr$Critique du subventionnement de l'éolien, sans opposition de principe à toute énergie renouvelable : part limitée dans le mix, le nucléaire restant la colonne vertébrale.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '500c6ae5-dfa5-4d65-9e10-3ee34b019775', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Faut-il instaurer un revenu universel ? → position 5 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '8774b1e2-a0b4-4c66-a0ab-98cb5016c760', 5, 85, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Opposition au revenu universel : les prestations sont plafonnées à 70 % du SMIC et conditionnées à 15 heures d'activité, logique inverse d'un revenu inconditionnel.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '8774b1e2-a0b4-4c66-a0ab-98cb5016c760', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Qui finance le revenu universel ? → position 5 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '0c1399b4-e2e3-43a1-b466-97005f49cf52', 5, 60, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Refus des hausses d'impôts et priorité au désendettement : un revenu universel est présenté comme impayable dans ce cadre budgétaire.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '0c1399b4-e2e3-43a1-b466-97005f49cf52', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Montant du revenu universel → position 5 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '8344f91f-2765-468c-b41a-d8922a41c251', 5, 55, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Dans une doctrine qui plafonne les aides à 70 % du SMIC et refuse l'inconditionnalité, seul un montant de survie serait envisageable — la mesure n'est pas défendue.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '8344f91f-2765-468c-b41a-d8922a41c251', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Made in France → position 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'f6c2ae32-fa63-4e5c-955e-6d176dbd3392', 2, 55, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Libéralisme économique assumé et refus des aides aux grandes entreprises, avec protection des secteurs stratégiques et opposition aux accords jugés déloyaux pour l'agriculture.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'f6c2ae32-fa63-4e5c-955e-6d176dbd3392', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Mille feuilles administratif → position 4 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '8b57539f-c045-47f6-9cbd-6c79f0e0145f', 4, 55, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Suppression d'agences d'État, mais attachement aux collectivités locales : on clarifie les compétences plutôt qu'on supprime des échelons territoriaux.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '8b57539f-c045-47f6-9cbd-6c79f0e0145f', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Déficits publics → position 3 (50 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'af2fc1be-2174-43b8-a646-5a00f165c580', 3, 50, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Refus des dépenses d'investissement public qui creusent le déficit et priorité au redressement des comptes, sans pour autant proposer de sanctionner personnellement les ministres.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'af2fc1be-2174-43b8-a646-5a00f165c580', 3, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Progrès technologiques → position 4 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'c38f4891-7367-47ff-8d86-cdb7bc9da12a', 4, 60, $lr$https://republicains.fr/actualites/2026/08/09/face-au-rechauffement-climatique-adapter-la-france-plutot-que-punir/$lr$, $lr$Les Républicains — « Adapter la France plutôt que punir » (09/08/2026)$lr$, $lr$Écologie « du progrès, de la technologie et de la liberté », opposée à la décroissance : la technique est présentée comme la solution, pas comme le problème.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'c38f4891-7367-47ff-8d86-cdb7bc9da12a', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Travail = identité ou aliénation ? → position 1 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'a7a32da9-7c8c-4f4c-9149-baa8b19d39cb', 1, 65, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$La valeur travail est au cœur du projet : augmentation du temps de travail, baisse du coût du travail, écart affirmé entre revenus du travail et prestations.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'a7a32da9-7c8c-4f4c-9149-baa8b19d39cb', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Ce qui a fait ses preuves ou tout réinventer ? → position 2 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'ee999e5a-bccd-4286-bc84-526338af5f7b', 2, 60, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Droite conservatrice revendiquée : autorité, transmission, valeurs collectives, redressement — la référence est l'éprouvé plutôt que la table rase.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'ee999e5a-bccd-4286-bc84-526338af5f7b', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- C'était mieux avant ? → position 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'd5f208c2-7ccc-47ee-a2f5-92d76e9be4a0', 2, 55, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Discours de redressement national et de restauration de l'autorité, qui pose un déclin par rapport au passé sans être passéiste sur la technique.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', 'd5f208c2-7ccc-47ee-a2f5-92d76e9be4a0', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- École : emploi ou mission perso ? → position 2 (50 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '833dfe36-2c47-44ec-959a-dcca545a8a08', 2, 50, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$École du mérite, de l'effort et de la transmission, orientée vers l'insertion et l'exigence plutôt que vers l'épanouissement personnel.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '833dfe36-2c47-44ec-959a-dcca545a8a08', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Voiture électrique → position 2 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '5b4152af-6743-4a5a-ba0c-7b71e1b41fd7', 2, 60, $lr$https://republicains.fr/actualites/2026/08/09/face-au-rechauffement-climatique-adapter-la-france-plutot-que-punir/$lr$, $lr$Les Républicains — « Adapter la France plutôt que punir » (09/08/2026)$lr$, $lr$Abandon demandé de l'interdiction des véhicules thermiques en 2035, fin des pénalités fiscales sur l'automobile, suspension des ZFE : forte réserve sur le tout-électrique imposé.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '5b4152af-6743-4a5a-ba0c-7b71e1b41fd7', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Réseaux sociaux → position 4 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '84a4ef57-c68c-4fe3-b5ac-db7e4fb9a5df', 4, 55, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Ligne de fermeté sur la protection des mineurs et l'ordre public en ligne : les réseaux sociaux sont traités comme un risque à encadrer.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '84a4ef57-c68c-4fe3-b5ac-db7e4fb9a5df', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Peur des étrangers ? → position 3 (50 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '9f80cbde-5663-45a3-86e1-6a04dd3c961d', 3, 50, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Le discours porte sur la maîtrise des flux, l'assimilation et l'ordre public, pas sur une hostilité affichée envers les étrangers eux-mêmes.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '9f80cbde-5663-45a3-86e1-6a04dd3c961d', 3, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- IA militaire et armes autonomes → position 4 (50 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '238575df-3c71-4f80-9de9-d128b2028095', 4, 50, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Doctrine de défense classique attachée au commandement et à la responsabilité humaine ; aucun soutien à une délégation de la décision de tir à une machine.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '238575df-3c71-4f80-9de9-d128b2028095', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Faut il créer sa boîte ? → position 5 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '745dbcc0-8985-410b-947a-01309fca3626', 5, 55, $lr$https://monvote2027.fr/candidat/retailleau$lr$, $lr$Programme Retailleau 2027 — synthèse par thème$lr$, $lr$Défense revendiquée des libertés économiques et de l'entreprise, allègement des charges des PME, simplification : l'entrepreneuriat est encouragé.$lr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('daf1097b-0f06-4a75-a3fb-e6ae1a99b1c1', '745dbcc0-8985-410b-947a-01309fca3626', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

commit;
