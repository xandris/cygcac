export PKG_CONFIG_PATH=$(PREFIX)/lib/pkgconfig
CURL_VERSION=7.37.1
GIT_VERSION=2.1.0
CORES=4
LDFLAGS=-L$(PREFIX)/lib -s
CFLAGS=-O2 -march=native
PREFIX=/usr/local

TARGETS+=$(PREFIX)/lib/libp11.la
TARGETS+=$(PREFIX)/lib/engines/engine_pkcs11.la
TARGETS+=$(PREFIX)/lib/libopensc.la
TARGETS+=$(PREFIX)/bin/curl
TARGETS+=$(PREFIX)/bin/git
TARGETS+=$(PREFIX)/libexec/git-core/git-credential-wincred.exe
TARGETS+=$(PREFIX)/ssl/openssl.cnf
TARGETS+=$(PREFIX)/libexec/git-core/completion/git-completion.bash
TARGETS+=$(PREFIX)/libexec/git-core/completion/git-completion.tcsh
TARGETS+=$(PREFIX)/libexec/git-core/completion/git-completion.zsh
TARGETS+=$(PREFIX)/libexec/git-core/completion/git-prompt.sh
TARGETS+=/etc/profile.d/cygcac.sh
TARGETS+=/etc/pki/ca-trust/source/anchors/dodroot.pem



all: $(TARGETS)



# Environment setup

/etc/pki/ca-trust/source/anchors $(PREFIX)/ssl:
	mkdir $@

/etc/pki/ca-trust/source/anchors/dodroot.pem: | /etc/pki/ca-trust/source/anchors 
	curl http://dodpki.c3pki.chamb.disa.mil/rel3_dodroot_2048.p7b | openssl pkcs7 -inform DER -out $@ -print_certs
	update-ca-trust

$(PREFIX)/ssl/openssl.cnf: openssl.cnf | $(PREFIX)/ssl
	cp openssl.cnf $@

/etc/profile.d/cygcac.sh: profile.d/cygcac.sh
	cp profile.d/cygcac.sh $@



# git compile/install

$(PREFIX)/libexec/git-core/completion:
	mkdir -p $@

$(PREFIX)/libexec/git-core/completion/%: git/contrib/completion/% | $(PREFIX)/libexec/git-core/completion
	cp $< $@

$(PREFIX)/libexec/git-core/git-credential-wincred.exe: | git/Makefile
	make -C git/contrib/credential/wincred CFLAGS='$(CFLAGS) -D_fileno=fileno' install

$(PREFIX)/bin/git: git/git.exe
	cd git; make install

git/git.exe: | git/config.mak.autogen
	cd git; make -j$(CORES)

git/config.mak.autogen: | git/.patched git/configure
	cd git; ./configure LDFLAGS="$(LDFLAGS)"

git/configure: | git/.patched $(PREFIX)/lib/libcurl.a
	cd git; autoconf

git/.patched: | git git-ssl-engines.patch
	cd git; git apply ../git-ssl-engines.patch
	touch git/.patched

git:
	git clone --branch v$(GIT_VERSION) --depth 1 https://github.com/git/git.git git




# libp11 compile/install

$(PREFIX)/lib/libp11.la: libp11/build/Makefile
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

$(PREFIX)/lib/engines/engine_pkcs11.la: engine_pkcs11/Makefile
	cd engine_pkcs11; make -j$(CORES) && make install

engine_pkcs11/Makefile: | engine_pkcs11/configure engine_pkcs11/config.sub
	cd engine_pkcs11; ./configure

engine_pkcs11/configure engine_pkcs11/config.sub: | engine_pkcs11
	cd engine_pkcs11; ./bootstrap

engine_pkcs11:
	git clone https://github.com/OpenSC/engine_pkcs11.git engine_pkcs11


# OpenSC compile/install

$(PREFIX)/lib/libopensc.la: opensc/build/Makefile
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

$(PREFIX)/bin/curl $(PREFIX)/lib/libcurl.a: curl/build/Makefile
	cd curl/build; make -j$(CORES) && make install

curl/build/Makefile: | curl/build curl/configure
	cd curl/build; ../configure --with-ca-bundle=/usr/ssl/certs/ca-bundle.crt

curl/build: | curl
	-mkdir curl/build

curl/configure: | curl
	cd curl; ./buildconf

curl:
	git clone --branch curl-$(subst .,_,$(CURL_VERSION)) --depth 1 https://github.com/bagder/curl.git
