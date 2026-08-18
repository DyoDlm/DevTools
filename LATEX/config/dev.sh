#!/bin/bash

COMPILER="pdflatex"
SRC_DIR="./srcs"
LOG_DIR="tex_aux"
MAIN="command_catalog.tex"
PDF="command_catalog.pdf"

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

	info "FIRST COMPILATION"
	echo Q | $COMPILER "$MAIN" >> "$LOG_DIR/dbug" 2>&1
	info "SECOND COMPILATION"
	echo Q | $COMPILER "$MAIN" >> "$LOG_DIR/dbug" 2>&1

	kill "$bar_pid" 2>/dev/null
	wait "$bar_pid" 2>/dev/null
	printf "\r[%s] 100%%%s\n" "$(printf '%0.s#' $(seq 1 40))" "                    "

	local t_end duration
	t_end=$(date +%s)
	duration=$((t_end - t_start))
	echo "$duration" > "$TIME_FILE"

	for FORMAT in \
		*.log *.aux *.toc *.out \
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
	SRC_STATE=$(find -L "$SRC_DIR" -type f -name "*.tex" -exec $MD5 {} \;)
	MAIN_STATE=$(find . -maxdepth 1 -name "$MAIN" -exec $MD5 {} \;)
	echo "$SRC_STATE $MAIN_STATE"
}

watch() {
	STATE_A=""
	COMPILE="y"
    BACKUP="y"

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

			if [[ $COMPILE == "y" ]]; then
				rm -f "$PDF"
				compile
				sleep 0.5

				if [ ! -f "$PDF" ]; then
					error "\n\nCOMPILATION\tERROR\n\n"
					grep -i "error\|fatal" "$LOG_DIR/dbug" 2>/dev/null | head -20
				else
					success "\n\nCOMPILATION\tOK\n\n"
                    if [[ $BACKUP == "y" ]]; then 
                        cp $PDF ..
                    fi
                    [[ $BACKUP == "y" ]] && cp $PDF .. # wich is prettier ??
					info "───────────────────────────────────────────────────\n"
					#cp "$PDF" $LOG_DIR
                    xdg-open "$PDF" &>/dev/null &
				fi
			else
				warning "\nAuto-compilation en pause\n"
			fi

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

mkdir -p srcs

watch "$@"
