if ! [ -x /usr/local/bin/apt-cyg ]; then
    curl 'https://apt-cyg.googlecode.com/svn/trunk/apt-cyg' > /usr/local/bin/apt-cyg
    chmod +x /usr/local/bin/apt-cyg
fi

apt-cyg install gcc-g++ make autoconf automake vim zip unzip git libtool patch pkg-config openssl openssl-devel curl libiconv-devel tcl

make
