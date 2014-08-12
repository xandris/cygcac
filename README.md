# CYGCAC

A script to help use smartcards with git (and other tools) on Windows under Cygwin.

## Installation

1. [install cygwin](https://github.com/xandris/install-cygwin). You will need git to clone this repository (or download a ZIP or something).

1. Clone this repository:

        git clone https://github.com/xandris/install-cygwin.git

1. Enter the new directory and run `build.sh`:

        cd install-cygwin
        ./build.sh

1. Go make a sandwich or something. It seriously takes a long time.

1. Edit `/usr/ssl/openssl.cnf` and insert this _just after_ `oid_section ...`:

        openssl_conf    = default_conf

        [default_conf]
  
        engines = engines_section

        [engines_section]

        dynamic = dynamic_engine
       
        [dynamic_engine]

        SO_PATH=/usr/local/lib/engines/engine_pkcs11.so
        LIST_ADD=2
        LOAD=EMPTY
        MODULE_PATH=/usr/local/lib/pkcs11/opensc-pkcs11.so
        init=1

1. Edit `~/.gitconfig` and add this section, substituting `$PROTECTED-WEBSITE` with the base URL of a smartcard-protected website of your choosing:

        [http "$PROTECTED-WEBSITE"]
            sslEngine = pkcs11
            sslKeyType = ENG
            sslCertType = ENG

  Note that you might want to add `sslVerify = false` if your server doesn't use a standard certificate.

## Troubleshooting

* `git` loads `curl`
* `curl` loads `openssl`
* `openssl` loads `engine_pkcs11`
* `engine_pkcs11` loads `opensc_pkcs11`

So to troubleshoot, start at the very beginning.

1. Verify opensc is installed:

        $ opensc-tool -i
        OpenSC 0.13.0 [gcc  4.8.3]
        Enabled features: zlib openssl pcsc(winscard.dll)

  If not, verify that `opensc-tool` is on your `$PATH`.

  If not, rebuild `opensc`:

      rm -rf opensc
      make

1. Verify that opensc can read your certificates:

        $ pkcs15-tool -c
        Using reader with a card: Hewlett-Packard Company HP USB CCID Keyboard Smartcard  0
        X.509 Certificate [Certificate for PIV Authentication]
                Object Flags   : [0x0]
                Authority      : no
                Path           :
                ID             : 01
                Encoded serial :
        X.509 Certificate [Certificate for Digital Signature]
                Object Flags   : [0x0]
                Authority      : no
                Path           :
                ID             : 02
                Encoded serial :
        X.509 Certificate [Certificate for Key Management]
                Object Flags   : [0x0]
                Authority      : no
                Path           :
                ID             : 03
                Encoded serial :

  If not, verify that your card is installed and Windows can access it.

  TODO: More troubleshooting steps here?

1. Verify that openssl is loading `engine_pkcs11`:

        $ openssl engine
        (rsax) RSAX engine support
        (dynamic) Dynamic engine loading support
        (pkcs11) pkcs11 engine

  You should see `(pkcs11)` in that list.

  If not, ensure that `/usr/ssl/openssl.cnf` was modified appropriately (see above).

1. Verify that curl is loading `engine_pkcs11` as well:

        $ curl --engine list
        Build-time engines:
          rsax
          dynamic
          pkcs11

  If not, ensure that you're using the patched version of `curl` provided by this project.

1. Verify that you can contact a smartcard-protected website with `curl`:

        $ curl -k --engine pkcs11 --key-type ENG --cert-type ENG

  If not, ensure that the server is accepting your certificate by using a browser or other means.

1. Verify that git can clone a repo (or at least contact your server without a certificate error) from your smartcard-protected server.

  If not, ensure that you're using the patched version of `git` provided by this project.

  If you are, verify `git` is linked against the patched version of `curl`:

      $ ldd /usr/local/libexec/git-core/git-remote-https.exe
              ntdll.dll => /cygdrive/c/windows/SYSTEM32/ntdll.dll (0x76f50000)
              kernel32.dll => /cygdrive/c/windows/system32/kernel32.dll (0x76e30000)
              KERNELBASE.dll => /cygdrive/c/windows/system32/KERNELBASE.dll (0x7fefce10000)
              cygcrypto-1.0.0.dll => /usr/bin/cygcrypto-1.0.0.dll (0x3ffdf0000)
              cygwin1.dll => /usr/bin/cygwin1.dll (0x180040000)
              cygz.dll => /usr/bin/cygz.dll (0x3ff740000)
              cygiconv-2.dll => /usr/bin/cygiconv-2.dll (0x3ffbc0000)
              cygintl-8.dll => /usr/bin/cygintl-8.dll (0x3ffba0000)
              cygcurl-4.dll => /usr/local/bin/cygcurl-4.dll (0x482aa0000)
              cygssl-1.0.0.dll => /usr/bin/cygssl-1.0.0.dll (0x3ff890000)

  If `git` isn't linking against `/usr/local/bin/cygcurl-*.dll`, rebuild `git` after verifying that `curl` works correctly:

      rm -rf git
      make
