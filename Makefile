export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
CURL_VERSION=7.33.0
GIT_VERSION=1.9.1
CORES=4
LDFLAGS=-L/usr/local/lib

all: /usr/local/lib/libp11.la /usr/local/lib/engines/engine_pkcs11.la /usr/local/lib/libopensc.la /usr/local/bin/curl /usr/local/bin/git /etc/profile.d/cygcac.sh /usr/local/ssl/openssl.cnf /etc/pki/ca-trust/source/anchors/dodroot.pem

# Environment setup

/etc/pki/ca-trust/source/anchors /usr/local/ssl:
	mkdir $@

/etc/pki/ca-trust/source/anchors/dodroot.pem:
	curl http://dodpki.c3pki.chamb.disa.mil/rel3_dodroot_2048.p7b | openssl pkcs7 -inform DER -out $@ -print_certs
	update-ca-trust

/usr/local/ssl/openssl.cnf: openssl.cnf | /usr/local/ssl
	cp openssl.cnf $@

/etc/profile.d/cygcac.sh: profile.d/cygcac.sh
	cp profile.d/cygcac.sh $@

# git compile/install

/usr/local/bin/git: git/git.exe
	cd git; make install

git/git.exe: | git/Makefile
	cd git; make -j$(CORES)

git/Makefile: | git/.patched git/configure
	cd git; ./configure LDFLAGS=$(LDFLAGS)

git/configure: | git/.patched /usr/local/lib/libcurl.a
	cd git; autoconf

git/.patched: | git git-ssl-engines.patch
	cd git; git apply ../git-ssl-engines.patch
	touch git/.patched

git:
	git clone --branch v$(GIT_VERSION) --depth 1 https://github.com/git/git.git git

# libp11 compile/install

/usr/local/lib/libp11.la: libp11/build/Makefile
	cd libp11/build; make -j$(CORES) && make install

libp11/build/Makefile: | libp11/build libp11/configure libp11/config.sub
	cd libp11/build; ../configure

libp11/build: | libp11
	mkdir libp11/build 

libp11/configure libp11/config.sub: | libp11
	cd libp11; ./bootstrap

libp11:
	git clone https://github.com/OpenSC/libp11.git libp11


# engine_pkcs11 compile/install

/usr/local/lib/engines/engine_pkcs11.la: engine_pkcs11/Makefile
	cd engine_pkcs11; make -j$(CORES) && make install

engine_pkcs11/Makefile: | engine_pkcs11/configure engine_pkcs11/config.sub
	cd engine_pkcs11; ./configure

engine_pkcs11/configure engine_pkcs11/config.sub: | engine_pkcs11
	cd engine_pkcs11; ./bootstrap

engine_pkcs11:
	git clone https://github.com/OpenSC/engine_pkcs11.git engine_pkcs11


# OpenSC compile/install

/usr/local/lib/libopensc.la: opensc/build/Makefile
	cd opensc/build; make -j$(CORES) && make install

opensc/build/Makefile: | opensc/configure opensc/config.sub opensc/build
	cd opensc/build; ../configure

opensc/build: | opensc
	mkdir opensc/build

opensc/configure opensc/config.sub: | opensc
	cd opensc; ./bootstrap

opensc:
	git clone https://github.com/OpenSC/OpenSC.git opensc


# Curl compile/install

/usr/local/bin/curl /usr/local/lib/libcurl.a: curl-$(CURL_VERSION)/build/Makefile
	cd curl-$(CURL_VERSION)/build; make -j$(CORES) && make install

curl-$(CURL_VERSION)/build/Makefile: | curl-$(CURL_VERSION)/build
	cd curl-$(CURL_VERSION)/build; ../configure --with-ca-bundle=/usr/ssl/certs/ca-bundle.crt

curl-$(CURL_VERSION)/build: | curl-$(CURL_VERSION)/.patched
	-mkdir curl-$(CURL_VERSION)/build

curl-$(CURL_VERSION)/.patched: | curl-$(CURL_VERSION) curl-load-engines.patch curl-reuse-engine.patch
	cd curl-$(CURL_VERSION); patch -p1 < ../curl-load-engines.patch
	cd curl-$(CURL_VERSION); patch -p1 < ../curl-reuse-engine.patch
	touch curl-$(CURL_VERSION)/.patched

curl-$(CURL_VERSION): | curl-$(CURL_VERSION).tar.bz2
	tar xjf curl-$(CURL_VERSION).tar.bz2

curl-$(CURL_VERSION).tar.bz2:
	curl -O http://curl.haxx.se/download/curl-$(CURL_VERSION).tar.bz2
