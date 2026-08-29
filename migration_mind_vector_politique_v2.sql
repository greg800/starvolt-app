-- Mind Vector — réécriture des 5 positions des 16 sujets politiques.
-- Consigne de Greg : le dégradé doit être facile à renseigner par une personne,
-- pas calé sur les programmes des partis. pos 1 = extrême A, pos 5 = extrême B.
begin;

-- Retraites : à quel âge s'arrêter ?
update mv_positions set titre = $mv$[Le plus tard possible]$mv$, content = $mv$Tant qu'on est en forme, on travaille. **67 ans ou plus**, et tant mieux : rester actif garde en vie, et il faut bien que quelqu'un paie les pensions de ceux qui s'arrêtent.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Retraites : à quel âge s'arrêter ?$mv$);
update mv_positions set titre = $mv$[Un peu plus tard]$mv$, content = $mv$Travailler **deux ou trois ans de plus** ne me choque pas. On vit plus vieux, c'est logique d'y mettre du sien. Ceux qui ont un métier dur partent avant, les autres peuvent tenir.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Retraites : à quel âge s'arrêter ?$mv$);
update mv_positions set titre = $mv$[Comme aujourd'hui]$mv$, content = $mv$L'âge actuel me paraît **à peu près juste**. Ni le repousser encore, ni revenir en arrière : on a assez tiré sur cette corde, il y a d'autres façons d'équilibrer les comptes.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Retraites : à quel âge s'arrêter ?$mv$);
update mv_positions set titre = $mv$[Plutôt 62 ans]$mv$, content = $mv$**62 ans** me semble un bon âge, et plus tôt pour ceux qui ont commencé à 18 ans ou qui portent des charges toute la journée. Après, le corps ne suit plus vraiment.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Retraites : à quel âge s'arrêter ?$mv$);
update mv_positions set titre = $mv$[60 ans, et profiter]$mv$, content = $mv$**60 ans** pour tout le monde. On travaille pour vivre, pas l'inverse : après une vie de boulot, on a droit à des années en bonne santé pour soi, ses proches, ses projets.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Retraites : à quel âge s'arrêter ?$mv$);

