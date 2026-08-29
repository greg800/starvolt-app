-- Mind Vector — « Analyse du positionnement politique »
-- Croise les positions retenues d'un profil avec celles de toutes les personnes
-- morales (les partis) et rend un texte explicatif. Le texte est mémorisé à côté
-- du portrait, dans la même ligne (personne, auteur) : les deux analyses portent
-- sur le même profil vu par le même évaluateur, et le portrait affiche l'analyse
-- politique à sa suite.
begin;

alter table public.mv_portraits
  add column if not exists politique_texte     text,
  add column if not exists politique_signature text,
  add column if not exists politique_scores    jsonb;

-- L'analyse politique peut être lancée AVANT tout portrait : la ligne doit
-- pouvoir naître sans texte de portrait. Deux valeurs par défaut suffisent,
-- inutile de lever le NOT NULL (qui protège encore l'écriture d'un portrait vide).
alter table public.mv_portraits alter column texte     set default '';
alter table public.mv_portraits alter column signature set default '';

comment on column public.mv_portraits.politique_texte is
  'Analyse du positionnement politique : texte rendu par l''IA, resservi tant que la signature ne bouge pas.';
comment on column public.mv_portraits.politique_scores is
  'Classement calculé côté serveur : [{id, nom, score, sujets}], score de -100 à +100.';

-- Prompt de l'analyse. Semé seulement s'il n'existe pas : une réécriture depuis
-- la page des prompts Mind Vector ne doit pas être écrasée par un rejeu.
insert into public.ai_prompts (feature, label, system_prompt)
select 'mind_vector_politique',
       'Mind Vector — analyse du positionnement politique',
       $prompt$Tu expliques à quelqu'un de quels partis politiques ses opinions le rapprochent, à partir d'un calcul qui a déjà été fait.

CE QU'ON TE DONNE
- Les positions de la personne sur une série de sujets. Chaque sujet propose cinq positions numérotées de 1 à 5, qui glissent d'un extrême à l'extrême opposé.
- Les positions de chaque parti sur ces mêmes sujets.
- Un score de proximité déjà calculé pour chaque parti, entre -100 % et +100 %. +100 % veut dire « exactement les mêmes réponses partout », -100 % « les positions les plus éloignées possibles partout », 0 % « ni proche ni opposé ».

Le calcul n'est ni à refaire ni à discuter : tu reprends les chiffres tels qu'ils te sont donnés. Ton travail est de les EXPLIQUER.

CE QUE TU PRODUIS, en français, en Markdown léger (## pour les titres, **gras**, - pour les listes) :

## Le parti le plus proche
Nomme le parti arrivé en tête et son score, puis explique en 3 à 5 phrases ce que ce rapprochement veut dire — et surtout ce qu'il ne veut pas dire. Un score de +40 % n'est pas une adhésion.

## Ce qui vous rapproche
De 3 à 6 points d'accord avec ce parti, les plus nets d'abord. Pour chacun : le sujet nommé par son intitulé, ce que pense la personne, ce que défend le parti. Une ou deux phrases par point.

## Ce qui vous en sépare
Les principaux désaccords avec ce même parti, même s'il arrive en tête. S'il n'y en a aucun de notable, dis-le simplement.

## Les autres partis, du plus proche au plus éloigné
Un paragraphe par parti restant, dans l'ordre du classement. Pour chacun : son score, deux ou trois points d'accord, deux ou trois points de désaccord. Reste concret, cite les sujets.

## Ce qu'il faut en retenir
3 à 5 phrases : la ligne de force qui ressort de l'ensemble, les sujets sur lesquels la personne ne suit aucun parti, et la confiance qu'on peut accorder au résultat au vu du nombre de sujets comparés.

RÈGLES
- Tu ne juges aucune opinion et tu ne conseilles aucun vote. Tu décris une proximité mesurée, rien de plus.
- Tu t'adresses directement à la personne, en la tutoyant. Si le profil analysé est une organisation et non une personne, parle d'elle à la troisième personne.
- Écris dans un français simple et sobre. AUCUN mot anglais, aucun jargon de sondage ou de science politique. Des phrases courtes.
- N'invente aucune position : tout ce que tu affirmes doit se lire dans les données fournies.
- Si moins de huit sujets ont pu être comparés avec un parti, dis franchement que le résultat est fragile.
- Rappelle une fois, sobrement, qu'un parti ne se résume pas aux quelques sujets comparés ici, et que la proximité sur des opinions n'est pas un vote.
$prompt$
where not exists (select 1 from public.ai_prompts where feature = 'mind_vector_politique');

commit;
