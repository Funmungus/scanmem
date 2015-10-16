#!/bin/sh

if [ "x$1" = "x--help" ] || [ "x$1" = "xhelp" ] || [ "x$1" = "x-h" ]; then
    echo "
  ## Before building:
      # Run autogen.sh if \"./configure\" does not exist.
      # From scanmem source directory
      ./autogen.sh

  ## For libreadline support:
      # HOST is the compiler architecture for your toolchain and Android
      # device. (e.g. arm-linux-androideabi)
      # NDK_STANDALONE_TOOLCHAIN is the directory of your NDK standalone
      # toolchain.

      # Install libreadline to your NDK sysroot.
      # From libreadline source directory, execute:
      export PATH=\"\$NDK_STANDALONE_TOOLCHAIN/bin:\$PATH\"
      bash_cv_wcwidth_broken=false ./configure --host=\"\$HOST\" \\
          --disable-shared --enable-static \\
          --prefix=\"\$NDK_STANDALONE_TOOLCHAIN/sysroot/usr\"
      make
      make install

      # Install ncurses to your NDK sysgen.
      # From ncurses source directory, execute:
      export PATH=\"\$NDK_STANDALONE_TOOLCHAIN/bin:\$PATH\"
      ac_cv_header_locale_h=no ./configure --host=\"\$HOST\" \\
          --disable-shared --enable-static \\
          --prefix=\"\$NDK_STANDALONE_TOOLCHAIN/sysroot/usr\"
      make
      make install

  ## To build with standalone toolchain:
      export NDK_STANDALONE_TOOLCHAIN=\"/your/toolchain/path\"
      export HOST=\"your-androideabi\" # Default arm-linux-androideabi
      ./build_for_android.sh

  ## To build without an NDK standalone toolchain, and without libreadline:
      # For given NDK directory <NDKPath>, execute from the scanmem source
      # directory:
      ./configure --without-readline
      <NDKPath>/ndk-build>
  or
      export NDK_HOME=\"<NDKPath>\"
      ./build_for_android.sh

  ## Advanced features and Environment variables that may be set...
  NDK_STANDALONE_TOOLCHAIN - A standalone toolchain is required to build full
      capabilities.
  NDK_HOME                 - This will allow to use the ndk-build, and a full
      standalone toolchain is not required.  If this is set, the scanmem
      executable will be built with ndk-build.
  ANDROID_NDK_HOME         - Same as NDK_HOME
  HOST                     - Compiler architecture that will be used for
      cross-compiling, default is arm-linux-androideabi
  SCANMEM_HOME             - Path which has scanmem sources, and will be used
      to build scanmem.  Default current directory
  LIBREADLINE_DIR          - Path which has libreadline sources to build
      automatically.  Default is to download sources
  NCURSES_DIR              - Path which has ncurses sources to build
      automatically.  Default is to download sources
"
  exit 0
fi

# Build with Android.mk
# Do from scanmem directory, or SCANMEM_HOME
ANDROID_MK(){
  # Readline support with ndk-build does not work
#  if [ -f ./jni/libreadline.a ] && [ -f ./jni/libncurses.a ]; then
#    export WITH_READLINE=1
#    export HAVE_LIBREADLINE=1
#  fi
  local ndkhome
  if [ ! "x${NDK_HOME}" = "x" ]; then
    ndkhome="${NDK_HOME}"
  elif [ ! "x${ANDROID_NDK_HOME}" = "x"]; then
    ndkhome="${ANDROID_NDK_HOME}"
  else
    echo "Error: Please set \$NDK_HOME env variable." 1>&2
    exit 1
  fi

  # TODO: Configuring without cross-compile may give bad values in config.h
  if [ -f config.h ]; then
    sed -i '' 's,^#define HAVE_LIBREADLINE,//#define HAVE_LIBREADLINE/g' \
        config.h
  else
    ./configure --without-readline
  fi
  "${ndkhome}/ndk-build"
}

# Resolve ndk toolchain or other
if [ "x${NDK_STANDALONE_TOOLCHAIN}" = "x" ]; then
  echo "NDK_STANDALONE_TOOLCHAIN was not found.
Please enter the toolchain path:"
  read NDK_STANDALONE_TOOLCHAIN
  # Nothing entered
  if [ "x${NDK_STANDALONE_TOOLCHAIN}" = "x" ]; then
    # NDK home, but no toolchain, build with Android make system
    if [ ! "x${NDK_HOME}" = "x" ] || [ ! "x${ANDROID_NDK_HOME}" = "x" ]; then
      ANDROID_MK
      exit 0
    else
      echo "Error: Please set \$NDK_STANDALONE_TOOLCHAIN env variable." 1>&2
      echo "To build with Android.mk, without libreadline,