-- Sécurité et justice : punir ou prévenir ?
update mv_positions set titre = $mv$[Sévérité maximale]$mv$, content = $mv$Il faut **taper fort et vite**. Une peine annoncée doit être une peine faite, sans remise. Quand la sanction fait peur, les gens réfléchissent avant de passer à l'acte.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Sécurité et justice : punir ou prévenir ?$mv$);
update mv_positions set titre = $mv$[Plus ferme]$mv$, content = $mv$On est trop laxiste. **Des peines plus lourdes** pour les violences et la drogue, et de vraies places de prison. On parlera de réinsertion quand le quartier sera redevenu calme.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Sécurité et justice : punir ou prévenir ?$mv$);
update mv_positions set titre = $mv$[Punir et accompagner]$mv$, content = $mv$Les deux vont ensemble : une **sanction claire**, et derrière un vrai accompagnement pour éviter que ça recommence. Ni tout répressif, ni tout excuser.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Sécurité et justice : punir ou prévenir ?$mv$);
update mv_positions set titre = $mv$[Réparer plutôt qu'enfermer]$mv$, content = $mv$La prison abîme plus qu'elle ne corrige. Je préfère le **travail d'intérêt général**, l'éducateur, la réparation du préjudice — et l'enfermement pour ceux qui sont vraiment dangereux.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Sécurité et justice : punir ou prévenir ?$mv$);
update mv_positions set titre = $mv$[S'attaquer aux causes]$mv$, content = $mv$Personne ne naît délinquant. Ce qui fabrique la violence, c'est **la pauvreté, l'école ratée, le quartier abandonné**. On règle ça là, pas en construisant des prisons.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Sécurité et justice : punir ou prévenir ?$mv$);

-- Europe : nation ou fédération ?
update mv_positions set titre = $mv$[La France décide]$mv$, content = $mv$Les décisions qui nous concernent doivent se prendre **à Paris, pas à Bruxelles**. On coopère avec nos voisins quand ça nous arrange, mais personne ne nous dicte nos lois.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Europe : nation ou fédération ?$mv$);
update mv_positions set titre = $mv$[Coopérer, pas fusionner]$mv$, content = $mv$L'Europe oui, comme un club de pays qui s'entendent. Mais **chacun reste maître chez soi** : on garde le dernier mot sur nos frontières, notre budget, notre énergie.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Europe : nation ou fédération ?$mv$);
update mv_positions set titre = $mv$[Ni plus ni moins]$mv$, content = $mv$L'Europe telle qu'elle est me va **à peu près**. Utile sur certains sujets, pesante sur d'autres. Je ne veux ni en sortir, ni lui donner davantage de pouvoir.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Europe : nation ou fédération ?$mv$);
update mv_positions set titre = $mv$[Plus d'Europe]$mv$, content = $mv$Seuls, on ne pèse rien face aux Américains et aux Chinois. Il faut une Europe **plus forte et plus unie** : même industrie, même défense, des moyens communs pour de vrai.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Europe : nation ou fédération ?$mv$);
update mv_positions set titre = $mv$[Un seul pays européen]$mv$, content = $mv$Allons au bout : **un gouvernement européen élu**, un vrai budget, les décisions prises ensemble. Mon pays c'est l'Europe, les frontières entre nous n'ont plus de sens.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Europe : nation ou fédération ?$mv$);

-- Impôts : baisser ou redistribuer ?
update mv_positions set titre = $mv$[Trop d'impôts]$mv$, content = $mv$On paie **beaucoup trop**, et ça n'a pas rendu les gens moins pauvres. Baisse générale : chacun sait mieux que l'État quoi faire de l'argent qu'il a gagné.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Impôts : baisser ou redistribuer ?$mv$);
update mv_positions set titre = $mv$[Alléger]$mv$, content = $mv$Il faut **baisser la pression**, surtout pour ceux qui travaillent et pour les entreprises qui embauchent. On peut garder l'essentiel des services en dépensant mieux.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Impôts : baisser ou redistribuer ?$mv$);
update mv_positions set titre = $mv$[Ça me paraît normal]$mv$, content = $mv$Le niveau actuel ne me choque pas : l'impôt paie l'école, l'hôpital, les routes. Ce que je demande, c'est surtout qu'on **arrête de changer les règles** tous les ans.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Impôts : baisser ou redistribuer ?$mv$);
update mv_positions set titre = $mv$[Les aisés paient plus]$mv$, content = $mv$Il manque de la justice : plus on gagne, **plus on doit contribuer**, vraiment. Ceux qui ont beaucoup trouvent toujours le moyen de payer proportionnellement moins que moi.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Impôts : baisser ou redistribuer ?$mv$);
update mv_positions set titre = $mv$[Faire payer les fortunes]$mv$, content = $mv$**Beaucoup plus progressif**, sans échappatoire. Quand une poignée capte l'essentiel des richesses pendant que les autres comptent, redistribuer n'est pas un vol, c'est réparer.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Impôts : baisser ou redistribuer ?$mv$);

-- Climat : s'adapter ou tout transformer ?
update mv_positions set titre = $mv$[La technique s'en chargera]$mv$, content = $mv$Le climat se réglera par **l'innovation**, pas par les interdictions : nouveaux réacteurs, meilleurs moteurs, meilleures récoltes. Culpabiliser les gens ne baisse aucune émission.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Climat : s'adapter ou tout transformer ?$mv$);
update mv_positions set titre = $mv$[S'adapter d'abord]$mv$, content = $mv$Le réchauffement est là et on ne l'arrêtera pas seuls. Priorité à **s'y préparer** : l'eau, les incendies, les canicules, les récoltes. Le reste viendra ensuite.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Climat : s'adapter ou tout transformer ?$mv$);
update mv_positions set titre = $mv$[Avancer sans casser]$mv$, content = $mv$Il faut agir, mais **au rythme des gens**. Des aides, des règles raisonnables, des étapes tenables. Ni immobilisme, ni vie bouleversée du jour au lendemain.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Climat : s'adapter ou tout transformer ?$mv$);
update mv_positions set titre = $mv$[Un vrai plan]$mv$, content = $mv$Les bonnes intentions ne suffisent plus : il faut un **plan contraignant**, secteur par secteur, avec l'argent en face. Sinon on repousse toujours à la décennie suivante.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Climat : s'adapter ou tout transformer ?$mv$);
update mv_positions set titre = $mv$[Tout changer, vite]$mv$, content = $mv$On change **notre façon de produire et de consommer**, point. Moins, mieux, autrement. Le climat ne négocie pas ses délais, et attendre coûtera bien plus cher qu'agir.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Climat : s'adapter ou tout transformer ?$mv$);

