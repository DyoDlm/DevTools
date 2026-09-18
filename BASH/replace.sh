#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "❌ Usage: $0 <répertoire> <motif_à_remplacer> <nouveau_motif>"
    exit 1
fi

target_dir="$1"
old_pattern="$2"
new_pattern="$3"

# Vérifications
if [ -z "$old_pattern" ]; then
    echo "❌ Erreur : Le motif à remplacer ne peut pas être vide."
    exit 1
fi

if [ ! -d "$target_dir" ]; then
    echo "❌ Erreur : '$target_dir' n'est pas un répertoire valide."
    exit 1
fi

# Compteur
count=0

# Aperçu
echo "🔍 Aperçu des modifications :"
while IFS= read -r -d '' file; do
    dirname_path=$(dirname "$file")
    basename_path=$(basename "$file")
    new_basename="${basename_path//$old_pattern/$new_pattern}"

    if [ "$basename_path" != "$new_basename" ]; then
        new_path="$dirname_path/$new_basename"
        # Évite les conflits (ex: a → b et b → a)
        if [ -e "$new_path" ]; then
            echo "   ⚠️  Conflit : $file → $new_path (déjà existe)"
        else
            echo "   $file → $new_path"
            ((count++))
        fi
    fi
done < <(find "$target_dir" -type f -print0)

if [ "$count" -eq 0 ]; then
    echo "⚠️  Aucun fichier ne contient '$old_pattern'."
    exit 0
fi

read -p "❓ Appliquer ces modifications ? (o/n) : " -n 1 -r
echo
if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
    echo "❌ Annulé."
    exit 0
fi

# Application
count=0
while IFS= read -r -d '' file; do
    dirname_path=$(dirname "$file")
    basename_path=$(basename "$file")
    new_basename="${basename_path//$old_pattern/$new_pattern}"
    new_path="$dirname_path/$new_basename"

    if [ "$basename_path" != "$new_basename" ] && [ ! -e "$new_path" ]; then
        mv -v "$file" "$new_path" && ((count++))
    fi
done < <(find "$target_dir" -type f -print0)

echo "✅ $count fichier(s) renommé(s)."
