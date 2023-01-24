# -----------------------------------------------------------------------------
#
# Makefile for building native ni-neutrino and ni-libstb-hal
#
# (C) 2012,2013 Stefan Seyfried
# (C) 2015 Sven Hoefer
#
# prerequisite packages need to be installed, no checking is done for that
#
# -----------------------------------------------------------------------------
#
# This is a 'stand-alone' Makefile that works outside of our buildsystem too.
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
# echo "deb http://www.deb-multimedia.org jessie main non-free" >> /etc/apt/sources.list
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
# -----------------------------------------------------------------------------

-include config.local

BOXMODEL ?= generic

NEUTRINO = ni-neutrino
N_BRANCH = master
LIBSTB-HAL = ni-libstb-hal
LH_BRANCH = master

SOURCE = $(PWD)/../source
ifeq ($(wildcard $(SOURCE)),)
  SOURCE = $(PWD)/src
endif
SRC = $(PWD)/src
OBJ = $(PWD)/obj
ROOT = $(PWD)/root
DEPS = $(PWD)/deps

N_SRC  = $(SOURCE)/$(NEUTRINO)
N_OBJ  = $(OBJ)/$(NEUTRINO)
LH_SRC = $(SOURCE)/$(LIBSTB-HAL)
LH_OBJ = $(OBJ)/$(LIBSTB-HAL)

prefix = /usr

# search path(s) for all prerequisites
VPATH = $(DEPS)

# -----------------------------------------------------------------------------

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

# in case some libs are installed in $(ROOT)$(prefix) (e.g. libdvbsi++)
CFLAGS += -I$(ROOT)$(prefix)/include
CFLAGS += -L$(ROOT)$(prefix)/lib
CFLAGS += -L$(ROOT)$(prefix)/lib64

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

# -----------------------------------------------------------------------------

PKG_CONFIG_PATH = $(ROOT)$(prefix)/lib/pkgconfig
export PKG_CONFIG_PATH

# -----------------------------------------------------------------------------

# first target is default
default: neutrino

deps: libdvbsi lua ffmpeg

run:
	export SIMULATE_FE=1; \
	$(ROOT)$(prefix)/bin/neutrino

run-gdb:
	export SIMULATE_FE=1; \
	gdb -ex run $(ROOT)$(prefix)/bin/neutrino

run-valgrind:
	export SIMULATE_FE=1; \
	valgrind --leak-check=full --log-file="$(ROOT)/valgrind.log" -v $(ROOT)$(prefix)/bin/neutrino

# -----------------------------------------------------------------------------

neutrino: $(N_OBJ)/config.status | $(ROOT)
	-rm $(N_OBJ)/src/neutrino # force relinking on changed libstb-hal
	$(MAKE) -C $(N_OBJ) install

libstb-hal: $(LH_OBJ)/config.status | $(ROOT)
	$(MAKE) -C $(LH_OBJ) install

$(N_OBJ)/config.status: libstb-hal | $(N_OBJ) $(N_SRC)
	set -e; cd $(N_SRC); \
		git checkout $(N_BRANCH)
	$(N_SRC)/autogen.sh
	set -e; cd $(N_OBJ); \
		$(N_SRC)/configure \
			--prefix=$(ROOT)$(prefix) \
			--sysconfdir=$(ROOT)/etc \
			--localstatedir=$(ROOT)/var \
			\
			--enable-maintainer-mode \
			--enable-silent-rules \
			--enable-mdev \
			--enable-giflib \
			--enable-cleanup \
			\
			--with-target=native \
			--with-targetroot=$(ROOT) \
			--with-boxtype=generic \
			$(if $(filter $(BOXMODEL), raspi),--with-boxmodel=raspi) \
			--with-stb-hal-includes=$(LH_SRC)/include \
			--with-stb-hal-build=$(ROOT)$(prefix)/lib \
			; \

$(LH_OBJ)/config.status: deps | $(LH_OBJ) $(LH_SRC)
	set -e; cd $(LH_SRC); \
		git checkout $(LH_BRANCH)
	$(LH_SRC)/autogen.sh
	set -e; cd $(LH_OBJ); \
		$(LH_SRC)/configure \
			--prefix=$(ROOT)$(prefix) \
			\
			--enable-maintainer-mode \
			--enable-shared=no \
			$(if $(findstring gstreamer,$(CFLAGS)),--enable-gstreamer_10=yes) \
			\
			--with-target=native \
			--with-boxtype=generic \
			$(if $(filter $(BOXMODEL), raspi),--with-boxmodel=raspi) \
			;

# -----------------------------------------------------------------------------

$(OBJ):
	mkdir -p $(OBJ)

$(N_OBJ) \
$(LH_OBJ): | $(OBJ)
	mkdir -p $@

