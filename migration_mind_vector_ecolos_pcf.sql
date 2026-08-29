-- Les Écologistes et le Parti communiste français : fiches publiques +
-- positions recherchées à la main (Claude, 2026-08-29).
begin;

insert into mv_personnes (id, prenom, nom, email, commentaire, type_entite, est_public, created_by)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '', $ep$Les Écologistes$ep$, '', $ep$Parti écologiste français, anciennement Europe Écologie Les Verts, dirigé par Marine Tondelier. Écologie politique, sortie du nucléaire, gauche sociale.$ep$, 'morale', true, 'greg@starvolt.fr')
on conflict (id) do update set commentaire = excluded.commentaire, est_public = true;

insert into mv_personnes (id, prenom, nom, email, commentaire, type_entite, est_public, created_by)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '', $ep$Parti communiste français$ep$, '', $ep$Parti communiste français, dirigé par Fabien Roussel. Gauche du travail et des services publics, favorable au nucléaire et à la réindustrialisation, distincte de La France insoumise sur la sécurité et l'énergie.$ep$, 'morale', true, 'greg@starvolt.fr')
on conflict (id) do update set commentaire = excluded.commentaire, est_public = true;

-- Nucléaire versus renouvelable → 5 (90 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'ac84a7ca-ae6a-4f46-8a1d-38a0c5b95f8d', 5, 90, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Sortie du nucléaire et objectif de 100 % d'électricité renouvelable ; calendrier d'arrêt progressif des centrales vieillissantes sur deux décennies, la question étant confiée à une convention citoyenne.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'ac84a7ca-ae6a-4f46-8a1d-38a0c5b95f8d', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Déployer le nouveau nucléaire → 5 (90 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'bc398a58-4367-4dda-96aa-f0d15d47dd7b', 5, 90, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Opposition à tout nouveau réacteur : le programme prévoit l'arrêt progressif du parc existant, pas son renouvellement.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'bc398a58-4367-4dda-96aa-f0d15d47dd7b', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Renouvelables → 5 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '500c6ae5-dfa5-4d65-9e10-3ee34b019775', 5, 85, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Objectif assumé de 100 % d'électricité renouvelable.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '500c6ae5-dfa5-4d65-9e10-3ee34b019775', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Production d'électricité → 5 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '2836f26c-a14a-4f56-8673-7f74cbb99bed', 5, 70, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Un mix intégralement renouvelable suppose une production très répartie, à rebours du modèle centralisé nucléaire.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '2836f26c-a14a-4f56-8673-7f74cbb99bed', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Climat : s'adapter ou tout transformer ? → 5 (90 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 5, 90, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Fin des subventions aux énergies fossiles, taxation progressive de l'aviation, fin de l'élevage intensif, arrêt des nouvelles autoroutes : une transformation rapide des modes de production.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Retraites : à quel âge s'arrêter ? → 4 (90 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 4, 90, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Retour à 62 ans, contre 64 aujourd'hui.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Impôts : baisser ou redistribuer ? → 5 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '488be11b-5a34-4231-9562-60ee78628488', 5, 80, $ep$https://www.elyseescope.com/le-radar/tondelier-eelv-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Marine Tondelier$ep$, $ep$Plan d'investissement dans la transition et les services publics financé par la taxation des grandes fortunes, dont un « ISF climatique ».$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '488be11b-5a34-4231-9562-60ee78628488', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Patrimoine et capital : protéger ou taxer ? → 5 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 5, 85, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Rétablissement de l'impôt sur la fortune, assorti d'une dimension « climat » destinée à orienter le patrimoine vers les investissements verts.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Travail : coût du travail ou salaires ? → 5 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 5, 80, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$SMIC porté à 1 600 € net, dans un projet qui assume la réduction du temps de travail.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Pouvoir d'achat : détaxer ou encadrer ? → 5 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 5, 75, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Hausse du SMIC et encadrement des loyers dans les grandes villes : on agit sur les revenus et sur les prix, pas sur les taxes.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Logement : marché ou intervention publique ? → 5 (90 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 5, 90, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Encadrement des loyers dans les grandes villes et 200 000 logements sociaux par an.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Institutions : exécutif fort ou pouvoir au peuple ? → 5 (90 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '106b1aff-a35e-47d3-b657-7b23676de380', 5, 90, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$VIᵉ République aux pouvoirs parlementaires renforcés, suppression du 49.3, proportionnelle intégrale et référendum d'initiative citoyenne.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '106b1aff-a35e-47d3-b657-7b23676de380', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Immigration, pour ou contre ? → 4 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '695341fc-7cd7-4c6e-b878-d158c856c748', 4, 80, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Opposition aux restrictions de l'immigration légale et à l'expulsion systématique, élargissement du regroupement familial, droit de vote des étrangers aux élections locales, réforme du droit d'asile.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '695341fc-7cd7-4c6e-b878-d158c856c748', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Prestations sociales : les Français d'abord ? → 5 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '72bcbe3e-95cc-497a-8722-fc693f20619f', 5, 70, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Égalité des droits des résidents étrangers, jusqu'au droit de vote local : aucune distinction fondée sur la nationalité.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '72bcbe3e-95cc-497a-8722-fc693f20619f', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Peur des étrangers ? → 5 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '9f80cbde-5663-45a3-86e1-6a04dd3c961d', 5, 65, $ep$https://www.elyseescope.com/le-radar/tondelier-eelv-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Marine Tondelier$ep$, $ep$Marine Tondelier conteste tout lien de causalité entre immigration et délinquance — le lien qu'elle établit est avec la précarité — et récuse le récit de la « submersion migratoire ».$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '9f80cbde-5663-45a3-86e1-6a04dd3c961d', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Europe : nation ou fédération ? → 4 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 4, 70, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Ancrage européen assumé : opposition à une sortie de l'OTAN et soutien au développement d'une défense européenne.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Défense : Ukraine, Russie, OTAN → 1 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 1, 80, $ep$https://www.elyseescope.com/le-radar/tondelier-eelv-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Marine Tondelier$ep$, $ep$Soutien militaire et économique à l'Ukraine, préparation de l'armée française à un conflit de haute intensité, maintien dans l'OTAN et défense européenne.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Sécurité et justice : punir ou prévenir ? → 5 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 5, 80, $ep$https://www.elyseescope.com/le-radar/tondelier-eelv-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Marine Tondelier$ep$, $ep$La délinquance est rapportée à la précarité et non à l'immigration : la réponse passe par le social plutôt que par la sanction.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Agriculture : produire ou transformer ? → 5 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 5, 85, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Fin de l'élevage intensif et sortie des soutiens aux modèles les plus polluants.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- École : mérite ou égalité ? → 5 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '4788e43e-8c98-417a-870a-03854f9388d9', 5, 75, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Embauches massives dans l'éducation et refus de la privatisation des services publics.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '4788e43e-8c98-417a-870a-03854f9388d9', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Aides sociales : conditionner ou garantir ? → 5 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 5, 65, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Opposition à la conditionnalité des minima sociaux, dans une logique de droits garantis.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Faut-il instaurer un revenu universel ? → 2 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '8774b1e2-a0b4-4c66-a0ab-98cb5016c760', 2, 65, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Les Écologistes portent de longue date un revenu d'existence, mis en place progressivement plutôt que d'un seul coup.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '8774b1e2-a0b4-4c66-a0ab-98cb5016c760', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Faut-il développer l'avion ? → 4 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'b7195ad1-dea9-4608-855e-ccb49c14aaa4', 4, 75, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Taxation progressive du transport aérien : le vol devient l'exception plutôt que la norme.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'b7195ad1-dea9-4608-855e-ccb49c14aaa4', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Famille : encourager la natalité ? → 5 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 5, 60, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Politique familiale fondée sur les droits individuels et l'égalité, sans objectif démographique.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '63b1e42a-a939-43c6-a5c5-c57e7b1209b5', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Faut il manger bio ? → 2 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '785b1a8f-26ec-41ac-b8fe-baac52e046bb', 2, 65, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Sortie de l'agriculture intensive et soutien à la conversion : le bio est la trajectoire visée, pas une option marginale.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '785b1a8f-26ec-41ac-b8fe-baac52e046bb', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Végétarien → 3 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '03286048-16b7-40b4-841a-ec2adf00adf6', 3, 60, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Fin de l'élevage intensif et réduction assumée de la consommation de viande, sans imposer le végétarisme.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '03286048-16b7-40b4-841a-ec2adf00adf6', 3, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Made in France → 4 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'f6c2ae32-fa63-4e5c-955e-6d176dbd3392', 4, 60, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Relocalisation et clauses de réciprocité pour éviter que les normes environnementales ne soient contournées par les importations.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'f6c2ae32-fa63-4e5c-955e-6d176dbd3392', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Déficits publics → 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'af2fc1be-2174-43b8-a646-5a00f165c580', 2, 55, $ep$https://www.elyseescope.com/le-radar/tondelier-eelv-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Marine Tondelier$ep$, $ep$Plan d'investissement massif dans la transition, financé par l'impôt sur les grandes fortunes : la dépense publique est un levier, pas un mal.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'af2fc1be-2174-43b8-a646-5a00f165c580', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- IA militaire et armes autonomes → 5 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '238575df-3c71-4f80-9de9-d128b2028095', 5, 60, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Attachement au droit international et au contrôle des armements, hostile à la délégation de la décision de tir à une machine.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', '238575df-3c71-4f80-9de9-d128b2028095', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Travail = identité ou aliénation ? → 4 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'a7a32da9-7c8c-4f4c-9149-baa8b19d39cb', 4, 55, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Réduction du temps de travail et priorité au projet de vie : le travail n'est pas l'horizon unique.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'a7a32da9-7c8c-4f4c-9149-baa8b19d39cb', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- C'était mieux avant ? → 4 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'd5f208c2-7ccc-47ee-a2f5-92d76e9be4a0', 4, 55, $ep$https://monvote2027.fr/candidat/tondelier$ep$, $ep$MonVote2027 — positions de Marine Tondelier (Les Écologistes)$ep$, $ep$Projet tourné vers la transformation et l'extension des droits, sans nostalgie d'un ordre ancien.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('c7f04a92-8b31-4d6e-a057-1e9b3f8d2c60', 'd5f208c2-7ccc-47ee-a2f5-92d76e9be4a0', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Déployer le nouveau nucléaire → 1 (80 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'bc398a58-4367-4dda-96aa-f0d15d47dd7b', 1, 80, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Le plan du PCF prévoit la construction de 20 EPR, soit davantage que les 14 programmés par le gouvernement.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'bc398a58-4367-4dda-96aa-f0d15d47dd7b', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Nucléaire versus renouvelable → 2 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'ac84a7ca-ae6a-4f46-8a1d-38a0c5b95f8d', 2, 75, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Nucléaire public assumé comme colonne vertébrale du mix — 20 EPR — complété par les renouvelables, à rebours de la ligne écologiste.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'ac84a7ca-ae6a-4f46-8a1d-38a0c5b95f8d', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Production d'électricité → 1 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '2836f26c-a14a-4f56-8673-7f74cbb99bed', 1, 70, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Grand service public de l'énergie adossé au parc nucléaire national : une production centralisée et publique.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '2836f26c-a14a-4f56-8673-7f74cbb99bed', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Renouvelables → 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '500c6ae5-dfa5-4d65-9e10-3ee34b019775', 2, 55, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Les renouvelables complètent un mix dont le nucléaire reste la base.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '500c6ae5-dfa5-4d65-9e10-3ee34b019775', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Travail : coût du travail ou salaires ? → 5 (85 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 5, 85, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$SMIC porté à 1 500 € net, soit 1 923 € bruts — une hausse de 18,2 % par rapport à janvier 2022.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '0f917c25-ffd5-43f6-a052-ed655209f4a0', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Retraites : à quel âge s'arrêter ? → 5 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 5, 70, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Abrogation de la réforme de 2023 et retour à un départ à 62 ans « ou moins ».$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'cebe2cec-59f6-4e60-8f61-a3868abaa8ce', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Pouvoir d'achat : détaxer ou encadrer ? → 5 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 5, 75, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Hausse des salaires et des pensions comme premier levier, dans un projet dont le travail est l'axe central.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'eede8f9e-375f-4966-9ee6-8fb579a71d08', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Impôts : baisser ou redistribuer ? → 5 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '488be11b-5a34-4231-9562-60ee78628488', 5, 75, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Forte progressivité de l'impôt pour financer les services publics, l'un des trois axes du projet.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '488be11b-5a34-4231-9562-60ee78628488', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Patrimoine et capital : protéger ou taxer ? → 5 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 5, 75, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Taxation du capital et des grandes fortunes revendiquée pour financer les services publics.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '67d2ce30-3b8f-46d8-9f37-44dee0099e96', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Europe : nation ou fédération ? → 2 (75 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 2, 75, $ep$https://monvote2027.fr/candidat/roussel$ep$, $ep$MonVote2027 — positions de Fabien Roussel (PCF)$ep$, $ep$Sortie de l'OTAN et sécurité collective européenne fondée sur la coopération des peuples, avec un refus explicite de toute armée européenne fédérale.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '70ee0d0d-f993-4d74-ae3c-966e24d3c08d', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Défense : Ukraine, Russie, OTAN → 5 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 5, 65, $ep$https://monvote2027.fr/candidat/roussel$ep$, $ep$MonVote2027 — positions de Fabien Roussel (PCF)$ep$, $ep$Sortie de l'OTAN, opposition à l'extension de la dissuasion nucléaire française à l'échelle européenne et à tout projet d'armée européenne fédéraliste.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'f69e2a49-451e-4c3f-b1d8-83a35d6aa334', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Immigration, pour ou contre ? → 3 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '695341fc-7cd7-4c6e-b878-d158c856c748', 3, 65, $ep$https://monvote2027.fr/candidat/roussel$ep$, $ep$MonVote2027 — positions de Fabien Roussel (PCF)$ep$, $ep$Régularisation des travailleurs sans papiers et défense du droit d'asile, assorties d'un discours de fermeté sur le contrôle des frontières.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '695341fc-7cd7-4c6e-b878-d158c856c748', 3, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Prestations sociales : les Français d'abord ? → 4 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '72bcbe3e-95cc-497a-8722-fc693f20619f', 4, 55, $ep$https://monvote2027.fr/candidat/roussel$ep$, $ep$MonVote2027 — positions de Fabien Roussel (PCF)$ep$, $ep$Régularisation des travailleurs sans papiers : les droits suivent le travail et les cotisations, pas la nationalité.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '72bcbe3e-95cc-497a-8722-fc693f20619f', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Sécurité et justice : punir ou prévenir ? → 3 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 3, 70, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Ligne assumée d'une sécurité « de gauche » : moyens pour la police et sanction des faits graves, articulées à une réponse sociale — position distincte de celle de La France insoumise.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '09ef2e7e-a5ea-4b9b-aa1a-69967cb99fe3', 3, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Climat : s'adapter ou tout transformer ? → 4 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 4, 70, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$La planification écologique est l'un des trois axes du projet, mais adossée à l'industrie et au nucléaire plutôt qu'à la décroissance.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '8818ade6-57a1-4f11-9540-ad14d31ccc9f', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- École : mérite ou égalité ? → 5 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '4788e43e-8c98-417a-870a-03854f9388d9', 5, 70, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Services publics érigés en axe central : moyens massifs pour l'école et refus de la sélection sociale.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '4788e43e-8c98-417a-870a-03854f9388d9', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Logement : marché ou intervention publique ? → 5 (70 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 5, 70, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Logement public massif et encadrement des loyers, dans la continuité de la priorité donnée aux services publics.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '0ef32e3d-16a2-466d-81a6-d7ec4e92a277', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Aides sociales : conditionner ou garantir ? → 5 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 5, 65, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Droits sociaux garantis et refus de la conditionnalité des minima.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '8e6056f1-fd0c-4f43-abeb-677dc71026de', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Faut-il instaurer un revenu universel ? → 5 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '8774b1e2-a0b4-4c66-a0ab-98cb5016c760', 5, 65, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Le PCF défend la sécurité d'emploi et de formation plutôt qu'un revenu inconditionnel : l'emploi, pas l'allocation.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '8774b1e2-a0b4-4c66-a0ab-98cb5016c760', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Institutions : exécutif fort ou pouvoir au peuple ? → 4 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '106b1aff-a35e-47d3-b657-7b23676de380', 4, 60, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Renforcement des pouvoirs du Parlement et proportionnelle, sans se rallier au référendum d'initiative citoyenne généralisé.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '106b1aff-a35e-47d3-b657-7b23676de380', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Made in France → 4 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'f6c2ae32-fa63-4e5c-955e-6d176dbd3392', 4, 60, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Réindustrialisation et production en France revendiquées, avec protection des filières nationales.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'f6c2ae32-fa63-4e5c-955e-6d176dbd3392', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Agriculture : produire ou transformer ? → 3 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 3, 55, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Prix rémunérateurs et souveraineté alimentaire d'abord, transition écologique accompagnée plutôt qu'imposée aux exploitations.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'a5eafabd-1790-4e41-b6fe-e74b341f585f', 3, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Faut-il devenir syndicaliste ? → 1 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '38185f35-4a30-40ab-be02-1de9aad2e57a', 1, 65, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Parti historiquement lié au syndicalisme et au monde du travail, qui fait de l'engagement collectif un moyen d'action central.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '38185f35-4a30-40ab-be02-1de9aad2e57a', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- S'engager en politique → 1 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'd1043a3b-5dea-4e37-bc94-2e77444e7cd7', 1, 60, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Culture militante et implantation locale revendiquées comme la raison d'être du parti.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'd1043a3b-5dea-4e37-bc94-2e77444e7cd7', 1, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Végétarien → 4 (65 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '03286048-16b7-40b4-841a-ec2adf00adf6', 4, 65, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Fabien Roussel défend publiquement « le bon vin et la bonne viande » comme éléments de la gastronomie française et refuse d'en faire un sujet de culpabilisation.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '03286048-16b7-40b4-841a-ec2adf00adf6', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Travail = identité ou aliénation ? → 2 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'a7a32da9-7c8c-4f4c-9149-baa8b19d39cb', 2, 60, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Le travail est le premier des trois axes du projet, pensé comme émancipateur et structurant.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'a7a32da9-7c8c-4f4c-9149-baa8b19d39cb', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Progrès technologiques → 4 (60 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'c38f4891-7367-47ff-8d86-cdb7bc9da12a', 4, 60, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Réindustrialisation et maîtrise publique des technologies : le progrès technique est vu comme un levier d'émancipation.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'c38f4891-7367-47ff-8d86-cdb7bc9da12a', 4, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Déficits publics → 2 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'af2fc1be-2174-43b8-a646-5a00f165c580', 2, 55, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$L'investissement public dans les services publics prime sur le retour rapide à l'équilibre budgétaire.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', 'af2fc1be-2174-43b8-a646-5a00f165c580', 2, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

-- Mille feuilles administratif → 5 (55 %)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '8b57539f-c045-47f6-9cbd-6c79f0e0145f', 5, 55, $ep$https://www.elyseescope.com/questions/roussel-pcf-candidature-programme-2027$ep$, $ep$ÉlyséeScope — candidature et programme de Fabien Roussel$ep$, $ep$Attachement revendiqué aux communes et aux élus de proximité, maillage que le parti défend comme une richesse démocratique.$ep$, true, now())
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait, retenu = true, cherche_le = now();
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
values ('a3d81b5e-9f27-4c04-b6a8-0d5e7c1a4f92', '8b57539f-c045-47f6-9cbd-6c79f0e0145f', 5, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche')
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

commit;
