include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-myapp
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-myapp
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=My Custom Application
  DEPENDS:=+luci-base
endef

define Package/luci-app-myapp/description
  A custom LuCI application example.
endef

define Build/Compile
endef

define Package/luci-app-myapp/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./luasrc/controller/*.lua $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DATA) ./luasrc/model/cbi/*.lua $(1)/usr/lib/lua/luci/model/cbi/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view
	$(INSTALL_DATA) ./luasrc/view/*.htm $(1)/usr/lib/lua/luci/view/
endef

$(eval $(call BuildPackage,luci-app-myapp))
