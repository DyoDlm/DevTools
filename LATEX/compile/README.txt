PROJET DE TEST POUR compile.sh
==============================

Arborescence
------------
  main.tex                  fichier principal
  config.tex                vos commandes perso
  references.bib            bibliographie
  srcs/intro.tex            sous-fichier
  srcs/parties/partie1.tex  sous-sous-fichier
  compile.sh                le script

Lancer
------
  cd template_test
  ./compile.sh

Une première compilation se lance tout de suite (aucun état connu).
Le PDF doit contenir une bibliographie numérotée [1] [2] [3].

Tests
-----
  1. Modifier main.tex                -> recompile
  2. Modifier srcs/intro.tex          -> recompile, fichier listé dans FILES MODIFIED
  3. Modifier references.bib          -> recompile (ex. changer l'année de article1)
  4. Dans srcs/intro.tex, décommenter la ligne \cite{inexistant}
                                      -> "RÉFÉRENCES MANQUANTES DANS LE .bib : inexistant"
                                         et [?] dans le PDF
  5. Dans main.tex, décommenter \erreurvolontaire
                                      -> "COMPILATION ERROR" + message d'erreur
  6. Touche p                         -> pause ; modifier un fichier ne recompile plus
     Touche c                         -> compile une fois pendant la pause
     Touche p                         -> reprise
  7. Touche q                         -> quitte

Après chaque compilation, tex_aux/ doit contenir .aux .log .toc .out .bbl .blg
et le dossier racine ne doit garder que les sources et main.pdf.
