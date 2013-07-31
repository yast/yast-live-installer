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
#  save_config_finish.ycp
#
# Module:
#  Step of base installation finish
#
# Authors:
#  Jiri Srain <jsrain@suse.cz>
#
# $Id: save_config_finish.ycp 36694 2007-03-05 14:17:54Z locilka $
#
module Yast
  class LiveSaveConfigFinishClient < Client
    def main

      textdomain "live-installer"

      Yast.import "Progress"
      Yast.import "Timezone"
      Yast.import "Keyboard"
      Yast.import "Installation"
      Yast.import "Language"
      Yast.import "FileUtils"

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

      Builtins.y2milestone("starting save_config_finish")
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      if @func == "Info"
        return { "steps" => 3, "when" => [:live_installation] }
      elsif @func == "Write"
        # progress step title
        Progress.Title(_("Saving language..."))
        Language.Save
        Progress.NextStep

        # progress step title
        Progress.Title(_("Saving keyboard configuration..."))
        Keyboard.Save
        Progress.NextStep

        # progress step title
        Progress.Title(_("Saving time zone..."))
        Timezone.Save

        # bnc#550874
        # Call a script if it exists
        @scriptname = "/usr/bin/correct_live_for_reboot"
        if FileUtils.Exists(@scriptname)
          Builtins.y2milestone(
            "Calling %1 returned %2",
            @scriptname,
            SCR.Execute(path(".target.bash_output"), @scriptname)
          )
          Builtins.y2milestone(
            "Removing %1 returned %2",
            @scriptname,
            SCR.Execute(
              path(".target.bash_output"),
              Builtins.sformat("/bin/rm %1", @scriptname)
            )
          )
        else
          Builtins.y2milestone(
            "Script %1 doesn't exist, skipping...",
            @scriptname
          )
        end
      else
        Builtins.y2error("unknown function: %1", @func)
        @ret = nil
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("save_config_finish finished")
      deep_copy(@ret)
    end
  end
end

Yast::LiveSaveConfigFinishClient.new.main
