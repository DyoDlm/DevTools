#!/bin/bash

COMPILER="pdflatex"
SRC_DIR="./srcs"
LOG_DIR="tex_aux"
MAIN="main.tex"
PDF="main.pdf"

info()    { echo -e "\033[36m$1\033[0m"; }
error()   { echo -e "\033[31m$1\033[0m"; }
success() { echo -e "\033[32m$1\033[0m"; }
warning() { echo -e "\033[33m$1\033[0m"; }


TIME_FILE="$LOG_DIR/.last_time"

show_time() {
    local estimated=$1
    local start
    start=$(date +%s)
    local width=40

    while true; do
        local now elapsed percent filled empty
        now=$(date +%s)
        elapsed=$((now - start))
        percent=$(( elapsed * 100 / estimated ))
        [[ $percent -gt 99 ]] && percent=99
        filled=$(( percent * width / 100 ))
        empty=$(( width - filled ))

        printf "\r["
        printf "%0.s#" $(seq 1 $filled) 2>/dev/null
        printf "%0.s-" $(seq 1 $empty) 2>/dev/null
        printf "] %3d%% (%ds/%ds estimé)" "$percent" "$elapsed" "$estimated"

        sleep 0.2
    done
}

toggle_compile() {
	if [[ $COMPILE == "y" ]]; then
		COMPILE="n"
	else
		COMPILE="y"
	fi
	STATE_A=""
}

simple_compile() {
    if [[ $COMPILE == "n" ]]; then
        compile
    fi
    STATE_A=""
}