-- Pouvoir d'achat : détaxer ou encadrer ?
update mv_positions set titre = $mv$[Rendez-nous l'argent]$mv$, content = $mv$Le problème, ce sont **les taxes** : sur le carburant, l'électricité, tout. Baissez-les et mon budget respire tout de suite, sans avoir besoin de commander les prix.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Pouvoir d'achat : détaxer ou encadrer ?$mv$);
update mv_positions set titre = $mv$[Détaxer l'essentiel]$mv$, content = $mv$Au minimum, **plus de taxes sur ce qui est vital** : énergie, produits de base. Et des primes que l'employeur peut verser sans qu'on en reprenne la moitié au passage.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Pouvoir d'achat : détaxer ou encadrer ?$mv$);
update mv_positions set titre = $mv$[Un peu des deux]$mv$, content = $mv$Quelques taxes en moins, quelques salaires en plus, et **surveiller les marges** de ceux qui profitent de l'inflation. Il n'y a pas un seul bouton magique.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Pouvoir d'achat : détaxer ou encadrer ?$mv$);
update mv_positions set titre = $mv$[Encadrer les prix]$mv$, content = $mv$Sur ce qui est vital — se nourrir, se chauffer, se loger — les prix doivent être **encadrés**. Laisser faire le marché sur ces trois-là n'a jamais protégé personne.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Pouvoir d'achat : détaxer ou encadrer ?$mv$);
update mv_positions set titre = $mv$[Augmenter les revenus]$mv$, content = $mv$On **augmente les salaires, les retraites et les minima**, et on bloque les prix de base. Le pouvoir d'achat, ça se gagne, ça ne se quémande pas en baisses de taxes.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Pouvoir d'achat : détaxer ou encadrer ?$mv$);

-- Travail : coût du travail ou salaires ?
update mv_positions set titre = $mv$[Le travail coûte trop cher]$mv$, content = $mv$Embaucher coûte une fortune, c'est pour ça qu'on manque d'emplois. **Moins de charges, plus de souplesse** : une entreprise qui respire, c'est une entreprise qui recrute.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Travail : coût du travail ou salaires ?$mv$);
update mv_positions set titre = $mv$[Récompenser le travail]$mv$, content = $mv$Il faut que **travailler rapporte nettement plus** que ne pas travailler : heures supplémentaires détaxées, primes faciles à verser, charges allégées sur les petits salaires.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Travail : coût du travail ou salaires ?$mv$);
update mv_positions set titre = $mv$[Donnant-donnant]$mv$, content = $mv$Aider les entreprises d'accord, **à condition** qu'elles embauchent et qu'elles augmentent. Ce qui est gagné se partage entre les profits et les fiches de paie.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Travail : coût du travail ou salaires ?$mv$);
update mv_positions set titre = $mv$[Augmenter les salaires]$mv$, content = $mv$Les prix montent, les salaires non. Une **hausse nette des bas salaires** et une vraie négociation chaque année : aujourd'hui le travail ne paie plus assez pour vivre correctement.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Travail : coût du travail ou salaires ?$mv$);
update mv_positions set titre = $mv$[32 h, mieux payé]$mv$, content = $mv$**Salaires nettement relevés et semaine plus courte**. On produit plus qu'avant avec moins de bras : cette richesse doit revenir en temps libre et en paie.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Travail : coût du travail ou salaires ?$mv$);

