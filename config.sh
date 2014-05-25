CROSSARCH="arm"
CROSSCC="$CROSSARCH-eabi-"
USERCCDIR="/home/michaelc/.ccache"
DEFCONFIG="mac_defconfig"
TOOLCHAIN="/home/michaelc/android/toolchain/android-toolchain-eabi/bin"

echo "[BUILD]: Setting cross compile env vars...";
export ARCH=$CROSSARCH
export CROSS_COMPILE=$CROSSCC
export PATH=$TOOLCHAIN_CCACHE:${PATH}:$TOOLCHAIN

echo "[BUILD]: Cleaning kernel...";
make clean
echo "[BUILD]: Using defconfig: $DEFCONFIG...";
make $DEFCONFIG
echo "[BUILD]: Make defconfig...";
make menuconfig
