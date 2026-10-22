################################################################################
#
# Makefile for building native ni-libstb-hal and ni-neutrino
#
################################################################################
#
# (C) 2012,2013 Stefan Seyfried
# (C) 2015-2023 Sven Hoefer
#
# This is a 'stand-alone' Makefile that works outside of NI \o/ Buildsystem too.
#
# ------------------------------------------------------------------------------
#
# Prerequisite packages need to be installed, no checking is done for that
#
# Prerequisits
# ------------
#
# apt-get install build-essential ccache git make subversion patch gcc bison \
# 	flex texinfo automake libtool ncurses-dev pkg-config
#
# Neutrino dependencies for Debian
# --------------------------------
#
# apt-get install libavformat-dev
# apt-get install libswscale-dev
# echo "deb http://www.deb-multimedia.org stable main non-free" >> /etc/apt/sources.list
# apt-get install deb-multimedia-keyring
# apt-get install libswresample-dev
# apt-get install libopenthreads-dev
# apt-get install libglew-dev
# apt-get install freeglut3-dev
# apt-get install libao-dev
# apt-get install libid3tag0-dev
# apt-get install libmad0-dev
# apt-get install libogg-dev
# apt-get install libfreetype6-dev
# apt-get install libsigc++-2.0-dev
# apt-get install libjpeg-dev
# apt-get install libgif-dev
# apt-get install libvorbis-dev
# apt-get install libflac-dev
# apt-get install libcurl4-openssl-dev
# apt-get install libreadline6-dev
#
# Optional
# --------
#
# apt-get install libgstreamer1.0-dev
# apt-get install libgstreamer-plugins-base1.0-dev
#
# ------------------------------------------------------------------------------

-include config.local

BOXMODEL ?= generic

BUILD_DIR = $(PWD)/.build
DEPS_DIR = $(PWD)/.deps
ARCHIVE_DIR = $(PWD)/archive
TARGET_DIR = $(PWD)/root
SOURCE_DIR = $(PWD)/../source
ifeq ($(wildcard $(SOURCE_DIR)),)
  SOURCE_DIR = $(ARCHIVE_DIR)
endif
SKEL_DIR = $(PWD)/skel

prefix = /usr

# search path(s) for all prerequisites
VPATH = $(DEPS_DIR)

# ------------------------------------------------------------------------------

CFLAGS  = -W
CFLAGS += -Wall
#CFLAGS += -Werror
CFLAGS += -Wextra
CFLAGS += -Wshadow
CFLAGS += -Wsign-compare
#CFLAGS += -Wconversion
#CFLAGS += -Wfloat-equal
CFLAGS += -Wuninitialized
CFLAGS += -Wmaybe-uninitialized
CFLAGS += -Werror=type-limits
CFLAGS += -Warray-bounds
CFLAGS += -Wformat-security
#CFLAGS += -fmax-errors=10
CFLAGS += -O0 -g -ggdb3
CFLAGS += -funsigned-char
CFLAGS += -rdynamic
CFLAGS += -DPEDANTIC_VALGRIND_SETUP
CFLAGS += -DDYNAMIC_LUAPOSIX
CFLAGS += -D__KERNEL_STRICT_NAMES
CFLAGS += -D__STDC_FORMAT_MACROS
CFLAGS += -D__STDC_CONSTANT_MACROS
CFLAGS += -DASSUME_MDEV
CFLAGS += -DTEST_MENU

# enable --as-needed for catching more build problems...
CFLAGS += -Wl,--as-needed

# in case some libs are installed in $(TARGET_DIR)$(prefix) (e.g. libdvbsi++)
CFLAGS += -I$(TARGET_DIR)$(prefix)/include
CFLAGS += -L$(TARGET_DIR)$(prefix)/lib
CFLAGS += -L$(TARGET_DIR)$(prefix)/lib64

# workaround for debian's non-std sigc++ locations
CFLAGS += -I/usr/include/sigc++-2.0
CFLAGS += -I/usr/lib/x86_64-linux-gnu/sigc++-2.0/include

# gstreamer flags
#CFLAGS += $(shell pkg-config --cflags --libs gstreamer-1.0)
#CFLAGS += $(shell pkg-config --cflags --libs gstreamer-audio-1.0)
#CFLAGS += $(shell pkg-config --cflags --libs gstreamer-video-1.0)

