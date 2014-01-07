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
  class InstLiveCleanupClient < Client
    def main

      Yast.import "GetInstArgs"
      Yast.import "Popup"
      Yast.import "Product"
      Yast.import "Wizard"
      Yast.import "FileUtils"
      Yast.import "Installation"
      Yast.import "FileUtils"

      textdomain "live-installer"

      return :auto if GetInstArgs.going_back

      # bugzilla #326800
      # Call a script if it exists
      @scriptname = "/usr/bin/correct_live_install"

      if FileUtils.Exists(Installation.destdir + @scriptname)
        Builtins.y2milestone(
          "Calling %1 returned %2",
          @scriptname,
          SCR.Execute(path(".target.bash_output"), "chroot " + Installation.destdir + " " + @scriptname)
        )
        Builtins.y2milestone(
          "Removing %1 returned %2",
          @scriptname,
          SCR.Execute(
            path(".target.bash_output"),
            Builtins.sformat("chroot " + Installation.destdir + " /bin/rm %1", @scriptname)
          )
        )
      else
        Builtins.y2milestone(
          "Script %1 doesn't exist, skipping...",
          @scriptname
        )
      end

      # calling RPM is faster than initializing whole update stack
      Builtins.y2milestone("Removing yast2-live-installer package")

      @out = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          "chroot " + Installation.destdir + " /bin/rpm -e yast2-live-installer"
        )
      )

      if Ops.get_integer(@out, "exit", 0) != 0
        Builtins.y2error("Removing yast2-live-installer failed: %1", @out)
      end

      :auto
    end
  end
end

Yast::InstLiveCleanupClient.new.main
