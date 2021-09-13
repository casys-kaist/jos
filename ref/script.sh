#!/bin/bash
cd 
apt install gcc
apt install make
apt install python
apt install libsdl1.2-dev libtool-bin libglib2.0-dev libz-dev libpixman-1-dev
apt install texinfo
git clone https://github.com/geofft/qemu.git -b 6.828-1.7.0
cd qemu
./configure --disable-kvm --disable-werror --target-list="i386-softmmu x86_64-softmmu"
make -j 4
make install
cd
wget https://casys-kaist.github.io/jos/ref/gdb-7.11-patched.tar.gz
tar zxvf gdb-7.11-patched.tar.gz
cd gdb-7.11
patch -p1 < 0901-fix-conflicting-types-for-ps_get_thread_area.patch\?inline=false
./configure
make -j 4
make install
mv gdb/gdb /usr/local/bin/
cd
echo "set auto-load safe-path /" > .gdbinit
source .gdbinit