CXXFLAGS  = $(CFLAGS)
CXXFLAGS +=  -std=c++11
export CFLAGS CXXFLAGS

# ------------------------------------------------------------------------------

PKG_CONFIG_PATH = $(TARGET_DIR)$(prefix)/lib/pkgconfig
export PKG_CONFIG_PATH

# ------------------------------------------------------------------------------

# first target is default
default: neutrino

local-files: config.local $(SKEL_DIR) 

config.local:
	@clear
	@echo ""
	@echo "    ###   ###  ###"
	@echo "     ###   ##  ##"
	@echo "     ####  ##  ##"
	@echo "     ## ## ##  ##"
	@echo "     ##  ####  ##"
	@echo "     ##   ###  ##"
	@echo "     ##    ##  ##      http://www.neutrino-images.de"
	@echo "            #"
	@echo ""
	@echo "   -------------------------------------------------"
	@echo ""
	@echo "   1)  Generic-PC"
	@echo "   2)  Raspberry Pi"
	@echo ""
	@read -p "Select your boxmodel? [default: 1] " boxmodel; \
	boxmodel=$${boxmodel:-1}; \
	case "$$boxmodel" in \
		 1)	boxmodel=generic;; \
		 2)	boxmodel=raspi;; \
		*)	boxmodel=generic;; \
	esac; \
	install -m 0644 config.example $(@); \
	sed -i -e "s|^#BOXMODEL = $$boxmodel|BOXMODEL = $$boxmodel|" $(@)

# ------------------------------------------------------------------------------

run:
	export SIMULATE_FE=1; \
	$(TARGET_DIR)$(prefix)/bin/neutrino

run-gdb:
	export SIMULATE_FE=1; \
	gdb -ex run $(TARGET_DIR)$(prefix)/bin/neutrino

run-valgrind:
	export SIMULATE_FE=1; \
	valgrind --leak-check=full --log-file="$(TARGET_DIR)/valgrind.log" -v $(TARGET_DIR)$(prefix)/bin/neutrino

# ------------------------------------------------------------------------------

$(BUILD_DIR) \
$(DEPS_DIR) \
$(ARCHIVE_DIR) \
$(SKEL_DIR):
	install -d $(@)

ifneq ($(ARCHIVE_DIR),$(SOURCE_DIR))
$(SOURCE_DIR):
	install -d $(@)
endif

$(TARGET_DIR): | $(SKEL_DIR)
	install -d $(@) $(@)/etc $(foreach dir,\
		epg logos movies music pictures plugins streamripper,\
		$(@)/media/sda1/$(dir))
	echo "imagename=NI \o/ Neutrino Generic-PC" > $(@)/.version
	cp --remove-destination -a $(SKEL_DIR)/. $(@)/

# ------------------------------------------------------------------------------

ifeq ($(LIBSTB_HAL_BRANCH),$(empty))
LIBSTB_HAL_BRANCH = master
endif

LIBSTB_HAL_VERSION = $(LIBSTB_HAL_BRANCH)
LIBSTB_HAL_DIR = ni-libstb-hal
LIBSTB_HAL_SOURCE = ni-libstb-hal
LIBSTB_HAL_SITE = https://github.com/neutrino-images

LIBSTB_HAL_DEPENDENCIES = ffmpeg

LIBSTB_HAL_SOURCE_DIR = $(SOURCE_DIR)/$(LIBSTB_HAL_SOURCE)
LIBSTB_HAL_OBJ_DIR = $(BUILD_DIR)/$(LIBSTB_HAL_DIR)-obj
LIBSTB_HAL_CONFIG_STATUS = $(LIBSTB_HAL_OBJ_DIR)/config.status

$(LIBSTB_HAL_SOURCE_DIR): | $(SOURCE_DIR)
	cd $(SOURCE_DIR) && git clone $(LIBSTB_HAL_SITE)/$(LIBSTB_HAL_SOURCE).git

