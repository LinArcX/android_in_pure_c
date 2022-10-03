#!/bin/bash

OS_NAME=""
UNAME=$(uname)
if [ $UNAME == "Linux" ]; then
  OS_NAME="linux-x86_64"
elif [ $UNAME == "Darwin" ]; then
  OS_NAME="darwin-x86_64"
elif [ $UNAME == "Windows_NT" ]; then
  OS_NAME="windows-x86_64"
else
  OS_NAME="unknown"
fi

APP_NAME="neo"
PACKAGE_NAME="matrix.hackers.$APP_NAME"
APK_FILE="build/linux/output/$APP_NAME.apk"

AAPT="$ANDROID_BUILD_TOOLS/aapt"
ANDROID_BUILD_VERSION="23"

SOURCES="./sources/main.c"
RAWDRAWANDROID="."
RAWDRAWANDROIDSRCS="$RAWDRAWANDROID/sources/glue/android_native_app_glue.c"
ANDROID_SOURCES="$SOURCES $RAWDRAWANDROIDSRCS"

CFLAGS="-ffunction-sections -Os -fdata-sections -Wall -fvisibility=hidden "
CFLAGS+="-Os -DANDROID -DAPPNAME=\"$APP_NAME\" "
CFLAGS+="-DANDROID_FULLSCREEN "
CFLAGS+="-I. -I$ANDROID_NDK/sysroot/usr/include -I$ANDROID_NDK/sysroot/usr/include/android -fPIC -I$RAWDRAWANDROID -DANDROIDVERSION=$ANDROID_BUILD_VERSION "

# -I/usr/include/ -I$RAWDRAWANDROID/sources/gui -I$RAWDRAWANDROID/sources/glue -I$RAWDRAWANDROID/sources/devices

LDFLAGS="-Wl,--gc-sections -s "
LDFLAGS+="-lm -lGLESv3 -lEGL -landroid -llog "
LDFLAGS+="-shared -uANativeActivity_onCreate "
# -lX11 -lstdc++

CC_ARM64=$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/bin/aarch64-linux-android$ANDROID_BUILD_VERSION-clang
CC_ARM32=$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/bin/armv7a-linux-androideabi$ANDROID_BUILD_VERSION-clang
CC_x86=$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/bin/i686-linux-android$ANDROID_BUILD_VERSION-clang
CC_x86_64=$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/bin/x86_64-linux-android$ANDROID_BUILD_VERSION-clang

TARGETS+="build/lib/arm64-v8a/lib$APP_NAME.so"
TARGETS+="build/lib/armeabi-v7a/lib$APP_NAME.so"
#TARGETS += build/neo/lib/x86/lib$(APP_NAME).so
#TARGETS += build/neo/lib/x86_64/lib$(APP_NAME).so

CFLAGS_ARM64="-m64"
CFLAGS_ARM32="-mfloat-abi=softfp -m32"
CFLAGS_x86="-march=i686 -mtune=intel -m32 -mssse3 -mfpmath=sse "
CFLAGS_x86_64="-march=x86-64 -mtune=intel -m64 -msse4.2 -mpopcnt "

STOREPASS="password"
ALIASNAME="standkey"
KEYSTOREFILE="build/linux/output/neo-release-key.keystore"
DNAME="CN=example.com, OU=ID, O=Example, L=Doe, S=John, C=GB"

neo_generate_keystore()
{
	keytool -genkey -v -keystore $KEYSTOREFILE -alias $ALIASNAME -keyalg RSA -keysize 2048 -validity 10000 -storepass $STOREPASS -keypass $STOREPASS -dname "$DNAME"
}

neo_create_directories()
{
	mkdir -p build/linux/output/lib/arm64-v8a
	mkdir -p build/linux/output/lib/armeabi-v7a
	mkdir -p build/linux/output/lib/x86
	mkdir -p build/linux/output/lib/x86_64
}

