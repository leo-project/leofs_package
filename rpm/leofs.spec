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

Requires(post): %{_sbindir}/update-alternatives
Requires(postun): %{_sbindir}/update-alternatives
Requires:       sudo
#BuildArch:	noarch

%define target_dir %{_prefix}/local/leofs/%{version}

%description
LeoFS is a highly available, distributed, eventually consistent object/blob store. Organizations can use LeoFS to store lots of data efficiently, safely, and inexpensive.

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
make release

%install
%__mkdir -p ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}
%__mkdir -p ${RPM_BUILD_ROOT}%{_prefix}/local/bin
%__cp -rp ${RPM_BUILD_DIR}/leofs.git/package/* ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}
%__cp -rp ${RPM_BUILD_DIR}/leofs.git/leofs-adm ${RPM_BUILD_ROOT}%{_prefix}/local/bin
%__mkdir -p ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}/leo_storage/avs

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
# special case: handle side-by-side install with old version where leofs-adm isn't handled by alternatives
[ -L %{_prefix}/local/bin/leofs-adm ] || rm -f %{_prefix}/local/bin/leofs-adm

%{_sbindir}/update-alternatives --install %{_prefix}/local/bin/leofs-adm leofs-adm %{_prefix}/local/leofs/%{version}/leofs-adm 10

# .erlang.cookie needs to be created now, otherwise startup script will try to
# create it and fail, since $HOME isn't writable by leofs user.
# It's created with random string and must have 0400 permissions, owned by leofs user
COOKIE=%{_prefix}/local/leofs/.erlang.cookie
[ -f $COOKIE ] || \
    echo -ne $(dd if=/dev/urandom bs=1 count=32 2>/dev/null | md5sum | cut -d " " -f 1) \
    > $COOKIE
CURRENT_OWNER=$(stat -c %G:%U $COOKIE)
CURRENT_PERMISSIONS=$(stat -c %a $COOKIE)
[ "a$CURRENT_OWNER" == aleofs:leofs ] || chown leofs:leofs $COOKIE
[ "a$CURRENT_PERMISSIONS" == a400 ] || chmod 0400 $COOKIE

%postun
%{_sbindir}/update-alternatives --remove leofs-adm %{_prefix}/local/leofs/%{version}/leofs-adm

%files
%defattr(-,root,root,-)
%dir %{target_dir}

%attr(2755,leofs,leofs) %{target_dir}/leo_storage/avs
%attr(2755,leofs,leofs) %{target_dir}/leo_*/log
%attr(2755,leofs,leofs) %{target_dir}/leo_*/work
%dir %attr(2755,leofs,leofs) %{target_dir}/leo_*/etc
%dir %attr(2755,leofs,leofs) %{target_dir}/leo_*/snmp/*/db

%{target_dir}/leofs-adm
%{target_dir}/README.md
%dir %{target_dir}/leo_storage
%dir %{target_dir}/leo_gateway
%dir %{target_dir}/leo_manager*
%{target_dir}/leo_*/bin
%{target_dir}/leo_*/erts-*
%{target_dir}/leo_*/etc/*
%{target_dir}/leo_*/lib
%{target_dir}/leo_*/releases
%{target_dir}/leo_*/snmp
%ghost %{_prefix}/local/bin/leofs-adm

%changelog
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
