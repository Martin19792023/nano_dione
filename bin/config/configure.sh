#!/bin/bash

. config/base.sh

if [[ $1 == 'driver' ]]; then
        rm -Rf $CONFIGURATION_FILE
fi
if [[ ! -e $CONFIGURATION_FILE ]]; then
        . $BIN_DIR/config/setup.sh --driver $2 $3
fi
. $CONFIGURATION_FILE

BSP_DIR=$BUILD_DIR/$VC_MIPI_SOM\_$VC_MIPI_BSP
DOWNLOAD_DIR=$BSP_DIR/downloads
KERNEL_SOURCE=$BSP_DIR/Linux_for_Tegra/source/public
KERNEL_OUT=$KERNEL_SOURCE/build
MODULES_OUT=$KERNEL_SOURCE/modules
DRIVER_DST_DIR=$KERNEL_SOURCE/kernel/nvidia/drivers/media/i2c
case $VC_MIPI_BSP in
        35.1.0)
        KERNEL_DIR=kernel/kernel-5.10/
        MODULES_BSP=$BSP_DIR/Linux_for_Tegra/rootfs/usr
        DTB_OUT=$KERNEL_OUT/arch/arm64/boot/dts/nvidia
        ;;
        *)
        KERNEL_DIR=kernel/kernel-4.9/
        MODULES_BSP=$BSP_DIR/Linux_for_Tegra/rootfs
        DTB_OUT=$KERNEL_OUT/arch/arm64/boot/dts
        ;;
esac

TARGET_USER=$USER
TARGET_IP=
if [[ $1 == 'target' ]]; then
        . $BIN_DIR/config/setup.sh --target
fi
if [[ -e $TARGET_FILE ]]; then
        . $TARGET_FILE
fi
TARGET_SHELL="ssh $TARGET_USER@$TARGET_IP"

echo "------------------------------------------------------------"
echo "  Vision Components MIPI CSI-2 camera driver"
echo "------------------------------------------------------------"
echo "  System on Module:         $VC_MIPI_SOM"
echo "  Carrier Board:            $VC_MIPI_BOARD"
echo "  L4T Driver Package (BSP): $VC_MIPI_BSP"
echo "------------------------------------------------------------"

L4T=$BIN_DIR/config/L4T/R$VC_MIPI_BSP.sh
if [[ -e $L4T ]]; then
        . $L4T
else
        echo "BSP $VC_MIPI_BSP not supported!"
        exit 1
fi

PATCHES=('kernel_common_32.3.1+')

case $VC_MIPI_SOM in
        Nano|NanoSD|Nano2GB)
        # Carrier board dependant settings
        case $VC_MIPI_BOARD in
                NV_DevKit_Nano)
                DT_CAM_FILE=$DT_CAM_DIR/NV_DevKit_Nano/tegra210-porg-camera-rbpcv2-dione-ir.dtsi
				DT_CAM_DIR=$DT_CAM_DIR/NV_DevKit_Nano
                ;;
                *)
                echo "Carrier board $VC_MIPI_BOARD not supported!"
                ;;
        esac

        # Carrier board independant settings
        PATCHES+=('kernel_Nano_32.5.0+')
        DT_CAM_FILE_DST_DIR=$KERNEL_SOURCE/hardware/nvidia/platform/t210/porg/kernel-dts/porg-platforms

        FLASH_DT='DTB'
        case $VC_MIPI_SOM in
        Nano)   FLASH_BOARD='jetson-nano-emmc' ;;
        NanoSD|Nano2GB) FLASH_BOARD='jetson-nano-qspi-sd' ;;
        esac
        FLASH_PARTITION='mmcblk0p1'

        case $VC_MIPI_BSP in
                32.5.0|32.5.1|32.5.2)
                PATCHES+=('dt_camera_Nano_32.5.0+')
                ;;
                32.6.1|32.7.1|32.7.2)
                PATCHES+=('dt_camera_Nano_32.6.1+')
                ;;
        esac
        ;;
esac

# PATCHES+=('develop')

echo "  Using L4T Driver Package (BSP) URL:          $BSP_URL"
echo "  Using L4T Driver Package (BSP) FILE:         $BSP_FILE"
echo "  Using Sample Root Filesystem URL:            $RFS_URL"
echo "  Using Sample Root Filesystem FILE:           $RFS_FILE"
echo "  Using L4T Driver Package (BSP) Sources URL:  $SRC_URL"
echo "  Using L4T Driver Package (BSP) Sources FILE: $SRC_FILE"
echo "  Using patches:                               ${PATCHES[@]}"
echo "  Using devicetree camera file:                $DT_CAM_FILE"
echo "  Using flash parameters:                      $FLASH_DT $FLASH_BOARD $FLASH_PARTITION"
echo "  Using target user and ip address:            $TARGET_USER@$TARGET_IP"
echo "------------------------------------------------------------"

GCC_URL=http://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu
GCC_FILE=gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
export CROSS_COMPILE=$GCC_DIR/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
export LOCALVERSION=-tegra
export ARCH=arm64