-- Aides sociales : conditionner ou garantir ?
update mv_positions set titre = $mv$[Pour ceux qui ont cotisé]$mv$, content = $mv$On aide **ceux qui ont travaillé ici et cotisé**, pas les autres. La solidarité c'est un pot commun : on ne sert pas celui qui n'y a jamais rien mis.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Aides sociales : conditionner ou garantir ?$mv$);
update mv_positions set titre = $mv$[Avec des contreparties]$mv$, content = $mv$Toucher une aide oui, mais **en échange de quelque chose** : quelques heures d'activité, une formation, des démarches réelles. Sinon on installe les gens dans l'assistanat.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Aides sociales : conditionner ou garantir ?$mv$);
update mv_positions set titre = $mv$[Filet et contrôles]$mv$, content = $mv$Je veux un filet solide pour ceux qui tombent, **et** des contrôles sérieux contre les abus. Ni chasse aux pauvres, ni distribution sans regarder.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Aides sociales : conditionner ou garantir ?$mv$);
update mv_positions set titre = $mv$[Versées automatiquement]$mv$, content = $mv$Le vrai problème, c'est **tous ceux qui n'osent pas ou ne savent pas** demander. Les aides devraient arriver toutes seules quand on y a droit, sans parcours du combattant.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Aides sociales : conditionner ou garantir ?$mv$);
update mv_positions set titre = $mv$[Un droit pour tous]$mv$, content = $mv$Se soigner, se loger, manger : ce sont des **droits, sans condition**. Une aide qu'il faut mériter n'est plus un droit, c'est une récompense qu'on peut retirer.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Aides sociales : conditionner ou garantir ?$mv$);

-- Défense : Ukraine, Russie, OTAN
update mv_positions set titre = $mv$[Aider l'Ukraine à fond]$mv$, content = $mv$On donne **tout ce qu'on peut** à l'Ukraine et on renforce l'alliance avec nos voisins. Si l'agresseur gagne là-bas, il recommencera plus près, et ce sera notre tour.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Défense : Ukraine, Russie, OTAN$mv$);
update mv_positions set titre = $mv$[Se réarmer sérieusement]$mv$, content = $mv$Il faut **redevenir capables de nous défendre** : des usines d'armement, des stocks, une armée équipée. Aider l'Ukraine oui, mais sans envoyer nos soldats.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Défense : Ukraine, Russie, OTAN$mv$);
update mv_positions set titre = $mv$[Fermes et prudents]$mv$, content = $mv$On aide, on se prépare, **mais on garde la main** sur chaque engagement, et on soutient toute négociation sérieuse. Ni naïf, ni va-t-en-guerre.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Défense : Ukraine, Russie, OTAN$mv$);
update mv_positions set titre = $mv$[D'abord notre armée]$mv$, content = $mv$Ma priorité c'est **la défense de la France**, pas une armée européenne sans chef. On aide l'Ukraine avec mesure, sans se laisser entraîner dans une guerre qui n'est pas la nôtre.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Défense : Ukraine, Russie, OTAN$mv$);
update mv_positions set titre = $mv$[Surtout ne pas s'engager]$mv$, content = $mv$Chaque livraison d'armes nous **rapproche du conflit**. La France doit parler à tout le monde, chercher la paix, et ne suivre aveuglément aucun camp.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Défense : Ukraine, Russie, OTAN$mv$);

