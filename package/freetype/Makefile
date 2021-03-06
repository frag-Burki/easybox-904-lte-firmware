#
# Copyright (C) 2006-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=freetype
PKG_VERSION:=2.4.4
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=@SF/freetype
PKG_MD5SUM:=b3e2b6e2f1c3e0dffa1fd2a0f848b671

PKG_FIXUP:=libtool
PKG_LIBTOOL_PATHS:=builds/unix

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/package.mk

define Package/libfreetype
  SECTION:=libs
  CATEGORY:=Libraries
  DEPENDS:=+zlib
  TITLE:=A free, high-quality and portable font engine
  URL:=http://www.freetype.org/
endef

define Package/libfreetype/description
 The FreeType project is a team of volunteers who develop free, 
 portable and high-quality software solutions for digital typography.
 They specifically target embedded systems and focus on bringing small, 
 efficient and ubiquitous products.
endef

TARGET_CFLAGS += $(FPIC)

CONFIGURE_ARGS += \
	--enable-shared \
	--enable-static \

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) DESTDIR="$(PKG_INSTALL_DIR)" all install
endef

define Build/InstallDev
	$(INSTALL_DIR) $(2)/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/freetype-config $(2)/bin/
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/freetype2 $(1)/usr/include/
	$(CP) $(PKG_INSTALL_DIR)/usr/include/ft2build.h $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libfreetype.{a,so*} $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/pkgconfig/freetype2.pc $(1)/usr/lib/pkgconfig/

	$(SED) \
		's,^\(prefix\|exec_prefix\)=.*,\1="$(STAGING_DIR)/usr",g' \
		 $(2)/bin/freetype-config
endef


define Package/libfreetype/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libfreetype.so.* $(1)/usr/lib/
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,libfreetype))
