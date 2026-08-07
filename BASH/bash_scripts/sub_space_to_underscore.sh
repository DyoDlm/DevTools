#!/bin/bash

# Vérification des arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <répertoire_racine>"
    echo "Exemple: $0 /chemin/vers/mon_dossier"
    exit 1
fi

target_dir="$1"

if [ ! -d "$target_dir" ]; then
    echo "Erreur : '$target_dir' n'est pas un répertoire valide."
    exit 1
fi

# Traitement récursif (répertoires ET fichiers)
find "$target_dir" -depth -name "* *" -type d -exec bash -c '
    for dir; do
        new_name="${dir// /_}"  # Remplace les espaces par _
        if [ "$dir" != "$new_name" ]; then
            echo "Renommage : $dir → $new_name"
            mv -v "$dir" "$new_name"
        fi
    done
' bash {} +

# Optionnel : Faire de même pour les fichiers
find "$target_dir" -depth -name "* *" ! -type d -exec bash -c '
    for file; do
        new_name="${file// /_}"
        if [ "$file" != "$new_name" ]; then
            echo "Renommage fichier : $file → $new_name"
            mv -v "$file" "$new_name"
        fi
    done
' bash {} +