-- Prestations sociales : les Français d'abord ?
update mv_positions set titre = $mv$[Les Français d'abord]$mv$, content = $mv$Logement social, allocations, aides : **d'abord pour les Français**. On ne peut pas aider la terre entière quand nos propres retraités comptent chaque euro.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Prestations sociales : les Français d'abord ?$mv$);
update mv_positions set titre = $mv$[Après plusieurs années ici]$mv$, content = $mv$On accueille, mais **pas de versement dès l'arrivée**. Quelques années de travail et de cotisations dans le pays avant d'ouvrir les mêmes droits, c'est la moindre des choses.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Prestations sociales : les Français d'abord ?$mv$);
update mv_positions set titre = $mv$[Qui cotise a droit]$mv$, content = $mv$Simple : **qui travaille et cotise ici a les mêmes droits**. Pour le reste, une durée de présence raisonnable, et la même règle pour tout le monde.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Prestations sociales : les Français d'abord ?$mv$);
update mv_positions set titre = $mv$[Mêmes impôts, mêmes droits]$mv$, content = $mv$Quelqu'un qui paie les mêmes impôts et les mêmes cotisations doit avoir **exactement les mêmes droits**. Trier selon le passeport, c'est fabriquer des citoyens de seconde zone.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Prestations sociales : les Français d'abord ?$mv$);
update mv_positions set titre = $mv$[Aucune distinction]$mv$, content = $mv$**Mêmes droits pour tous ceux qui vivent ici**, sans condition de nationalité ni d'ancienneté. On aide une personne parce qu'elle en a besoin, pas selon ses papiers.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Prestations sociales : les Français d'abord ?$mv$);

-- Agriculture : produire ou transformer ?
update mv_positions set titre = $mv$[Produire, d'abord]$mv$, content = $mv$Qu'on **laisse les agriculteurs travailler**. Trop de règles, trop de paperasse : on finit par importer ce qu'on s'interdit de produire, et personne n'y gagne.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Agriculture : produire ou transformer ?$mv$);
update mv_positions set titre = $mv$[Moins de contraintes]$mv$, content = $mv$Alléger les normes et **garantir des prix corrects**, sinon les fermes ferment. On ne peut pas exiger toujours plus de quelqu'un qui ne vit déjà pas de son métier.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Agriculture : produire ou transformer ?$mv$);
update mv_positions set titre = $mv$[Changer au bon rythme]$mv$, content = $mv$Réduire les produits chimiques **quand il existe une solution qui marche**, et pas avant. On accompagne, on n'interdit pas du jour au lendemain.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Agriculture : produire ou transformer ?$mv$);
update mv_positions set titre = $mv$[Payer la transition]$mv$, content = $mv$Des objectifs clairs de baisse des pesticides, mais **l'État finance le changement**. Passer au bio ou replanter des haies ne doit pas ruiner celui qui s'y met.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Agriculture : produire ou transformer ?$mv$);
update mv_positions set titre = $mv$[Une autre agriculture]$mv$, content = $mv$**Fin des pesticides de synthèse et de l'élevage industriel**. Une agriculture qui soigne les sols et l'eau, plus proche et plus petite, même si ça coûte un peu plus cher.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Agriculture : produire ou transformer ?$mv$);

-- École : mérite ou égalité ?
update mv_positions set titre = $mv$[Autorité et mérite]$mv$, content = $mv$L'école doit **remettre de la discipline et du mérite** : des notes, du redoublement, des filières exigeantes. Nier les différences de niveau n'a jamais aidé personne.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$École : mérite ou égalité ?$mv$);
update mv_positions set titre = $mv$[Les bases et le respect]$mv$, content = $mv$Priorité au **lire, écrire, compter**, et au respect du professeur. À force de vouloir mettre tout le monde au même niveau, on a baissé le niveau de tous.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$École : mérite ou égalité ?$mv$);
update mv_positions set titre = $mv$[Exigeant et bienveillant]$mv$, content = $mv$De l'exigence, **et** du soutien pour ceux qui décrochent. On évalue sans humilier, on oriente sans condamner un gamin à quatorze ans.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$École : mérite ou égalité ?$mv$);
update mv_positions set titre = $mv$[Réduire les écarts]$mv$, content = $mv$Là où c'est difficile, il faut **des classes plus petites et des profs mieux payés**. Aujourd'hui l'école reproduit surtout le milieu d'où l'on vient.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$École : mérite ou égalité ?$mv$);
update mv_positions set titre = $mv$[L'école doit rattraper]$mv$, content = $mv$**Des moyens massifs**, plus de tri précoce, une vraie mixité entre établissements. L'école doit corriger les inégalités de départ, pas se contenter de les constater.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$École : mérite ou égalité ?$mv$);

