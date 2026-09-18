#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "❌ Usage: $0 <répertoire> <ancien_préfixe> <nouveau_préfixe>"
    exit 1
fi

target_dir="$1"
old_prefix="$2"
new_prefix="$3"

if [ ! -d "$target_dir" ]; then
    echo "❌ Erreur : '$target_dir' n'est pas un répertoire valide."
    exit 1
fi

# Afficher les modifications avant de les appliquer
echo "🔍 Aperçu des modifications :"
count=0
while IFS= read -r -d '' file; do
    dirname_path=$(dirname "$file")
    basename_path=$(basename "$file")
    if [[ "$basename_path" == "$old_prefix"* ]]; then
        suffix_with_ext="${basename_path#$old_prefix}"
        new_basename="$new_prefix$suffix_with_ext"
        new_path="$dirname_path/$new_basename"
        echo "   $file → $new_path"
        ((count++))
    fi
done < <(find "$target_dir" -type f -print0)

if [ "$count" -eq 0 ]; then
    echo "⚠️  Aucun fichier ne commence par '$old_prefix'."
    exit 0
fi

read -p "❓ Appliquer ces modifications ? (o/n) : " -n 1 -r
echo
if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
    echo "❌ Annulé."
    exit 0
fi

# Appliquer les modifications
count=0
while IFS= read -r -d '' file; do
    dirname_path=$(dirname "$file")
    basename_path=$(basename "$file")
    if [[ "$basename_path" == "$old_prefix"* ]]; then
        suffix_with_ext="${basename_path#$old_prefix}"
        new_basename="$new_prefix$suffix_with_ext"
        new_path="$dirname_path/$new_basename"
        mv -v "$file" "$new_path" && ((count++))
    fi
done < <(find "$target_dir" -type f -print0)

echo "✅ $count fichier(s) renommé(s)."
