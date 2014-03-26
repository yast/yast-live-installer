#
# spec file for package yast2-live-installer
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-live-installer
Version:        3.1.3
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:	        System/YaST
License:        GPL-2.0+

# Internet and InternetDevices
Requires:	yast2 >= 2.16.6
Requires:	yast2-network >= 2.16.6
Requires:	yast2-bootloader >= 2.18.7
#unified progress
Requires:	yast2-installation >= 2.18.17

Requires:	yast2-bootloader yast2-country yast2-storage
BuildRequires:	perl-XML-Writer update-desktop-files yast2 yast2-testsuite
BuildRequires:  yast2-devtools >= 3.1.10

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - Installation from Live Media

%description
This package contains the YaST component to deploy a live media to the
hard disk of the computer.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%{yast_clientdir}/*.rb
%{yast_moduledir}/LiveInstaller.*
%{yast_desktopdir}/live-installer.desktop
%doc %{yast_docdir}