-- Logement : marché ou intervention publique ?
update mv_positions set titre = $mv$[Laissons construire]$mv$, content = $mv$S'il n'y a pas de logements, c'est qu'on **empêche de construire**. Débloquez les permis et le terrain, allégez la fiscalité du propriétaire, et l'offre reviendra.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Logement : marché ou intervention publique ?$mv$);
update mv_positions set titre = $mv$[Construire et rassurer]$mv$, content = $mv$Simplifier les règles, aider à devenir propriétaire, et **rassurer ceux qui louent leur bien**. Plus de logements disponibles fera baisser les loyers mieux qu'un plafond.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Logement : marché ou intervention publique ?$mv$);
update mv_positions set titre = $mv$[Construire et encadrer]$mv$, content = $mv$**Les deux** : on construit beaucoup, et on met le holà aux abus — meublés touristiques, logements insalubres, loyers délirants dans les grandes villes.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Logement : marché ou intervention publique ?$mv$);
update mv_positions set titre = $mv$[Encadrer les loyers]$mv$, content = $mv$Se loger n'est pas un placement, c'est un **besoin**. Il faut plafonner les loyers, remettre sur le marché les logements vides, construire beaucoup plus de social.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Logement : marché ou intervention publique ?$mv$);
update mv_positions set titre = $mv$[Logement public]$mv$, content = $mv$**Du logement public en masse** et des loyers bloqués. Quarante ans qu'on attend que le marché règle la crise : il l'a aggravée, à l'État de reprendre la main.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Logement : marché ou intervention publique ?$mv$);

-- Famille : encourager la natalité ?
update mv_positions set titre = $mv$[Il faut des naissances]$mv$, content = $mv$Un pays sans enfants n'a pas d'avenir. Il faut **encourager clairement la natalité** : allocations dès le premier enfant, avantages fiscaux, congé long et bien payé.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Famille : encourager la natalité ?$mv$);
update mv_positions set titre = $mv$[Aider les familles]$mv$, content = $mv$Beaucoup de couples **voudraient un enfant de plus** et renoncent, faute de place en crèche ou de moyens. Aider les familles, ce n'est pas de l'idéologie, c'est du concret.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Famille : encourager la natalité ?$mv$);
update mv_positions set titre = $mv$[Aider sans encourager]$mv$, content = $mv$L'État aide les familles qui existent — crèches, congés — **sans se fixer d'objectif de naissances**. Combien d'enfants faire, ça ne le regarde pas.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Famille : encourager la natalité ?$mv$);
update mv_positions set titre = $mv$[Aider les personnes]$mv$, content = $mv$L'aide doit aller **à l'enfant et au parent qui l'élève**, surtout quand il est seul, plutôt qu'à un modèle de famille. Et le congé se partage à parts égales.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Famille : encourager la natalité ?$mv$);
update mv_positions set titre = $mv$[Cela ne regarde que moi]$mv$, content = $mv$Faire un enfant est un **choix strictement privé**. On aide les gens selon leurs revenus et leurs difficultés, jamais selon le nombre d'enfants qu'ils ont eus.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Famille : encourager la natalité ?$mv$);

