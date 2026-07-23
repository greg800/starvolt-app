# Données métier — Estimation DPE (non contractuelle)

Ce document sert de **référence métier au service IA « Ton bilan en clair »**.
Il permet de situer un foyer chauffé à l'électricité par rapport au parc français
et de générer une **phrase d'estimation DPE non contractuelle** dans le bilan.

Périmètre : **logements chauffés à l'électricité** (maison individuelle ou appartement).

---

## Table de travail (tout-en-un)

Comparer la consommation surfacique du foyer (kWh/m²/an) au **seuil haut** de chaque
classe : la classe DPE estimée est la **première dont le seuil est ≥ à la valeur du foyer**.

| Classe DPE | Seuil haut (kWh/m²/an) | Part du chauffage dans la conso | % des **maisons** qui consomment **moins** | % des **appartements** qui consomment **moins** |
|:---:|:---:|:---:|:---:|:---:|
| A | ≤ 22  | 30 % | 0 %  | 0 %  |
| B | ≤ 39  | 40 % | 2 %  | 4 %  |
| C | ≤ 63  | 50 % | 10 % | 18 % |
| D | ≤ 93  | 60 % | 30 % | 45 % |
| E | ≤ 126 | 65 % | 58 % | 71 % |
| F | ≤ 163 | 70 % | 80 % | 87 % |
| G | > 163 | 75 % | 92 % | 95 % |

- **Seuil haut** : borne supérieure de consommation surfacique de la classe.
- **% qui consomment moins** = cumul des classes meilleures (lettres précédentes) pour le
  type d'habitat considéré. Déjà pré-calculé dans la table ci-dessus (rien à additionner).
- **Part du chauffage** : fraction de la consommation totale imputable au chauffage —
  utile pour orienter les conseils (flexibilité, heures creuses, délestage, pilotage…).

---

## Mode d'emploi (comment générer la phrase métier)

1. **Consommation surfacique** = consommation annuelle (kWh) ÷ surface (m²).
   - Si la surface exacte est inconnue (seule une tranche est déclarée), prendre le
     **milieu de tranche** : « moins de 70 m² » → **50 m²** ; « 70 à 150 m² » → **110 m²** ;
     « plus de 150 m² » → **180 m²**.
2. **Classe DPE estimée** : comparer le résultat aux seuils hauts (colonne « Seuil haut »).
   La classe est la première dont le seuil est ≥ à la valeur obtenue.
3. **Type d'habitat** : choisir la colonne « maisons » ou « appartements » selon le logement.
4. **% qui consomment moins que vous** : lire directement la case correspondante (classe × type).
5. **Rédiger** la phrase, toujours présentée comme une **estimation non contractuelle**.

---

## Exemple

Foyer : **5 MWh/an** (5 000 kWh), **maison** de **100 m²**.

- Conso surfacique = 5 000 ÷ 100 = **50 kWh/m²/an**.
- 50 ≤ 63 → **classe C** (car 50 > 39, donc pas B ; 50 ≤ 63, donc C).
- Maison, classe C → **10 %** des maisons consomment moins.

**Phrase générée :**
> Vous consommez 50 kWh/m² = notre estimation (non contractuelle) **DPE C**,
> 10 % des maisons consomment moins que vous.

---

## Estimation de la consommation et du coût du chauffage

Une fois la classe DPE estimée, on peut estimer ce que **pèse le chauffage** dans le foyer,
à partir de la colonne « Part du chauffage » de la table de travail.

**Méthode :**

1. **Part du chauffage (X %)** = valeur de la colonne « Part du chauffage » pour la classe
   DPE estimée (A = 30 % … G = 75 %).
2. **Consommation chauffage (Y)** = consommation annuelle (kWh) × X %.
   - Exprimer en MWh si ≥ 1 000 kWh (ex. 2 500 kWh → 2,5 MWh).
3. **Coût du chauffage (Z)** = facture annuelle (€) × X %.

Ces deux grandeurs (consommation annuelle et facture annuelle) sont fournies dans les
données du foyer : ne rien recalculer d'autre, juste appliquer le pourcentage.

**Phrase à générer** (à formuler comme une estimation) :

> Nous estimons que votre chauffage représente environ **X %** de votre facture,
> soit **~Y MWh** et **~Z €/an**.

**Exemple** (dans le prolongement du précédent) : maison DPE C → part du chauffage = 50 %.
Conso 5 MWh → chauffage ≈ **2,5 MWh/an**. Facture 1 000 €/an → chauffage ≈ **500 €/an**.
→ « Nous estimons que votre chauffage représente environ 50 % de votre facture, soit
~2,5 MWh et ~500 €/an. »

- N'inclure cette phrase que si la **classe DPE a pu être estimée** ET que la **facture
  annuelle** (pour le montant en €) et/ou la **consommation annuelle** (pour les MWh) sont
  connues. Si seule la conso est connue, ne donner que les MWh ; si seule la facture est
  connue, ne donner que les €.
- Arrondir raisonnablement (chiffres « ronds », préfixe « ~ » ou « environ ») : c'est une
  estimation, pas une facture détaillée.

---

## Consignes de rédaction pour l'IA

- Inclure la phrase métier dans le bilan **uniquement si la surface (ou sa tranche) ET la
  consommation annuelle sont connues**. Sinon, ne pas l'inventer.
- Toujours qualifier l'estimation de **« non contractuelle »** ; ne jamais la présenter
  comme un DPE officiel (le vrai DPE dépend de bien d'autres facteurs).
- Rester bienveillant : une classe basse n'est pas une faute, c'est un **potentiel
  d'amélioration** (isolation, pilotage du chauffage, flexibilité…).
- Tu peux t'appuyer sur la **part du chauffage** pour expliquer pourquoi agir sur le
  chauffage (souvent le premier poste) est un levier majeur pour ce foyer.

---

## Sources chiffrées brutes (pour référence / mise à jour)

**Parc de logements chauffés à l'électricité** — nombre : maison individuelle **8 M**,
appartements **7,2 M**. Répartition par classe (%) :

| Classe DPE | Maison individuelle | Appartement |
|:---:|:---:|:---:|
| A | 2 %  | 4 %  |
| B | 8 %  | 14 % |
| C | 20 % | 27 % |
| D | 28 % | 26 % |
| E | 22 % | 16 % |
| F | 12 % | 8 %  |
| G | 8 %  | 5 %  |

**Consommation de référence par classe (kWh/m²/an)** — identique maison / appartement :
A = 22 · B = 39 · C = 63 · D = 93 · E = 126 · F = 163 · G = 200.

**Part du chauffage dans la consommation (%)** — identique maison / appartement :
A = 30 · B = 40 · C = 50 · D = 60 · E = 65 · F = 70 · G = 75.
