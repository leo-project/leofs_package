Name:		leofs
Version:	%{ver}
Release:	1
Summary:	LeoFS is a highly available, distributed, eventually consistent object/blob store.

Group:		Applications/System
License:	Apache License
URL:		http://www.leofs.org/
Source0:	leofs-%{version}.tar.gz
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Prefix:		%{_prefix}/local/leofs
BuildRequires:  git
# for building leo_mcerl/c_src/libcutil
BuildRequires:  cmake gcc check-devel
# for building eleveldb/c_src/snappy
BuildRequires:  gcc-c++ lzo-devel zlib-devel
#BuildArch:	noarch

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

%files
%defattr(-,root,root,-)
%{_prefix}/local/leofs/%{version}
%{_prefix}/local/bin/leofs-adm

%changelog
* Fri Mar 13 2015 <leofs@leofs.org>
- Modify directory name and hierarchy
* Wed Jun 26 2013 <leofs@leofs.org>
- Modify directory name and hierarchy
* Mon Jun 17 2013 <leofs@leofs.org>
- Change directory name and hierarchy
* Wed Mar 27 2013 <leofs@leofs.org>
- Corresponding argument
* Thu Jul  5 2012 <leofs@leofs.org>
- Initial build.
