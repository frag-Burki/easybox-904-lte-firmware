# 
# Copyright (C) 2006-2007 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/target.mk

export TARGET_BUILD=1

### ctc ###
prereq clean download prepare compile install menuconfig oldconfig update refresh: FORCE
	@+$(NO_TRACE_MAKE) -C $(BOARD) $@

#prereq clean mostlyclean download prepare compile install menuconfig oldconfig change_default setup-links remove-links update refresh: FORCE
#	@+$(NO_TRACE_MAKE) -C $(BOARD) $@
#
#rootfs firmware fullimage:
#	@+$(NO_TRACE_MAKE) -C $(BOARD)/image $@
###########
