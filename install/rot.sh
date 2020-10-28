#!/bin/bash

# ----------------------------------------------------------------
# Step 1: read arguments
# ----------------------------------------------------------------

printusage () {
	echo "Usage: $0 [OPTIONS] FILE_NAME"
	echo ''
	echo 'Rotates the given file by creating daily, weekly, monthly and yearly hard-'
	echo 'links in dedicated folders in the output directory (see --out option).'
	echo 'Only keeps a given number of copies for the daily, weekly, monthly and yearly'
	echo 'links; all older links will be deleted.'
	echo 'Links will be named after the current date in the format YYYY-MM-DD (daily),'
	echo 'YYYY-WW (weekly), YYYY-MM (monthly) and YYYY (yearly), respectively.'
	echo 'Optionally, a prefix and a suffix for the created links can be specified (with'
	echo 'the --prefix and --suffix options).'
	echo ''
	echo 'Note: this tool also supports an entire directory as FILE_NAME. In this case,'
	echo 'its entire content will be copied as hard links (using "cp -al").'
	echo ''
	echo 'Options:'
	echo '  -?, --help         Displays this help'
	echo '  -d, --daily-num    The number of daily copies that are kept'
	echo '  -w, --weekly-num   The number of weekly copies that are kept'
	echo '  -m, --monthly-num  The number of monthly copies that are kept'
	echo '  -y, --yearly-num   The number of yearly copies that are kept'
	echo '  -p, --prefix       A prefix to be prepended to the file name of the links'
	echo '  -s, --suffix       A suffix to be appended to the file name of the links'
	echo '  -o, --out          The folder in which the links are created; by default,'
	echo '                     files are organised in $OUT_DIR/daily/, $OUT_DIR/weekly/,'
	echo '                     $OUT_DIR/monthly/ and $OUT_DIR/yearly/ sub-folders'
	echo '      --daily-out    Overrides the default folder for daily copies'
	echo '      --weekly-out   Overrides the default folder for weekly copies'
	echo '      --monthly-out  Overrides the default folder for monthly copies'
	echo '      --yearly-out   Overrides the default folder for yearly copies'
	echo '      --now          By default, links will be named after the current date;'
	echo '                     with this option, a different date can be specified;'
	echo '                     the format is any format accepted by "date"'
	echo '      --no-create-daily     If set, no daily copies are created'
	echo '      --no-create-weekly    If set, no weekly copies are created'
	echo '      --no-create-monthly   If set, no monthly copies are created'
	echo '      --no-create-yearly    If set, no yearly copies are created'
	echo '      --no-delete-daily     If set, no daily copies are deleted'
	echo '      --no-delete-weekly    If set, no weekly copies are deleted'
	echo '      --no-delete-monthly   If set, no monthly copies are deleted'
	echo '      --no-delete-yearly    If set, no yearly copies are deleted'
}

debug () {
	echo "$0: $@" >&2
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
	case $1 in
		-\?|--help)
			printusage >&2
			exit 1
			;;
		-d|--days)
			KEEP_DAYS=$2
			shift
			shift
			;;
		-w|--weeks)
			KEEP_WEEKS=$2
			shift
			shift
			;;
		-m|--months)
			KEEP_MONTHS=$2
			shift
			shift
			;;
		-y|--years)
			KEEP_YEARS=$2
			shift
			shift
			;;
		-p|--prefix)
			OUT_PREFIX=$2
			shift
			shift
			;;
		-s|--suffix)
			OUT_SUFFIX=$2
			shift
			shift
			;;
		-o|--out)
			OUT_DIR=$2
			shift
			shift
			;;
		--daily-out)
			OUT_DIR_DAILY=$2
			shift
			shift
			;;
		--weekly-out)
			OUT_DIR_WEEKLY=$2
			shift
			shift
			;;
		--monthly-out)
			OUT_DIR_MONTHLY=$2
			shift
			shift
			;;
		--yearly-out)
			OUT_DIR_YEARLY=$2
			shift
			shift
			;;
		--now)
			NOW=$2
			shift
			shift
			;;
		--no-create-daily)
			DISABLE_DAILY_CREATE=1
			shift
			;;
		--no-create-weekly)
			DISABLE_WEEKLY_CREATE=1
			shift
			;;
		--no-create-monthly)
			DISABLE_MONTHLY_CREATE=1
			shift
			;;
		--no-create-yearly)
			DISABLE_YEARLY_CREATE=1
			shift
			;;
		--no-delete-daily)
			DISABLE_DAILY_DELETE=1
			shift
			;;
		--no-delete-weekly)
			DISABLE_WEEKLY_DELETE=1
			shift
			;;
		--no-delete-monthly)
			DISABLE_MONTHLY_DELETE=1
			shift
			;;
		--no-delete-yearly)
			DISABLE_YEARLY_DELETE=1
			shift
			;;
		*)
			POSITIONAL+=("$1")
			shift
			;;
	esac
done
set -- ${POSITIONAL[@]}

