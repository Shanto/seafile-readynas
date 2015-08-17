APPNAME = seafile
BASE_VER = 4.3.1-server
RPC_VER = 3.0-latest
CCNET_VER = $(BASE_VER)
ZDB_VER = 2.12
EVHTP_VER = 1.2.10

PWD = $(shell pwd)
PREFIX=$(PWD)/build-$(shell uname -m)

APPDIR=$(PWD)/files/apps/$(APPNAME)

CFLAGS		:= $(shell dpkg-buildflags --get CFLAGS)
CPPFLAGS	:= $(shell dpkg-buildflags --get CPPFLAGS)
CXXFLAGS	:= $(shell dpkg-buildflags --get CXXFLAGS)
FFLAGS		:= $(shell dpkg-buildflags --get FFLAGS)
LDFLAGS		:= $(shell dpkg-buildflags --get LDFLAGS)

PKGCONFIG ?= pkg-config
PKG_CONFIG_PATH := $(PKG_CONFIG_PATH):$(PREFIX)/lib/pkgconfig
LD_LIBRARY_PATH := $(PREFIX)/lib

# picked from build-server.py
CFLAGS := $(CFLAGS) -I$(PREFIX)/include -L$(PREFIX)/lib
CPPFLAGS := $(CPPFLAGS) -I$(PREFIX)/include -DDLIBICONV_PLUG
LDFLAGS := $(LDFLAGS) -L$(PREFIX)/lib
PATH := $(PATH):$(PREFIX)/bin

PYSITE=$(PREFIX)/lib/python2.7/site-packages

export PATH
export CFLAGS CPPFLAGS CXXFLAGS FFLAGS LDFLAGS
export PKG_CONFIG_PATH LD_LIBRARY_PATH LD_RUN_PATH

all: install
	$(noop)

debug:
	@echo LDFLAGS="$(LDFLAGS)"
	@echo CPPFLAGS="$(CPPFLAGS)"
	@echo CFLAGS="$(CFLAGS)"

zdb: libzdb-$(ZDB_VER).tar.gz
	@tar xzf libzdb-$(ZDB_VER).tar.gz
	cd libzdb-$(ZDB_VER) && \
		./configure --prefix=$(PREFIX) --enable-optimized --with-postgresql && \
		$(MAKE) && \
		$(MAKE) install

$(PREFIX)/lib/libzdb.so:
	$(MAKE) zdb

evhtp: libevhtp-$(EVHTP_VER).tar.gz
	@tar xzf libevhtp-$(EVHTP_VER).tar.gz
	cd libevhtp-$(EVHTP_VER) && \
		cmake -DCMAKE_INSTALL_PREFIX:PATH=$(PREFIX) -DEVHTP_DISABLE_SSL=OFF -DEVHTP_BUILD_SHARED=ON . && \
		$(MAKE) && \
		$(MAKE) install

$(PREFIX)/lib/libevhtp.so:
	$(MAKE) evhtp

searpc: libsearpc-$(RPC_VER).tar.gz
	@tar xzf libsearpc-$(RPC_VER).tar.gz
	cd libsearpc-$(RPC_VER) && \
		[ -f ./configure ] || ./autogen.sh && \
		./configure --prefix=$(PREFIX) --disable-compile-demo && \
		$(MAKE) && \
		$(MAKE) install

$(PREFIX)/lib/libsearpc.so:
	$(MAKE) searpc

ccnet: ccnet-$(CCNET_VER).tar.gz $(PREFIX)/lib/libsearpc.so $(PREFIX)/lib/libzdb.so
	@tar xzf ccnet-$(CCNET_VER).tar.gz
	cd ccnet-$(CCNET_VER) && \
		[ -f ./configure ] || ./autogen.sh && \
		./configure --prefix=$(PREFIX) --disable-client --enable-server --enable-ldap --disable-compile-demo && \
		$(MAKE) && \
		$(MAKE) install

$(PREFIX)/lib/libccnet.so:
	$(MAKE) ccnet

seahub-thirdparty:
	mkdir -p $(PYSITE) $(PWD)/.pip && cd $(PYSITE) && \
		pip-2.7 install --no-deps --target $(PYSITE) --install-option="--install-scripts=$(PREFIX)/bin" --download-cache $(PWD)/.pip -r $(PWD)/python-requirements.txt
	cd $(PYSITE) && \
		tar xf $(PWD)/seafdav-$(BASE_VER).tar.gz seafdav-$(BASE_VER)/wsgidav --strip-components=1 && \
		tar xf $(PWD)/seafobj-$(BASE_VER).tar.gz seafobj-$(BASE_VER)/seafobj --strip-components=1

