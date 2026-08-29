-- Parti socialiste et Renaissance : fiches publiques + positions recherchées
-- à la main (Claude, 2026-08-29), sur le même périmètre que Les Républicains.
-- Chaque position porte sa source et son taux de certitude dans mv_recherches.
begin;

insert into mv_personnes (id, prenom, nom, email, commentaire, type_entite, est_public, created_by)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '', $ps$Parti socialiste$ps$, '', $ps$Parti socialiste français, dirigé par Olivier Faure. Gauche social-démocrate, distincte de La France insoumise sur l'Europe, le nucléaire et l'économie.$ps$, 'morale', true, 'greg@starvolt.fr')
on conflict (id) do update set commentaire = excluded.commentaire, est_public = true;

insert into mv_personnes (id, prenom, nom, email, commentaire, type_entite, est_public, created_by)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '', $ps$Renaissance$ps$, '', $ps$Le parti présidentiel fondé par Emmanuel Macron, dirigé par Gabriel Attal. Centre libéral, européen et réformateur.$ps$, 'morale', true, 'greg@starvolt.fr')
on conflict (id) do update set commentaire = excluded.commentaire, est_public = true;

-- Retraites : à quel âge s'arrêter ? → 4 (90 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 4, 90, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Abrogation de la réforme Borne et retour à 62 ans, durée de cotisation de 43 ans « réductible selon la pénibilité », refus de la capitalisation.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Impôts : baisser ou redistribuer ? → 4 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '488be11b-5a34-4231-9562-60ee78628488', 4, 80, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Rétablissement de l'impôt sur la fortune, présenté comme rapportant 15 milliards d'euros par an, et taxation des patrimoines au-delà de 2 millions.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '488be11b-5a34-4231-9562-60ee78628488', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Patrimoine et capital : protéger ou taxer ? → 4 (90 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 4, 90, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Retour de l'ISF pour 15 milliards d'euros et taxation des successions au-dessus de 2 millions d'euros.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Travail : coût du travail ou salaires ? → 4 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 4, 85, $ps$https://lcp.fr/actualites/smic-retraites-immigration-le-ps-presente-un-projet-de-144-pages-pour-preparer-2027$ps$, $ps$LCP — le projet du PS en 144 pages pour 2027$ps$, $ps$Hausse significative du SMIC et refus d'allonger la durée légale du travail au-delà de 35 heures, défendues comme un acquis social.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Immigration, pour ou contre ? → 4 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '695341fc-7cd7-4c6e-b878-d158c856c748', 4, 80, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Opposition aux restrictions de l'immigration légale, facilitation du regroupement familial, refus de l'expulsion systématique, droit de vote des étrangers aux élections locales.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '695341fc-7cd7-4c6e-b878-d158c856c748', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Prestations sociales : les Français d'abord ? → 4 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '72bcbe3e-95cc-497a-8722-fc693f20619f', 4, 70, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Refus des dérogations aux engagements européens au prétexte migratoire et défense de l'égalité de traitement des résidents étrangers.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '72bcbe3e-95cc-497a-8722-fc693f20619f', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Europe : nation ou fédération ? → 4 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 4, 80, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Parti résolument européen : opposition à toute dérogation aux engagements européens, y compris à la Convention européenne des droits de l'homme.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Nucléaire versus renouvelable → 4 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'ac84a7ca-ae6a-4f46-8a1d-38a0c5b95f8d', 4, 85, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Opposition à l'extension du parc nucléaire, vote contre les projets EPR2, transition vers un mix « 100 % décarboné en 2050 » par les renouvelables.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'ac84a7ca-ae6a-4f46-8a1d-38a0c5b95f8d', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Déployer le nouveau nucléaire → 4 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'bc398a58-4367-4dda-96aa-f0d15d47dd7b', 4, 85, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Vote contre les réacteurs EPR2 : la priorité va au développement des renouvelables plutôt qu'à un nouveau parc nucléaire.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'bc398a58-4367-4dda-96aa-f0d15d47dd7b', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Production d'électricité → 3 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '2836f26c-a14a-4f56-8673-7f74cbb99bed', 3, 55, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Sortie de la logique de marché pour l'électricité et montée des renouvelables, qui suppose une production plus répartie sans abandon du parc existant.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '2836f26c-a14a-4f56-8673-7f74cbb99bed', 3, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Renouvelables → 4 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '500c6ae5-dfa5-4d65-9e10-3ee34b019775', 4, 75, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Trajectoire vers un mix « 100 % décarboné en 2050 » adossée aux renouvelables plutôt qu'à un nouveau nucléaire.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '500c6ae5-dfa5-4d65-9e10-3ee34b019775', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Climat : s'adapter ou tout transformer ? → 4 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 4, 80, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Planification de la sortie des énergies fossiles et sortie de l'électricité de la logique de marché : une transformation organisée par la puissance publique.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Institutions : exécutif fort ou pouvoir au peuple ? → 4 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '106b1aff-a35e-47d3-b657-7b23676de380', 4, 85, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Suppression du 49.3 pour renforcer le Parlement, droit de vote à 16 ans, sans se rallier à une VIᵉ République.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '106b1aff-a35e-47d3-b657-7b23676de380', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Défense : Ukraine, Russie, OTAN → 2 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 2, 70, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Soutien militaire à l'Ukraine et à la coopération européenne de défense, position assumée comme proche de celle de l'exécutif sur ce sujet.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Pouvoir d'achat : détaxer ou encadrer ? → 4 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 4, 60, $ps$https://lcp.fr/actualites/smic-retraites-immigration-le-ps-presente-un-projet-de-144-pages-pour-preparer-2027$ps$, $ps$LCP — le projet du PS en 144 pages pour 2027$ps$, $ps$Suppression de la TVA sur les produits de première nécessité et hausse du SMIC : on agit à la fois sur les prix de l'essentiel et sur les revenus.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Aides sociales : conditionner ou garantir ? → 4 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 4, 65, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Opposition à la conditionnalité des minima sociaux et priorité donnée à la lutte contre le non-recours plutôt qu'au contrôle des allocataires.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- École : mérite ou égalité ? → 4 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '4788e43e-8c98-417a-870a-03854f9388d9', 4, 70, $ps$https://lcp.fr/actualites/smic-retraites-immigration-le-ps-presente-un-projet-de-144-pages-pour-preparer-2027$ps$, $ps$LCP — le projet du PS en 144 pages pour 2027$ps$, $ps$Priorité à la réduction des inégalités scolaires et aux moyens pour les établissements les plus en difficulté.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '4788e43e-8c98-417a-870a-03854f9388d9', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Logement : marché ou intervention publique ? → 4 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 4, 70, $ps$https://lcp.fr/actualites/smic-retraites-immigration-le-ps-presente-un-projet-de-144-pages-pour-preparer-2027$ps$, $ps$LCP — le projet du PS en 144 pages pour 2027$ps$, $ps$Encadrement des loyers et relance du logement social : le logement est traité comme un besoin à réguler, pas comme un marché.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Sécurité et justice : punir ou prévenir ? → 4 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 4, 60, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Attachement à l'État de droit et aux libertés publiques, priorité à la prévention et à la réinsertion, sans renoncer à la sanction des faits graves.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Agriculture : produire ou transformer ? → 4 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 4, 65, $ps$https://lcp.fr/actualites/smic-retraites-immigration-le-ps-presente-un-projet-de-144-pages-pour-preparer-2027$ps$, $ps$LCP — le projet du PS en 144 pages pour 2027$ps$, $ps$Transition agroécologique accompagnée financièrement, avec des objectifs de réduction des intrants et des clauses de réciprocité aux frontières.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Famille : encourager la natalité ? → 4 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 4, 55, $ps$https://lcp.fr/actualites/smic-retraites-immigration-le-ps-presente-un-projet-de-144-pages-pour-preparer-2027$ps$, $ps$LCP — le projet du PS en 144 pages pour 2027$ps$, $ps$Politique familiale orientée vers l'égalité et le soutien aux familles monoparentales plutôt que vers un objectif de natalité.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Made in France → 4 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'f6c2ae32-fa63-4e5c-955e-6d176dbd3392', 4, 60, $ps$https://lcp.fr/actualites/smic-retraites-immigration-le-ps-presente-un-projet-de-144-pages-pour-preparer-2027$ps$, $ps$LCP — le projet du PS en 144 pages pour 2027$ps$, $ps$Préférence européenne et clauses miroirs pour protéger l'industrie et l'agriculture, sans fermeture complète des frontières commerciales.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'f6c2ae32-fa63-4e5c-955e-6d176dbd3392', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Déficits publics → 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'af2fc1be-2174-43b8-a646-5a00f165c580', 2, 55, $ps$https://lcp.fr/actualites/smic-retraites-immigration-le-ps-presente-un-projet-de-144-pages-pour-preparer-2027$ps$, $ps$LCP — le projet du PS en 144 pages pour 2027$ps$, $ps$Priorité à l'investissement public et à la redistribution plutôt qu'au retour rapide à l'équilibre ; aucune sanction personnelle des ministres proposée.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'af2fc1be-2174-43b8-a646-5a00f165c580', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Faut-il instaurer un revenu universel ? → 4 (50 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '8774b1e2-a0b4-4c66-a0ab-98cb5016c760', 4, 50, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Le PS d'Olivier Faure privilégie le renforcement des minima sociaux existants et l'automatisation des droits plutôt qu'un revenu universel.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '8774b1e2-a0b4-4c66-a0ab-98cb5016c760', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Mille feuilles administratif → 4 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '8b57539f-c045-47f6-9cbd-6c79f0e0145f', 4, 55, $ps$https://lcp.fr/actualites/smic-retraites-immigration-le-ps-presente-un-projet-de-144-pages-pour-preparer-2027$ps$, $ps$LCP — le projet du PS en 144 pages pour 2027$ps$, $ps$Attachement aux collectivités locales et à la décentralisation : on clarifie les compétences plutôt qu'on supprime des échelons.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '8b57539f-c045-47f6-9cbd-6c79f0e0145f', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Travail = identité ou aliénation ? → 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'a7a32da9-7c8c-4f4c-9149-baa8b19d39cb', 2, 55, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Le travail est défendu comme structurant et protecteur — les 35 heures sont revendiquées comme un acquis — sans en faire toute l'identité.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'a7a32da9-7c8c-4f4c-9149-baa8b19d39cb', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- C'était mieux avant ? → 4 (50 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'd5f208c2-7ccc-47ee-a2f5-92d76e9be4a0', 4, 50, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Discours de progrès et d'extension des droits (droit de vote à 16 ans, droits des résidents étrangers), pas de nostalgie revendiquée.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', 'd5f208c2-7ccc-47ee-a2f5-92d76e9be4a0', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Voiture électrique → 4 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '5b4152af-6743-4a5a-ba0c-7b71e1b41fd7', 4, 55, $ps$https://monvote2027.fr/candidat/faure$ps$, $ps$MonVote2027 — positions d'Olivier Faure (PS)$ps$, $ps$Soutien à la décarbonation des transports dans une trajectoire « 100 % décarboné en 2050 », avec accompagnement social de la bascule.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('3f5d2c18-6a41-4e7b-9c0d-8b2e1f4a7d63', '5b4152af-6743-4a5a-ba0c-7b71e1b41fd7', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Retraites : à quel âge s'arrêter ? → 2 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 2, 65, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Renaissance assume la réforme portée à 64 ans ; Attal propose d'aller plus loin en supprimant l'âge légal fixe, avec décote pour un départ anticipé et surcote au-delà, plus une part de capitalisation.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Impôts : baisser ou redistribuer ? → 2 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '488be11b-5a34-4231-9562-60ee78628488', 2, 85, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$« Pas de hausse d'impôts » comme engagement de campagne, opposition au rétablissement de l'ISF, baisse des cotisations patronales et règle d'or budgétaire.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '488be11b-5a34-4231-9562-60ee78628488', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Patrimoine et capital : protéger ou taxer ? → 2 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 2, 80, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Opposition explicite à l'impôt sur la fortune et à son rétablissement, priorité donnée à l'investissement productif.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Déficits publics → 4 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'af2fc1be-2174-43b8-a646-5a00f165c580', 4, 55, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Proposition d'inscrire une règle d'or budgétaire dans la Constitution pour interdire les budgets en déficit — une contrainte automatique, sans sanction personnelle des ministres.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'af2fc1be-2174-43b8-a646-5a00f165c580', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Europe : nation ou fédération ? → 4 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 4, 85, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Ligne résolument européenne et atlantiste, portée comme un marqueur central du projet.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Défense : Ukraine, Russie, OTAN → 1 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 1, 85, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Soutien appuyé à l'Ukraine, alignement sur l'OTAN et hausse de l'effort de défense vers 3 % du PIB.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Nucléaire versus renouvelable → 2 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'ac84a7ca-ae6a-4f46-8a1d-38a0c5b95f8d', 2, 85, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Le nucléaire est défendu comme « une fierté française », avec la construction de 14 nouveaux réacteurs, tout en poursuivant le développement des renouvelables.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'ac84a7ca-ae6a-4f46-8a1d-38a0c5b95f8d', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Déployer le nouveau nucléaire → 2 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'bc398a58-4367-4dda-96aa-f0d15d47dd7b', 2, 85, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Construction de 14 nouveaux réacteurs, adossée à un mix qui conserve les renouvelables.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'bc398a58-4367-4dda-96aa-f0d15d47dd7b', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Renouvelables → 3 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '500c6ae5-dfa5-4d65-9e10-3ee34b019775', 3, 60, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Mix combinant nucléaire et renouvelables, avec l'objectif de produire davantage d'énergie en France : les renouvelables complètent le parc sans le remplacer.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '500c6ae5-dfa5-4d65-9e10-3ee34b019775', 3, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Production d'électricité → 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '2836f26c-a14a-4f56-8673-7f74cbb99bed', 2, 55, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Stratégie adossée à un grand parc nucléaire national, complétée par des productions réparties.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '2836f26c-a14a-4f56-8673-7f74cbb99bed', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Immigration, pour ou contre ? → 3 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '695341fc-7cd7-4c6e-b878-d158c856c748', 3, 70, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Immigration maîtrisée et orientée vers le travail : quotas d'immigration économique votés chaque année au Parlement, regroupement familial resserré, expulsion de ceux « qui n'ont pas vocation à rester » — mais refus de supprimer le droit du sol.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '695341fc-7cd7-4c6e-b878-d158c856c748', 3, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Prestations sociales : les Français d'abord ? → 3 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '72bcbe3e-95cc-497a-8722-fc693f20619f', 3, 60, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Logique de contribution et de travail plutôt que de nationalité : l'accès aux droits est lié à l'activité, sans priorité nationale affichée.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '72bcbe3e-95cc-497a-8722-fc693f20619f', 3, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Sécurité et justice : punir ou prévenir ? → 2 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 2, 75, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Durcissement des peines pour les faits violents et les mineurs récidivistes de plus de 16 ans, suppression des aménagements de peine pour que les peines soient exécutées.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- École : mérite ou égalité ? → 2 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '4788e43e-8c98-417a-870a-03854f9388d9', 2, 80, $ps$https://www.elyseescope.com/le-radar/gabriel-attal-programme-propositions-presidentielle-2027$ps$, $ps$ÉlyséeScope — programme de Gabriel Attal$ps$, $ps$Ligne du « choc des savoirs » portée comme ministre de l'Éducation : retour aux fondamentaux, autorité, expérimentation de l'uniforme.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '4788e43e-8c98-417a-870a-03854f9388d9', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Aides sociales : conditionner ou garantir ? → 2 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 2, 80, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Conditionnalité assumée du RSA à des heures d'activité hebdomadaires, dans la continuité de la loi pour le plein emploi.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Travail : coût du travail ou salaires ? → 2 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 2, 75, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Baisse des cotisations patronales et valorisation du travail comme leviers du plein emploi, plutôt que hausse administrée des salaires.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Pouvoir d'achat : détaxer ou encadrer ? → 2 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 2, 60, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Refus des hausses d'impôts et allègements ciblés plutôt qu'encadrement des prix ou revalorisation générale des salaires.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Climat : s'adapter ou tout transformer ? → 3 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 3, 70, $ps$https://www.elyseescope.com/le-radar/gabriel-attal-programme-propositions-presidentielle-2027$ps$, $ps$ÉlyséeScope — programme de Gabriel Attal$ps$, $ps$Écologie présentée comme pragmatique : planification et technologie, en évitant aussi bien l'inaction que les ruptures brutales pour les ménages.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 3, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Logement : marché ou intervention publique ? → 3 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 3, 60, $ps$https://www.elyseescope.com/le-radar/gabriel-attal-programme-propositions-presidentielle-2027$ps$, $ps$ÉlyséeScope — programme de Gabriel Attal$ps$, $ps$Fonds public pour rénover 300 000 logements d'ici 2027, financé par une taxe sur les rachats d'actions : intervention ciblée, sans encadrement général des loyers.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 3, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Famille : encourager la natalité ? → 2 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 2, 65, $ps$https://www.elyseescope.com/le-radar/gabriel-attal-programme-propositions-presidentielle-2027$ps$, $ps$ÉlyséeScope — programme de Gabriel Attal$ps$, $ps$Ligne du « réarmement démographique » portée par la majorité présidentielle : congé de naissance et soutien aux familles, sans injonction.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Institutions : exécutif fort ou pouvoir au peuple ? → 2 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '106b1aff-a35e-47d3-b657-7b23676de380', 2, 65, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Attachement aux institutions de la Vᵉ République et à la stabilité de l'exécutif, avec une ouverture limitée à la proportionnelle.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '106b1aff-a35e-47d3-b657-7b23676de380', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Agriculture : produire ou transformer ? → 3 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 3, 65, $ps$https://www.elyseescope.com/le-radar/gabriel-attal-programme-propositions-presidentielle-2027$ps$, $ps$ÉlyséeScope — programme de Gabriel Attal$ps$, $ps$Simplification des normes et soutien au revenu agricole, tout en maintenant une trajectoire de transition : un changement au rythme des solutions disponibles.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 3, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Made in France → 3 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'f6c2ae32-fa63-4e5c-955e-6d176dbd3392', 3, 55, $ps$https://www.elyseescope.com/le-radar/gabriel-attal-programme-propositions-presidentielle-2027$ps$, $ps$ÉlyséeScope — programme de Gabriel Attal$ps$, $ps$Souveraineté industrielle et préférence européenne assumées, dans un cadre qui reste celui du marché ouvert.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'f6c2ae32-fa63-4e5c-955e-6d176dbd3392', 3, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Faut-il instaurer un revenu universel ? → 4 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '8774b1e2-a0b4-4c66-a0ab-98cb5016c760', 4, 55, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Priorité à la « solidarité à la source » et aux minima ciblés conditionnés à l'activité, pas à un revenu inconditionnel.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '8774b1e2-a0b4-4c66-a0ab-98cb5016c760', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Mille feuilles administratif → 4 (50 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '8b57539f-c045-47f6-9cbd-6c79f0e0145f', 4, 50, $ps$https://www.elyseescope.com/le-radar/gabriel-attal-programme-propositions-presidentielle-2027$ps$, $ps$ÉlyséeScope — programme de Gabriel Attal$ps$, $ps$Simplification administrative et réduction du nombre d'agences de l'État, sans suppression d'échelons territoriaux.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '8b57539f-c045-47f6-9cbd-6c79f0e0145f', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Travail = identité ou aliénation ? → 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'a7a32da9-7c8c-4f4c-9149-baa8b19d39cb', 2, 55, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$La valeur travail structure le projet — plein emploi, conditionnalité des aides — sans en faire l'unique horizon.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'a7a32da9-7c8c-4f4c-9149-baa8b19d39cb', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Progrès technologiques → 4 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'c38f4891-7367-47ff-8d86-cdb7bc9da12a', 4, 60, $ps$https://www.elyseescope.com/le-radar/gabriel-attal-programme-propositions-presidentielle-2027$ps$, $ps$ÉlyséeScope — programme de Gabriel Attal$ps$, $ps$Discours de progrès et de souveraineté technologique, l'intelligence artificielle étant présentée comme une chance à saisir.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'c38f4891-7367-47ff-8d86-cdb7bc9da12a', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Réseaux sociaux → 4 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '84a4ef57-c68c-4fe3-b5ac-db7e4fb9a5df', 4, 70, $ps$https://www.elyseescope.com/le-radar/gabriel-attal-programme-propositions-presidentielle-2027$ps$, $ps$ÉlyséeScope — programme de Gabriel Attal$ps$, $ps$Ligne de fermeté sur l'exposition des mineurs aux réseaux sociaux, traités comme un risque à encadrer.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '84a4ef57-c68c-4fe3-b5ac-db7e4fb9a5df', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Voiture électrique → 4 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '5b4152af-6743-4a5a-ba0c-7b71e1b41fd7', 4, 65, $ps$https://www.elyseescope.com/le-radar/gabriel-attal-programme-propositions-presidentielle-2027$ps$, $ps$ÉlyséeScope — programme de Gabriel Attal$ps$, $ps$Soutien assumé à l'électrification du parc automobile, avec des dispositifs d'accès pour les ménages modestes.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '5b4152af-6743-4a5a-ba0c-7b71e1b41fd7', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- C'était mieux avant ? → 4 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'd5f208c2-7ccc-47ee-a2f5-92d76e9be4a0', 4, 55, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Ligne progressiste et réformatrice revendiquée, tournée vers le progrès plutôt que vers la restauration d'un ordre ancien.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', 'd5f208c2-7ccc-47ee-a2f5-92d76e9be4a0', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Faut il créer sa boîte ? → 5 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '745dbcc0-8985-410b-947a-01309fca3626', 5, 60, $ps$https://monvote2027.fr/candidat/attal$ps$, $ps$MonVote2027 — positions de Gabriel Attal (Renaissance)$ps$, $ps$Culture entrepreneuriale revendiquée depuis « start-up nation » : allègement des charges et encouragement à créer son activité.$ps$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('6c9a4e37-2d58-4f1a-b83e-5a7c0d9e2b41', '745dbcc0-8985-410b-947a-01309fca3626', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

commit;
