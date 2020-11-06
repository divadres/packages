#
# Copyright (C) 2008-2018 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=rwol
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0
PKG_MAINTAINER:=

include $(INCLUDE_DIR)/package.mk

PKG_DEFAULT_DEPENDS=+etherwake

define Package/rwol
    SECTION:=net
    CATEGORY:=Network
    SUBMENU:=Routing and Redirection
    PKGARCH:=all
    TITLE:=Remote Wake on LAN
endef

# shown in LuCI package description
define Package/rwol/description
    Remote Wake on LAN
endef

# shown in menuconfig <Help>
define Package/rwol/config
	help
		A configurable set of scripts for broadcast remote wol packages using tcpdump and etherwake.
		  - IPv4 support
		  - log file support
		Version: $(PKG_VERSION)-$(PKG_RELEASE)
endef

define Build/Configure
endef

define Build/Compile
	$(CP) ./files $(PKG_BUILD_DIR)

	$(SED) '/^VERSION=*/s/.*/VERSION="$(PKG_VERSION)-$(PKG_RELEASE)"/' $(PKG_BUILD_DIR)/files/functions.sh
	
	# remove comments, white spaces and empty lines
	for FILE in `find $(PKG_BUILD_DIR)/files -type f`; do \
		$(SED) 's/^[[:space:]]*//' \
		-e '/^#[[:space:]]\|^#$$$$/d' \
		-e 's/[[:space:]]#[[:space:]].*$$$$//' \
		-e 's/[[:space:]]*$$$$//' \
		-e '/^\/\/[[:space:]]/d'	\
		-e '/^[[:space:]]*$$$$/d'	$$$$FILE; \
	done
endef

define Package/rwol/conffiles
/etc/config/rwol
endef

###### *************************************************************************
define Package/rwol/preinst
	#!/bin/sh
	# if NOT run buildroot then stop service
	[ -z "$${IPKG_INSTROOT}" ] && /etc/init.d/rwol stop >/dev/null 2>&1
	exit 0	# suppress errors
endef

define Package/rwol/install
	$(INSTALL_DIR)  $(1)/etc/init.d
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/files/rwol.init $(1)/etc/init.d/rwol
	$(INSTALL_DIR)  $(1)/etc/config
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/files/rwol.config $(1)/etc/config/rwol
	$(INSTALL_DIR)  $(1)/usr/lib/rwol
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/files/*.sh $(1)/usr/lib/rwol
endef

define Package/rwol/postinst
	#!/bin/sh
	# if NOT run buildroot and PKG_UPGRADE then (re)start service if enabled
	[ -z "$${IPKG_INSTROOT}" -a "$${PKG_UPGRADE}" = "1" ] && {
		/etc/init.d/rwol enabled && \
			/etc/init.d/rwol start >/dev/null 2>&1
	}
	exit 0	# suppress errors
endef

define Package/rwol/prerm
	#!/bin/sh
	# if run within buildroot exit
	[ -n "$${IPKG_INSTROOT}" ] && exit 0
	# stop running scripts
	/etc/init.d/rwol stop
	/etc/init.d/rwol disable
	# clear LuCI indexcache
	rm -f /tmp/luci-indexcache >/dev/null 2>&1
	exit 0	# suppress errors
endef


$(eval $(call BuildPackage,rwol))
