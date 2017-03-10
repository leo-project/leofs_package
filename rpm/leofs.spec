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
#BuildArch:	noarch

Requires(post): %{_sbindir}/update-alternatives
Requires(postun): %{_sbindir}/update-alternatives

%description
LeoFS is a highly available, distributed, eventually consistent object/blob store. Organizations can use LeoFS to store lots of data efficiently, safely, and inexpensive.

%prep
echo ${RPM_BUILD_ROOT}
#%setup -q -n leofs-%{version}

%__rm -rf ${RPM_BUILD_DIR}/leofs.git
git clone https://github.com/leo-project/leofs.git ${RPM_BUILD_DIR}/leofs.git

%build
cd leofs.git
git checkout %{version}
make
make release

%install
%__mkdir -p ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}
%__mkdir -p ${RPM_BUILD_ROOT}%{_prefix}/local/bin
%__cp -rp ${RPM_BUILD_DIR}/leofs.git/package/* ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}
%__cp -rp ${RPM_BUILD_DIR}/leofs.git/leofs-adm ${RPM_BUILD_ROOT}%{_prefix}/local/bin

%clean
%__rm -rf ${RPM_BUILD_DIR}/leofs.git
%__rm -rf ${RPM_BUILD_ROOT}

%post
# special case: handle side-by-side install with old version where leofs-adm isn't handled by alternatives
[ -L %{_prefix}/local/bin/leofs-adm ] || rm -f %{_prefix}/local/bin/leofs-adm

%{_sbindir}/update-alternatives --install %{_prefix}/local/bin/leofs-adm leofs-adm %{_prefix}/local/leofs/%{version}/leofs-adm 10

%postun
%{_sbindir}/update-alternatives --remove leofs-adm %{_prefix}/local/leofs/%{version}/leofs-adm

%files
%defattr(-,root,root,-)
%{_prefix}/local/leofs/%{version}
%ghost %{_prefix}/local/bin/leofs-adm

%changelog
* Thu Feb 23 2017 <Vladimir.MV@gmail.com>
- manage /usr/local/bin/leofs-adm with alternatives
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
