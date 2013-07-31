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
# File:	clients/inst_live_prepare_net_test.ycp
# Package:	Network configuration
# Summary:	Configuration dialogs for installation
# Authors:	Michal Svec <msvec@suse.cz>
#		Arvin Schnell <arvin@suse.de>
#
# $Id: inst_ask_net_test.ycp 27667 2006-02-07 10:33:15Z mvidner $
module Yast
  class InstLivePrepareNetTestClient < Client
    def main
      Yast.import "UI"

      textdomain "network"

      Yast.import "GetInstArgs"
      Yast.import "InternetDevices"
      Yast.import "Mode"

      Yast.include self, "network/routines.rb"
      Yast.include self, "network/installation/dialogs.rb"

      return :auto if GetInstArgs.going_back

      if Mode.update
        # FIXME should be made somewhere else

        Builtins.y2milestone("starting network")
        SCR.Execute(path(".target.bash"), "/sbin/rcnetwork start")
        Builtins.sleep(1)
      end

      # Nothing to test
      if !InternetDevices.FindFastest
        Internet.do_test = false
        return :auto
      end

      :next 

      # EOF
    end
  end
end

Yast::InstLivePrepareNetTestClient.new.main
