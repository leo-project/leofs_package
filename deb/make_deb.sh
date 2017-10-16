#!/usr/bin/env bash

cd `dirname $0`
export LANG=C
DT1=`date | awk '{print $1", "$3" "$2" "$6" "$4" +0900"}'`
DT2=`date | awk '{print $6}'`
LEOFS=leofs-${1}

case "$2" in
    yes|no)  USE_SYSTEMD=$2
             ;;
    *)       echo "Wrong syntax (\"$2\" is neither \"yes\" nor \"no\")"
             echo "Usage: $0 <package_version> <use_systemd>"
             echo "where use_systemd can be \"yes\" or \"no\""
             exit 1
             ;;
esac

./check_version.sh ${1} ${2} || exit 1

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
Build-Depends: debhelper (>= 9.0.0), check, git, cmake, liblzo2-dev, zlib1g-dev,
EOT

if [ "$USE_SYSTEMD" = yes ]
then
    echo "  dh-systemd" >> debian/control
fi

cat << 'EOT' >> debian/control
Standards-Version: 3.9.2
Homepage: https://leo-project.net/leofs/
#Vcs-Git: git://git.debian.org/collab-maint/leofs.git
#Vcs-Browser: http://git.debian.org/?p=collab-maint/leofs.git;a=summary

Package: leofs
Architecture: any
Depends: ${shlibs:Depends}, sudo, sysstat, netcat-openbsd,
EOT

if [ "$USE_SYSTEMD" = yes ]
then
    echo "  systemd" >> debian/control
fi

cat << 'EOT' >> debian/control
#, ${misc:Depends}
Description: LeoFS is a highly available, distributed, eventually consistent S3 compatible storage.
 Organizations can use LeoFS to store lots of data efficiently, safely, and inexpensive.

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
#!/bin/bash

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
        chown -R leofs:leofs /usr/local/leofs/$version/leo_gateway/cache
        chown -R leofs:leofs /usr/local/leofs/$version/leo_{manager_0,manager_1,storage,gateway}/log
        chown -R leofs:leofs /usr/local/leofs/$version/leo_{manager_0,manager_1,storage,gateway}/work
        chown leofs:leofs /usr/local/leofs/$version/leo_{manager_0,manager_1,storage,gateway}/etc
        chown leofs:leofs /etc/leofs/leo_{manager_0,manager_1,storage,gateway}
        chown leofs:leofs /usr/local/leofs/$version/leo_{manager_0,manager_1,storage,gateway}/snmp/*/db

        chmod -R 2755 /usr/local/leofs/$version/leo_storage/avs
        chmod -R 2755 /usr/local/leofs/$version/leo_gateway/cache
        chmod -R 2755 /usr/local/leofs/$version/leo_{manager_0,manager_1,storage,gateway}/log
        chmod 2755 /usr/local/leofs/$version/leo_{manager_0,manager_1,storage,gateway}/work
        chmod 2755 /usr/local/leofs/$version/leo_{manager_0,manager_1,storage,gateway}/etc
        chmod 2755 /etc/leofs/leo_{manager_0,manager_1,storage,gateway}
        chmod 2755 /usr/local/leofs/$version/leo_{manager_0,manager_1,storage,gateway}/snmp/*/db

EOT

if [ "$USE_SYSTEMD" = yes ]
then
    cat << 'EOT' >> debian/leofs.postinst
# If this is first configured version, or previous configured version was < 1.3.8, reset services state
        if [ -z "$2" ] || dpkg --compare-versions "$2" lt 1.3.8
        then
# preset enables everything by default on Debian/Ubuntu, so it's meaningless to do for the rest of services
            systemctl preset leofs-epmd.socket
        fi

        systemctl daemon-reload
        systemctl start leofs-epmd.socket || :
EOT
fi

cat << 'EOT' >> debian/leofs.postinst
    ;;
esac

#DEBHELPER#

exit 0
EOT

if [ "$USE_SYSTEMD" = yes ]
then
    cat << 'EOT' >> debian/leofs.prerm
