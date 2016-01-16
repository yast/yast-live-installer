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
  class InstLiveDoitClient < Client
    def main
      Yast.import "Pkg"
      textdomain "live-installer"

      Yast.import "FileUtils"
      Yast.import "Installation"
      Yast.import "Progress"
      Yast.import "Wizard"
      Yast.import "ImageInstallation"
      Yast.import "LiveInstaller"
      Yast.import "SlideShow"
      Yast.import "Report"

      Installation.destdir = "/mnt"
      # Progress::New(
      #     // Headline for last dialog of base installation: Install LILO etc.
      #     _("Copying the Live Image to Hard Disk"),
      #     "",	// Initial progress bar label - not empty (reserve space!)
      #     100,
      #     [ _("Evaluate filesystems to copy"), _("Copy root filesystem"), _("Copy additional filesystems") ],
      #     [],
      #     "");
      #
      # Wizard::DisableBackButton ();
      # Wizard::DisableNextButton ();
      #
      # Progress::NextStage ();
      # Progress::Title (_("Evaluating filesystems to copy..."));
      SlideShow.MoveToStage("images")
      SlideShow.StageProgress(0, _("Evaluating filesystems to copy..."))
      SlideShow.AppendMessageToInstLog(_("Evaluating filesystems to copy..."))
      @copy_map = LinksMap(LinksToCopyList())
      SlideShow.SubProgress(0, _("Copying root filesystem..."))
      SlideShow.AppendMessageToInstLog(_("Copying root filesystem..."))
      SlideShow.StageProgress(5, _("Copying live image..."))
      # Progress::NextStageStep (5);
      # Progress::Title (_("Copying root filesystem..."));

      @steps = Ops.add(Builtins.size(@copy_map), 1)
      @step_size = Ops.divide(95, @steps)

      if !CopyRootImage(5, Ops.add(5, @step_size))
        ReportImageCopyError()
        return :abort
      end
      #Progress::NextStageStep (10);
      if !CopySymlinkedImage(@copy_map, Ops.add(5, @step_size))
        ReportImageCopyError()
        return :abort
      end
      #Progress::Finish();
      #Progress::Title (_("Finished."));

      # reenable sources/services before their status gets stored in the target system
      Pkg.SourceEditSet(LiveInstaller.source_states)
      Builtins.foreach(LiveInstaller.service_states) do |s, state|
        Pkg.ServiceSet(s, state)
        Pkg.ServiceSave(s)
      end


      :next
    end

    # Find symlinks which need to be resolved and copied
    # @return a list of such symlinks
    def LinksToCopyList
      cmd = Builtins.sformat(
        "\n" +
          "\tfor LINK in `find / -xdev -type l` ; do\n" +
          "\t    stat -c \"%N\" $LINK |grep livecd >/dev/null 2>/dev/null && echo $LINK;\n" +
          "\tdone; exit 0"
      )
      Builtins.y2milestone("Executing %1", cmd)
      out = Convert.to_map(SCR.Execute(path(".target.bash_output"), cmd))
      Builtins.y2milestone("Result: %1", out)
      if Ops.get_integer(out, "exit", -1) != 0
        Builtins.y2error("Faild resolving symlinks")
        return []
      end
      stdout = Ops.get_string(out, "stdout", "")
      lines = Builtins.splitstring(stdout, "\n")
      lines = Builtins.filter(lines) { |l| l != "" }
      Builtins.y2milestone("Symlinks to resolve: %1", lines)
      deep_copy(lines)
    end

    # Create a map of relevant link pointers
    # @param list of links which need to be resolved and copied
    # @return a map $[ link : target ]
    def LinksMap(links)
      links = deep_copy(links)
      dest_length = Builtins.size(Installation.destdir)
      out = Builtins.listmap(links) do |link|
        if Builtins.substring(link, 0, dest_length) == Installation.destdir
          link = Builtins.substring(link, dest_length)
        end
        link = Ops.add("/", link) if Builtins.substring(link, 0, 1) != "/"
        target = Convert.to_string(SCR.Read(path(".target.symlink"), link))
        { link => target }
      end
      Builtins.y2milestone("Resolved symlinks: %1", out)
      deep_copy(out)
    end

    # Copy all the symlinks as needed
    # @param [Hash{String => String}] symlinks a map of resolved symlinks
    # @return [Boolean] true on success
    def CopySymlinkedImage(symlinks, progress_start)
      symlinks = deep_copy(symlinks)
      if Builtins.size(symlinks) == 0
        Builtins.y2milestone("No symlinked image")
        return true
      end
      index = 0
      progress_step = Ops.divide(
        Ops.multiply(Ops.subtract(100, progress_start), index),
        Builtins.size(symlinks)
      )
      ret = true
      Builtins.foreach(symlinks) do |link, target|
        index = Ops.add(index, 1)
        SlideShow.StageProgress(progress_start, nil)
        SlideShow.SubProgress(0, Builtins.sformat(_("Copying %1..."), link))
        SlideShow.AppendMessageToInstLog(
          Builtins.sformat(_("Copying %1..."), link)
        )
        #	Progress::Title (sformat (_("Copying %1..."), link));
        SCR.Execute(
          path(".target.remove"),
          Builtins.sformat("%1/%2", Installation.destdir, link)
        )
        # 	list<string> components = splitstring (link, "/");
        # 	while (size(components) > 1
        # 	    && components[size(components) - 1]:"" == "")
        # 	{
        # 	    components = remove (components, size (components) - 1);
        # 	}
        # 	if (size (components) > 1)
        # 	    components[size(components) - 1] = "";
        # 	link = mergestring (components, "/");
        progress_done = Ops.add(progress_start, progress_step)
        if FileUtils.IsDirectory(target)
          ret = ImageInstallation.FileSystemCopy(
            Ops.add("/", target),
            Builtins.sformat("%1/%2", Installation.destdir, link),
            progress_start,
            progress_done
          ) && ret
        else
          SCR.Execute(
            path(".target.bash"),
            Builtins.sformat("/bin/cp -a %1 %2/%3", target, Installation.destdir, link)
          )
        end
        progress_start = progress_done
        #	Progress::Step (progress_start);
        SlideShow.StageProgress(progress_done, nil)
        SlideShow.SubProgress(100, nil)
      end
      ret
    end

    # Copy root image to hard disk
    # @return [Boolean] true on success
    def CopyRootImage(progress_start, progress_finish)
      tmpdir = Convert.to_string(SCR.Read(path(".target.tmpdir")))
      SCR.Execute(
        path(".target.bash"),
        Builtins.sformat("/bin/cp -a %1/etc %2", Installation.destdir, tmpdir)
      )
      ret = ImageInstallation.FileSystemCopy(
        "/",
        Installation.destdir,
        progress_start,
        progress_finish
      )
      SCR.Execute(
        path(".target.bash"),
        Builtins.sformat("/bin/cp -a %1/etc %2", tmpdir, Installation.destdir)
      )
      ret
    end

    def ReportImageCopyError
      # check for out of disk space
      cmd = "df -P"
      Builtins.y2milestone("Executing %1", cmd)
      out = Convert.to_map(SCR.Execute(path(".target.bash_output"), cmd))
      Builtins.y2milestone("Output: %1", out)
      total_str = Ops.get_string(out, "stdout", "")
      error = nil
      Builtins.foreach(Builtins.splitstring(total_str, "\n")) do |line|
        parsed = Builtins.filter(Builtins.splitstring(line, " ")) { |s| s != "" }
        dev = Ops.get(parsed, 0, "")
        mp = Ops.get(parsed, 5, "")
        free = Ops.get(parsed, 3, "")
        if Builtins.substring(dev, 0, 4) == "/dev" &&
            Builtins.substring(mp, 0, 4) == "/mnt"
          if Ops.less_than(Builtins.tointeger(free), 100 * 1024) # need to set some lower limit - roughly estimated maximum size of the last file which could have failed
            error = _(
              "Copying the live image to hard disk failed.\n" +
                "\n" +
                "You have run out of disk space. Choose\n" +
                "a bigger disk partition for the installation\n" +
                "of the live system."
            )
          end
        end
      end
      if error != nil
        Report.Error(error)
        return
      end

      total_str = Ops.get(Builtins.splitstring(total_str, "\n"), 1, "")
      total_mb = Ops.divide(
        Builtins.tointeger(
          Ops.get(Builtins.filter(Builtins.splitstring(total_str, " ")) do |s|
            s != ""
          end, 2, "0")
        ),
        1024
      )



      # generic error report
      Report.Error(_("Copying the live image to hard disk failed."))

      nil
    end
  end
end

Yast::InstLiveDoitClient.new.main