neo_create_shared_files()
{
  $CC_ARM64 $CFLAGS $CFLAGS_ARM64 -o build/linux/output/lib/arm64-v8a/lib$APP_NAME.so $ANDROID_SOURCES -L$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/sysroot/usr/lib/aarch64-linux-android/$ANDROID_BUILD_VERSION $LDFLAGS
	$CC_ARM32 $CFLAGS $CFLAGS_ARM32 -o build/linux/output/lib/armeabi-v7a/lib$APP_NAME.so $ANDROID_SOURCES -L$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/sysroot/usr/lib/arm-linux-androideabi/$ANDROID_BUILD_VERSION $LDFLAGS
	#$CC_x86 $CFLAGS $CFLAGS_x86 -o build/lib/x86/lib$APPNAME.so $ANDROID_SOURCES -L$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/sysroot/usr/lib/i686-linux-android/$ANDROID_BUILD_VERSION $LDFLAGS
	#$CC_x86 $CFLAGS $CFLAGS_x86_64 -o build/lib/x86_64/lib$APPNAME.so $ANDROID_SOURCES -L$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/sysroot/usr/lib/x86_64-linux-android/$ANDROID_BUILD_VERSION $LDFLAGS

  # mkdir -p build/neo/lib/arm64-v8a

  # /mnt/D/software/01_linux/ide/android/sdk/ndk/20/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android23-clang
  # -ffunction-sections -Os -fdata-sections -Wall -fvisibility=hidden -Os -DANDROID -DAPPNAME=\"neo\" -I./rawdraw -I/mnt/D/software/01_linux/ide/android/sdk/ndk/20/sysroot/usr/include -I/mnt/D/software/01_linux/ide/android/sdk/ndk/20/sysroot/usr/include/android -fPIC -I. -DANDROIDVERSION=23
  # -m64
  # -o build/neo/lib/arm64-v8a/libneo.so sources/main.c sources/glue/android_native_app_glue.c
  # -L/mnt/D/software/01_linux/ide/android/sdk/ndk/20/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/23
  # -Wl,--gc-sections -s -lm -lGLESv3 -lEGL -landroid -llog -shared -uANativeActivity_onCreate


  # sources/main.c:259:7: warning: unused variable 'i' [-Wunused-variable]
  #                 int i, pos;
  #                     ^
  # sources/main.c:259:10: warning: unused variable 'pos' [-Wunused-variable]
  #                 int i, pos;
  #                        ^
  # 2 warnings generated.
}

neo_build_debug() {
    echo ">>> Creating build directory and copy assets files"
    mkdir -p build/linux/debug
    cp assets/image.bmp build/linux/debug

    echo ">>> Building app (Debug mode)"
    $CXX \
    -g \
    -lGLEW \
    -lGLU \
    -lGL \
    -I/usr/local/include/SDL2/ \
    `sdl2-config --cflags --libs` \
    src/*.cpp \
    -o build/linux/debug/app
}

neo_build_release() {
    echo ">>> Creating build directory and copy assets files"
    mkdir -p build/linux/release
    cp assets/image.bmp build/linux/release

    echo ">>> Building app (Release mode)"
    $CXX \
    -lGLEW \
    -lGLU \
    -lGL \
    -I/usr/local/include/SDL2/ \
    `sdl2-config --cflags --libs` \
    src/*.cpp \
    -o build/linux/release/app
}

neo_run_debug() {
    echo ">>> Running app (Debug mode)"
    cd build/linux/debug
    ./app &
    cd ../../..
}

neo_run_release() {
    echo ">>> Running app (Release mode)"
    cd build/linux/release
    ./app &
    cd ../../..
}

neo_install()
{
  echo ">>> Installing $(PACKAGENAME) on device.."
	adb install -r $(APKFILE)
}

neo_run()
{
	$(eval ACTIVITYNAME:=$(shell $(AAPT) dump badging $(APKFILE) | grep "launchable-activity" | cut -f 2 -d"'"))
	$(ADB) shell am start -n $(PACKAGENAME)/$(ACTIVITYNAME)
}

neo_uninstall()
{
  echo ">>> Uninstalling $(PACKAGENAME) from device.."
  adb uninstall $(PACKAGENAME) || true
}

neo_clean()
{
  echo ">>> Cleaning build directory"
	rm -rf temp.apk build/_neo.apk build/neo $(APKFILE)
}

#SDK_LOCATION=$ANDROID_HOME
#NDK_LOCATION="$ANDROID_HOME/ndk"
#EMULATOR="$ANDROID_HOME/emulator"
#BUILD_TOOLS="$ANDROID_HOME/build-tools"
#ANDROID_TARGET=$ANDROID_BUILD_VERSION
#neo_detect_os()
#{
#  echo $OS_NAME
#}

#    /usr/X11R6/include -L/usr/X11/lib toolchains/llvm/preuilt/$OS_NAME/ toolchains/llvm/preuilt/$OS_NAME/