$(ROOT):
	mkdir -p $@
	mkdir -p $(ROOT)/etc
	mkdir -p $(ROOT)/media/sda1/{epg,logos,movies,music,pictures,plugins,streamripper}
	echo "imagename=NI \o/ Neutrino Generic-PC" > $(ROOT)/.version
	cp --remove-destination -a skel-root/. $(ROOT)/
	cp --remove-destination -a skel-user/. $(ROOT)/

$(DEPS) \
$(SRC):
	mkdir -p $@

$(N_SRC): | $(SOURCE)
	cd $(SOURCE) && git clone https://github.com/neutrino-images/$(NEUTRINO).git

$(LH_SRC): | $(SOURCE)
	cd $(SOURCE) && git clone https://github.com/neutrino-images/$(LIBSTB-HAL).git

# -----------------------------------------------------------------------------

update: $(N_SRC) $(LH_SRC)
	cd $(N_SRC) && git pull
	cd $(LH_SRC) && git pull
	git pull

neutrino-clean:
	-$(MAKE) -C $(N_OBJ) clean
	rm -rf $(N_OBJ)

libstb-hal-clean:
	-$(MAKE) -C $(LH_OBJ) clean
	rm -rf $(LH_OBJ)

clean: neutrino-clean libstb-hal-clean

clean-all:
	rm -rf $(OBJ)
	rm -rf $(DEPS)
	rm -rf $(ROOT)

# -----------------------------------------------------------------------------

# libdvbsi is not commonly packaged for linux distributions
LIBDVBSI_VERSION = 0.3.9
LIBDVBSI_DIR = libdvbsi++-$(LIBDVBSI_VERSION)
LIBDVBSI_SOURCE = libdvbsi++-$(LIBDVBSI_VERSION).tar.bz2
LIBDVBSI_SITE = https://github.com/mtdcr/libdvbsi/releases/download/$(LIBDVBSI_VERSION)

$(SRC)/$(LIBDVBSI_SOURCE): | $(SRC)
	cd $(SRC) && wget $(LIBDVBSI_SITE)/$(LIBDVBSI_SOURCE)

libdvbsi: $(SRC)/$(LIBDVBSI_SOURCE) | $(DEPS) $(ROOT)
	rm -rf $(SRC)/$(LIBDVBSI_DIR)
	tar -C $(SRC) -xf $(SRC)/$(LIBDVBSI_SOURCE)
	set -e; cd $(SRC)/$(LIBDVBSI_DIR); \
		./autogen.sh; \
		./configure \
			--prefix=$(ROOT)$(prefix) \
			; \
		$(MAKE); \
		make install
	rm -rf $(SRC)/$(LIBDVBSI_DIR)
	touch $(DEPS)/$(@)

# -----------------------------------------------------------------------------

LUA_VERSION = 5.2.4
LUA_DIR = lua-$(LUA_VERSION)
LUA_SOURCE = lua-$(LUA_VERSION).tar.gz
LUA_SITE = https://www.lua.org/ftp

$(SRC)/$(LUA_SOURCE): | $(SRC)
	cd $(SRC) && wget $(LUA_SITE)/$(LUA_SOURCE)

lua: $(SRC)/$(LUA_SOURCE) | $(DEPS) $(ROOT)
	rm -rf $(SRC)/$(LUA_DIR)
	tar -C $(SRC) -xf $(SRC)/$(LUA_SOURCE)
	set -e;	cd $(SRC)/$(LUA_DIR); \
		sed -i "s|^#define LUA_ROOT	.*|#define LUA_ROOT	\"$(ROOT)$(prefix)/\"|" src/luaconf.h && \
		$(MAKE) linux; \
		make install INSTALL_TOP=$(ROOT)$(prefix)
	rm -rf $(SRC)/$(LUA_DIR)
	touch $(DEPS)/$(@)

# -----------------------------------------------------------------------------

FFMPEG_VERSION = 4.4.2
FFMPEG_DIR = ffmpeg-$(FFMPEG_VERSION)
FFMPEG_SOURCE = ffmpeg-$(FFMPEG_VERSION).tar.xz
FFMPEG_SITE = http://www.ffmpeg.org/releases

$(SRC)/$(FFMPEG_SOURCE): | $(SRC)
	cd $(SRC) && wget $(FFMPEG_SITE)/$(FFMPEG_SOURCE)

ffmpeg: $(SRC)/$(FFMPEG_SOURCE) | $(DEPS) $(ROOT)
	rm -rf $(SRC)/$(FFMPEG_DIR)
	tar -C $(SRC) -xf $(SRC)/$(FFMPEG_SOURCE)
	set -e; cd $(SRC)/$(FFMPEG_DIR); \
		./configure \
			--prefix=$(ROOT)$(prefix) \
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
	rm -rf $(SRC)/$(FFMPEG_DIR)
	touch $(DEPS)/$(@)

# -----------------------------------------------------------------------------

#PHONY =

.PHONY: $(PHONY)
