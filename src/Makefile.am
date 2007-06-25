# Makefile.am for live-installer/src

yncludedir = @yncludedir@/live-installer

client_DATA =			\
	live-installer.ycp	\
	live_doit.ycp		\
	live_finish.ycp		\
	live_stage_normal.ycp	\
	live_stage_initial.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp

desktop_DATA =			\
	live-installer.desktop

module_DATA =			\
	LiveInstaller.ycp

# create a symlink for local build, #145327
live-installer:
	ln -sf . $@
ycpchook = live-installer

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
