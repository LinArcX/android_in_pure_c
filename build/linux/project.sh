#!/bin/bash

Black='\033[0;30m'
DarkGray='\033[1;30m'

Red='\033[0;31m'
LightRed='\033[1;31m'

Green='\033[0;32m'
LightGreen='\033[1;32m'

Brown='\033[0;33m'
Yellow='\033[1;33m'

Blue='\033[0;34m'
LightBlue='\033[1;34m'

Purple='\033[0;35m'
LightPurple='\033[1;35m'

Cyan='\033[0;36m'
LightCyan='\033[1;36m'

LightGray='\033[0;37m'
White='\033[1;37m'

NC='\033[0m' # No Color

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

MIN_SDK_VERSION="23"
TARGET_SDK_VERSION="23"
TARGET_SDK_VERSION="23"

AAPT="$ANDROID_BUILD_TOOLS/29.0.2/aapt"
ZIP_ALIGN="$ANDROID_BUILD_TOOLS/29.0.2/zipalign"
APK_SIGNER="$ANDROID_BUILD_TOOLS/29.0.2/apksigner"

SOURCES="./sources/main.c"
RAWDRAWANDROID="."
RAWDRAWANDROIDSRCS="$RAWDRAWANDROID/sources/glue/android_native_app_glue.c"
ANDROID_SOURCES="$SOURCES $RAWDRAWANDROIDSRCS"

CFLAGS="-ffunction-sections -Os -fdata-sections -Wall -fvisibility=hidden "
CFLAGS+="-Os -DANDROID -DAPPNAME=\"$APP_NAME\" "
CFLAGS+="-DANDROID_FULLSCREEN "
CFLAGS+="-I. -I$ANDROID_NDK/sysroot/usr/include -I$ANDROID_NDK/sysroot/usr/include/android -fPIC -I$RAWDRAWANDROID -DANDROIDVERSION=$TARGET_SDK_VERSION "

LDFLAGS="-Wl,--gc-sections -s "
LDFLAGS+="-lm -lGLESv3 -lEGL -landroid -llog "
LDFLAGS+="-shared -uANativeActivity_onCreate "

CC_ARM64=$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/bin/aarch64-linux-android$TARGET_SDK_VERSION-clang
CC_ARM32=$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/bin/armv7a-linux-androideabi$TARGET_SDK_VERSION-clang
CC_x86=$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/bin/i686-linux-android$TARGET_SDK_VERSION-clang
CC_x86_64=$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/bin/x86_64-linux-android$TARGET_SDK_VERSION-clang

TARGETS+="build/linux/outpu/lib/arm64-v8a/lib$APP_NAME.so"
TARGETS+="build/linux/outpu/lib/armeabi-v7a/lib$APP_NAME.so"
TARGETS+="build/linux/output/lib/x86/lib$APP_NAME.so"
TARGETS+="build/linux/output/lib/x86_64/lib$APP_NAME.so"

CFLAGS_ARM64="-m64"
CFLAGS_ARM32="-mfloat-abi=softfp -m32"
CFLAGS_x86="-march=i686 -mtune=intel -m32 -mssse3 -mfpmath=sse "
CFLAGS_x86_64="-march=x86-64 -mtune=intel -m64 -msse4.2 -mpopcnt "

STOREPASS="password"
ALIASNAME="standkey"
KEYSTOREFILE="neo-release-key.keystore"
DNAME="CN=example.com, OU=ID, O=Example, L=Doe, S=John, C=GB"

neo_generate_keystore()
{
	printf "${Blue}>> Generating keystore ${NC}\n"
  printf "${Blue}------------------------${NC}\n"

	keytool -genkey -v -keystore $KEYSTOREFILE -alias $ALIASNAME -keyalg RSA -keysize 2048 -validity 10000 -storepass $STOREPASS -keypass $STOREPASS -dname "$DNAME"

  printf "\n\n"
}

neo_generate_directories()
{
	printf "${Blue}>> Generating output directories ${NC}\n"
  printf "${Blue}------------------------${NC}\n"

	mkdir -p build/linux/output/lib/arm64-v8a
	mkdir -p build/linux/output/lib/armeabi-v7a
	mkdir -p build/linux/output/lib/x86
	mkdir -p build/linux/output/lib/x86_64

  printf "\n\n"
}

neo_generate_shared_files()
{
	printf "${Blue}>> Generating .so files ${NC}\n"
  printf "${Blue}------------------------${NC}\n"

  $CC_ARM64 $CFLAGS $CFLAGS_ARM64 -o build/linux/output/lib/arm64-v8a/lib$APP_NAME.so $ANDROID_SOURCES -L$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/sysroot/usr/lib/aarch64-linux-android/$TARGET_SDK_VERSION $LDFLAGS
	$CC_ARM32 $CFLAGS $CFLAGS_ARM32 -o build/linux/output/lib/armeabi-v7a/lib$APP_NAME.so $ANDROID_SOURCES -L$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/sysroot/usr/lib/arm-linux-androideabi/$TARGET_SDK_VERSION $LDFLAGS
	$CC_x86 $CFLAGS $CFLAGS_x86 -o build/linux/output/lib/x86/lib$APP_NAME.so $ANDROID_SOURCES -L$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/sysroot/usr/lib/i686-linux-android/$TARGET_SDK_VERSION $LDFLAGS
	$CC_x86 $CFLAGS $CFLAGS_x86_64 -o build/linux/output/lib/x86_64/lib$APP_NAME.so $ANDROID_SOURCES -L$ANDROID_NDK/toolchains/llvm/prebuilt/$OS_NAME/sysroot/usr/lib/x86_64-linux-android/$TARGET_SDK_VERSION $LDFLAGS

  printf "\n\n"
}

