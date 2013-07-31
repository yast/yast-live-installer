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
  class InstLiveSimpleProposalClient < Client
    def main
      Yast.import "UI"

      Yast.import "BootCommon"
      Yast.import "GetInstArgs"
      Yast.import "Popup"
      Yast.import "Product"
      Yast.import "Wizard"
      Yast.import "LiveInstaller"
      Yast.import "Storage"
      Yast.import "HTML"
      Yast.import "Label"
      Yast.import "Keyboard"
      Yast.import "Timezone"

      textdomain "live-installer"

      Wizard.SetContents(
        # dialog caption
        _("Installation Settings"),
        # label
        Label(_("Analyzing the system...")),
        "",
        false,
        false
      )

      WFM.CallFunction(
        "partitions_proposal",
        [
          "MakeProposal",
          { "force_reset" => false, "language_changed" => false }
        ]
      )

      WFM.CallFunction(
        "bootloader_proposal",
        [
          "MakeProposal",
          { "force_reset" => false, "language_changed" => false }
        ]
      )

      WFM.CallFunction(
        "timezone_proposal",
        [
          "MakeProposal",
          { "force_reset" => false, "language_changed" => false }
        ]
      )

      WFM.CallFunction(
        "keyboard_proposal",
        [
          "MakeProposal",
          { "force_reset" => false, "language_changed" => false }
        ]
      )

      @contents = VBox()

      # partitioning summary

      @tm = Storage.GetTargetMap
      @used = 0
      @free = 0

      @disks = []

      Builtins.foreach(@tm) do |disk, data|
        partitions = Ops.get_list(data, "partitions", [])
        Builtins.foreach(partitions) do |p|
          if Ops.get_string(p, "mount", "") == "swap" ||
              Ops.get_string(p, "mount", "") != "" &&
                Ops.get_boolean(p, "format", false)
            @used = Ops.add(@used, Ops.get_integer(p, "size_k", 0))
          elsif Ops.get(p, "type") != :extended
            @free = Ops.add(@free, Ops.get_integer(p, "size_k", 0))
          end
        end
        if Ops.greater_than(@used, 0)
          @used = Ops.divide(Ops.multiply(100, @used), Ops.add(@used, @free))
          @disks = Builtins.add(
            @disks,
            Builtins.sformat(
              _("Use %1%% of disk %2 for Linux"),
              @used,
              Ops.get_string(data, "name", "")
            )
          )
        else
          @disks = Builtins.add(
            @disks,
            Builtins.sformat(
              _("Do not use disk %1"),
              Ops.get_string(data, "name", "")
            )
          )
        end
      end

      @contents = Builtins.add(@contents, Left(Heading(_("Partitioning"))))
      Builtins.foreach(@disks) do |disk|
        @contents = Builtins.add(@contents, Left(Label(disk)))
      end

      # end of partitioning summary
      # bootloader summary

      @timeout = Ops.get(BootCommon.globals, "timeout", "")

      @other = false
      Builtins.foreach(BootCommon.sections) do |s|
        @other = true if Ops.get_string(s, "type", "") == "other"
      end

      @contents = Builtins.add(@contents, VSpacing(1))
      @contents = Builtins.add(@contents, Left(Heading(_("System start-up"))))
      @contents = Builtins.add(
        @contents,
        Left(
          Label(
            @other ?
              _("Ask whether to boot Linux or existing system") :
              _("Boot only Linux")
          )
        )
      )
      @contents = Builtins.add(
        @contents,
        Left(
          Label(
            Builtins.sformat(_("System start time-out: %1 seconds"), @timeout)
          )
        )
      )

      # end of bootloader summary
      # keyboard entry

      @contents = Builtins.add(@contents, VSpacing(1))
      @contents = Builtins.add(@contents, Left(Heading(_("Keyboard"))))
      @contents = Builtins.add(
        @contents,
        Left(Label(Keyboard.MakeProposal(false, false)))
      )

      # end of keyboard entry
      # timezone entry

      @contents = Builtins.add(@contents, VSpacing(1))
      @contents = Builtins.add(@contents, Left(Heading(_("Time Zone"))))
      @contents = Builtins.add(@contents, Left(Label(Timezone.timezone)))

      # end of timezone entry

      @contents = HBox(HSpacing(2), @contents, HSpacing(2))
      @contents = VBox(
        VSpacing(1),
        @contents,
        VStretch(),
        PushButton(Id(:change), _("Change Installation Settings")),
        VSpacing(1)
      )

      # help text 1/3
      @help = _(
        "<p>\nUse <b>Accept</b> to perform a new installation with the values displayed.</p>"
      ) +
        # help text 2/3
        _(
          "<p>\n" +
            "To change the values, click the respective headline\n" +
            "or select <b>Change Installation Settings</b>.</p>\n"
        ) +
        # help text 3/3
        _(
          "<p>\n" +
            "Your hard disk has not been modified, you can still safely abort.\n" +
            "</p>"
        )



      Wizard.SetContents(
        _("Installation Settings"),
        @contents,
        @help,
        GetInstArgs.enable_back,
        GetInstArgs.enable_next
      )
      Wizard.SetTitleIcon("yast-software")
      Wizard.SetNextButton(:next, Label.AcceptButton)

      @ret = nil

      while @ret != :back && @ret != :next
        @ret = Convert.to_symbol(UI.UserInput)
        return :abort if @ret == :abort && Popup.ConfirmAbort(:painless)
        if @ret == :next
          LiveInstaller.run_full_proposal = false
          @ret = Convert.to_symbol(WFM.CallFunction("inst_doit", []))
        elsif @ret == :change
          LiveInstaller.run_full_proposal = true
          @ret = :next
        end
      end

      @ret
    end
  end
end

Yast::InstLiveSimpleProposalClient.new.main