$(LIBSTB_HAL_CONFIG_STATUS): $(LIBSTB_HAL_DEPENDENCIES) | $(LIBSTB_HAL_SOURCE_DIR) $(LIBSTB_HAL_OBJ_DIR)
	set -e; cd $(LIBSTB_HAL_SOURCE_DIR); \
		git checkout $(LIBSTB_HAL_VERSION)
	$(LIBSTB_HAL_SOURCE_DIR)/autogen.sh
	set -e; cd $(LIBSTB_HAL_OBJ_DIR); \
		$(LIBSTB_HAL_SOURCE_DIR)/configure \
			--prefix=$(TARGET_DIR)$(prefix) \
			\
			--enable-maintainer-mode \
			--enable-shared=no \
			$(if $(findstring gstreamer,$(CFLAGS)),--enable-gstreamer_10=yes) \
			\
			--with-target=native \
			--with-targetroot=$(TARGET_DIR) \
			--with-boxtype=generic \
			$(if $(filter $(BOXMODEL), raspi),--with-boxmodel=raspi) \
			;

$(LIBSTB_HAL_OBJ_DIR)/libstb-hal.a: libstb-hal
libstb-hal: $(LIBSTB_HAL_CONFIG_STATUS) | $(TARGET_DIR)
	$(MAKE) -C $(LIBSTB_HAL_OBJ_DIR) install

libstb-hal.clean:
	-$(MAKE) -C $(LIBSTB_HAL_OBJ_DIR) clean
	rm -rf $(LIBSTB_HAL_OBJ_DIR)

# ------------------------------------------------------------------------------

ifeq ($(NEUTRINO_BRANCH),$(empty))
NEUTRINO_BRANCH = master
endif

NEUTRINO_VERSION = $(NEUTRINO_BRANCH)
NEUTRINO_DIR = ni-neutrino
NEUTRINO_SOURCE = ni-neutrino
NEUTRINO_SITE = https://github.com/neutrino-images

NEUTRINO_DEPENDENCIES = ffmpeg libdvbsi lua libmicrohttpd preact

NEUTRINO_SOURCE_DIR = $(SOURCE_DIR)/$(NEUTRINO_SOURCE)
NEUTRINO_OBJ_DIR = $(BUILD_DIR)/$(NEUTRINO_DIR)-obj
NEUTRINO_CONFIG_STATUS = $(NEUTRINO_OBJ_DIR)/config.status

$(NEUTRINO_SOURCE_DIR): | $(SOURCE_DIR)
	cd $(SOURCE_DIR); git clone $(NEUTRINO_SITE)/$(NEUTRINO_SOURCE).git

$(NEUTRINO_CONFIG_STATUS): $(NEUTRINO_DEPENDENCIES) | $(NEUTRINO_SOURCE_DIR) $(NEUTRINO_OBJ_DIR) $(LIBSTB_HAL_OBJ_DIR)/libstb-hal.a
	set -e; cd $(NEUTRINO_SOURCE_DIR); \
		git checkout $(NEUTRINO_VERSION)
	$(NEUTRINO_SOURCE_DIR)/autogen.sh
	set -e; cd $(NEUTRINO_OBJ_DIR); \
		$(NEUTRINO_SOURCE_DIR)/configure \
			--prefix=$(TARGET_DIR)$(prefix) \
			--sysconfdir=$(TARGET_DIR)/etc \
			--localstatedir=$(TARGET_DIR)/var \
			\
			--enable-maintainer-mode \
			--enable-silent-rules \
			--enable-mdev \
			--enable-giflib \
			--enable-cleanup \
			--enable-unit-tests \
			\
			--with-target=native \
			--with-targetroot=$(TARGET_DIR) \
			--with-boxtype=generic \
			$(if $(filter $(BOXMODEL), raspi),--with-boxmodel=raspi) \
			--with-stb-hal-includes=$(LIBSTB_HAL_SOURCE_DIR)/include \
			--with-stb-hal-build=$(TARGET_DIR)$(prefix)/lib \
			; \

neutrino: $(NEUTRINO_CONFIG_STATUS) | $(TARGET_DIR)
	-rm $(NEUTRINO_OBJ_DIR)/src/neutrino # force relinking on changed libstb-hal
	$(MAKE) -C $(NEUTRINO_OBJ_DIR) install

neutrino.clean:
	-$(MAKE) -C $(NEUTRINO_OBJ_DIR) clean
	rm -rf $(NEUTRINO_OBJ_DIR)

# ------------------------------------------------------------------------------

$(LIBSTB_HAL_OBJ_DIR) \
$(NEUTRINO_OBJ_DIR): | $(BUILD_DIR)
	install -d $(@)

# ------------------------------------------------------------------------------