neo_generate_android_manifest()
{
	printf "${Purple}>> Generating AndroidManifest from template file ${NC}\n"
  printf "${Purple}------------------------${NC}\n"

  rm -rf build/linux/output/AndroidManifest.xml

	PACKAGE_NAME=$PACKAGE_NAME \
	MIN_SDK_VERSION=$MIN_SDK_VERSION \
	TARGET_SDK_VERSION=$TARGET_SDK_VERSION \
	APP_NAME=$APP_NAME  envsubst '$$PACKAGE_NAME $$MIN_SDK_VERSION $$TARGET_SDK_VERSION $$APP_NAME' < assets/android/AndroidManifest.xml.template > build/linux/output/AndroidManifest.xml

  printf "\n\n"
}

neo_aapt()
{
	printf "${Blue}>> Running aapt ${NC}\n"
  printf "${Blue}------------------------${NC}\n"

  rm -rf aapt.apk

	mkdir -p build/linux/output/assets
	cp -r assets/android/assets/* build/linux/output/assets
	$AAPT package -f -F aapt.apk -I $ANDROID_SDK/platforms/android-$TARGET_SDK_VERSION/android.jar -M build/linux/output/AndroidManifest.xml -S assets/android/res -A build/linux/output/assets -v --target-sdk-version $TARGET_SDK_VERSION
	unzip -o aapt.apk -d build/linux/output

  printf "\n\n"
}

neo_create_zipped_apk()
{
	printf "${LightRed}>> Creating zipped.apk ${NC}\n"
  printf "${LightRed}------------------------${NC}\n"

  rm -rf zipped.apk
  #rm -rf build/linux/output/aapt.apk

  cd build/linux/output &&zip -D9r ../../../zipped.apk .  && zip -D0r ../../../zipped.apk ./resources.arsc ./AndroidManifest.xml

  printf "\n\n"
}

neo_jar_sign()
{
	printf "${Green}>> Running JarSigner ${NC}\n"
  printf "${Green}------------------------${NC}\n"

	jarsigner -sigalg SHA1withRSA -digestalg SHA1 -verbose -keystore "../../../neo-release-key.keystore" -storepass $STOREPASS ../../../zipped.apk $ALIASNAME

  printf "\n\n"
}

neo_zip_align()
{
	printf "${Yellow}>> Running ZipAlign ${NC}\n"
  printf "${Yellow}------------------------${NC}\n"

	$ZIP_ALIGN -v 4 ../../../zipped.apk "neo.apk"

  printf "\n\n"
}

neo_apk_signer_30()
{
	printf "${Green}>> Signing apk +30 ${NC}\n"
  printf "${Green}------------------------${NC}\n"

	#Using the apksigner in this way is only required on Android 30+
	$APK_SIGNER sign --key-pass pass:$STOREPASS --ks-pass pass:$STOREPASS --ks "../../../neo-release-key.keystore" "neo.apk"

  printf "\n\n"
}

neo_remove_temp_apks()
{
	printf "${Cyan}>> Removing temp apks ${NC}\n"
  printf "${Cyan}------------------------${NC}\n"

  rm -rf assets/
  rm -rf lib/
  rm -rf res/
  rm -rf resources.arsc
  rm -rf AndroidManifest.xml
  rm -rf ../../../aapt.apk
  rm -rf ../../../zipped.apk
  rm -rf ../../../neo-release-key.keystore

  printf "\n\n"
}

neo_generate_apk()
{
  neo_generate_keystore
  neo_generate_directories
  neo_generate_shared_files
  neo_generate_android_manifest
  neo_aapt
  neo_create_zipped_apk
  neo_jar_sign
  neo_zip_align
  neo_apk_signer_30
  neo_remove_temp_apks
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
  echo ">>> Installing $PACKAGE_NAME on device.."
	adb install -r $(APKFILE)
}

neo_run()
{
	$(eval ACTIVITYNAME:=$(shell $AAPT dump badging $APK_FILE | grep "launchable-activity" | cut -f 2 -d"'"))
	adb shell am start -n $PACKAGE_NAME/$ACTIVITYNAME
}

neo_uninstall()
{
  echo ">>> Uninstalling $PACKAGE_NAME from device.."
  adb uninstall $PACKAGE_NAME || true
}

neo_clean()
{
  echo ">>> Cleaning build directory"
	rm -rf aapt.apk build/_neo.apk build/neo $APK_FILE
}

#SDK_LOCATION=$ANDROID_HOME
#NDK_LOCATION="$ANDROID_HOME/ndk"
#EMULATOR="$ANDROID_HOME/emulator"
#BUILD_TOOLS="$ANDROID_HOME/build-tools"
#ANDROID_TARGET=$TARGET_SDK_VERSION
#neo_detect_os()
#{
#  echo $OS_NAME
#}

#    /usr/X11R6/include -L/usr/X11/lib toolchains/llvm/preuilt/$OS_NAME/ toolchains/llvm/preuilt/$OS_NAME/

# -I/usr/include/ -I$RAWDRAWANDROID/sources/gui -I$RAWDRAWANDROID/sources/glue -I$RAWDRAWANDROID/sources/devices
# -lX11 -lstdc++
