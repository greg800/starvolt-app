-- « Financement du salaire universel » : position des dix partis.
--
-- ⚠️ Sujet PROSPECTIF : aucun parti n'a publié de position sur un fonds citoyen.
-- Les taux de certitude sont donc plus bas (50 à 70 %) que sur les sujets où
-- une mesure est écrite noir sur blanc dans un programme. Deux positions
-- seulement s'appuient sur une politique existante : Renaissance (dividende
-- salarié, ANI de février 2023, loi partage de la valeur) et La France insoumise
-- (taxe Zucman, impôt universel sur les entreprises, grand secteur public du
-- numérique et de l'IA). Les huit autres sont des extrapolations de doctrine,
-- et doivent être lues comme telles.
begin;

-- Position 1 = tout par l'impôt (taxer les robots) ; position 5 = tout par le
-- capital citoyen (chacun actionnaire des machines).
with cible as (select '2b99e9f9-fafb-410e-9269-a3b8dfe1ee57'::uuid as node_id),
     auteur as (select '98628a67-0aa0-41d3-ac92-815894449546'::uuid as id),
     avis(nom, pos, taux, url, source, extrait) as (values
  ('La france Insoumise', 1, 65,
   'https://melenchon2027.fr/programme2025/livre/chapitre6/s5/',
   'Programme LFI 2027 — révolution fiscale',
   'Taxe Zucman sur les milliardaires, impôt universel sur les entreprises, et création d''un grand secteur PUBLIC du numérique et de l''IA. La réponse est la redistribution fiscale et la propriété publique, pas l''actionnariat individuel.'),
  ('Parti communiste français', 2, 55,
   'https://monvote2027.fr/candidat/roussel',
   'MonVote2027 — positions de Fabien Roussel (PCF)',
   'Doctrine de la propriété publique des moyens de production et du financement par l''impôt. L''actionnariat populaire, qui fait du salarié un petit capitaliste, est étranger à cette tradition ; un fonds resterait un appoint.'),
  ('Les Écologistes', 2, 55,
   'https://monvote2027.fr/candidat/tondelier',
   'MonVote2027 — positions de Marine Tondelier (Les Écologistes)',
   'L''« ISF climatique » oriente le patrimoine vers les investissements verts : la fiscalité est le levier revendiqué, et le revenu d''existence qu''ils portent est financé par l''impôt.'),
  ('Les socialistes', 2, 55,
   'https://monvote2027.fr/candidat/faure',
   'MonVote2027 — positions d''Olivier Faure (PS)',
   'Rétablissement de l''ISF pour 15 milliards et taxation des grandes successions : le financement passe d''abord par l''impôt, l''épargne salariale restant un complément.'),
  ('Place publique', 2, 55,
   'https://monvote2027.fr/candidat/faure',
   'Positions de Place publique — taxation des grandes fortunes',
   'Soutien appuyé à la taxation des très hauts patrimoines. La logique reste celle de la contribution fiscale, même si le tropisme industriel et européen du parti le rendrait ouvert à un fonds d''investissement.'),
  ('Renaissance', 4, 70,
   'https://www.usinenouvelle.com/article/presidentielle-mieux-associer-les-salaries-a-la-creation-de-valeur-la-nouvelle-ambition-d-emmanuel-macron.N1995027',
   'L''Usine Nouvelle — le dividende salarié d''Emmanuel Macron',
   'Le « dividende salarié » était une promesse de campagne, concrétisée par l''accord interprofessionnel de février 2023 puis la loi partage de la valeur. L''intention affichée était de « réconcilier les Français avec le capitalisme » en les associant au capital — la voie actionnariale, pas la taxe.'),
  ('Horizons', 4, 60,
   'https://monvote2027.fr/candidat/philippe',
   'MonVote2027 — positions d''Édouard Philippe (Horizons)',
   'Opposition à l''impôt sur la fortune et aux prélèvements sur les successions, et introduction assumée d''une part de capitalisation de 10 à 15 % dans les retraites : la logique du fonds est déjà dans le programme.'),
  ('Les Républicains', 4, 60,
   'https://monvote2027.fr/candidat/retailleau',
   'MonVote2027 — positions de Bruno Retailleau (LR)',
   'Refus de toute taxation du patrimoine, et tradition gaulliste de la participation et de l''association capital-travail, dont un fonds citoyen est le prolongement direct.'),
  ('Reconquête', 4, 55,
   'https://monvote2027.fr/candidat/zemmour',
   'MonVote2027 — positions d''Éric Zemmour (Reconquête)',
   'Priorité assumée à l''accumulation du capital plutôt qu''à la redistribution, et opposition à toute hausse d''impôt sur les fortunes : la voie actionnariale est plus cohérente avec cette doctrine que la taxe sur les machines.'),
  ('Le rassemblement national', 3, 50,
   'https://monvote2027.fr/candidat/zemmour',
   'Positions économiques du Rassemblement national',
   'Position hybride : refus des hausses d''impôts sur les ménages mais recours massif à l''État et taxation des multinationales. Aucune doctrine sur l''actionnariat citoyen — les deux voies sont également mobilisables.')
)
insert into mv_recherches (personne_id, node_id, pos, taux, url, source, extrait, retenu, cherche_le)
select p.id, c.node_id, a.pos, a.taux, a.url, a.source, a.extrait, true, now()
from avis a
join mv_personnes p on p.nom = a.nom and p.type_entite = 'morale'
cross join cible c
on conflict (personne_id, node_id) do update set pos = excluded.pos, taux = excluded.taux,
  url = excluded.url, source = excluded.source, extrait = excluded.extrait,
  retenu = true, cherche_le = now();

-- La réponse ferme suit la recherche, comme pour les autres sujets.
insert into mv_reponses (personne_id, node_id, pos, auteur_id, origine)
select r.personne_id, r.node_id, r.pos, '98628a67-0aa0-41d3-ac92-815894449546', 'recherche'
from mv_recherches r
where r.node_id = '2b99e9f9-fafb-410e-9269-a3b8dfe1ee57' and r.pos is not null
on conflict (personne_id, node_id, auteur_id) do update set pos = excluded.pos, origine = 'recherche';

commit;