#!/bin/sh

set -e

if [ "$1" = "remove" ]; then
    systemctl --no-reload disable leofs-epmd.service > /dev/null 2>&1 || :
    systemctl stop leofs-epmd.service > /dev/null 2>&1 || :
    systemctl --no-reload disable leofs-epmd.socket > /dev/null 2>&1 || :
    systemctl stop leofs-epmd.socket > /dev/null 2>&1 || :
    systemctl --no-reload disable leofs-manager-master.service > /dev/null 2>&1 || :
    systemctl stop leofs-manager-master.service > /dev/null 2>&1 || :
    systemctl --no-reload disable leofs-manager-slave.service > /dev/null 2>&1 || :
    systemctl stop leofs-manager-slave.service > /dev/null 2>&1 || :
    systemctl --no-reload disable leofs-gateway.service > /dev/null 2>&1 || :
    systemctl stop leofs-gateway.service > /dev/null 2>&1 || :
    systemctl --no-reload disable leofs-storage.service > /dev/null 2>&1 || :
    systemctl stop leofs-storage.service > /dev/null 2>&1 || :
fi

exit 0
EOT
fi

if [ "$USE_SYSTEMD" = yes ]
then
    cat << 'EOT' >> debian/leofs.postrm
#!/bin/sh

set -e

if [ "$1" = "remove" ]; then
    systemctl daemon-reload
fi

exit 0
EOT
fi

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

SHELL=/bin/bash


#%:
#	dh $@

package = leofs
EOT
cat << EOT >> debian/rules
version = ${1}
use_systemd = ${USE_SYSTEMD}
EOT
cat << 'EOT' >> debian/rules
docdir = debian/tmp/usr/share/doc/$(package)
installdir = debian/tmp/usr/local/$(package)/$(version)
bindir = debian/tmp/usr/local/bin
presetdir = debian/tmp/lib/systemd/system-preset
unitdir = debian/tmp/lib/systemd/system
confdir = debian/tmp/etc/leofs
limitsconfdir = debian/tmp/etc/security/limits.d

build:	binary

clean:
	$(MAKE) clean
	rm -rf packages *~ debian/tmp debian/*~ debian/files* debian/substvars

binary-indep:	checkroot build

binary-arch:	checkroot build
	rm -rf debian/tmp
	mkdir -p $(installdir)
	mkdir -p $(bindir)
	mkdir -p $(confdir)/leo_manager_0 $(confdir)/leo_manager_1
	mkdir -p $(confdir)/leo_gateway $(confdir)/leo_storage
	mkdir -p $(limitsconfdir)
	$(MAKE)
	$(MAKE) release
	cp -r package/* $(installdir)
	cp rel/common/leofs.conf $(confdir)
	cp rel/common/leofs-limits.conf $(limitsconfdir)/70-leofs.conf
	cp -r $(installdir)/leo_manager_0/etc/*.{environment,conf,d} $(confdir)/leo_manager_0
	cp -r $(installdir)/leo_manager_1/etc/*.{environment,conf,d} $(confdir)/leo_manager_1
	cp -r $(installdir)/leo_gateway/etc/*.{environment,conf,d} $(confdir)/leo_gateway
	cp -r $(installdir)/leo_storage/etc/*.{environment,conf,d} $(confdir)/leo_storage
ifeq ($(use_systemd),yes)
	mkdir -p $(presetdir) $(unitdir)
	cp rel/service/*.preset $(presetdir)/
	cp rel/service/*.{service,socket} $(unitdir)
	cp rel/leo_manager/service/leofs-epmd.service $(unitdir)
endif
	mkdir $(installdir)/leo_storage/avs
	mkdir $(installdir)/leo_gateway/cache
	ln -s $(version) debian/tmp/usr/local/$(package)/current
	cp leofs-adm $(bindir)
	dpkg-shlibdeps $(installdir)/leo_manager_0/erts-*/bin/beam
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
