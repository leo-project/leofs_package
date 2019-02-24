%define use_systemd (0%{?rhel} && 0%{?rhel} >= 7) || (0%{?fedora} && 0%{?fedora} >= 18)

Name:		leofs
Version:	%{ver}
Release:	1
Summary:	LeoFS is a highly available, distributed, eventually consistent object/blob store.

Group:		Applications/System
License:	Apache License
URL:		https://leofs-project.net/leofs/
Source0:	leofs-%{version}.tar.gz
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Prefix:		%{_prefix}/local/leofs
BuildRequires:  git
# for building leo_mcerl/c_src/libcutil
BuildRequires:  cmake gcc check-devel
# for building eleveldb/c_src/snappy
BuildRequires:  gcc-c++ lzo-devel zlib-devel
%if %{use_systemd}
BuildRequires: systemd systemd-devel
%endif

Requires:       sudo sysstat /usr/bin/nc
%{?systemd_requires}

#BuildArch:	noarch

%define target_dir %{_prefix}/local/leofs/%{version}

%description
LeoFS is a highly available, distributed, eventually consistent S3 compatible storage.
Organizations can use LeoFS to store lots of data efficiently, safely, and inexpensive.

%prep
echo ${RPM_BUILD_ROOT}
#%setup -q -n leofs-%{version}

%__rm -rf ${RPM_BUILD_DIR}/leofs.git
git clone https://github.com/leo-project/leofs.git ${RPM_BUILD_DIR}/leofs.git
cd leofs.git
git checkout %{version}

%build
cd leofs.git
make
%if %{use_systemd}
make sd_notify
make release with_sd_notify=yes
%else
make release
%endif

