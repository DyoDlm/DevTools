#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <répertoire_racine>"
    exit 1
fi

target_dir="$1"

# Traitement récursif (répertoires + fichiers)
find "$target_dir" -depth -exec bash -c '
    for path; do
        dirname_path=$(dirname "$path")
        basename_path=$(basename "$path")
        new_basename=$(echo "$basename_path" | tr "[:upper:]" "[:lower:]")
        new_path="$dirname_path/$new_basename"
        if [ "$path" != "$new_path" ]; then
            echo "Renommage : $path → $new_path"
            mv -v "$path" "$new_path"
        fi
    done
' bash {} +
