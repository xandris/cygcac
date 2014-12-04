NOTE! You might need to run the command "dos2unix" on every file before running the build script
	find . | xargs dos2unix
if dos2unix does not exists, then install it
	apt-cyg install dos2unix

# CYGCAC

A script to help use smartcards with git (and other tools) on Windows under Cygwin.

This project:

* Builds and installs custom versions of opensc, engine\_pkcs11, libp11, curl, and git

* Sets up a new OpenSSL configuration file and adds a `OPENSSL_CONF` environment variable to point to it

* Installs the DoD root certificates into Cygwin to make them accessible to OpenSSL, curl, etc.

## Installation

1. [install cygwin](https://github.com/xandris/install-cygwin). You will need git to clone this repository (or download a ZIP or something).

1. Clone this repository:

        git clone https://github.com/xandris/cygcac.git

1. Enter the new directory and run `build.sh`:

        cd cygcac
        ./build.sh

1. Go make a sandwich or something. It seriously takes a long time.

1. Restart your shell to pick up the new environment.

1. Edit `~/.gitconfig` and add this section, substituting `$PROTECTED-WEBSITE` with the base URL of a smartcard-protected website of your choosing:

        [http "$PROTECTED-WEBSITE"]
            sslEngine = pkcs11
            sslKeyType = ENG
            sslCertType = ENG

  Note that you might want to add `sslVerify = false` if your server doesn't use a standard certificate.

### Extra stuff

There are a couple of extra features supplied by cygcac that you might like to use:

1. `wincred` helper. Tell git to use Windows Credential Manager for credentials storage:

        git config --global credential.helper wincred

1. bash completion and prompt flair. Add this to `~/.bash_profile`:

        . /usr/local/libexec/git-core/completion/git-prompt.sh
        . /usr/local/libexec/git-core/completion/git-completion.bash

        GIT_PS1_SHOWDIRTYSTATE=1 
        GIT_PS1_SHOWSTASHSTATE=1
        GIT_PS1_SHOWUNTRACKEDFILES=1
        GIT_PS1_SHOWUPSTREAM=auto  
        GIT_PS1_SHOWCOLORHINTS=1

        PROMPT_COMMAND='__git_ps1 "\[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]" "\n\$ "'

   If you've customized `PS1` already, change `PROMPT_COMMAND`. Decide where in your prompt git info should be placed and use this format:

        PROMPT_COMMAND='__git_ps1 "<First half of PS1>" "<Second half of PS1>"'

   If `git-prompt.sh` has anything to say about the current directory, it will insert a space, _then_ the git info, and _then_ `<Second half of PS1>`.

   Note that the prompt can slow down bash a bit. If it annoys you, comment out some of the `SHOW` variables above that you can live without.

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
