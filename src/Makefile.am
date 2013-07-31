# Sources for live-installer

module_DATA = \
  modules/LiveInstaller.rb

client_DATA = \
  clients/inst_live_welcome.rb \
  clients/inst_live_sw_select.rb \
  clients/inst_live_simple_proposal.rb \
  clients/inst_live_add_base_repo.rb \
  clients/live_copy_files_finish.rb \
  clients/inst_live_doit.rb \
  clients/inst_live_cleanup.rb \
  clients/live-installer.rb \
  clients/inst_live_pre-proposal.rb \
  clients/live_save_config_finish.rb \
  clients/inst_live_prepare_net_test.rb \
  clients/inst_live_full_proposal.rb \
  clients/live_runme_at_boot_finish.rb

desktop_DATA = \
  desktop/live-installer.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common