update: $(LIBSTB_HAL_SOURCE_DIR) $(NEUTRINO_SOURCE_DIR)
	cd $(LIBSTB_HAL_SOURCE_DIR); git pull
	cd $(NEUTRINO_SOURCE_DIR); git pull
	git pull

# ------------------------------------------------------------------------------

clean: libstb-hal.clean neutrino.clean

clean-all:
	rm -rf $(BUILD_DIR)
	rm -rf $(DEPS_DIR)
	rm -rf $(TARGET_DIR)

%-clean:
	-find $(DEPS_DIR) -name $(subst -clean,,$(@)) -delete

# ------------------------------------------------------------------------------

FFMPEG_VERSION = 6.1.1
FFMPEG_DIR = ffmpeg-$(FFMPEG_VERSION)
FFMPEG_SOURCE = ffmpeg-$(FFMPEG_VERSION).tar.xz
FFMPEG_SITE = http://www.ffmpeg.org/releases

$(ARCHIVE_DIR)/$(FFMPEG_SOURCE): | $(ARCHIVE_DIR)
	cd $(ARCHIVE_DIR) && wget $(FFMPEG_SITE)/$(FFMPEG_SOURCE)

ffmpeg: $(ARCHIVE_DIR)/$(FFMPEG_SOURCE) | $(BUILD_DIR) $(DEPS_DIR) $(TARGET_DIR)
	rm -rf $(BUILD_DIR)/$(FFMPEG_DIR)
	tar -C $(BUILD_DIR) -xf $(ARCHIVE_DIR)/$(FFMPEG_SOURCE)
	set -e; cd $(BUILD_DIR)/$(FFMPEG_DIR); \
		./configure \
			--prefix=$(TARGET_DIR)$(prefix) \
			\
			--disable-doc \
			--disable-htmlpages \
			--disable-manpages \
			--disable-podpages \
			--disable-txtpages \
			\
			--disable-stripping \
			--disable-x86asm \
			; \
		$(MAKE); \
		make install
	rm -rf $(BUILD_DIR)/$(FFMPEG_DIR)
	touch $(DEPS_DIR)/$(@)

# ------------------------------------------------------------------------------

# libdvbsi is not commonly packaged for linux distributions
LIBDVBSI_VERSION = 0.3.9
LIBDVBSI_DIR = libdvbsi++-$(LIBDVBSI_VERSION)
LIBDVBSI_SOURCE = libdvbsi++-$(LIBDVBSI_VERSION).tar.bz2
LIBDVBSI_SITE = https://github.com/mtdcr/libdvbsi/releases/download/$(LIBDVBSI_VERSION)

$(ARCHIVE_DIR)/$(LIBDVBSI_SOURCE): | $(ARCHIVE_DIR)
	cd $(ARCHIVE_DIR) && wget $(LIBDVBSI_SITE)/$(LIBDVBSI_SOURCE)

libdvbsi: $(ARCHIVE_DIR)/$(LIBDVBSI_SOURCE) | $(BUILD_DIR) $(DEPS_DIR) $(TARGET_DIR)
	rm -rf $(BUILD_DIR)/$(LIBDVBSI_DIR)
	tar -C $(BUILD_DIR) -xf $(ARCHIVE_DIR)/$(LIBDVBSI_SOURCE)
	set -e; cd $(BUILD_DIR)/$(LIBDVBSI_DIR); \
		./autogen.sh; \
		./configure \
			--prefix=$(TARGET_DIR)$(prefix) \
			; \
		$(MAKE); \
		make install
	rm -rf $(BUILD_DIR)/$(LIBDVBSI_DIR)
	touch $(DEPS_DIR)/$(@)

# ------------------------------------------------------------------------------

LUA_VERSION = 5.2.4
LUA_DIR = lua-$(LUA_VERSION)
LUA_SOURCE = lua-$(LUA_VERSION).tar.gz
LUA_SITE = https://www.lua.org/ftp

$(ARCHIVE_DIR)/$(LUA_SOURCE): | $(ARCHIVE_DIR)
	cd $(ARCHIVE_DIR) && wget $(LUA_SITE)/$(LUA_SOURCE)

