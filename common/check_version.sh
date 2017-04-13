#!/bin/sh

# This script ensures that no one tries to use new version of packaging script (which require leofs >= 1.3.3)
# with an older version by mistake. The way this check works might become obsolete at some point when original file
# is moved; it will probably be OK to replace or remove it at that point.

continue_anyway=false
version=$1
URL="https://raw.githubusercontent.com/leo-project/leofs/$version/rel/common/launch.sh"
tmpfile=$(mktemp)

cleanup () {
    rm -f $tmpfile
}

trap cleanup EXIT

go_on_after_warning () {
# Don't warn twice
    if [ "$continue_anyway" = true ]
    then
        return
    fi

    echo "Do you want to continue? The resulting package is not likely to work correctly."
    echo "It is recommended that you use older version of packaging scripts instead"
    echo "(older version is available at https://github.com/leo-project/leofs_package/tree/1.0.0)"
    read -p "Type y to continue: " answer
    case "$answer" in
        y|Y ) echo "Ignoring possible problems, proceed at your own risk!"
              continue_anyway=true ;;
          * ) echo "Aborting package build!"
              exit 1 ;;
    esac
}

if ! which curl > /dev/null
then
    echo "curl is not installed, unable to proceed with version check"
    go_on_after_warning
fi

curl -s "$URL" -o $tmpfile

# sanity check - whether curl actually has downloaded some shell script
head -1 $tmpfile | grep bin/sh  > /dev/null
if [ $? -ne 0 ]
then
    echo "Unable to download file from $URL"
    echo "Version check is impossible!"
    go_on_after_warning
fi

grep RUNNER_USER= $tmpfile | grep leofs > /dev/null
if [ $? -ne 0 ]
then
    echo "Source version is too old to build this package with!"
    go_on_after_warning
fi

# version check passed
exit 0
