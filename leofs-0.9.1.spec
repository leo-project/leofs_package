Name:		leofs
Version:	0.9.1
Release:	1
Summary:	LeoFS is a highly available, distributed, eventually consistent object/blob store.

Group:		Applications/System
License:	Apache License
URL:		http://www.leofs.org/
Source0:	leofs-%{version}.tar.gz
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
#BuildArch:	noarch

%description
LeoFS is a highly available, distributed, eventually consistent object/blob store. Organizations can use LeoFS to store lots of data efficiently, safely, and inexpensive.

%prep
echo ${RPM_BUILD_ROOT}
#%setup -q -n leofs-%{version}
git clone https://github.com/leo-project/leofs.git ${RPM_BUILD_DIR}
git clone https://github.com/leo-project/cherly.git ${RPM_BUILD_DIR}/deps/cherly

%build
git checkout 0.9.1
make
make release

%install
%__mkdir -p ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}
%__cp -rp ${RPM_BUILD_DIR}/package/* ${RPM_BUILD_ROOT}%{_prefix}/local/leofs/%{version}

%clean
%__rm -rf ${RPM_BUILD_DIR}
%__rm -rf ${RPM_BUILD_ROOT}

%files
%defattr(-,root,root,-)
%{_prefix}/local/leofs/%{version}

%changelog
* Thu Jul  5 2012  <leofs@leofs.org>
- Initial build.
