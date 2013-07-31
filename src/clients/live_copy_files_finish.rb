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
#  copy_files_finish.ycp
#
# Module:
#  Step of base installation finish
#
# Authors:
#  Jiri Srain <jsrain@suse.cz>
#
# $Id: live_copy_files_finish.ycp 38430 2007-06-13 13:50:38Z locilka $
#
module Yast
  class LiveCopyFilesFinishClient < Client
    def main
      Yast.import "UI"

      textdomain "live-installer"

      Yast.import "Installation"
      Yast.import "Directory"
      Yast.import "ProductControl"
      Yast.import "FileUtils"
      Yast.import "String"
      Yast.import "Initrd"
      Yast.import "BootStorage"
      # FIXME don't know why it fails :-(
      # import "SystemFilesCopy";

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

      Builtins.y2milestone("live_starting copy_files_finish")
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      if @func == "Info"
        return {
          "steps" => 1,
          # progress step title
          "title" => _(
            "Copying files to installed system..."
          ),
          "when"  => [:live_installation]
        }
      elsif @func == "Write"
        # bugzilla #221815
        # Adding blacklisted modules into the /etc/modprobe.d/blacklist
        # This should run before the SCR::switch function
        AdjustModprobeBlacklist()

        # Copy control.xml so it can be read once again during continue mode
        SCR.Execute(
          path(".target.bash"),
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(
                    Ops.add("/bin/cp ", ProductControl.current_control_file),
                    " "
                  ),
                  "'"
                ),
                String.Quote(Installation.destdir)
              ),
              Directory.etcdir
            ),
            "/control.xml'"
          )
        )
        SCR.Execute(
          path(".target.bash"),
          Ops.add(
            Ops.add(
              Ops.add(
                "/bin/chmod 0644 " + "'",
                String.Quote(Installation.destdir)
              ),
              Directory.etcdir
            ),
            "/control.xml'"
          )
        )

        # Copy files from inst-sys to the just installed system
        # FATE #301937, items are defined in the control file
        #    SystemFilesCopy::SaveInstSysContent();

        # Remove old eula.txt
        # bugzilla #208908
        @eula_txt = Builtins.sformat(
          "%1%2/eula.txt",
          Installation.destdir,
          Directory.etcdir
        )
        if FileUtils.Exists(@eula_txt)
          SCR.Execute(path(".target.remove"), @eula_txt)
        end

        # Copy info.txt so it can be used in firstboot (new eula.txt)
        if FileUtils.Exists("/info.txt")
          SCR.Execute(
            path(".target.bash"),
            Builtins.sformat("/bin/cp /info.txt %1", @eula_txt)
          )
        end
      else
        Builtins.y2error("unknown function: %1", @func)
        @ret = nil
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("live_copy_files_finish finished")
      deep_copy(@ret)
    end
  end
end

Yast::LiveCopyFilesFinishClient.new.main