please set the \$NDK_HOME env variable instead." 1>&2
      exit 1
    fi
  fi
fi
export SYSROOT="${NDK_STANDALONE_TOOLCHAIN}/sysroot"
export PATH="${NDK_STANDALONE_TOOLCHAIN}/bin:${PATH}"

# Host architecture
if [ "x${HOST}" = "x" ]; then
  HOST=arm-linux-androideabi
  echo "Env variable \$HOST, host architecture, is not specified.
Defaulting to ${HOST}"
fi

# Build and return directory
if [ "x${SCANMEM_HOME}" = "x" ]; then
  export SCANMEM_HOME="$(pwd)"
else
  cd "${SCANMEM_HOME}"
fi

# Processor count for make instructions
procnum="$(getconf _NPROCESSORS_ONLN)"
if [ "x${procnum}" = "x" ] || [ $procnum -eq 0 ]; then
  procnum=1
fi

# Do not fail for source downloads, workarounds may be found for broken links
if [ ! -f "${SYSROOT}/usr/lib/libreadline.a" ]; then
  # Build libreadline for android
  if [ "x${LIBREADLINE_DIR}" = "x" ]; then
    echo "LIBREADLINE_DIR was not found.  Please enter the path where
libreadline source is located, or press enter to try a source download:"
    read LIBREADLINE_DIR
    if [ "x${LIBREADLINE_DIR}" = "x" ]; then
      echo "Downloading libreadline..."
      if [ ! -f readline-6.3.tar.gz ]; then
        wget -c ftp://ftp.gnu.org/gnu/readline/readline-6.3.tar.gz
      fi
      tar xvf readline-6.3.tar.gz
      export LIBREADLINE_DIR="$(pwd)/readline-6.3"
    fi
  fi
  cd "${LIBREADLINE_DIR}"
  bash_cv_wcwidth_broken=false ./configure --host="${HOST}" \
      --disable-shared --enable-static --prefix="${SYSROOT}/usr"
  make -j ${procnum}
  make install
  cd "${SCANMEM_HOME}"
  # To make sure headers can be found
  if [ ! -f readline ]; then
    ln -s "${LIBREADLINE_DIR}" readline
  fi
fi

# ncurses, same logic as libreadline
if [ ! -f "${SYSROOT}/usr/lib/libncurses.a" ]; then
  # Build libncurses for android (needed by libreadline)
  if [ "x${NCURSES_DIR}" = "x" ]; then
    echo "NCURSES_DIR was not found.  Please enter the path where
ncurses source is located, or press enter to try a source download:"
    read NCURSES_DIR
    if [ "x${NCURSES_DIR}" = "x" ]; then
      echo "Downloading ncurses..."
      if [ ! -f ncurses-6.0.tar.gz ]; then
        wget -c http://invisible-mirror.net/archives/ncurses/ncurses-6.0.tar.gz
      fi
      tar xvf ncurses-6.0.tar.gz
      export NCURSES_DIR="$(pwd)/ncurses-6.0"
    fi
  fi
  cd "${NCURSES_DIR}"
  ac_cv_header_locale_h=no ./configure --host="${HOST}" \
      --disable-shared --enable-static --prefix="${SYSROOT}/usr"
  make -j ${procnum}
  make install
  cd "${SCANMEM_HOME}"
  # To make sure headers can be found
  if [ ! -f ncurses ]; then
    ln -s "${NCURSES_DIR}" ncurses
  fi
fi

# Build scanmem for android
if [ "$(uname -s)" == "Darwin" ]; then
  PATH=/usr/local/opt/gettext/bin:${PATH} # brew install gettext
fi
LIBS="-lncurses -lm" ./configure --host="${HOST}" --prefix="${SYSROOT}/usr" \
    --enable-static --disable-shared
[ "$?" != "0" ] && exit 1
make -j ${procnum} && make install
# If NDK_HOME is defined, assume the user wishes to use the Android makefile
if [ ! "x${NDK_HOME}" = "x" ] || [ ! "x${ANDROID_NDK_HOME}" = "x" ]; then
  # libreadline not available for ndk-build
  ./configure --without-readline --host="${HOST}" --prefix="${SYSROOT}/usr" \
    --enable-static --disable-shared
  ANDROID_MK
fi
