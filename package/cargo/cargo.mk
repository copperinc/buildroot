################################################################################
#
# cargo
#
################################################################################

CARGO_VERSION = 0.33.0
CARGO_SITE = $(call github,rust-lang,cargo,$(CARGO_VERSION))
CARGO_LICENSE = Apache-2.0 or MIT
CARGO_LICENSE_FILES = LICENSE-APACHE LICENSE-MIT

CARGO_DEPS_SHA256 = 78d19be7410f942cd5c30a4ad715555a75036ed97c0078130ae51c380b0cfd45
CARGO_DEPS_SITE = http://ftp.ubuntu.com/ubuntu/ubuntu/pool/universe/c/cargo
CARGO_DEPS_SOURCE = cargo_$(CARGO_VERSION).orig-vendor.tar.gz

CARGO_INSTALLER_VERSION = 4f994850808a572e2cc8d43f968893c8e942e9bf
CARGO_INSTALLER_SITE = $(call github,rust-lang,rust-installer,$(CARGO_INSTALLER_VERSION))
CARGO_INSTALLER_SOURCE = rust-installer-$(CARGO_INSTALLER_VERSION).tar.gz

HOST_CARGO_EXTRA_DOWNLOADS = \
	$(CARGO_DEPS_SITE)/$(CARGO_DEPS_SOURCE) \
	$(CARGO_INSTALLER_SITE)/$(CARGO_INSTALLER_SOURCE)

HOST_CARGO_DEPENDENCIES = \
	$(BR2_CMAKE_HOST_DEPENDENCY) \
	host-pkgconf \
	host-openssl \
	host-libhttpparser \
	host-libssh2 \
	host-libcurl \
	host-libgit2 \
	host-rustc \
	host-cargo-bin

HOST_CARGO_SNAP_BIN = $(HOST_CARGO_BIN_DIR)/cargo/bin/cargo
HOST_CARGO_HOME = $(HOST_DIR)/share/cargo

define HOST_CARGO_EXTRACT_DEPS
	@mkdir -p $(@D)/vendor
	$(call suitable-extractor,$(CARGO_DEPS_SOURCE)) \
		$(HOST_CARGO_DL_DIR)/$(CARGO_DEPS_SOURCE) | \
		$(TAR) --strip-components=1 -C $(@D)/vendor $(TAR_OPTIONS) -
endef

HOST_CARGO_POST_EXTRACT_HOOKS += HOST_CARGO_EXTRACT_DEPS

define HOST_CARGO_EXTRACT_INSTALLER
	@mkdir -p $(@D)/src/rust-installer
	$(call suitable-extractor,$(CARGO_INSTALLER_SOURCE)) \
		$(HOST_CARGO_DL_DIR)/$(CARGO_INSTALLER_SOURCE) | \
		$(TAR) --strip-components=1 -C $(@D)/src/rust-installer $(TAR_OPTIONS) -
endef

HOST_CARGO_POST_EXTRACT_HOOKS += HOST_CARGO_EXTRACT_INSTALLER

define HOST_CARGO_SETUP_DEPS
	mkdir -p $(@D)/.cargo
	( \
		echo "[source.crates-io]"; \
		echo "registry = 'https://github.com/rust-lang/crates.io-index'"; \
		echo "replace-with = 'vendored-sources'"; \
		echo "[source.vendored-sources]"; \
		echo "directory = '$(@D)/vendor'"; \
	) > $(@D)/.cargo/config
endef

HOST_CARGO_PRE_CONFIGURE_HOOKS += HOST_CARGO_SETUP_DEPS

HOST_CARGO_SNAP_OPTS = \
	--release \
	$(if $(VERBOSE),--verbose)

HOST_CARGO_ENV = \
	RUSTFLAGS="$(addprefix -Clink-arg=,$(HOST_LDFLAGS))" \
	CARGO_HOME=$(HOST_CARGO_HOME)

define HOST_CARGO_BUILD_CMDS
	(cd $(@D); $(HOST_MAKE_ENV) $(HOST_CARGO_ENV) $(HOST_CARGO_SNAP_BIN) \
		build $(HOST_CARGO_SNAP_OPTS))
endef

define HOST_CARGO_INSTALL_CMDS
	$(INSTALL) -D -m 0755 $(@D)/target/release/cargo $(HOST_DIR)/bin/cargo
	$(INSTALL) -D package/cargo/config.in \
		$(HOST_DIR)/share/cargo/config
	$(SED) 's/@RUSTC_TARGET_NAME@/$(RUSTC_TARGET_NAME)/' \
		$(HOST_DIR)/share/cargo/config
	$(SED) 's/@CROSS_PREFIX@/$(notdir $(TARGET_CROSS))/' \
		$(HOST_DIR)/share/cargo/config
endef

$(eval $(host-generic-package))
