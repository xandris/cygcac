if ! [ -x /usr/local/bin/apt-cyg ]; then
    curl 'https://raw.githubusercontent.com/transcode-open/apt-cyg/master/apt-cyg' > /usr/local/bin/apt-cyg
    chmod +x /usr/local/bin/apt-cyg
fi

apt-cyg install gcc-g++ make autoconf automake vim zip unzip git libtool patch pkg-config openssl openssl-devel curl libiconv-devel tcl gettext-devel libexpat1-devel

make
