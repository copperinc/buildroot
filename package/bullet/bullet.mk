################################################################################
#
# bullet
#
################################################################################

BULLET_VERSION = 2.88
BULLET_SITE = $(call github,bulletphysics,bullet3,$(BULLET_VERSION))
BULLET_INSTALL_STAGING = YES
BULLET_LICENSE = Zlib
BULLET_LICENSE_FILES = LICENSE.txt

# Disable demos apps and unit tests.
# Disable Bullet3 library.
BULLET_CONF_OPTS = -DBUILD_UNIT_TESTS=OFF \
	-DBUILD_BULLET2_DEMOS=OFF \
	-DBUILD_BULLET3=OFF

# extras needs dlfcn.h and threads
ifeq ($(BR2_STATIC_LIBS):$(BR2_TOOLCHAIN_HAS_THREADS),:y)
BULLET_CONF_OPTS += -DBUILD_EXTRAS=ON
else
BULLET_CONF_OPTS += -DBUILD_EXTRAS=OFF
endif

$(eval $(cmake-package))
