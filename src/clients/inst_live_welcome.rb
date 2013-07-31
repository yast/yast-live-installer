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
module Yast
  class InstLiveWelcomeClient < Client
    def main
      Yast.import "UI"

      Yast.import "GetInstArgs"
      Yast.import "Popup"
      Yast.import "Product"
      Yast.import "Wizard"

      textdomain "live-installer"

      # help text 1/1
      @help = _(
        "<p>Welcome to the &product; installation.\nPress <b>Next</p> to run the installation wizard.</p>"
      )

      Wizard.SetContents(
        # dialog caption, %1 is product name (typically openSUSE)
        Builtins.sformat(_("Welcome to %1 installation"), Product.name),
        # wellcome label, %1 is product name
        Label(
          Builtins.sformat(
            _(
              "Your %1 will be installed quickly\n" +
                "and easily in a few steps.\n" +
                "You will only have to answer some questions."
            ),
            Product.name
          )
        ),
        @help,
        GetInstArgs.enable_back,
        GetInstArgs.enable_next
      )
      Wizard.SetTitleIcon("yast-software")

      @ret = nil

      while @ret != :next
        @ret = Convert.to_symbol(UI.UserInput)
        return :abort if @ret == :abort && Popup.ConfirmAbort(:painless)
      end

      @ret
    end
  end
end

Yast::InstLiveWelcomeClient.new.main
