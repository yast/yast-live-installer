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
# File:
#  yast_inf_finish.ycp
#
# Module:
#  Step of base installation finish
#
# Authors:
#  Jiri Srain <jsrain@suse.cz>
#
# $Id: yast_inf_finish.ycp 27936 2006-02-13 20:01:14Z olh $
#
module Yast
  class LiveRunmeAtBootFinishClient < Client
    def main
      Yast.import "UI"

      textdomain "live-installer"

      Yast.import "Mode"
      Yast.import "Directory"
      Yast.import "Misc"

      Yast.include self, "installation/misc.rb"

      @ret = nil
      @func = ""
      @param = {}

      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.to_map(WFM.Args(1))
        end
      end

      Builtins.y2milestone("starting yast_inf_finish")
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      if @func == "Info"
        return {
          "steps" => 1,
          # progress step title
          "title" => _("Writing YaST Configuration..."),
          "when"  => [:live_installation]
        }
      elsif @func == "Write"
        # --------------------------------------------------------------
        # Tell new boot scripts to launch yast2, once the
        # new system has done its virgin boot. The Write call
        # creates any missing directory :-).

        @runme_at_boot = Ops.add(Directory.vardir, "/runme_at_boot")
        if !SCR.Write(path(".target.string"), @runme_at_boot, "")
          Builtins.y2error("Couldn't create target %1", @runme_at_boot)
        end
        if !SCR.Write(
            path(".target.string"),
            Installation.file_live_install_mode,
            "YES"
          )
          Builtins.y2error(
            "Couldn't create target %1",
            Installation.file_live_install_mode
          )
        end
        # FIXME doesn't belong here
        Misc.boot_msg = "" # _("Reboot the computer without the Live CD in the drive
        # to continue the installation.
        #
        # Note that the CD cannot be ejected now. You can eject
        # it after the Live system shuts down or by selecting
        # \"Hard Disk\" in the boot menu of the Live CD.");
      else
        Builtins.y2error("unknown function: %1", @func)
        @ret = nil
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("yast_inf_finish finished")
      deep_copy(@ret)
    end
  end
end

Yast::LiveRunmeAtBootFinishClient.new.main
