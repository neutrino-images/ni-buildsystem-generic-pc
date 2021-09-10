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
# apt-get install libcurl4-openssl-dev
# apt-get install libfreetype6-dev
# apt-get install libsigc++-2.0-dev
# apt-get install libreadline6-dev
# apt-get install libjpeg-dev
# apt-get install libgif-dev
# apt-get install libflac-dev
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
DEST = $(PWD)/root

N_SRC  = $(SOURCE)/$(NEUTRINO)
N_OBJ  = $(OBJ)/$(NEUTRINO)
LH_SRC = $(SOURCE)/$(LIBSTB-HAL)
LH_OBJ = $(OBJ)/$(LIBSTB-HAL)

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

# in case some libs are installed in $(DEST) (e.g. dvbsi++)
CFLAGS += -I$(DEST)/include
CFLAGS += -L$(DEST)/lib
CFLAGS += -L$(DEST)/lib64

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

PKG_CONFIG_PATH = $(DEST)/lib/pkgconfig
export PKG_CONFIG_PATH

# -----------------------------------------------------------------------------

# first target is default
default: neutrino

deps: libdvbsi lua ffmpeg

run:
	export SIMULATE_FE=1; \
	$(DEST)/bin/neutrino

run-gdb:
	export SIMULATE_FE=1; \
	gdb -ex run $(DEST)/bin/neutrino

run-valgrind:
	export SIMULATE_FE=1; \
	valgrind --leak-check=full --log-file="$(DEST)/valgrind.log" -v $(DEST)/bin/neutrino

# -----------------------------------------------------------------------------

neutrino: $(N_OBJ)/config.status | $(DEST)
	-rm $(N_OBJ)/src/neutrino # force relinking on changed libstb-hal
	$(MAKE) -C $(N_OBJ) install

libstb-hal: $(LH_OBJ)/config.status | $(DEST)
	$(MAKE) -C $(LH_OBJ) install

$(N_OBJ)/config.status: deps | $(N_OBJ) $(N_SRC) libstb-hal
	set -e; cd $(N_SRC); \
		git checkout $(N_BRANCH)
	$(N_SRC)/autogen.sh
	set -e; cd $(N_OBJ); \
		$(N_SRC)/configure \
			--prefix=$(DEST) \
			--enable-maintainer-mode \
			--enable-silent-rules \
			--enable-mdev \
			--enable-giflib \
			--enable-cleanup \
			--with-target=native \
			--with-boxtype=generic \
			$(if $(filter $(BOXMODEL), raspi),--with-boxmodel=raspi) \
			--with-stb-hal-includes=$(LH_SRC)/include \
			--with-stb-hal-build=$(DEST)/lib \
			; \

$(LH_OBJ)/config.status: deps | $(LH_OBJ) $(LH_SRC)
	set -e; cd $(LH_SRC); \
		git checkout $(LH_BRANCH)
	$(LH_SRC)/autogen.sh
	set -e; cd $(LH_OBJ); \
		$(LH_SRC)/configure \
			--prefix=$(DEST) \
			--with-target=native \
			--with-boxtype=generic \
			$(if $(filter $(BOXMODEL), raspi),--with-boxmodel=raspi) \
			--enable-maintainer-mode \
			--enable-shared=no \
			$(if $(findstring gstreamer,$(CFLAGS)),--enable-gstreamer_10=yes) \
			;

# -----------------------------------------------------------------------------

$(OBJ):
	mkdir -p $(OBJ)

$(N_OBJ) \
$(LH_OBJ): | $(OBJ)
	mkdir -p $@

$(DEST):
	mkdir -p $@
	cp --remove-destination -a skel-root/. $(DEST)/
	cp --remove-destination -a skel-user/. $(DEST)/

$(SRC):
	mkdir -p $@

$(N_SRC): | $(SOURCE)
	cd $(SOURCE) && git clone https://github.com/neutrino-images/$(NEUTRINO).git

$(LH_SRC): | $(SOURCE)
	cd $(SOURCE) && git clone https://github.com/neutrino-images/$(LIBSTB-HAL).git

# -----------------------------------------------------------------------------

checkout: $(N_SRC) $(LH_SRC)

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

clean-all: clean
	rm -rf $(DEST)

# -----------------------------------------------------------------------------

# libdvbsi is not commonly packaged for linux distributions
libdvbsi: | $(DEST)
	rm -rf $(SRC)/libdvbsi++
	git clone https://github.com/OpenVisionE2/libdvbsi.git $(SRC)/libdvbsi++
	set -e; cd $(SRC)/libdvbsi++; \
		./autogen.sh; \
		./configure \
			--prefix=$(DEST) \
			; \
		$(MAKE); \
		make install
	rm -rf $(SRC)/libdvbsi++

# -----------------------------------------------------------------------------

LUA_VER=5.2.4

$(SRC)/lua-$(LUA_VER).tar.gz: | $(SRC)
	cd $(SRC) && wget http://www.lua.org/ftp/lua-$(LUA_VER).tar.gz

lua: $(SRC)/lua-$(LUA_VER).tar.gz | $(DEST)
	rm -rf $(SRC)/lua-$(LUA_VER)
	tar -C $(SRC) -xf $(SRC)/lua-$(LUA_VER).tar.gz
	set -e;	cd $(SRC)/lua-$(LUA_VER); \
		sed -i "s|^#define LUA_ROOT	.*|#define LUA_ROOT	\"$(DEST)/\"|" src/luaconf.h && \
		$(MAKE) linux; \
		make install INSTALL_TOP=$(DEST)
	rm -rf $(SRC)/lua-$(LUA_VER)
	rm -rf $(DEST)/man

# -----------------------------------------------------------------------------

FFMPEG_VER=4.3.2

$(SRC)/ffmpeg-$(FFMPEG_VER).tar.bz2: | $(SRC)
	cd $(SRC) && wget http://www.ffmpeg.org/releases/ffmpeg-$(FFMPEG_VER).tar.bz2

ffmpeg: $(SRC)/ffmpeg-$(FFMPEG_VER).tar.bz2 | $(DEST)
	rm -rf $(SRC)/ffmpeg-$(FFMPEG_VER)
	tar -C $(SRC) -xf $(SRC)/ffmpeg-$(FFMPEG_VER).tar.bz2
	set -e; cd $(SRC)/ffmpeg-$(FFMPEG_VER); \
		./configure \
			--prefix=$(DEST) \
			\
			--disable-doc \
			--disable-htmlpages \
			--disable-manpages \
			--disable-podpages \
			--disable-txtpages \
			\
			--disable-stripping \
			; \
		$(MAKE); \
		make install
	rm -rf $(SRC)/ffmpeg-$(FFMPEG_VER)

# -----------------------------------------------------------------------------

PHONY  = $(DEST)
PHONY += checkout

.PHONY: $(PHONY)
