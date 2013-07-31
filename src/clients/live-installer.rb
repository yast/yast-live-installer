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
  class LiveInstallerClient < Client
    def main
      Yast.import "Pkg"
      Yast.import "UI"
      textdomain "live-installer"

      Yast.import "Mode"
      Yast.import "Stage"
      Yast.import "ProductControl"
      Yast.import "Wizard"
      Yast.import "Report"
      Yast.import "LiveInstaller"
      Yast.import "Misc"
      Yast.import "Installation"
      Yast.import "Product"
      Yast.import "CommandLine"
      Yast.import "Popup"

      # Bugzilla #269890, CommanLine "support"
      # argmap is only a map, CommandLine uses string parameters
      if Ops.greater_than(Builtins.size(WFM.Args), 0)
        Mode.SetUI("commandline")
        Builtins.y2milestone("Mode CommandLine not supported, exiting...")
        # TRANSLATORS: error message - the module does not provide command line interface
        CommandLine.Print(
          _("There is no user interface available for this module.")
        )
        return nil
      end

      Wizard.OpenNextBackStepsDialog

      # check available memory
      @memories = Convert.to_list(SCR.Read(path(".probe.memory")))
      @memsize = Ops.get_integer(
        @memories,
        [0, "resource", "phys_mem", 0, "range"],
        0
      )
      @oneGB = 1073741824
      Builtins.y2milestone("Physical memory %1", @memsize)

      @cmd = "cat /proc/cmdline | grep -q liveinstall"
      @live_only = 0 ==
        Convert.to_integer(SCR.Execute(path(".target.bash"), @cmd))

      if Ops.less_than(@memsize, @oneGB) && !@live_only
        # pop-up, %1 is memory size, currently hardcoded "1 GB"
        if !Popup.ContinueCancel(
            Builtins.sformat(
              _(
                "Your computer has less than %1 of memory. This may not be\n" +
                  "sufficient for the live installation, especially when installing\n" +
                  "while running other applications.\n" +
                  "Before continuing, close all running applications.\n"
              ),
              "1 GB"
            )
          )
          UI.CloseDialog
          return nil
        end
      end

      # ensure all installation sources are disabled
      @source_init_success = Pkg.SourceStartManager(false)
      if @source_init_success
        LiveInstaller.source_states = Pkg.SourceEditGet
        Pkg.SourceEditSet(Builtins.maplist(LiveInstaller.source_states) do |s|
          Ops.set(s, "enabled", false)
          deep_copy(s)
        end)
        Builtins.foreach(Pkg.ServiceAliases) do |s|
          state = Pkg.ServiceGet(s)
          Ops.set(LiveInstaller.service_states, s, state)
          Ops.set(state, "enabled", false)
          Pkg.ServiceSet(s, state)
        end
      end

      Installation.destdir = "/mnt"
      Installation.scr_destdir = "/mnt"
      Yast.import "Storage"

      Storage.SwitchUiAutomounter(false)

      # detect removable media, if they are mounted, they cannot be used for installation (bnc #437235)
      # this is a hack, since partitioner cannot provide information which partitions will be resized,
      # removed or formatted and thus mustn't be mounted during installation
      @cmd = "cat /proc/mounts  |grep '/media/'"
      if 0 == Convert.to_integer(SCR.Execute(path(".target.bash"), @cmd))
        # continue/cancel pop-up
        if !Popup.ContinueCancel(
            _(
              "YaST detected a mounted removable media. YaST cannot install\n" +
                "the system on mounted media.\n" +
                "Unmount the media to install the system on it.\n"
            )
          )
          Storage.SwitchUiAutomounter(true)
          UI.CloseDialog
          return nil
        end
      end

      # do several checks because of DMRAID problems - bug #328388
      @out = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          "\n" +
            "/etc/init.d/boot.device-mapper start\n" +
            "/etc/init.d/boot.dmraid start\n" +
            "/etc/init.d/boot.lvm start\n" +
            "echo 1 > /sys/module/md_mod/parameters/start_ro\n" +
            "mdadm --examine --scan --config=partitions >/tmp/mdadm.conf\n" +
            "mdadm --assemble --scan --config=/tmp/mdadm.conf\n"
        )
      )
      Builtins.y2milestone("Device initialization output: %1", @out)
      @out = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          "\nhwinfo --disk | grep \"^Drive status: soft raid\"\n"
        )
      )
      Builtins.y2milestone("Soft raid detection: %1", @out)
      if Ops.get_integer(@out, "exit", -1) == 0
        if !Popup.ContinueCancel(
            # continue-cancel popup
            _(
              "openSUSE installer detected DMRAID array.\n" +
                "It is not supported by the openSUSE live installer.\n" +
                "Continuing the installation may cause data loss."
            )
          )
          Storage.SwitchUiAutomounter(true)
          UI.CloseDialog
          return :back
        end
      end

      @stage_mode = [
        { "stage" => "initial", "mode" => "live_installation" },
        { "stage" => "continue", "mode" => "live_installation" }
      ]
      Mode.SetMode("live_installation")
      # Stage::initial is required for most of the modules to behave correctly
      Stage.Set("initial")
      Storage.InitLibstorage(false)

      if Ops.less_than(
          0,
          Builtins.size(
            Convert.to_map(
              SCR.Read(path(".target.stat"), LiveInstaller.live_control_file)
            )
          )
        )
        ProductControl.custom_control_file = LiveInstaller.live_control_file
      end
      if !ProductControl.Init
        Builtins.y2error(
          "control file %1 not found",
          ProductControl.custom_control_file
        )
      end
      ProductControl.AddWizardSteps(@stage_mode)

      # Do log Report messages by default (#180862)
      Report.LogMessages(true)
      Report.LogErrors(true)
      Report.LogWarnings(true)

      @ret = ProductControl.Run
      Builtins.y2milestone("ProductControl::Run() returned: %1", @ret)

      # reenable sources/services
      Pkg.SourceEditSet(LiveInstaller.source_states)
      Builtins.foreach(LiveInstaller.service_states) do |s, state|
        Pkg.ServiceSet(s, state)
        Pkg.ServiceSave(s)
      end

      Pkg.SourceFinishAll
      Pkg.TargetFinish

      Storage.SwitchUiAutomounter(true)
      # handle reboot (bnc #455760)
      if @ret == :next
        # popup dialog, text followed by 'Reboot Now' and 'Reboot Later' buttons
        @msg = _(
          "The computer needs to be rebooted without the Live CD in the\n" +
            "drive to finish the installation. Either YaST can reboot\n" +
            "now or you can reboot any time later.\n" +
            "\n" +
            "Note that the Live CD is not ejected, you can either eject\n" +
            "it after the Live system shuts down or select \"Hard Disk\"\n" +
            "in the boot menu of the Live CD."
        )
        # push button
        if Popup.AnyQuestion(
            Popup.NoHeadline,
            @msg,
            _("Reboot &Now"),
            _("Reboot &Later"),
            :focus_no
          )
          @cmd2 = "/sbin/reboot"
          UI.OpenDialog(Label("Rebooting the system..."))
          if 0 == Convert.to_integer(WFM.Execute(path(".local.bash"), @cmd2))
            while true
              Builtins.sleep(10)
            end
          end
          # this should never be reached in case of successful reboot
          UI.CloseDialog
          # error report
          Report.Error(
            _(
              "Failed to restart the computer.\n" +
                "Reboot it manually. You may even need to push the\n" +
                "'Reset' button to restart it."
            )
          )
        end
      end
      UI.CloseDialog

      @ret
    end
  end
end

Yast::LiveInstallerClient.new.main