compile() {
	mkdir -p "$LOG_DIR"

	local estimated=10
	[[ -f "$TIME_FILE" ]] && estimated=$(cat "$TIME_FILE")
	[[ -z "$estimated" || "$estimated" -le 0 ]] && estimated=10

	local t_start
	t_start=$(date +%s)

	show_time "$estimated" &
	local bar_pid=$!

	# Nom du .aux : pdflatex l'écrit dans le dossier courant,
	# avec le nom du fichier principal sans chemin ni extension
	local base
	base=$(basename "${MAIN%.tex}")

	# On repart d'un journal vide, sinon les anciennes erreurs
	# s'affichent encore après une compilation réussie
	: > "$LOG_DIR/dbug"

	info "FIRST COMPILATION"
	echo Q | $COMPILER "$MAIN" >> "$LOG_DIR/dbug" 2>&1

	# bibtex seulement si le document contient \bibliography{...}
	if grep -q '\\bibdata' "$base.aux" 2>/dev/null; then
		info "BIBLIOGRAPHY"
		bibtex "$base" >> "$LOG_DIR/dbug" 2>&1
		info "SECOND COMPILATION"
		echo Q | $COMPILER "$MAIN" >> "$LOG_DIR/dbug" 2>&1
	fi

	info "LAST COMPILATION"
	echo Q | $COMPILER "$MAIN" >> "$LOG_DIR/dbug" 2>&1

	kill "$bar_pid" 2>/dev/null
	wait "$bar_pid" 2>/dev/null
	printf "\r[%s] 100%%%s\n" "$(printf '%0.s#' $(seq 1 40))" "                    "

	local t_end duration
	t_end=$(date +%s)
	duration=$((t_end - t_start))
	echo "$duration" > "$TIME_FILE"

	for FORMAT in \
		*.log *.aux *.toc *.out *.bbl *.blg \
		srcs/*.aux srcs/*.toc srcs/*.out srcs/*.log \
		srcs/*/*.aux srcs/*/*.toc srcs/*/*.out srcs/*/*.log
	do
		mv "$FORMAT" "$LOG_DIR/" 2>/dev/null
	done
}

get_state() {
	if [[ $(uname) == "Linux" ]]; then
		MD5="md5sum"
	else
		MD5="md5"
	fi
	SRC_STATE=$(find -L "$SRC_DIR" -type f \( -name "*.tex" -o -name "*.bib" \) -exec $MD5 {} \;)
	MAIN_STATE=$(find . -maxdepth 1 \( -name "*.tex" -o -name "*.bib" \) -exec $MD5 {} \;)
	echo "$SRC_STATE $MAIN_STATE"
}

get_file_hashes() {
	if [[ $(uname) == "Linux" ]]; then
		MD5="md5sum"
	else
		MD5="md5"
	fi
	find -L "$SRC_DIR" -type f \( -name "*.tex" -o -name "*.bib" \) -exec $MD5 {} \;
	find . -maxdepth 1 \( -name "*.tex" -o -name "*.bib" \) -exec $MD5 {} \;
}

fetch_modifications() {
	local snapshot="$LOG_DIR/.state_snapshot"
	local current
	current=$(get_file_hashes)

	if [[ -f "$snapshot" ]]; then
		diff "$snapshot" <(echo "$current") \
			| grep -E '^[<>]' \
			| awk '{print $NF}' \
			| sort -u > "$LOG_DIR/.modified_files"
	else
		echo "$current" | awk '{print $NF}' | sort -u > "$LOG_DIR/.modified_files"
	fi

	echo "$current" > "$snapshot"
}

watch() {
	STATE_A=""
    CONTENT_A=""
	COMPILE="y"
    BACKUP="y"
    mkdir -p $SRC_DIR
    mkdir -p $LOG_DIR

	while true; do

		if read -r -s -n 1 -t 0.1 key 2>/dev/null; then
			[[ "$key" == "p" ]] && toggle_compile
            [[ "$key" == "c" ]] && simple_compile
            [[ "$key" == "q" ]] && break
		fi

		STATE_B=$(get_state)
    
        if [[ "$STATE_A" != "$STATE_B" ]]; then
			STATE_A="$STATE_B"
			clear
			info "───────── $(date) ─────────"
            
            fetch_modifications

			if [[ $COMPILE == "y" ]]; then
				rm -f "$PDF"
				compile
				sleep 0.5

				if [ ! -f "$PDF" ]; then
					error "\n\nCOMPILATION\tERROR\n\n"
					grep -i "error\|fatal" "$LOG_DIR/dbug" 2>/dev/null | head -20
				else
					success "\n\nCOMPILATION\tOK\n\n"
                    [[ $BACKUP == "y" ]] && cp "$PDF" ..
					info "───────────────────────────────────────────────────\n"
					#cp "$PDF" $LOG_DIR
                    xdg-open "$PDF" &>/dev/null &
				fi

				# Clés \cite{...} absentes du .bib (le PDF se crée quand même,
				# avec des [?] à la place des numéros)
				if grep -q "didn't find a database entry" "$LOG_DIR/dbug" 2>/dev/null; then
					warning "\nRÉFÉRENCES MANQUANTES DANS LE .bib :"
					grep -o "didn't find a database entry for \"[^\"]*\"" "$LOG_DIR/dbug" | sort -u | head -10
				fi
			else
				warning "\nAuto-compilation en pause\n"
			fi

            echo $STATE_A
            echo $STATE_B
            info "────────────────────── INFO ─────────────────────────\n\n"

            info "Compilation Time Estimation : $(cat $LOG_DIR/.last_time)"
            
            echo
            
            info "FILES MODIFIED : "

            warning "$(cat $LOG_DIR/.modified_files)"

            echo 
			info "────────────────────── WAITING A MODIFICATION ─────────────────────────\n\n"
			if [[ $COMPILE == "n" ]]; then
				info "           ────────── p : restart auto-compiling ────────── "
                info "           ────────── c : simple compilation  ────────── "
                info "           ────────── q : quit  ────────── "

			else
				info "           ────────── p : stop auto-compiling ────────── "
                info "           ────────── q : quit  ────────── "
			fi
		fi
	done
}

watch "$@"