seahub: seahub-$(BASE_VER).tar.gz seahub-thirdparty
	@tar xzf seahub-$(BASE_VER).tar.gz
	cd seahub-$(BASE_VER) && \
		cat $(PWD)/rn-app-layout.seahub.patch | patch -N -p1 -r /dev/null
	cd seahub-$(BASE_VER) && \
		sed -i -r "s|(SEAFILE_VERSION\s*=\s*)'.+'|\1'4.2.3'|" seahub/settings.py && \
		cp -pr ./thirdpart/* $(PYSITE) && rm -rf ./thirdpart/*
	install -d $(PREFIX)/seahub && cp -pr seahub-$(BASE_VER)/* $(PREFIX)/seahub

$(PREFIX)/seahub/manage.py:
	$(MAKE) seahub

seafile: $(PREFIX)/lib/libccnet.so $(PREFIX)/lib/libzdb.so $(PREFIX)/lib/libevhtp.so
	@tar xzf seafile-$(BASE_VER).tar.gz
	cd seafile-$(BASE_VER) && \
		cat $(PWD)/rn-app-layout.seafile.patch | patch -N -p1 -r /dev/null
	cd seafile-$(BASE_VER) && \
		[ -f ./configure ] || ./autogen.sh && \
		./configure --prefix=$(PREFIX) --disable-client --enable-server --enable-fuse && \
		$(MAKE) && \
		$(MAKE) install

$(PREFIX)/lib/libseafile.so:
	$(MAKE) seafile

install-libs:
	ldd $(PREFIX)/bin/* | grep "=>" | egrep -v "$(PREFIX)/lib|ld-linux.so|libpthread.so|libc.so|libm.so|librt.so|libdl.so|libselinux.so|libresolv.so" | \
		cut -d\  -f3 | sort -u | while read lib; do \
		cp -p $$lib $(PREFIX)/lib; \
		done

install: fetch-source $(PREFIX)/lib/libseafile.so $(PREFIX)/seahub/manage.py install-libs
	mkdir -p $(APPDIR) && cp -pr $(PREFIX)/* $(APPDIR)
	install -d $(APPDIR) $(APPDIR)/default-config/seafile $(APPDIR)/default-config/seahub $(APPDIR)/scripts/upgrade $(APPDIR)/var/log $(APPDIR)/var/run
	install seafile-$(BASE_VER)/scripts/*.sh $(APPDIR)/scripts
	install seafile-$(BASE_VER)/scripts/upgrade/*.sh $(APPDIR)/scripts/upgrade
	install seafile-$(BASE_VER)/scripts/upgrade/*.py $(APPDIR)/scripts/upgrade
	cp -r seafile-$(BASE_VER)/scripts/upgrade/sql $(APPDIR)/scripts/upgrade
	rm -rf $(APPDIR)/include $(APPDIR)/lib/pkgconfig
	find $(APPDIR) -type f -path '*/lib/*.so*' -o -path '*/bin/*' | while read bin; do file $$bin | grep -q 'not stripped' && strip $$bin; done || true
	find $(APPDIR) -type f -path '*/lib/*.la' -delete
	find $(APPDIR) -type f -path '*/lib/*.a' -delete
	find $(APPDIR) -name '*.py[oc]' -delete
	find $(APPDIR) -depth -path '*/tests' -exec rm -rf {} \;

clean:
	@find . -depth -type d ! -name '.' ! -name '.pip' -exec rm -rf {} \;


# # # # # # # # # # # # # # # # # SOURCE URLS # # # # # # # # # # # # # # # # #

ccnet-$(CCNET_VER).tar.gz:
	wget -O ccnet-$(CCNET_VER).tar.gz https://github.com/haiwen/ccnet/archive/v$(CCNET_VER).tar.gz

seafile-$(BASE_VER).tar.gz:
	wget -O seafile-$(BASE_VER).tar.gz https://github.com/haiwen/seafile/archive/v$(BASE_VER).tar.gz

seahub-$(BASE_VER).tar.gz:
	wget -O seahub-$(BASE_VER).tar.gz https://github.com/haiwen/seahub/archive/v$(BASE_VER).tar.gz

seafdav-$(BASE_VER).tar.gz:
	wget -O seafdav-$(BASE_VER).tar.gz https://github.com/haiwen/seafdav/archive/v$(BASE_VER).tar.gz

seafobj-$(BASE_VER).tar.gz:
	wget -O seafobj-$(BASE_VER).tar.gz https://github.com/haiwen/seafobj/archive/v$(BASE_VER).tar.gz

libsearpc-$(RPC_VER).tar.gz:
	wget -O libsearpc-$(RPC_VER).tar.gz https://github.com/haiwen/libsearpc/archive/v$(RPC_VER).tar.gz

libzdb-$(ZDB_VER).tar.gz:
	wget -O libzdb-$(ZDB_VER).tar.gz http://www.tildeslash.com/libzdb/dist/libzdb-$(ZDB_VER).tar.gz

libevhtp-$(EVHTP_VER).tar.gz:
	wget -O libevhtp-$(EVHTP_VER).tar.gz https://github.com/ellzey/libevhtp/archive/$(EVHTP_VER).tar.gz

fetch-source: ccnet-$(BASE_VER).tar.gz seafile-$(BASE_VER).tar.gz seahub-$(BASE_VER).tar.gz seafdav-$(BASE_VER).tar.gz seafobj-$(BASE_VER).tar.gz libsearpc-$(RPC_VER).tar.gz libzdb-$(ZDB_VER).tar.gz libevhtp-$(EVHTP_VER).tar.gz
	$(noop)