%install
%__mkdir -p ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}
%__mkdir -p ${RPM_BUILD_ROOT}%{_prefix}/local/bin
%__cp -rp ${RPM_BUILD_DIR}/leofs.git/package/* ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}
%__cp -rp ${RPM_BUILD_DIR}/leofs.git/leofs-adm ${RPM_BUILD_ROOT}%{_prefix}/local/bin
%__mkdir -p ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}/leo_storage/avs
%__mkdir -p ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}/leo_gateway/cache

%__mkdir -p ${RPM_BUILD_ROOT}%{_sysconfdir}/leofs/leo_manager_0 ${RPM_BUILD_ROOT}%{_sysconfdir}/leofs/leo_manager_1
%__mkdir -p ${RPM_BUILD_ROOT}%{_sysconfdir}/leofs/leo_gateway ${RPM_BUILD_ROOT}%{_sysconfdir}/leofs/leo_storage
%__cp -p ${RPM_BUILD_DIR}/leofs.git/rel/common/leofs.conf ${RPM_BUILD_ROOT}%{_sysconfdir}/leofs
%__mkdir -p ${RPM_BUILD_ROOT}%{_sysconfdir}/security/limits.d
%__cp -p ${RPM_BUILD_DIR}/leofs.git/rel/common/leofs-limits.conf ${RPM_BUILD_ROOT}%{_sysconfdir}/security/limits.d/70-leofs.conf
%__cp -rp ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}/leo_manager_0/etc/*.{environment,conf,d} ${RPM_BUILD_ROOT}%{_sysconfdir}/leofs/leo_manager_0
%__cp -rp ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}/leo_manager_1/etc/*.{environment,conf,d} ${RPM_BUILD_ROOT}%{_sysconfdir}/leofs/leo_manager_1
%__cp -rp ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}/leo_gateway/etc/*.{environment,conf,d} ${RPM_BUILD_ROOT}%{_sysconfdir}/leofs/leo_gateway
%__cp -rp ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}/leo_storage/etc/*.{environment,conf,d} ${RPM_BUILD_ROOT}%{_sysconfdir}/leofs/leo_storage

%__ln_s %{version} ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/current

%if %{use_systemd}
%__mkdir -p ${RPM_BUILD_ROOT}%{_unitdir}
%__mkdir -p ${RPM_BUILD_ROOT}%{_presetdir}
%__cp -p ${RPM_BUILD_DIR}/leofs.git/rel/service/*.{service,socket} ${RPM_BUILD_ROOT}%{_unitdir}
%__cp -p ${RPM_BUILD_DIR}/leofs.git/rel/service/*.preset ${RPM_BUILD_ROOT}%{_presetdir}
%__cp -p ${RPM_BUILD_DIR}/leofs.git/rel/leo_manager/service/leofs-epmd.service ${RPM_BUILD_ROOT}%{_unitdir}
%endif

%clean
%__rm -rf ${RPM_BUILD_DIR}/leofs.git
%__rm -rf ${RPM_BUILD_ROOT}

%pre
getent group leofs > /dev/null || groupadd -r leofs
getent passwd leofs > /dev/null || \
        useradd -r -g leofs -d %{_prefix}/local/leofs -s /sbin/nologin \
        -c "LeoFS Object Storage" leofs
:

%post
%if %use_systemd
# Install defaults for systemd services on first package installation
%systemd_post leofs-epmd.service
%systemd_post leofs-epmd.socket
%systemd_post leofs-manager-master.service
%systemd_post leofs-manager-slave.service
%systemd_post leofs-gateway.service
%systemd_post leofs-storage.service
%endif

# .erlang.cookie needs to be created now, otherwise startup script will try to
# create it and fail, since $HOME isn't writable by leofs user.
# It's created with random string and must have 0400 permissions, owned by leofs user
COOKIE=%{_prefix}/local/leofs/.erlang.cookie
[ -f $COOKIE ] || \
    /bin/echo -ne $(dd if=/dev/urandom bs=1 count=32 2>/dev/null | md5sum | cut -d " " -f 1) \
    > $COOKIE
CURRENT_OWNER=$(stat -c %G:%U $COOKIE)
CURRENT_PERMISSIONS=$(stat -c %a $COOKIE)
[ "a$CURRENT_OWNER" = aleofs:leofs ] || chown leofs:leofs $COOKIE
[ "a$CURRENT_PERMISSIONS" = a400 ] || chmod 0400 $COOKIE

%triggerun -- leofs < 1.3.8
[ $2 = 0 ] && exit 0; :
%if %use_systemd
# Install defaults for systemd services on upgrade from versions without systemd support
systemctl preset leofs-epmd.service
systemctl preset leofs-epmd.socket
systemctl preset leofs-manager-master.service
systemctl preset leofs-manager-slave.service
systemctl preset leofs-gateway.service
systemctl preset leofs-storage.service
%endif

%preun
%if %use_systemd
%systemd_preun leofs-epmd.service
%systemd_preun leofs-epmd.socket
%systemd_preun leofs-manager-master.service
%systemd_preun leofs-manager-slave.service
%systemd_preun leofs-gateway.service
%systemd_preun leofs-storage.service
%endif

%postun
%if %use_systemd
%systemd_postun leofs-epmd.service
%systemd_postun leofs-epmd.socket
%systemd_postun leofs-manager-master.service
%systemd_postun leofs-manager-slave.service
%systemd_postun leofs-gateway.service
%systemd_postun leofs-storage.service
%endif

%posttrans
%if %use_systemd
# "daemon-reload" is needed to silence "start" from next command after upgrade
systemctl daemon-reload
systemctl start leofs-epmd.socket
%endif

%files
%defattr(-,root,root,-)
%dir %{target_dir}

%attr(2755,leofs,leofs) %{target_dir}/leo_storage/avs
%attr(2755,leofs,leofs) %{target_dir}/leo_gateway/cache
%attr(2755,leofs,leofs) %{target_dir}/leo_*/log
%attr(2755,leofs,leofs) %{target_dir}/leo_*/work
%dir %attr(2755,leofs,leofs) %{target_dir}/leo_*/etc
%dir %attr(2755,leofs,leofs) %{target_dir}/leo_*/snmp/*/db
%dir %{_sysconfdir}/leofs
%dir %attr(2755,leofs,leofs) %{_sysconfdir}/leofs/leo_*
%{_sysconfdir}/security/limits.d/70-leofs.conf

%{target_dir}/leofs-adm
%{target_dir}/README.md
%dir %{target_dir}/leo_storage
%dir %{target_dir}/leo_gateway
%dir %{target_dir}/leo_manager*
%{target_dir}/leo_*/bin
%{target_dir}/leo_*/erts-*
%{target_dir}/leo_*/etc/*.d
%config %{target_dir}/leo_*/etc/*schema
%config(noreplace) %{target_dir}/leo_*/etc/*.conf
%config(noreplace) %{target_dir}/leo_*/etc/*.environment
%config(noreplace) %{target_dir}/leo_gateway/etc/server_cert.pem
%config(noreplace) %{target_dir}/leo_gateway/etc/server_key.pem
%config(noreplace) %{_sysconfdir}/leofs/leofs.conf
%config(noreplace) %{_sysconfdir}/leofs/leo_*/*.conf
%config(noreplace) %{_sysconfdir}/leofs/leo_*/*.environment
%{_sysconfdir}/leofs/leo_*/*.d
%{target_dir}/leo_*/lib
%{target_dir}/leo_*/releases
%{target_dir}/leo_*/snmp
%{_prefix}/local/bin/leofs-adm
%{_prefix}/local/leofs/current

%if %{use_systemd}
%{_unitdir}/*
%{_presetdir}/*
%endif


%changelog
* Thu Aug 31 2017 <Vladimir.MV@gmail.com>
- Systemd services support
- Removed support for installing multiple versions at once

* Thu Mar 23 2017 <Vladimir.MV@gmail.com>
- Run as non-privileged user

* Thu Feb 23 2017 <Vladimir.MV@gmail.com>
- Manage /usr/local/bin/leofs-adm with alternatives

* Fri Mar 13 2015 <leofs@leo-project.net>
- Modify directory name and hierarchy

* Wed Jun 26 2013 <leofs@leo-project.net>
- Modify directory name and hierarchy

* Mon Jun 17 2013 <leofs@leo-project.net>
- Change directory name and hierarchy

* Wed Mar 27 2013 <leofs@leo-project.net>
- Corresponding argument

* Thu Jul  5 2012 <leofs@leo-project.net>
- Initial build.
