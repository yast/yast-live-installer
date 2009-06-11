# Makefile.am for live-installer/src

yncludedir = @yncludedir@/live-installer

client_DATA =			\
	live-installer.ycp	\
	inst_live_doit.ycp		\
	inst_live_add_base_repo.ycp	\
	inst_live_sw_select.ycp		\
	live_copy_files_finish.ycp	\
	live_runme_at_boot_finish.ycp	\
	inst_live_welcome.ycp		\
	inst_live_full_proposal.ycp	\
	inst_live_simple_proposal.ycp	\
	inst_live_cleanup.ycp		\
	inst_live_prepare_net_test.ycp	\
	inst_live_prepareprogress.ycp	\
	live_save_config_finish.ycp	\
	inst_live_pre-proposal.ycp

desktop_DATA =			\
	live-installer.desktop

module_DATA =			\
	LiveInstaller.ycp

# create a symlink for local build, #145327
live-installer:
	ln -sf . $@
ycpchook = live-installer

EXTRA_DIST = $(client_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
