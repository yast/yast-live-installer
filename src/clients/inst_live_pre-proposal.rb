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
# Steps that need to be done before the installation proposal is called
module Yast
  class InstLivePreProposalClient < Client
    def main

      Yast.import "GetInstArgs"
      Yast.import "Kernel"

      # <-- functions -->

      if GetInstArgs.going_back
        Builtins.y2milestone("going back...")
        return :back
      end

      # bugzilla #297612
      SetVGAKernelParam()

      :next
    end

    # <-- functions -->

    def SetVGAKernelParam
      cmldline = Convert.to_string(
        WFM.Read(path(".local.string"), "/proc/cmdline")
      )

      if cmldline == nil
        Builtins.y2error("No cmdline!")
        return
      end

      cmdline_args = Builtins.splitstring(cmldline, " \t\n")

      just_parsing = ""

      Builtins.foreach(cmdline_args) do |cmdline_arg|
        if Builtins.regexpmatch(cmdline_arg, "[vV][gG][aA]=.*")
          just_parsing = cmdline_arg
          cmdline_arg = Builtins.regexpsub(
            cmdline_arg,
            "[vV][gG][aA]=(.*)",
            "\\1"
          )

          if cmdline_arg == nil || cmdline_arg == ""
            Builtins.y2error("Incorrect vga param %1", just_parsing)
            raise Break
          else
            Builtins.y2milestone("Adjusting Kernel cmdline vga=%1", cmdline_arg)
            Kernel.SetVgaType(cmdline_arg)
            raise Break
          end
        end
      end

      nil
    end
  end
end

Yast::InstLivePreProposalClient.new.main
