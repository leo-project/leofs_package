#!/usr/bin/env sh

if [ $# -eq 1 ]; then
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
  echo Usage: leofs.sh version
fi
