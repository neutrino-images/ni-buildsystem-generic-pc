###############################################################################
#
# Makefile for building native ni-neutrino-hd and libstb-hal
#
# (C) 2012,2013 Stefan Seyfried
# (C) 2015 Sven Hoefer
#
# prerequisite packages need to be installed, no checking is done for that
#
###############################################################################

### This is a 'stand-alone' Makefile that works outside of our buildsystem too.

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

###############################################################################

NEUTRINO = ni-neutrino-hd
N_BRANCH = ni/mp/tuxbox
LIBSTB-HAL = ni-libstb-hal

SOURCE = $(PWD)/../source
ifeq ($(wildcard $(SOURCE)),)
  SOURCE = $(PWD)/src
endif
SRC = $(PWD)/src
OBJ = $(PWD)/obj
DEST = $(PWD)/root

LH_SRC = $(SOURCE)/$(LIBSTB-HAL)
LH_OBJ = $(OBJ)/$(LIBSTB-HAL)
N_SRC  = $(SOURCE)/$(NEUTRINO)
N_OBJ  = $(OBJ)/$(NEUTRINO)

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
### enable --as-needed for catching more build problems...
CFLAGS += -Wl,--as-needed

### in case some libs are installed in $(DEST) (e.g. dvbsi++)
CFLAGS += -I$(DEST)/include
CFLAGS += -L$(DEST)/lib
CFLAGS += -L$(DEST)/lib64

### workaround for debian's non-std sigc++ locations
CFLAGS += -I/usr/include/sigc++-2.0
CFLAGS += -I/usr/lib/x86_64-linux-gnu/sigc++-2.0/include

PKG_CONFIG_PATH = $(DEST)/lib/pkgconfig
export PKG_CONFIG_PATH

CXXFLAGS = $(CFLAGS)
export CFLAGS CXXFLAGS

###############################################################################

# first target is default...
default: neutrino

run:
	export SIMULATE_FE=1; \
	$(DEST)/bin/neutrino

run-gdb:
	export SIMULATE_FE=1; \
	gdb -ex run $(DEST)/bin/neutrino

run-valgrind:
	export SIMULATE_FE=1; \
	valgrind --leak-check=full --log-file="$(DEST)/valgrind.log" -v $(DEST)/bin/neutrino

neutrino: $(N_OBJ)/config.status | $(DEST)
	-rm $(N_OBJ)/src/neutrino # force relinking on changed libstb-hal
	$(MAKE) -C $(N_OBJ) install

libstb-hal: $(LH_OBJ)/config.status | $(DEST)
	$(MAKE) -C $(LH_OBJ) install

$(LH_OBJ)/config.status: | $(LH_OBJ) $(LH_SRC)
	$(LH_SRC)/autogen.sh
	set -e; cd $(LH_OBJ); \
		$(LH_SRC)/configure --enable-maintainer-mode \
			--prefix=$(DEST) \
			--enable-shared=no \
			;

$(N_OBJ)/config.status: | $(N_OBJ) $(N_SRC) libstb-hal
	$(N_SRC)/autogen.sh
	set -e; cd $(N_SRC); \
		git checkout $(N_BRANCH); \
	set -e; cd $(N_OBJ); \
		$(N_SRC)/configure --enable-maintainer-mode \
			--prefix=$(DEST) \
			--enable-silent-rules \
			--enable-mdev \
			--enable-giflib \
			--enable-cleanup \
			--with-target=native \
			--with-boxtype=generic \
			--with-stb-hal-includes=$(LH_SRC)/include \
			--with-stb-hal-build=$(DEST)/lib \
			; \
		test -e version.h || touch version.h

$(OBJ):
	mkdir $(OBJ)

$(OBJ)/$(NEUTRINO) \
$(OBJ)/$(LIBSTB-HAL): | $(OBJ)
	mkdir $@

$(DEST):
	mkdir $@
	cp --remove-destination -a skel-root/* $(DEST)/

$(SRC):
	mkdir $@

$(LH_SRC): | $(SOURCE)
	cd $(SOURCE) && git clone https://bitbucket.org/neutrino-images/$(LIBSTB-HAL).git

$(N_SRC): | $(SOURCE)
	cd $(SOURCE) && git clone https://bitbucket.org/neutrino-images/$(NEUTRINO).git

checkout: $(SOURCE)/$(LIBSTB-HAL) $(SOURCE)/$(NEUTRINO)

update: $(LH_SRC) $(N_SRC)
	cd $(LH_SRC) && git pull
	cd $(N_SRC) && git pull
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

###############################################################################

# libdvbsi is not commonly packaged for linux distributions...
LIBDVBSI_VER=0.3.7
$(SRC)/libdvbsi++-$(LIBDVBSI_VER).tar.bz2: | $(SRC)
	cd $(SRC) && wget http://www.saftware.de/libdvbsi++/libdvbsi++-$(LIBDVBSI_VER).tar.bz2

libdvbsi: $(SRC)/libdvbsi++-$(LIBDVBSI_VER).tar.bz2 | $(DEST)
	rm -rf $(SRC)/libdvbsi++-$(LIBDVBSI_VER)
	tar -C $(SRC) -xf $(SRC)/libdvbsi++-$(LIBDVBSI_VER).tar.bz2
	set -e; cd $(SRC)/libdvbsi++-$(LIBDVBSI_VER); \
		./configure --prefix=$(DEST); \
		$(MAKE); \
		make install
	rm -rf $(SRC)/libdvbsi++-$(LIBDVBSI_VER)

LUA_VER=5.3.4
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

FFMPEG_VER=3.3.3
$(SRC)/ffmpeg-$(FFMPEG_VER).tar.bz2: | $(SOURCE)
	cd $(SRC) && wget http://www.ffmpeg.org/releases/ffmpeg-$(FFMPEG_VER).tar.bz2

ffmpeg: $(SRC)/ffmpeg-$(FFMPEG_VER).tar.bz2
	rm -rf $(SRC)/ffmpeg-$(FFMPEG_VER)
	tar -C $(SRC) -xf $(SRC)/ffmpeg-$(FFMPEG_VER).tar.bz2
	set -e; cd $(SRC)/ffmpeg-$(FFMPEG_VER); \
		./configure --prefix=$(DEST) --disable-doc --disable-stripping ; \
		$(MAKE); \
		make install
	rm -rf $(SRC)/ffmpeg-$(FFMPEG_VER)

###############################################################################

PHONY = checkout
.PHONY: $(PHONY)
