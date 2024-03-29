#
# Copyright (C) 2020 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

BOARD_FLASH_BLOCK_SIZE              := 4096
BOARD_BOOTIMAGE_PARTITION_SIZE      := 83886080
BOARD_RECOVERYIMAGE_PARTITION_SIZE  := 66060288
BOARD_USERDATAIMAGE_PARTITION_SIZE  := 10099646976
TARGET_USERIMAGES_USE_EXT4          := true
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE     := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE  := ext4
TARGET_COPY_OUT_ODM                 := odm
TARGET_COPY_OUT_PRODUCT             := product
TARGET_COPY_OUT_VENDOR              := vendor

BOARD_NVIDIA_DYNAMIC_PARTITIONS_PARTITION_LIST := product system vendor odm
BOARD_NVIDIA_DYNAMIC_PARTITIONS_SIZE           := 5268184832
BOARD_SUPER_PARTITION_GROUPS                   := nvidia_dynamic_partitions
BOARD_SUPER_PARTITION_SIZE                     := 10737418240

# Android Verified Boot
BOARD_AVB_ENABLE ?= true
ifeq ($(BOARD_AVB_ENABLE),true)
BOARD_AVB_ALGORITHM                             ?= SHA256_RSA4096
BOARD_AVB_KEY_PATH                              ?= external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_BOOT_ALGORITHM                        := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_BOOT_KEY_PATH                         := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_BOOT_ROLLBACK_INDEX                   := 0
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION          := 1
BOARD_AVB_RECOVERY_ALGORITHM                    := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_RECOVERY_KEY_PATH                     := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX               := 0
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION      := 2
BOARD_AVB_VBMETA_SYSTEM                         := system vendor odm product
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM               := $(BOARD_AVB_ALGORITHM)
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH                := $(BOARD_AVB_KEY_PATH)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX          := 0
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 3
endif

# Assert
TARGET_OTA_ASSERT_DEVICE := galen,rey

# Bluetooth
ifneq ($(TARGET_TEGRA_BT),)
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/nvidia/galen/comms
endif

# Fingerprint override
BUILD_FINGERPRINT := NVIDIA/galen/galen:11/RQ1A.210105.003/7825230_3167.5736:user/release-keys

# Kernel
ifneq ($(TARGET_PREBUILT_KERNEL),)
BOARD_VENDOR_KERNEL_MODULES += $(wildcard $(dir $(TARGET_PREBUILT_KERNEL))/*.ko)
endif
TARGET_KERNEL_CLANG_COMPILE    := false
TARGET_KERNEL_NO_GCC           := false
KERNEL_TOOLCHAIN               := $(shell pwd)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-gnu-9.3/bin
KERNEL_TOOLCHAIN_PREFIX        := aarch64-buildroot-linux-gnu-
TARGET_KERNEL_SOURCE           := kernel/nvidia/kernel-$(TARGET_TEGRA_KERNEL)
TARGET_KERNEL_CONFIG           := tegra_android_defconfig
BOARD_KERNEL_IMAGE_NAME        := Image
TARGET_KERNEL_ADDITIONAL_FLAGS := "NV_BUILD_KERNEL_OPTIONS=$(TARGET_TEGRA_KERNEL)"

TARGET_KERNEL_EXT_MODULE_ROOT := kernel/nvidia
TARGET_KERNEL_EXT_MODULES := \
    nvgpu/drivers/gpu/nvgpu:kbuild
include device/nvidia/galen/modules.mk

# Manifest
DEVICE_MANIFEST_FILE := device/nvidia/galen/manifest.xml

# Recovery
TARGET_RECOVERY_FSTAB := device/nvidia/galen/initfiles/fstab.galen
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888

# Security Patch Level
VENDOR_SECURITY_PATCH := 2021-04-05

include device/nvidia/t194-common/BoardConfigCommon.mk
