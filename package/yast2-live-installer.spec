#
# spec file for package yast2-live-installer
#
# Copyright (c) 2016 SUSE LINUX GmbH, Nuernberg, Germany.
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
Version:        3.1.11
Release:        0
Summary:        YaST2 - Installation from Live Media
Group:          System/YaST
License:        GPL-2.0+
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2
Source1:        correct_live_for_reboot
Source2:        correct_live_install
BuildRequires:  perl-XML-Writer
BuildRequires:  update-desktop-files
BuildRequires:  yast2
BuildRequires:  yast2-devtools >= 3.1.10
BuildRequires:  yast2-testsuite
# Internet and InternetDevices
Requires:       yast2 >= 2.16.6
Requires:       yast2-bootloader >= 2.18.7
Requires:       yast2-network >= 2.16.6
# unified progress
Requires:       yast2-bootloader
Requires:       yast2-country
Requires:       yast2-installation >= 2.18.17
Requires:       yast2-qt-branding
Requires:       yast2-storage
Requires:       yast2-users
Requires:       yast2-ruby-bindings >= 1.0.0
# disk and partitioning utils/tools
Requires:       btrfsprogs
Requires:       dosfstools
Requires:       dmraid
Requires:       e2fsprogs
Requires:       jfsutils
Requires:       hfsutils
Requires:       kpartx
Requires:       lvm2
Requires:       ntfs-3g
Requires:       ntfsprogs
Requires:       os-prober
Requires:       reiserfs
Requires:       sg3_utils
Requires:       xfsprogs

%description
This package contains the YaST component to deploy a live media to the
hard disk of the computer.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install
%__install -d -m 755 %{buildroot}/%_bindir/
cp %{SOURCE1} %{buildroot}/%_bindir/
cp %{SOURCE2} %{buildroot}/%_bindir/
chmod 755 %{buildroot}/%_bindir/*

%post
if ( [ ! -L /etc/products.d/baseproduct ] &&  [ -f /etc/products.d/openSUSE.prod ] ) ; then
  if [   -f /etc/products.d/baseproduct ] ; then
    rm /etc/products.d/baseproduct
  fi
  ln -s /etc/products.d/openSUSE.prod /etc/products.d/baseproduct
fi
%files
%defattr(-,root,root)
%{yast_clientdir}/*.rb
%{yast_moduledir}/LiveInstaller.*
%{yast_desktopdir}/live-installer.desktop
%_bindir/correct_live_for_reboot
%_bindir/correct_live_install
%doc %{yast_docdir}

%changelog
