#!/bin/sh

if [ "x$NDK_STANDALONE_TOOLCHAIN" = "x" ]; then
  echo "Error: Please set \$NDK_STANDALONE_TOOLCHAIN env variable." 1>&2
  exit 1
fi

export SYSROOT="$NDK_STANDALONE_TOOLCHAIN/sysroot"
export PATH="$NDK_STANDALONE_TOOLCHAIN/bin:$PATH"
export procnum="$(cat /proc/cpuinfo | grep -e '^processor' | wc -l)"

if [ ! -f $SYSROOT/usr/lib/libreadline.a ]; then
  # Build libreadline for android
  wget -c ftp://ftp.gnu.org/gnu/readline/readline-6.3.tar.gz
  tar xvf readline-6.3.tar.gz
  cd readline-*
  bash_cv_wcwidth_broken=false ./configure --host=arm-linux-androideabi --disable-shared --enable-static --prefix="${SYSROOT}/usr"
  make -j $procnum
  make install
  cd ..
fi

if [ ! -f $SYSROOT/usr/lib/libncurses.a ]; then
  # Build libncurses for android (needed by libreadline)
  wget -c http://invisible-mirror.net/archives/ncurses/ncurses-6.0.tar.gz
  tar xvf ncurses-6.0.tar.gz
  cd ncurses-*
  ac_cv_header_locale_h=no ./configure --disable-shared --enable-static --prefix="${SYSROOT}/usr" --host=arm-linux-androideabi
  make -j $procnum
  make install
  cd ..
fi

Build scanmem for android
if [ "$(uname -s)" == "Darwin" ]; then
  PATH=/usr/local/opt/gettext/bin:$PATH # brew install gettext
fi
LIBS="-lncurses -lm" ./configure --host=arm-linux-androideabi --prefix="${SYSROOT}/usr" --enable-static --disable-shared
[ "$?" != "0" ] && exit 1
make -j $procnum && make install