-- Institutions : exécutif fort ou pouvoir au peuple ?
update mv_positions set titre = $mv$[Un chef qui tranche]$mv$, content = $mv$Il faut **quelqu'un qui décide** et qui assume. À force de consulter tout le monde, on ne fait plus rien : un pays se dirige, il ne se met pas aux voix chaque matin.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Institutions : exécutif fort ou pouvoir au peuple ?$mv$);
update mv_positions set titre = $mv$[De la stabilité]$mv$, content = $mv$Je préfère un pouvoir **solide et stable** à une assemblée ingouvernable. On peut consulter les citoyens de temps en temps, mais quelqu'un doit garder le cap.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Institutions : exécutif fort ou pouvoir au peuple ?$mv$);
update mv_positions set titre = $mv$[Rééquilibrer un peu]$mv$, content = $mv$Le président a **un peu trop de pouvoir** et le Parlement pas assez. Un rééquilibrage et une meilleure représentation des voix, sans tout refonder pour autant.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Institutions : exécutif fort ou pouvoir au peuple ?$mv$);
update mv_positions set titre = $mv$[Le Parlement d'abord]$mv$, content = $mv$C'est **l'Assemblée qui doit faire la loi**, avec une représentation fidèle des votes. Le président n'est pas un roi élu pour cinq ans sans personne pour le contrôler.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Institutions : exécutif fort ou pouvoir au peuple ?$mv$);
update mv_positions set titre = $mv$[Le peuple décide]$mv$, content = $mv$**Référendums à l'initiative des citoyens**, possibilité de révoquer un élu, nouvelle constitution écrite par des citoyens. Voter tous les cinq ans, ce n'est pas décider.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Institutions : exécutif fort ou pouvoir au peuple ?$mv$);

-- Patrimoine et capital : protéger ou taxer ?
update mv_positions set titre = $mv$[Pas touche au patrimoine]$mv$, content = $mv$Ce qu'on a mis de côté a **déjà été imposé une fois**. Taxer l'épargne, l'héritage ou les placements, c'est punir ceux qui ont fait attention et faire fuir l'argent.$mv$, updated_at = now()
  where pos = 1 and node_id = (select id from mv_nodes where label = $mv$Patrimoine et capital : protéger ou taxer ?$mv$);
update mv_positions set titre = $mv$[Encourager à investir]$mv$, content = $mv$Il faut que placer son argent et **transmettre à ses enfants** reste intéressant. On allège la succession et on récompense ceux qui investissent dans les entreprises.$mv$, updated_at = now()
  where pos = 2 and node_id = (select id from mv_nodes where label = $mv$Patrimoine et capital : protéger ou taxer ?$mv$);
update mv_positions set titre = $mv$[Comme un salaire]$mv$, content = $mv$Un revenu du capital doit être taxé **comme un revenu du travail**, ni plus ni moins. Pas de cadeau, pas de punition : la même règle pour tout le monde.$mv$, updated_at = now()
  where pos = 3 and node_id = (select id from mv_nodes where label = $mv$Patrimoine et capital : protéger ou taxer ?$mv$);
update mv_positions set titre = $mv$[Patrimoines élevés taxés]$mv$, content = $mv$Les grandes fortunes doivent **contribuer davantage** : impôt sur les patrimoines élevés, gros héritages moins avantagés. Le patrimoine a explosé, pas les salaires.$mv$, updated_at = now()
  where pos = 4 and node_id = (select id from mv_nodes where label = $mv$Patrimoine et capital : protéger ou taxer ?$mv$);
update mv_positions set titre = $mv$[Taxer fortement la fortune]$mv$, content = $mv$**Impôt lourd sur les très grandes fortunes et plafond sur l'héritage**. À la troisième génération qui vit d'une rente, on ne parle plus de mérite mais de privilège.$mv$, updated_at = now()
  where pos = 5 and node_id = (select id from mv_nodes where label = $mv$Patrimoine et capital : protéger ou taxer ?$mv$);

update mv_reponses set pos = 3, updated_at = now()
  where personne_id = 'f58aa768-a85e-4539-a2c8-b09e7b1517bd' and node_id = (select id from mv_nodes where label = $mv$Sécurité et justice : punir ou prévenir ?$mv$);

commit;
