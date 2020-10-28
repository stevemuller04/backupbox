#!/bin/bash

# ----------------------------------------------------------------
# Step 1: read arguments
# ----------------------------------------------------------------

printusage () {
	echo "Usage: $0 [OPTIONS] SOURCE DESTINATION"
	echo ''
	echo 'Creates a file-wise back-up of the entire source directory at the given'
	echo 'destination. The back-up is created using hard links, so that the back-up is a'
	echo 'full back-up (independent from other back-ups), but maintains a link to a file'
	echo 'that already exists in another back-up, so that it does not need to be copied.'
	echo 'The source directory and its contents will be linked to a newly created'
	echo 'directory in $DESTINATION that is named after the current date by default,'
	echo 'in YYYY-MM-DD format. The name can be changed with the --name option.'
	echo ''
	echo 'Both the destination and the source must be folders that exist, otherwise this'
	echo 'script fails with exit code 2.'
	echo ''
	echo 'Options:'
	echo '  -?, --help     Displays this help'
	echo '      --name     Specifies a different name for the backup than the default'
	echo '      --exclude  Excludes a sub-folder (pattern) of $SOURCE from the backup'
}

debug () {
	echo "$0: $@" >&2
}

POSITIONAL=()
EXCLUDES=()
while [[ $# -gt 0 ]]; do
	case $1 in
		-\?|--help)
			printusage >&2
			exit 1
			;;
		--name)
			NAME=$2
			shift
			shift
			;;
		--exclude)
			EXCLUDES+=("--exclude" "$2")
			shift
			shift
			;;
		*)
			POSITIONAL+=("$1")
			shift
			;;
	esac
done
set -- ${POSITIONAL[@]}

if [[ $# -lt 2 ]]; then
	printusage >&2
	exit 1
fi

SOURCE=$1
DESTINATION=$2

# ----------------------------------------------------------------
# Step 2: apply defaults and sanitize
# ----------------------------------------------------------------

NAME=${NAME-$(date +%Y-%m-%d)}
DESTINATION=${DESTINATION%/} # remove trailing slash

# ----------------------------------------------------------------
# Step 3: prepare
# ----------------------------------------------------------------

debug "Start backup '$NAME' from $SOURCE to $DESTINATION"

# Check if source and destination exist, and if they are directories

#if [[ "$SOURCE" != *"@"* ]] && [[ ! -d "$SOURCE" ]]; then
#	echo "Source directory '$SOURCE' does not exist, or is not a directory" >&2
#	exit 2
#fi
#if [[ ! -d "$DESTINATION" ]]; then
#	echo "Destination directory '$DESTINATION' does not exist, or is not a directory" >&2
#	exit 2
#fi

# The very first call to this script cannot compare anything
# to ./last/ because the latter does not exist. The solution
# is to create a dummy 'empty' directory and let ./last point
# to it.
if [[ ! -d "$DESTINATION/last" ]]; then
	debug "Creating temporary dummy directory $DESTINATION/empty"
	mkdir -p "$DESTINATION/empty"
	ln -nsf "$DESTINATION/empty" "$DESTINATION/last"
fi

# ----------------------------------------------------------------
# Step 4: back up
# ----------------------------------------------------------------

rsync -aRH --numeric-ids --stats --rsh=ssh "${EXCLUDES[@]}" --delete "$SOURCE" "$DESTINATION/$NAME/" --link-dest="$DESTINATION/last/" >&2
result=$?

if [[ $result -ne 0 ]]; then
	debug "rsync failed with exit code $result"
	exit $result
fi

# ----------------------------------------------------------------
# Step 5 finalise
# ----------------------------------------------------------------

# Symlink last/ to newly created directory
debug "Symlink $DESTINATION/last to $NAME"
ln -nsf "$NAME" "$DESTINATION/last"

# Delete the dummy directory again
[[ -d "$DESTINATION/empty" ]] && rmdir "$DESTINATION/empty"

exit 0
