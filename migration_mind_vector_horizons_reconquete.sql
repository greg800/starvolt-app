-- Horizons et Reconquête : fiches publiques + positions recherchées à la main
-- (Claude, 2026-08-29), sur le même périmètre que les autres partis.
begin;

insert into mv_personnes (id, prenom, nom, email, commentaire, type_entite, est_public, created_by)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '', $hr$Horizons$hr$, '', $hr$Parti fondé par Édouard Philippe, ancien Premier ministre. Droite libérale, européenne et réformatrice, alliée puis distincte de la majorité présidentielle.$hr$, 'morale', true, 'greg@starvolt.fr')
on conflict (id) do update set commentaire = excluded.commentaire, est_public = true;

insert into mv_personnes (id, prenom, nom, email, commentaire, type_entite, est_public, created_by)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '', $hr$Reconquête$hr$, '', $hr$Parti fondé par Éric Zemmour. Extrême droite identitaire, qui fait de l'immigration et de l'identité française l'axe central de son projet.$hr$, 'morale', true, 'greg@starvolt.fr')
on conflict (id) do update set commentaire = excluded.commentaire, est_public = true;

-- Retraites : à quel âge s'arrêter ? → 1 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 1, 65, $hr$https://monvote2027.fr/candidat/philippe$hr$, $hr$MonVote2027 — positions d'Édouard Philippe (Horizons)$hr$, $hr$Report de l'âge de départ vers 65-67 ans et introduction d'une part de capitalisation de 10 à 15 % ; le financement doit s'équilibrer sans recours à la dette, avec un bonus pour ceux qui travaillent plus longtemps.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Impôts : baisser ou redistribuer ? → 1 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '488be11b-5a34-4231-9562-60ee78628488', 1, 75, $hr$https://www.elyseescope.com/le-radar/edouard-philippe-programme-presidentielle-2027$hr$, $hr$ÉlyséeScope — programme d'Édouard Philippe$hr$, $hr$« Deal fiscal » de 250 milliards : baisse de 50 milliards par an des impôts de production pendant cinq ans, en échange d'investissements industriels.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '488be11b-5a34-4231-9562-60ee78628488', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Patrimoine et capital : protéger ou taxer ? → 1 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 1, 85, $hr$https://monvote2027.fr/candidat/philippe$hr$, $hr$MonVote2027 — positions d'Édouard Philippe (Horizons)$hr$, $hr$Opposition à l'impôt sur la fortune comme aux prélèvements sur les successions.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Déficits publics → 4 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'af2fc1be-2174-43b8-a646-5a00f165c580', 4, 60, $hr$https://www.elyseescope.com/le-radar/edouard-philippe-programme-presidentielle-2027$hr$, $hr$ÉlyséeScope — programme d'Édouard Philippe$hr$, $hr$« Règle d'or » inscrite dans la Constitution interdisant de financer les dépenses courantes par la dette, et déficit ramené sous 3 % du PIB en 2030.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'af2fc1be-2174-43b8-a646-5a00f165c580', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Europe : nation ou fédération ? → 4 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 4, 85, $hr$https://www.elyseescope.com/le-radar/edouard-philippe-programme-presidentielle-2027$hr$, $hr$ÉlyséeScope — programme d'Édouard Philippe$hr$, $hr$Ancrage européen revendiqué, opposition ferme à toute sortie de l'Union, et autonomie économique et technologique de l'Europe face aux États-Unis et à la Chine.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Défense : Ukraine, Russie, OTAN → 2 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 2, 70, $hr$https://www.elyseescope.com/le-radar/edouard-philippe-programme-presidentielle-2027$hr$, $hr$ÉlyséeScope — programme d'Édouard Philippe$hr$, $hr$Réarmement des forces françaises et autonomie stratégique européenne, dans un cadre atlantiste assumé.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Nucléaire versus renouvelable → 2 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'ac84a7ca-ae6a-4f46-8a1d-38a0c5b95f8d', 2, 80, $hr$https://www.elyseescope.com/le-radar/edouard-philippe-programme-presidentielle-2027$hr$, $hr$ÉlyséeScope — programme d'Édouard Philippe$hr$, $hr$Relance massive du nucléaire — six à huit nouveaux EPR — présentée comme le pilier de la souveraineté énergétique, avec opposition aux objectifs progressifs d'énergies renouvelables.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'ac84a7ca-ae6a-4f46-8a1d-38a0c5b95f8d', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Déployer le nouveau nucléaire → 2 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'bc398a58-4367-4dda-96aa-f0d15d47dd7b', 2, 85, $hr$https://www.elyseescope.com/le-radar/edouard-philippe-programme-presidentielle-2027$hr$, $hr$ÉlyséeScope — programme d'Édouard Philippe$hr$, $hr$Six à huit nouveaux réacteurs EPR, pilier de la stratégie énergétique.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'bc398a58-4367-4dda-96aa-f0d15d47dd7b', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Renouvelables → 2 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '500c6ae5-dfa5-4d65-9e10-3ee34b019775', 2, 60, $hr$https://monvote2027.fr/candidat/philippe$hr$, $hr$MonVote2027 — positions d'Édouard Philippe (Horizons)$hr$, $hr$Opposition aux objectifs progressifs d'énergies renouvelables, le nucléaire restant la colonne vertébrale du mix.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '500c6ae5-dfa5-4d65-9e10-3ee34b019775', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Production d'électricité → 1 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '2836f26c-a14a-4f56-8673-7f74cbb99bed', 1, 60, $hr$https://www.elyseescope.com/le-radar/edouard-philippe-programme-presidentielle-2027$hr$, $hr$ÉlyséeScope — programme d'Édouard Philippe$hr$, $hr$Stratégie adossée à un grand parc nucléaire national, donc à une production centralisée.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '2836f26c-a14a-4f56-8673-7f74cbb99bed', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Immigration, pour ou contre ? → 2 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '695341fc-7cd7-4c6e-b878-d158c856c748', 2, 80, $hr$https://monvote2027.fr/candidat/philippe$hr$, $hr$MonVote2027 — positions d'Édouard Philippe (Horizons)$hr$, $hr$Immigration « maîtrisée » orientée vers le travail : quotas votés au Parlement, regroupement familial resserré, fin de l'accord de 1968 avec l'Algérie, expulsion systématique des personnes en situation irrégulière, refus du droit de vote des étrangers.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '695341fc-7cd7-4c6e-b878-d158c856c748', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Prestations sociales : les Français d'abord ? → 2 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '72bcbe3e-95cc-497a-8722-fc693f20619f', 2, 60, $hr$https://monvote2027.fr/candidat/philippe$hr$, $hr$MonVote2027 — positions d'Édouard Philippe (Horizons)$hr$, $hr$Transformation de l'aide médicale d'État en aide d'urgence : l'accès des étrangers aux dispositifs sociaux est restreint sans être conditionné à la nationalité.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '72bcbe3e-95cc-497a-8722-fc693f20619f', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Sécurité et justice : punir ou prévenir ? → 1 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 1, 70, $hr$https://monvote2027.fr/candidat/philippe$hr$, $hr$MonVote2027 — positions d'Édouard Philippe (Horizons)$hr$, $hr$Peines planchers pour les récidivistes, jugement comme majeurs de certains mineurs de plus de 16 ans, augmentation des capacités carcérales.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Travail : coût du travail ou salaires ? → 2 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 2, 70, $hr$https://monvote2027.fr/candidat/philippe$hr$, $hr$MonVote2027 — positions d'Édouard Philippe (Horizons)$hr$, $hr$Opposition à une hausse significative du SMIC et priorité donnée à la baisse des prélèvements sur les entreprises et à l'emploi.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Aides sociales : conditionner ou garantir ? → 2 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 2, 65, $hr$https://monvote2027.fr/candidat/philippe$hr$, $hr$MonVote2027 — positions d'Édouard Philippe (Horizons)$hr$, $hr$Priorité aux politiques de retour à l'emploi plutôt qu'aux versements directs, et opposition à un revenu inconditionnel.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Faut-il instaurer un revenu universel ? → 5 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '8774b1e2-a0b4-4c66-a0ab-98cb5016c760', 5, 75, $hr$https://monvote2027.fr/candidat/philippe$hr$, $hr$MonVote2027 — positions d'Édouard Philippe (Horizons)$hr$, $hr$Opposition explicite au revenu universel, jugé moins efficace qu'une politique centrée sur l'emploi.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '8774b1e2-a0b4-4c66-a0ab-98cb5016c760', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Climat : s'adapter ou tout transformer ? → 2 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 2, 60, $hr$https://monvote2027.fr/candidat/philippe$hr$, $hr$MonVote2027 — positions d'Édouard Philippe (Horizons)$hr$, $hr$Décarbonation par le nucléaire et la technologie, avec des votes contre les contraintes environnementales pesant sur l'agriculture et contre les objectifs progressifs d'énergies renouvelables.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Agriculture : produire ou transformer ? → 2 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 2, 70, $hr$https://monvote2027.fr/candidat/philippe$hr$, $hr$MonVote2027 — positions d'Édouard Philippe (Horizons)$hr$, $hr$Votes contre les contraintes environnementales sur l'agriculture intensive et contre les restrictions d'usage des pesticides.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Institutions : exécutif fort ou pouvoir au peuple ? → 1 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '106b1aff-a35e-47d3-b657-7b23676de380', 1, 80, $hr$https://monvote2027.fr/candidat/philippe$hr$, $hr$MonVote2027 — positions d'Édouard Philippe (Horizons)$hr$, $hr$Opposition à la proportionnelle et au référendum d'initiative citoyenne, préférence pour le fait majoritaire, usage assumé du 49.3 lorsqu'il était Premier ministre.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '106b1aff-a35e-47d3-b657-7b23676de380', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Pouvoir d'achat : détaxer ou encadrer ? → 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 2, 55, $hr$https://www.elyseescope.com/le-radar/edouard-philippe-programme-presidentielle-2027$hr$, $hr$ÉlyséeScope — programme d'Édouard Philippe$hr$, $hr$Le pouvoir d'achat passe par la baisse des prélèvements et le retour à l'emploi, pas par l'encadrement des prix ni par la hausse administrée des salaires.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Made in France → 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'f6c2ae32-fa63-4e5c-955e-6d176dbd3392', 2, 55, $hr$https://www.elyseescope.com/le-radar/edouard-philippe-programme-presidentielle-2027$hr$, $hr$ÉlyséeScope — programme d'Édouard Philippe$hr$, $hr$Économie de marché et ancrage européen, avec une autonomie industrielle recherchée à l'échelle européenne plutôt que par la fermeture.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'f6c2ae32-fa63-4e5c-955e-6d176dbd3392', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Travail = identité ou aliénation ? → 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'a7a32da9-7c8c-4f4c-9149-baa8b19d39cb', 2, 55, $hr$https://monvote2027.fr/candidat/philippe$hr$, $hr$MonVote2027 — positions d'Édouard Philippe (Horizons)$hr$, $hr$Le travail structure le projet — emploi plutôt que transferts, incitations à travailler plus longtemps — sans en faire l'unique horizon.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'a7a32da9-7c8c-4f4c-9149-baa8b19d39cb', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Progrès technologiques → 4 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'c38f4891-7367-47ff-8d86-cdb7bc9da12a', 4, 55, $hr$https://www.elyseescope.com/le-radar/edouard-philippe-programme-presidentielle-2027$hr$, $hr$ÉlyséeScope — programme d'Édouard Philippe$hr$, $hr$Souveraineté technologique et réindustrialisation présentées comme la réponse, la technique étant traitée comme une solution.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', 'c38f4891-7367-47ff-8d86-cdb7bc9da12a', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Faut il créer sa boîte ? → 5 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '745dbcc0-8985-410b-947a-01309fca3626', 5, 55, $hr$https://www.elyseescope.com/le-radar/edouard-philippe-programme-presidentielle-2027$hr$, $hr$ÉlyséeScope — programme d'Édouard Philippe$hr$, $hr$Baisse massive des impôts de production en échange d'investissements : l'initiative économique privée est le moteur revendiqué du projet.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('b1e7d3c9-4a26-4f80-9d15-7c3b2e6a8f04', '745dbcc0-8985-410b-947a-01309fca3626', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Immigration, pour ou contre ? → 1 (95 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '695341fc-7cd7-4c6e-b878-d158c856c748', 1, 95, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$« Immigration zéro » : arrêt de l'immigration extra-européenne, remigration, suppression du regroupement familial, droit d'asile limité à une centaine de personnes par an et déposé dans les consulats, fin du droit du sol.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '695341fc-7cd7-4c6e-b878-d158c856c748', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Prestations sociales : les Français d'abord ? → 1 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '72bcbe3e-95cc-497a-8722-fc693f20619f', 1, 85, $hr$https://economie-politique.org/reconquete/$hr$, $hr$Reconquête — idéologie, programme et structure du parti$hr$, $hr$Priorité nationale revendiquée dans l'accès aux prestations, corollaire direct de la doctrine sur l'immigration.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '72bcbe3e-95cc-497a-8722-fc693f20619f', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Peur des étrangers ? → 1 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '9f80cbde-5663-45a3-86e1-6a04dd3c961d', 1, 60, $hr$https://economie-politique.org/reconquete/$hr$, $hr$Reconquête — idéologie, programme et structure du parti$hr$, $hr$L'identité et l'immigration sont l'axe central du projet, construit sur l'idée d'une menace pesant sur la civilisation française.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '9f80cbde-5663-45a3-86e1-6a04dd3c961d', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Europe : nation ou fédération ? → 1 (90 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 1, 90, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Refus de sortir de l'Union mais primauté du droit national inscrite dans la Constitution, suppression de la Commission de Bruxelles au profit d'un secrétariat placé sous l'autorité du Conseil, opposition à toute défense commune et à l'harmonisation fiscale.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Défense : Ukraine, Russie, OTAN → 5 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 5, 85, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Opposition à l'accroissement du soutien militaire à l'Ukraine et maintien revendiqué des canaux diplomatiques avec la Russie.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Retraites : à quel âge s'arrêter ? → 2 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 2, 75, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Report de l'âge légal à 64 ans d'ici 2030, pour environ 20 milliards d'euros d'économies annuelles, assorti d'une revalorisation des pensions de réversion.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Impôts : baisser ou redistribuer ? → 1 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '488be11b-5a34-4231-9562-60ee78628488', 1, 80, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Trente milliards d'euros de baisses d'impôts pour les entreprises, exonération des heures supplémentaires, opposition à toute hausse d'impôt sur les grandes fortunes.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '488be11b-5a34-4231-9562-60ee78628488', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Patrimoine et capital : protéger ou taxer ? → 1 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 1, 80, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Opposition à la taxation des grandes fortunes, priorité assumée à l'accumulation du capital plutôt qu'à la redistribution.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Nucléaire versus renouvelable → 1 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'ac84a7ca-ae6a-4f46-8a1d-38a0c5b95f8d', 1, 85, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Quatorze nouveaux réacteurs EPR d'ici 2050, blocage des nouveaux projets éoliens et opposition aux objectifs de 100 % renouvelable.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'ac84a7ca-ae6a-4f46-8a1d-38a0c5b95f8d', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Déployer le nouveau nucléaire → 1 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'bc398a58-4367-4dda-96aa-f0d15d47dd7b', 1, 85, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Quatorze réacteurs EPR programmés à l'horizon 2050.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'bc398a58-4367-4dda-96aa-f0d15d47dd7b', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Renouvelables → 1 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '500c6ae5-dfa5-4d65-9e10-3ee34b019775', 1, 80, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Blocage des nouveaux projets éoliens et refus des trajectoires 100 % renouvelable.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '500c6ae5-dfa5-4d65-9e10-3ee34b019775', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Production d'électricité → 1 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '2836f26c-a14a-4f56-8673-7f74cbb99bed', 1, 70, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Souveraineté énergétique adossée au parc nucléaire, donc à une production centralisée, contre l'éolien réparti.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '2836f26c-a14a-4f56-8673-7f74cbb99bed', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Climat : s'adapter ou tout transformer ? → 1 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 1, 80, $hr$https://economie-politique.org/reconquete/$hr$, $hr$Reconquête — idéologie, programme et structure du parti$hr$, $hr$Priorité donnée à la croissance et à la réindustrialisation sur les contraintes environnementales ; l'indépendance énergétique par le nucléaire tient lieu de politique climatique.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Agriculture : produire ou transformer ? → 1 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 1, 70, $hr$https://economie-politique.org/reconquete/$hr$, $hr$Reconquête — idéologie, programme et structure du parti$hr$, $hr$Priorité à la production et à la souveraineté alimentaire, contre les contraintes environnementales pesant sur les exploitations.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Institutions : exécutif fort ou pouvoir au peuple ? → 1 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '106b1aff-a35e-47d3-b657-7b23676de380', 1, 85, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Gaullisme revendiqué : défense du 49.3 et du pouvoir exécutif, opposition au référendum d'initiative citoyenne et à toute VIᵉ République.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '106b1aff-a35e-47d3-b657-7b23676de380', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Sécurité et justice : punir ou prévenir ? → 1 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 1, 85, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Fermeté pénale maximale, exécution intégrale des peines et expulsion systématique des étrangers délinquants.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Travail : coût du travail ou salaires ? → 1 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 1, 75, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Baisse des charges et exonération des heures supplémentaires plutôt que hausse des salaires : le coût du travail est désigné comme le frein.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Aides sociales : conditionner ou garantir ? → 1 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 1, 70, $hr$https://economie-politique.org/reconquete/$hr$, $hr$Reconquête — idéologie, programme et structure du parti$hr$, $hr$Solidarité réservée aux nationaux et conditionnée au travail, dans la continuité de la priorité nationale.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Faut-il instaurer un revenu universel ? → 5 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '8774b1e2-a0b4-4c66-a0ab-98cb5016c760', 5, 75, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Opposition au revenu universel : la doctrine privilégie le travail et la baisse des prélèvements.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '8774b1e2-a0b4-4c66-a0ab-98cb5016c760', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Famille : encourager la natalité ? → 1 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 1, 75, $hr$https://economie-politique.org/reconquete/$hr$, $hr$Reconquête — idéologie, programme et structure du parti$hr$, $hr$Politique nataliste assumée, présentée comme la réponse française au défi démographique face à l'immigration.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- École : mérite ou égalité ? → 1 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '4788e43e-8c98-417a-870a-03854f9388d9', 1, 80, $hr$https://economie-politique.org/reconquete/$hr$, $hr$Reconquête — idéologie, programme et structure du parti$hr$, $hr$École de l'autorité, du mérite et de la transmission des savoirs et du roman national.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '4788e43e-8c98-417a-870a-03854f9388d9', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- C'était mieux avant ? → 1 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'd5f208c2-7ccc-47ee-a2f5-92d76e9be4a0', 1, 80, $hr$https://economie-politique.org/reconquete/$hr$, $hr$Reconquête — idéologie, programme et structure du parti$hr$, $hr$Le décliniste assumé : le projet repose sur l'idée d'un déclin français à inverser et d'un âge d'or à retrouver.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'd5f208c2-7ccc-47ee-a2f5-92d76e9be4a0', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Pouvoir d'achat : détaxer ou encadrer ? → 1 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 1, 65, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Baisse des prélèvements et exonération des heures supplémentaires, sans encadrement des prix ni revalorisation administrée des salaires.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Made in France → 4 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'f6c2ae32-fa63-4e5c-955e-6d176dbd3392', 4, 55, $hr$https://economie-politique.org/reconquete/$hr$, $hr$Reconquête — idéologie, programme et structure du parti$hr$, $hr$Réindustrialisation et souveraineté économique revendiquées, avec protection des productions nationales.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'f6c2ae32-fa63-4e5c-955e-6d176dbd3392', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Travail = identité ou aliénation ? → 1 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'a7a32da9-7c8c-4f4c-9149-baa8b19d39cb', 1, 60, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$La valeur travail est centrale : exonération des heures supplémentaires, opposition aux transferts sans contrepartie.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'a7a32da9-7c8c-4f4c-9149-baa8b19d39cb', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Mille feuilles administratif → 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '8b57539f-c045-47f6-9cbd-6c79f0e0145f', 2, 55, $hr$https://economie-politique.org/reconquete/$hr$, $hr$Reconquête — idéologie, programme et structure du parti$hr$, $hr$Réduction revendiquée du poids de l'administration et des structures intermédiaires.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '8b57539f-c045-47f6-9cbd-6c79f0e0145f', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Voiture électrique → 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '5b4152af-6743-4a5a-ba0c-7b71e1b41fd7', 2, 55, $hr$https://economie-politique.org/reconquete/$hr$, $hr$Reconquête — idéologie, programme et structure du parti$hr$, $hr$Opposition aux contraintes environnementales imposées à l'automobile et au calendrier de sortie du thermique.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', '5b4152af-6743-4a5a-ba0c-7b71e1b41fd7', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Déficits publics → 4 (50 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'af2fc1be-2174-43b8-a646-5a00f165c580', 4, 50, $hr$https://monvote2027.fr/candidat/zemmour$hr$, $hr$MonVote2027 — positions d'Éric Zemmour (Reconquête)$hr$, $hr$Réduction de la dépense publique et économies chiffrées sur les retraites, sans proposer de sanctionner personnellement les ministres.$hr$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('e42a9b18-7c50-4d3e-8a61-2f9d4c7b0e35', 'af2fc1be-2174-43b8-a646-5a00f165c580', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

commit;
