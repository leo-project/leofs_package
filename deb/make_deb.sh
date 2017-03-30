#!/usr/bin/env bash

cd `dirname $0`
export LANG=C
DT1=`date | awk '{print $1", "$3" "$2" "$6" "$4" +0900"}'`
DT2=`date | awk '{print $6}'`
LEOFS=leofs-${1}

git clone https://github.com/leo-project/leofs.git

mv leofs ${LEOFS}

cd ${LEOFS}
git checkout ${1}

mkdir -p debian
#cd debian

cat << EOT >> debian/changelog
leofs (${1}-1) unstable; urgency=low

  * Initial release.

 -- LeoProject <leoproject_leofs@googlegroups.com>  ${DT1}
EOT

cat << 'EOT' >> debian/control
Source: leofs
Section: unknown
Priority: optional
Maintainer: LeoProject <leoproject_leofs@googlegroups.com>
Build-Depends: debhelper (>= 8.0.0)
Standards-Version: 3.9.2
Homepage: https://leo-project.net/leofs/
#Vcs-Git: git://git.debian.org/collab-maint/leofs.git
#Vcs-Browser: http://git.debian.org/?p=collab-maint/leofs.git;a=summary

Package: leofs
Architecture: any
Depends: ${shlibs:Depends}
#, ${misc:Depends}
Description: LeoFS is the Web shaped object storage system.
 LeoFS is the Web shaped object storage system and S3 compatible storage.

#Package: leofs-doc
#Architecture: all
#Description: documentation for leofs
# documentation for leofs
EOT

cat << EOT >> debian/copyright
Format: http://dep.debian.net/deps/dep5
Upstream-Name: leofs
Source: https://github.com/leo-project/leofs

Files: *
Copyright: ${DT2} LeoProject <leoproject_leofs@googlegroups.com>
License: Apache-2.0

Files: debian/*
Copyright: ${DT2} LeoProject <leoproject_leofs@googlegroups.com>
License: Apache-2.0

License: Apache-2.0
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 .
 http://www.apache.org/licenses/LICENSE-2.0
 .
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 .
 On Debian systems, the complete text of the Apache version 2.0 license
 can be found in "/usr/share/common-licenses/Apache-2.0".

# Please also look if there are files or directories which have a
# different copyright/license attached and list them here.
EOT


echo 9 > debian/compat

cat << 'EOT' >> debian/leofs.postinst
#!/bin/sh

set -e

EOT
cat << EOT >> debian/leofs.postinst
version=${1}
EOT

cat << 'EOT' >> debian/leofs.postinst

case "$1" in
    configure)

        getent group leofs > /dev/null || addgroup --quiet --system leofs

        getent passwd leofs > /dev/null || adduser --system --group --home /usr/local/leofs leofs \
            --quiet --shell /sbin/nologin --gecos "LeoFS Object Storage"

        COOKIE=/usr/local/leofs/.erlang.cookie
        [ -f $COOKIE ] || /bin/echo -ne $(dd if=/dev/urandom bs=1 count=32 2>/dev/null | md5sum | cut -d " " -f 1) > $COOKIE
        CURRENT_OWNER=$(stat -c %G:%U $COOKIE)
        CURRENT_PERMISSIONS=$(stat -c %a $COOKIE)
        [ "a$CURRENT_OWNER" = aleofs:leofs ] || chown leofs:leofs $COOKIE
        [ "a$CURRENT_PERMISSIONS" = a400 ] || chmod 0400 $COOKIE

        chown -R leofs:leofs /usr/local/leofs/$version/leo_storage/avs
        chown -R leofs:leofs /usr/local/leofs/$version/leo_*/log
        chown -R leofs:leofs /usr/local/leofs/$version/leo_*/work
        chown leofs:leofs /usr/local/leofs/$version/leo_*/etc
        chown leofs:leofs /usr/local/leofs/$version/leo_*/snmp/*/db

        chmod -R 2755 /usr/local/leofs/$version/leo_storage/avs
        chmod -R 2755 /usr/local/leofs/$version/leo_*/log
        chmod 2755 /usr/local/leofs/$version/leo_*/work
        chmod 2755 /usr/local/leofs/$version/leo_*/etc
        chmod 2755 /usr/local/leofs/$version/leo_*/snmp/*/db

    ;;
esac

#DEBHELPER#

exit 0
EOT

cat << 'EOT' >> debian/rules
#!/usr/bin/make -f
# -*- makefile -*-
# Sample debian/rules that uses debhelper.
#
# This file was originally written by Joey Hess and Craig Small.
# As a special exception, when this file is copied by dh-make into a
# dh-make output file, you may use that output file without restriction.
# This special exception was added by Craig Small in version 0.37 of dh-make.
#
# Modified to make a template file for a multi-binary package with separated
# build-arch and build-indep targets  by Bill Allombert 2001

# Uncomment this to turn on verbose mode.
#export DH_VERBOSE=1

# This has to be exported to make some magic below work.
export DH_OPTIONS


#%:
#	dh $@

package = leofs
EOT
cat << EOT >> debian/rules
version = ${1}
EOT
cat << 'EOT' >> debian/rules
docdir = debian/tmp/usr/share/doc/$(package)
installdir = debian/tmp/usr/local/$(package)/$(version)
bindir = debian/tmp/usr/local/bin

build:	binary

clean:
	$(MAKE) clean
	rm -rf packages *~ debian/tmp debian/*~ debian/files* debian/substvars

binary-indep:	checkroot build

binary-arch:	checkroot build
	rm -rf debian/tmp
	mkdir -p $(installdir)
	mkdir -p $(bindir)
	$(MAKE)
	$(MAKE) release
	cp -r package/* $(installdir)
	mkdir $(installdir)/leo_storage/avs
	cp leofs-adm $(bindir)
	dpkg-shlibdeps $(installdir)/leo_manager_0/erts-6.3/bin/beam
	mkdir -p debian/tmp/DEBIAN
	dh_installdeb -Pdebian/tmp
	dpkg-gencontrol
	chown -R root:root debian/tmp
	chmod -R u+w,go=rX debian/tmp
	dpkg-deb --build debian/tmp ..

binary:	binary-indep binary-arch

checkroot:
	test $$(id -u) = 0

.PHONY: binary binary-arch binary-indep clean checkroot
EOT

chmod 755 debian/rules

fakeroot debian/rules

cd ..
rm -rf ${LEOFS}
