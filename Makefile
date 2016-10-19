export PKG_CONFIG_PATH=$(PREFIX)/lib/pkgconfig
CURL_VERSION=7.33.0
GIT_VERSION=1.9.1
CORES=4
LDFLAGS=-L$(PREFIX)/lib -s
CFLAGS=-O2 -march=native
PREFIX=/usr/local

TARGETS+=$(PREFIX)/lib/libp11.la
#TARGETS+=$(PREFIX)/lib/engines/engine_pkcs11.la
TARGETS+=$(PREFIX)/lib/libopensc.la
TARGETS+=$(PREFIX)/lib/libcurl.a
TARGETS+=$(PREFIX)/bin/curl
TARGETS+=$(PREFIX)/bin/git
TARGETS+=$(PREFIX)/libexec/git-core/git-credential-wincred.exe
TARGETS+=$(PREFIX)/ssl/openssl.cnf
TARGETS+=$(PREFIX)/libexec/git-core/completion/git-completion.bash
TARGETS+=$(PREFIX)/libexec/git-core/completion/git-completion.tcsh
TARGETS+=$(PREFIX)/libexec/git-core/completion/git-completion.zsh
TARGETS+=$(PREFIX)/libexec/git-core/completion/git-prompt.sh
TARGETS+=/etc/profile.d/cygcac.sh
TARGETS+=/etc/pki/ca-trust/source/anchors/DoD_Root_CA_2__0x05__DoD_Root_CA_2.cer



all: $(TARGETS)

clean:
	-rm -rf $(TARGETS) git libp11 opensc curl-$(CURL_VERSION)


# Environment setup

/etc/pki/ca-trust/source/anchors $(PREFIX)/ssl:
	mkdir $@

#/etc/pki/ca-trust/source/anchors/dodroot.pem: | /etc/pki/ca-trust/source/anchors 
#	curl http://dodpki.c3pki.chamb.disa.mil/rel3_dodroot_2048.p7b | openssl pkcs7 -inform DER -out $@ -print_certs
 
	cp DoD_Root_CA_2__0x05__DoD_Root_CA_2.cer /etc/pki/ca-trust/source/anchors/
	update-ca-trust

$(PREFIX)/ssl/openssl.cnf: openssl.cnf | $(PREFIX)/ssl
	cp openssl.cnf $@

/etc/profile.d/cygcac.sh: profile.d/cygcac.sh
	cp profile.d/cygcac.sh $@
	chmod 555 $@



# git compile/install

$(PREFIX)/libexec/git-core/completion:
	mkdir -p $@

$(PREFIX)/libexec/git-core/completion/%: git/contrib/completion/% | $(PREFIX)/libexec/git-core/completion
	cp $< $@

$(PREFIX)/libexec/git-core/git-credential-wincred.exe: git/contrib/credential/wincred/git-credential-wincred.exe
	cp $? $@

git/contrib/credential/wincred/git-credential-wincred.exe: | git/Makefile
	make -C git/contrib/credential/wincred CFLAGS='$(CFLAGS) -D_fileno=fileno -D_O_BINARY=O_BINARY'

$(PREFIX)/bin/git: git/git.exe
	cd git; make install

git/git.exe: | git/Makefile
	cd git; make -j$(CORES)

git/Makefile: | git/.patched git/configure
	cd git; ./configure LDFLAGS='$(LDFLAGS)'

git/configure: | git/.patched $(PREFIX)/lib/libcurl.a
	cd git; autoconf

git/.patched: | git git-ssl-engines.patch
	cd git; git apply ../git-ssl-engines.patch
	touch git/.patched

git:
	git init $@
	cd $@; git config core.autocrlf false
	cd $@; git remote add origin https://github.com/git/git.git
	cd $@; git fetch origin tags/v$(GIT_VERSION):tags/v$(GIT_VERSION) --depth 1
	cd $@; git checkout v$(GIT_VERSION)



# libp11 compile/install

$(PREFIX)/lib/libp11.la: libp11/build/Makefile
	cd libp11/build; make -j$(CORES) && make install

libp11/build/Makefile: | libp11/build libp11/configure libp11/config.sub
	cd libp11/build; ../configure --with-enginesdir=/usr/local/lib

libp11/build: | libp11
	mkdir libp11/build 

libp11/configure libp11/config.sub: | libp11
	cd libp11; ./bootstrap

libp11:
	git init $@
	cd $@; git config core.autocrlf false
	cd $@; git remote add origin https://github.com/OpenSC/libp11.git
	cd $@; git fetch
	cd $@; git checkout master


# engine_pkcs11 compile/install

#$(PREFIX)/lib/engines/engine_pkcs11.la: engine_pkcs11/Makefile
#	cd engine_pkcs11; make -j$(CORES) && make install

#engine_pkcs11/Makefile: | engine_pkcs11/configure engine_pkcs11/config.sub
#	cd engine_pkcs11; ./configure

#engine_pkcs11/configure engine_pkcs11/config.sub: | engine_pkcs11
#	cd engine_pkcs11; ./bootstrap

#engine_pkcs11:
#	git init $@
#	cd $@; git config core.autocrlf false
#	cd $@; git remote add origin https://github.com/OpenSC/engine_pkcs11.git
#	cd $@; git fetch
#	cd $@; git checkout master


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
	git init $@
	cd $@; git config core.autocrlf false
	cd $@; git remote add origin https://github.com/OpenSC/OpenSC.git
	cd $@; git fetch
	cd $@; git checkout master


# Curl compile/install

$(PREFIX)/bin/curl $(PREFIX)/lib/libcurl.a: curl-$(CURL_VERSION)/build/Makefile
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
	wget http://curl.haxx.se/download/curl-$(CURL_VERSION).tar.bz2
