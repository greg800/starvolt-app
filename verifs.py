#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Vérifications avant mise en prod de starvolt.html.

Pourquoi ce fichier et pas des tests unitaires : l'application est un seul
document HTML compilé par Babel dans le navigateur, sans node ni npm sur la
machine de dev — impossible d'exécuter un ESLint ou un test runner. Ce script
ne dépend que de Python 3 et attrape les fautes de React qui ont RÉELLEMENT
cassé la prod :

  1. hook appelé après un `return` anticipé dans un composant
     → « Rendered fewer hooks than expected », écran blanc. Vécu le 2026-08-11 :
       l'écran de confirmation de changement de fournisseur plantait.
  2. composant déclaré dans le corps d'un autre composant
     → React le démonte/remonte à chaque frappe ; les clics tombent sur un
       nœud détaché. Vécu sur les boutons de mise en forme de la description
       fournisseur.

Le découpage s'appuie sur la convention du fichier : les composants sont
déclarés en colonne 0 (`function NomDuComposant(`) et leur corps est indenté
de 2 espaces. Les hooks au premier niveau du composant sont donc à l'indent 2.

Usage :  python3 verifs.py [fichier.html]
Sortie :  0 = rien à signaler, 1 = au moins un problème.
"""
import re
import sys

HOOK = re.compile(r'^  (?:const|let|var)?\s*.*?\buse(?:State|Effect|LayoutEffect|Memo|Ref|Callback|Context|Reducer|ImperativeHandle)\s*\(')
# `return` au premier niveau du composant : soit `  return`, soit `  if (…) return …`
RETURN_NIV1 = re.compile(r'^  (?:return\b|if\s*\(.*\)\s*return\b)')
IF_NIV1_OUVRANT = re.compile(r'^  if\s*\(.*\)\s*\{\s*$')
DEBUT_COMPOSANT = re.compile(r'^function ([A-Z]\w*)\s*\(')
DEBUT_TOP = re.compile(r'^(?:function|const|let|var|class)\s')
# composant imbriqué : `  const Truc = (` / `  function Truc(` (majuscule initiale)
IMBRIQUE = re.compile(r'^ {2,}(?:const|let|var)\s+([A-Z]\w*)\s*=\s*(?:\(|function|React\.memo)|^ {2,}function\s+([A-Z]\w*)\s*\(')


def extraire_script(html: str) -> tuple[str, int]:
    """Renvoie le contenu du <script type="text/babel"> et sa ligne de départ."""
    m = re.search(r'<script type="text/babel"[^>]*>', html)
    if not m:
        return '', 0
    debut = m.end()
    fin = html.index('</script>', debut)
    return html[debut:fin], html[:debut].count('\n') + 1


def composants(src: str):
    """Découpe le script en composants : (nom, ligne_de_depart, lignes)."""
    lignes = src.split('\n')
    bornes = []
    for i, l in enumerate(lignes):
        m = DEBUT_COMPOSANT.match(l)
        if m:
            bornes.append((i, m.group(1)))
    for n, (i, nom) in enumerate(bornes):
        fin = len(lignes)
        for j in range(i + 1, len(lignes)):
            if DEBUT_TOP.match(lignes[j]):
                fin = j
                break
        yield nom, i, lignes[i:fin]


def controler(chemin: str) -> int:
    html = open(chemin, encoding='utf-8').read()
    src, decalage = extraire_script(html)
    if not src:
        print(f'{chemin} : aucun <script type="text/babel"> trouvé.')
        return 1

    erreurs = []        # bloquant : ça plante en prod
    avertissements = [] # dette : ça ne plante pas, mais c'est à corriger
    for nom, depart, corps in composants(src):
        ligne_return = None
        profondeur_if = 0
        for k, l in enumerate(corps):
            # On ignore le corps d'un `if (…) {` de premier niveau : un return
            # qui s'y trouve est un return anticipé, c'est justement le cas 1.
            if IF_NIV1_OUVRANT.match(l):
                profondeur_if += 1
            if RETURN_NIV1.match(l) and ligne_return is None:
                ligne_return = k
            elif profondeur_if and re.match(r'^    return\b', l) and ligne_return is None:
                ligne_return = k

            if ligne_return is not None and k > ligne_return and HOOK.match(l):
                erreurs.append((
                    decalage + depart + k, nom,
                    'hook après un return anticipé (ligne %d) — React plantera '
                    'l\'écran dès que cette branche sera prise' % (decalage + depart + ligne_return),
                    l.strip()[:80]))

            m = IMBRIQUE.match(l)
            if m and k > 0:
                imbrique = m.group(1) or m.group(2)
                # Un composant imbriqué se reconnaît à ce qu'il rend du JSX.
                suite = '\n'.join(corps[k:k + 12])
                if '<' in suite and 'return' in suite or '=> (' in l or '=> <' in l:
                    avertissements.append((
                        decalage + depart + k, nom,
                        'composant « %s » déclaré dans un composant — React le '
                        'remonte à chaque rendu (état interne, focus et animations '
                        'perdus)' % imbrique,
                        l.strip()[:80]))

    def afficher(titre, liste):
        print('%s : %d\n' % (titre, len(liste)))
        for ligne, comp, quoi, extrait in sorted(liste):
            print(f'  {chemin}:{ligne}  [{comp}]')
            print(f'      {quoi}')
            print(f'      > {extrait}\n')

    if erreurs:
        afficher('ERREURS (bloquant — plantage en prod)', erreurs)
    if avertissements:
        afficher('AVERTISSEMENTS (non bloquant)', avertissements)
    if not erreurs:
        print('verifs : OK — aucun hook après return anticipé.'
              + (' %d avertissement(s) à traiter un jour.' % len(avertissements) if avertissements else ''))
    return 1 if erreurs else 0


if __name__ == '__main__':
    sys.exit(controler(sys.argv[1] if len(sys.argv) > 1 else 'starvolt.html'))