lua: $(ARCHIVE_DIR)/$(LUA_SOURCE) | $(BUILD_DIR) $(DEPS_DIR) $(TARGET_DIR)
	rm -rf $(BUILD_DIR)/$(LUA_DIR)
	tar -C $(BUILD_DIR) -xf $(ARCHIVE_DIR)/$(LUA_SOURCE)
	set -e;	cd $(BUILD_DIR)/$(LUA_DIR); \
		sed -i "s|^#define LUA_ROOT	.*|#define LUA_ROOT	\"$(TARGET_DIR)$(prefix)/\"|" src/luaconf.h && \
		$(MAKE) linux; \
		make install INSTALL_TOP=$(TARGET_DIR)$(prefix)
	rm -rf $(BUILD_DIR)/$(LUA_DIR)
	touch $(DEPS_DIR)/$(@)

# ------------------------------------------------------------------------------

LIBMICROHTTPD_VERSION = 1.0.10
LIBMICROHTTPD_DIR = libmicrohttpd-$(LIBMICROHTTPD_VERSION)
LIBMICROHTTPD_SOURCE = libmicrohttpd-$(LIBMICROHTTPD_VERSION).tar.gz
LIBMICROHTTPD_SITE = http://ftp.gnu.org/pub/gnu/libmicrohttpd

$(ARCHIVE_DIR)/$(LIBMICROHTTPD_SOURCE): | $(ARCHIVE_DIR)
	cd $(ARCHIVE_DIR) && wget $(LIBMICROHTTPD_SITE)/$(LIBMICROHTTPD_SOURCE)

libmicrohttpd: $(ARCHIVE_DIR)/$(LIBMICROHTTPD_SOURCE) | $(BUILD_DIR) $(DEPS_DIR) $(TARGET_DIR)
	rm -rf $(BUILD_DIR)/$(LIBMICROHTTPD_DIR)
	tar -C $(BUILD_DIR) -xf $(ARCHIVE_DIR)/$(LIBMICROHTTPD_SOURCE)
	set -e; cd $(BUILD_DIR)/$(LIBMICROHTTPD_DIR); \
		./configure \
			--prefix=$(TARGET_DIR)$(prefix) \
			; \
		$(MAKE); \
		make install
	rm -rf $(BUILD_DIR)/$(LIBMICROHTTPD_DIR)
	touch $(DEPS_DIR)/$(@)

# ------------------------------------------------------------------------------

PREACT_VERSION = 10.24.3
PREACT_DIR     = preact-$(PREACT_VERSION)
PREACT_SOURCE  = preact-$(PREACT_VERSION).tgz
PREACT_SITE    = https://registry.npmjs.org/preact/-

PREACT_TARGET_DIR = $(TARGET_DIR)$(prefix)/share/tuxbox/neutrino/httpd/ni-web/vendor

$(ARCHIVE_DIR)/$(PREACT_SOURCE): | $(ARCHIVE_DIR)
	cd $(ARCHIVE_DIR) && wget $(PREACT_SITE)/$(PREACT_SOURCE)

preact: $(ARCHIVE_DIR)/$(PREACT_SOURCE) | $(BUILD_DIR) $(DEPS_DIR) $(TARGET_DIR)
	rm -rf $(BUILD_DIR)/$(PREACT_DIR)
	# npm archives all unpack to package/, so each needs a directory of its own
	mkdir $(BUILD_DIR)/$(PREACT_DIR)
	tar -C $(BUILD_DIR)/$(PREACT_DIR) -xf $(ARCHIVE_DIR)/$(PREACT_SOURCE)
	install -d $(PREACT_TARGET_DIR)
	sed -e '/^\/\/# sourceMappingURL=/d' \
		$(BUILD_DIR)/$(PREACT_DIR)/package/dist/preact.module.js \
		| gzip -9 -n -c > $(PREACT_TARGET_DIR)/preact.module.js.gz
	sed -e '/^\/\/# sourceMappingURL=/d' \
		-e 's|from"preact"|from"/vendor/preact.module.js"|g' \
		$(BUILD_DIR)/$(PREACT_DIR)/package/hooks/dist/hooks.module.js \
		| gzip -9 -n -c > $(PREACT_TARGET_DIR)/hooks.module.js.gz
	rm -rf $(BUILD_DIR)/$(PREACT_DIR)
	touch $(DEPS_DIR)/$(@)

# ------------------------------------------------------------------------------

PHONY = preact

.PHONY: $(PHONY)
