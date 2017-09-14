#!/bin/sh

# This script ensures that no one tries to use new version of packaging script (which require leofs > 1.3.7)
# with an older version by mistake. The way this check works might become obsolete at some point when original file
# is moved; it will probably be OK to replace or remove it at that point.

# also checks if epmd is build with systemd support (only when building systemd-compatible package)

continue_anyway=false
version=$1
URL="https://raw.githubusercontent.com/leo-project/leofs/$version/rel/service/leofs-epmd.socket"
tmpfile=$(mktemp)

case "$2" in
    yes)  systemd_check=yes ;;
      *)  systemd_check=no  ;;
esac


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
    echo "(older version is available at https://github.com/leo-project/leofs_package/releases/tag/1.2.0)"
    read -p "Type y to continue: " answer
    case "$answer" in
        y|Y ) echo "Ignoring possible problems, proceed at your own risk!"
              continue_anyway=true ;;
          * ) echo "Aborting package build!"
              exit 1 ;;
    esac
}

check_epmd_for_systemd() {
    epmd -help 2>& 1 | grep systemd > /dev/null
    [ $? -eq 0 ] && return

    echo "You are trying to build package with systemd support using Erlang runtime built"
    echo "WITHOUT systemd support. This is not supported and will result in broken package,"
    echo "as package with systemd support depends on \"socket activation\" feature in epmd."
    echo "Please use Erlang \>= 17 configured with --enable-systemd option."
    read -p "Type y to continue: " answer
    case "$answer" in
        y|Y ) echo "Ignoring possible problems, proceed at your own risk!" ;;
          * ) echo "Aborting package build!"
              exit 1 ;;
    esac
}

if [ "$systemd_check" = yes ]
then
    check_epmd_for_systemd
fi

if ! which curl > /dev/null
then
    echo "curl is not installed, unable to proceed with version check"
    go_on_after_warning
fi

curl -s "$URL" -o $tmpfile

# sanity check - whether curl actually has downloaded unit file
head -1 $tmpfile | grep Unit  > /dev/null
if [ $? -ne 0 ]
then
    echo "Unable to download file from $URL"
    echo "Version check is impossible!"
    go_on_after_warning
fi

# version check passed
exit 0
