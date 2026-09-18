#!/usr/bin/env bash
#
# yt_download.sh - Télécharge en masse des pistes audio depuis YouTube
#
# Usage : ./yt_download.sh <format> <fichier_liste.conf>
#
# Le fichier de configuration doit contenir une entrée par ligne :
#   nom_du_son  https://youtube.com/lien
#
# Exemple de list.conf :
#   sound1 https://youtube.com/linktoasound1
#   sound2 https://youtube.com/linktoasound2

set -euo pipefail

# --- Vérification des arguments ---
if [[ $# -ne 2 ]]; then
    echo "Usage : $0 <format> <fichier_liste.conf>" >&2
    echo "Exemple : $0 mp3 list.conf" >&2
    exit 1
fi

FORMAT="$1"
LIST_FILE="$2"
OUTPUT_DIR="./downloads"

# --- Vérification des dépendances ---
if ! command -v yt-dlp &> /dev/null; then
    echo "Erreur : yt-dlp n'est pas installé. Installez-le avec : pip install -U yt-dlp" >&2
    exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
    echo "Erreur : ffmpeg n'est pas installé (nécessaire pour la conversion audio)." >&2
    exit 1
fi

# --- Vérification du fichier de liste ---
if [[ ! -f "$LIST_FILE" ]]; then
    echo "Erreur : le fichier '$LIST_FILE' est introuvable." >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# --- Compteurs ---
total=0
success=0
failed=0
failed_names=()

echo "=== Téléchargement des pistes au format .$FORMAT ==="
echo "Fichier de configuration : $LIST_FILE"
echo "Dossier de sortie        : $OUTPUT_DIR"
echo

# --- Lecture ligne par ligne du fichier ---
while IFS= read -r line || [[ -n "$line" ]]; do
    # Ignore les lignes vides et les commentaires (#)
    [[ -z "${line// }" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    # Découpe la ligne en nom (1er champ) + URL (2e champ)
    name=$(awk '{print $1}' <<< "$line")
    url=$(awk '{print $2}' <<< "$line")

    if [[ -z "$name" || -z "$url" ]]; then
        echo "Ligne ignorée (format invalide) : $line" >&2
        continue
    fi

    total=$((total + 1))
    echo "[$total] Téléchargement de '$name' depuis $url ..."

    if yt-dlp -x --audio-format "$FORMAT" --audio-quality 0 \
        -o "${OUTPUT_DIR}/${name}.%(ext)s" \
        "$url"; then
        success=$((success + 1))
        echo "    OK -> ${OUTPUT_DIR}/${name}.${FORMAT}"
    else
        failed=$((failed + 1))
        failed_names+=("$name")
        echo "    Échec du téléchargement pour '$name'" >&2
    fi
    echo
done < "$LIST_FILE"

# --- Résumé ---
echo "=== Résumé ==="
echo "Total     : $total"
echo "Réussis   : $success"
echo "Échecs    : $failed"
if [[ $failed -gt 0 ]]; then
    echo "Échecs pour : ${failed_names[*]}"
fi
