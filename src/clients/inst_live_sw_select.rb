# encoding: utf-8

# ***************************************************************************
#
# Copyright (c) 2002 - 2012 Novell, Inc.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#
# ***************************************************************************
# Maintainer:             Jiri Srain <jsrain@suse.cz>
#
# $Id: firstboot.ycp 36560 2007-02-28 12:40:38Z lslezak $
module Yast
  class InstLiveSwSelectClient < Client
    def main
      textdomain "live-installer"

      Yast.import "GetInstArgs"
      Yast.import "Wizard"
      Yast.import "PackagesUI"

      # Called backwards
      return :auto if GetInstArgs.going_back

      Wizard.SetContents(
        _("Software Installation"),
        VBox(),
        "",
        GetInstArgs.enable_back,
        GetInstArgs.enable_next
      )
      @result = PackagesUI.RunPackageSelector({ "mode" => :searchMode })
      Builtins.y2milestone("Result: %1", @result)
      @result == :accept ? :next : :back
    end
  end
end

Yast::InstLiveSwSelectClient.new.main
