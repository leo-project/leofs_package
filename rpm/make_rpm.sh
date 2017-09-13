#!/usr/bin/env sh
cd `dirname $0`
if [ $# -eq 1 ]; then
  rhel_ver=$(rpmbuild --eval='0%{?rhel}' 2>/dev/null)
  fedora_ver=$(rpmbuild --eval='0%{?fedora}' 2>/dev/null)
  [ $rhel_ver -ge 7 -o $fedora_ver -ge 18 ] && use_systemd=yes

  ./check_version.sh ${1} ${use_systemd} || exit 1
  sed -e "s/%{ver}/${1}/g" leofs.spec > leofs-${1}.spec
  rpmbuild -bb leofs-${1}.spec
  if [ $? == 0 ]; then
    echo "You have successfully build rpm file.(leofs-${1}.rpm)"
  else
    echo "An error has occurred."
    if [ -e ../BUILD ]; then
      rm -rf ../BUILD
    fi
  fi
  rm -f leofs-${1}.spec
else
  echo "Usage: $0 <version>"
fi
