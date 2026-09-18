#!/bin/bash

# Définis ta fonction de renommage ici
rename_function() {
    local old_name="$1"
    # Exemple : Remplace les tirets par des underscores et met en minuscules
    local new_name=$(echo "$old_name" | tr "-" "_" | tr "[:upper:]" "[:lower:]")
    echo "$new_name"
}

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <répertoire_racine>"
    exit 1
fi

target_dir="$1"

find "$target_dir" -depth -exec bash -c '
    for path; do
        dirname_path=$(dirname "$path")
        basename_path=$(basename "$path")
        new_basename=$(rename_function "$basename_path")
        new_path="$dirname_path/$new_basename"
        if [ "$path" != "$new_path" ]; then
            echo "Renommage : $path → $new_path"
            mv -v "$path" "$new_path"
        fi
    done
' bash {} +
