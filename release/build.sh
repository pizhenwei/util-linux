#!/bin/bash
set -xe

apt-get install -y asciidoctor

CPUS=$(cat /proc/cpuinfo | grep processor | wc -l)
RELEASE_DIR=`pwd`

UTIL_LINUX_DIR=$RELEASE_DIR/..
BUILD_DIR=$RELEASE_DIR/build
BIN_DIR=$BUILD_DIR/usr/local/bin/
COMPLETION_DIR=$BUILD_DIR/usr/share/bash-completion/completions
MAN_DIR=$BUILD_DIR/usr/share/man/man1

UTIL_LINUX_VERSION=$(cat $UTIL_LINUX_DIR/.version)
GITVERSION="git-$(git rev-parse --short HEAD)"

cd $UTIL_LINUX_DIR
./autogen.sh

./configure --enable-irqtop --enable-lsirq
make all -j $CPUS
rm irqtop lsirq
# staticly build to avoid libsmartcols.so.X conflict
gcc sys-utils/irqtop.c sys-utils/irq-common.c .libs/libsmartcols.a -g -o irqtop -I include -I libsmartcols/src -DHAVE_NANOSLEEP -DHAVE_LOCALE_H -DHAVE_WIDECHAR -DHAVE_NCURSES_H -DHAVE_FSYNC -DPACKAGE_STRING="0.1" -D_GNU_SOURCE -lncurses
gcc sys-utils/lsirq.c sys-utils/irq-common.c .libs/libsmartcols.a -g -o lsirq -I include -I libsmartcols/src -DHAVE_NANOSLEEP -DHAVE_LOCALE_H -DHAVE_WIDECHAR -DHAVE_NCURSES_H -DHAVE_FSYNC -DPACKAGE_STRING="0.1" -D_GNU_SOURCE -lncurses

cd $RELEASE_DIR
mkdir -p $BUILD_DIR/DEBIAN
cp control $BUILD_DIR/DEBIAN/control
sed -i "s/^Version:.*$/Version: $UTIL_LINUX_VERSION-$GITVERSION/" $BUILD_DIR/DEBIAN/control

mkdir -p $BIN_DIR
cp $UTIL_LINUX_DIR/irqtop $BIN_DIR
cp $UTIL_LINUX_DIR/lsirq $BIN_DIR

mkdir -p $COMPLETION_DIR
cp $UTIL_LINUX_DIR/bash-completion/irqtop $COMPLETION_DIR
cp $UTIL_LINUX_DIR/bash-completion/lsirq $COMPLETION_DIR

mkdir -p $MAN_DIR
cp $UTIL_LINUX_DIR/sys-utils/irqtop.1 $MAN_DIR
cp $UTIL_LINUX_DIR/sys-utils/lsirq.1 $MAN_DIR

dpkg-deb -b $BUILD_DIR $RELEASE_DIR/irq-util-linux.deb
