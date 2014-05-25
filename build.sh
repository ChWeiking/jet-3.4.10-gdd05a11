#!/bin/sh

KERNELDIR="/home/michaelc/android/kernels/jewel/jet-3.4.10-gdd05a11"
PACKAGES="/home/michaelc/android/kernels/jewel/jewel-4.3"
TOOLCHAIN="/home/michaelc/android/toolchain/android-toolchain-eabi/bin"
MODULES=$PACKAGES/modules
DATE=$(date +"%A-%B-%d-%Y")
TIME=$(date +"%r")
CROSSARCH="arm"
CROSSCC="$CROSSARCH-eabi-"
USERCCDIR="/home/michaelc/.ccache"
DEFCONFIG="mac_defconfig"

echo "[BUILD]: Clean up package directory..."
find $MODULES -type f -exec rm {} \;
rm $PACKAGES/mac_jewel*.zip
rm $PACKAGES/kernel/zImage

###CCACHE CONFIGURATION STARTS HERE, DO NOT MESS WITH IT!!!
TOOLCHAIN_CCACHE="$TOOLCHAIN/../bin-ccache"
gototoolchain() {
  echo "[BUILD]: Changing directory to $TOOLCHAIN/../ ...";
  cd $TOOLCHAIN/../
}

gotocctoolchain() {
  echo "[BUILD]: Changing directory to $TOOLCHAIN_CCACHE...";
  cd $TOOLCHAIN_CCACHE
}

#check ccache configuration
#if not configured, do that now.
if [ ! -d "$TOOLCHAIN_CCACHE" ]; then
    echo "[BUILD]: CCACHE: not configured! Doing it now...";
    gototoolchain
    mkdir bin-ccache
    gotocctoolchain
    ln -s $(which ccache) "$CROSSCC""gcc"
    ln -s $(which ccache) "$CROSSCC""g++"
    ln -s $(which ccache) "$CROSSCC""cpp"
    ln -s $(which ccache) "$CROSSCC""c++"
    gototoolchain
    chmod -R 777 bin-ccache
    echo "[BUILD]: CCACHE: Done...";
fi
export CCACHE_DIR=$USERCCDIR
###CCACHE CONFIGURATION ENDS HERE, DO NOT MESS WITH IT!!!

echo "[BUILD]: Setting cross compile env vars...";
export ARCH=$CROSSARCH
export CROSS_COMPILE=$CROSSCC
export PATH=$TOOLCHAIN_CCACHE:${PATH}:$TOOLCHAIN

echo "[BUILD]: Cleaning kernel...";
make clean
echo "[BUILD]: Using defconfig: $DEFCONFIG...";
make $DEFCONFIG
echo "[BUILD]: Bulding the kernel...";
make -j`grep 'processor' /proc/cpuinfo | wc -l`
echo "[BUILD]: Done!...";

if [ -e $KERNELDIR/arch/arm/boot/zImage ]; then
	echo "[BUILD]: Make kcontrol gpu module"
	git clone https://github.com/showp1984/kcontrol_gpu_msm.git
	cd $KERNELDIR/kcontrol_gpu_msm
	sed -i '/KERNEL_BUILD := /c\KERNEL_BUILD := ../' Makefile
	make
	cd $KERNELDIR

	echo "[BUILD]: Copy modules to Package"
	cp -a $(find . -name *.ko -print) $MODULES
	cp kcontrol_gpu_msm/kcontrol_gpu_msm.ko $MODULES

	echo "[BUILD]: Remove temp kcontrol directory"
	rm -rf kcontrol_gpu_msm

	echo "[BUILD]: Copy zImage to Package"
	cp arch/arm/boot/zImage-dtb $PACKAGES/kernel/zImage

	echo "[BUILD]: Make kernel.zip"
	export curdate=`date "+%m%d%Y"`
	cd $PACKAGES
	zip -r mac_jewel_$curdate.zip .
	cd $KERNELDIR
else
	echo "[BUILD]: KERNEL DID NOT BUILD! no zImage exist"
fi;
