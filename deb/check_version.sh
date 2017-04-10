#!/bin/sh

# This script ensures that no one tries to use new version of packaging script (which require leofs >= 1.3.3)
# with an older version by mistake. The way this check works might become obsolete at some point when original file
# is moved; it will probably be OK to replace or remove it at that point.

if ! which curl > /dev/null
then
	echo "Curl not installed, unable to proceed with version check"
	exit 1
fi

version=$1
tmpfile=$(mktemp)

URL="https://raw.githubusercontent.com/leo-project/leofs/$version/rel/common/launch.sh"

curl -s "$URL" -o $tmpfile

# sanity check, that curl actually has downloaded some shell script
head -1 $tmpfile | grep bin/sh  > /dev/null
if [ $? -ne 0 ]
then
	echo "Unable to download file from $URL"
	echo "Version check is impossible!"
	rm -f $tmpfile
	exit 1
fi

grep RUNNER_USER= $tmpfile | grep leofs > /dev/null
if [ $? -ne 0 ]
then
	echo "This version is too old to build this package with!"
	rm -f $tmpfile
	exit 2
fi

# version check is ok
rm -f $tmpfile
exit 0
