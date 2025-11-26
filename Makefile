include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-modbusTcp
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-modbusTcp
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Modbus TCP Bridge (西南交通大学PLC协议)
  PKGARCH:=all
  DEPENDS:=+lua +luci-lib-nixio +libmosquitto-nossl +mosquitto-client-nossl
endef

define Package/luci-app-modbusTcp/description
  LuCI application for Modbus TCP communication with Southwest Jiaotong University PLC devices
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	cp -r ./luasrc $(PKG_BUILD_DIR)/
	cp -r ./htdocs $(PKG_BUILD_DIR)/
	cp -r ./files $(PKG_BUILD_DIR)/
	cp Makefile $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-modbusTcp/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
	
	$(INSTALL_DIR) $(1)/www/luci-static/resources
	cp -pR $(PKG_BUILD_DIR)/htdocs/* $(1)/www/luci-static/resources/
	
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/files/etc/config/modbusTcp $(1)/etc/config/modbusTcp
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/init.d/modbus_bridge $(1)/etc/init.d/modbus_bridge
	
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/sbin/modbus_bridge $(1)/usr/sbin/modbus_bridge
endef

$(eval $(call Build/Template,luci-app-modbusTcp))

include $(TOPDIR)/feeds/luci/luci.mk