if [[ $# -eq 0 ]]; then
	printusage >&2
	exit 1
fi

# ----------------------------------------------------------------
# Step 2: apply defaults
# ----------------------------------------------------------------

IN_FILE=$1
KEEP_DAYS=${KEEP_DAYS-15}
KEEP_WEEKS=${KEEP_WEEKS-8}
KEEP_MONTHS=${KEEP_MONTHS-12}
KEEP_YEARS=${KEEP_YEARS-5}
OUT_PREFIX=${OUT_PREFIX-}
OUT_SUFFIX=${OUT_SUFFIX-.${IN_FILE##*.}}
OUT_DIR=${OUT_DIR-.}
OUT_DIR=${OUT_DIR%/} # sanitize
OUT_DIR_DAILY=${OUT_DIR_DAILY-$OUT_DIR/daily}
OUT_DIR_WEEKLY=${OUT_DIR_WEEKLY-$OUT_DIR/weekly}
OUT_DIR_MONTHLY=${OUT_DIR_MONTHLY-$OUT_DIR/monthly}
OUT_DIR_YEARLY=${OUT_DIR_YEARLY-$OUT_DIR/yearly}
DISABLE_DAILY_CREATE=${DISABLE_DAILY_CREATE-0}
DISABLE_WEEKLY_CREATE=${DISABLE_WEEKLY_CREATE-0}
DISABLE_MONTHLY_CREATE=${DISABLE_MONTHLY_CREATE-0}
DISABLE_YEARLY_CREATE=${DISABLE_YEARLY_CREATE-0}
DISABLE_DAILY_DELETE=${DISABLE_DAILY_DELETE-0}
DISABLE_WEEKLY_DELETE=${DISABLE_WEEKLY_DELETE-0}
DISABLE_MONTHLY_DELETE=${DISABLE_MONTHLY_DELETE-0}
DISABLE_YEARLY_DELETE=${DISABLE_YEARLY_DELETE-0}
NOW=${NOW-now}

# ----------------------------------------------------------------
# Step 3: prepare environment
# ----------------------------------------------------------------

debug "Start rotation of '$IN_FILE' to $OUT_DIR"

[[ DISABLE_DAILY_CREATE -eq 0 ]] && debug "Create daily directory $OUT_DIR_DAILY" && mkdir -p "$OUT_DIR_DAILY"
[[ DISABLE_WEEKLY_CREATE -eq 0 ]] && debug "Create weekly directory $OUT_DIR_WEEKLY" && mkdir -p "$OUT_DIR_WEEKLY"
[[ DISABLE_MONTHLY_CREATE -eq 0 ]] && debug "Create monthly directory $OUT_DIR_MONTHLY" && mkdir -p "$OUT_DIR_MONTHLY"
[[ DISABLE_YEARLY_CREATE -eq 0 ]] && debug "Create yearly directory $OUT_DIR_YEARLY" && mkdir -p "$OUT_DIR_YEARLY"

# ----------------------------------------------------------------
# Step 4: create hard links for daily/weekly/monthly/yearly copy
# ----------------------------------------------------------------

try_cp () {
	if [[ -e "$2" ]]; then
		debug "Not copying $1 to $2: destination exists"
	else
		debug "Copy $1 to $2"
	 	cp -al "$1" "$2" >&2
	 fi
}

[[ DISABLE_DAILY_CREATE -eq 0 ]] && try_cp "$IN_FILE" "$OUT_DIR_DAILY/$OUT_PREFIX$(date --date="$NOW" +%Y-%m-%d)$OUT_SUFFIX"
[[ DISABLE_WEEKLY_CREATE -eq 0 ]] && try_cp "$IN_FILE" "$OUT_DIR_WEEKLY/$OUT_PREFIX$(date --date="$NOW" +%Y-%V)$OUT_SUFFIX"
[[ DISABLE_MONTHLY_CREATE -eq 0 ]] && try_cp "$IN_FILE" "$OUT_DIR_MONTHLY/$OUT_PREFIX$(date --date="$NOW" +%Y-%m)$OUT_SUFFIX"
[[ DISABLE_YEARLY_CREATE -eq 0 ]] && try_cp "$IN_FILE" "$OUT_DIR_YEARLY/$OUT_PREFIX$(date --date="$NOW" +%Y)$OUT_SUFFIX"

# ----------------------------------------------------------------
# Step 5: delete all old files
# ----------------------------------------------------------------

rm_and_debug () {
	debug "Delete $1"
	rm -r "$1"
}

rm_and_debug_many () {
	while read path; do
		rm_and_debug "$path"
	done
}

[[ DISABLE_DAILY_DELETE -eq 0 ]] && (find "$OUT_DIR_DAILY" -maxdepth 1 -mindepth 1 -type d | sort -r | tail -n +$((KEEP_DAYS+1)) | rm_and_debug_many)
[[ DISABLE_WEEKLY_DELETE -eq 0 ]] && (find "$OUT_DIR_WEEKLY" -maxdepth 1 -mindepth 1 -type d | sort -r | tail -n +$((KEEP_WEEKS+1)) | rm_and_debug_many)
[[ DISABLE_MONTHLY_DELETE -eq 0 ]] && (find "$OUT_DIR_MONTHLY" -maxdepth 1 -mindepth 1 -type d | sort -r | tail -n +$((KEEP_MONTHS+1)) | rm_and_debug_many)
[[ DISABLE_YEARLY_DELETE -eq 0 ]] && (find "$OUT_DIR_YEARLY" -maxdepth 1 -mindepth 1 -type d | sort -r | tail -n +$((KEEP_YEARS+1)) | rm_and_debug_many)

exit 0
