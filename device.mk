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

# Only include Shield apps for first party targets
ifneq ($(filter $(word 2,$(subst _, ,$(TARGET_PRODUCT))), galen galen_tab),)
include device/nvidia/shield-common/shield.mk
endif

TARGET_REFERENCE_DEVICE ?= galen
TARGET_TEGRA_VARIANT    ?= common

TARGET_TEGRA_AUDIO    ?= nvaudio
TARGET_TEGRA_BOOTCTRL ?= smd
TARGET_TEGRA_BT       ?= btlinux
TARGET_TEGRA_CAMERA   ?= nvcamera
TARGET_TEGRA_CEC      ?= nvhdmi
TARGET_TEGRA_HEALTH   ?= nobattery
TARGET_TEGRA_KERNEL   ?= 5.10
TARGET_TEGRA_KEYSTORE ?= software
TARGET_TEGRA_MEMTRACK ?= nvmemtrack
TARGET_TEGRA_OMX      ?= nvmm
TARGET_TEGRA_PHS      ?= nvphs
TARGET_TEGRA_POWER    ?= aosp
TARGET_TEGRA_WIDEVINE ?= true
TARGET_TEGRA_WIFI     ?= rtl8822ce

include device/nvidia/t194-common/t194.mk

# System properties
include device/nvidia/galen/system_prop.mk

PRODUCT_CHARACTERISTICS   := tv
PRODUCT_AAPT_PREBUILT_DPI := xxhdpi xhdpi hdpi mdpi hdpi tvdpi
PRODUCT_AAPT_PREF_CONFIG  := xhdpi
TARGET_SCREEN_HEIGHT      := 1920
TARGET_SCREEN_WIDTH       := 1080

$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)

PRODUCT_USE_DYNAMIC_PARTITIONS := true

include device/nvidia/galen/vendor/galen-vendor.mk

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += device/nvidia/galen

# Init related
PRODUCT_PACKAGES += \
    fstab.galen \
    fstab.rey \
    init.galen.rc \
    init.rey.rc \
    init.galen_common.rc \
    init.recovery.galen.rc \
    init.recovery.rey.rc \
    power.galen.rc \
    power.rey.rc

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.ethernet.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.ethernet.xml

# ATV specific stuff
ifeq ($(PRODUCT_IS_ATV),true)
    $(call inherit-product-if-exists, vendor/google/atv/atv-common.mk)

    PRODUCT_PACKAGES += \
        android.hardware.tv.input@1.0-impl
endif

# Audio
ifeq ($(TARGET_TEGRA_AUDIO),nvaudio)
PRODUCT_PACKAGES += \
    audio_effects.xml \
    audio_policy_configuration.xml \
    nvaudio_conf.xml \
    rey_nvaudio_conf.xml \
    nvaudio_fx.xml
endif

# Kernel
ifneq ($(TARGET_PREBUILT_KERNEL),)
TARGET_FORCE_PREBUILT_KERNEL := true
endif

# Light
PRODUCT_PACKAGES += \
    android.hardware.light@2.0-service-nvidia

# Loadable kernel modules
PRODUCT_PACKAGES += \
    init.lkm.rc \
    lkm_loader

# Media config
PRODUCT_COPY_FILES += \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_ODM)/etc/media_codecs_google_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:$(TARGET_COPY_OUT_ODM)/etc/media_codecs_google_video.xml
PRODUCT_PACKAGES += \
    media_codecs.xml
ifeq ($(TARGET_TEGRA_OMX),nvmm)
PRODUCT_PACKAGES += \
    media_codecs_performance.xml \
    media_profiles_V1_0.xml \
    enctune.conf
endif

# Partitions for dynamic
PRODUCT_COPY_FILES += \
    device/nvidia/galen/initfiles/fstab.galen:$(TARGET_COPY_OUT_RAMDISK)/fstab.galen \
    device/nvidia/galen/initfiles/fstab.galen:$(TARGET_COPY_OUT_RAMDISK)/fstab.rey

# PHS
ifeq ($(TARGET_TEGRA_PHS),nvphs)
PRODUCT_PACKAGES += \
    nvphsd.conf
endif

# PModel
PRODUCT_PACKAGES += \
    nvpmodel \
    nvpmodel_t194.conf \
    nvpmodel_t194_p3668.conf

# Thermal
PRODUCT_PACKAGES += \
    android.hardware.thermal@1.0-service-nvidia \
    thermalhal.galen.xml \
    thermalhal.rey.xml

# Trust HAL
PRODUCT_PACKAGES += \
    vendor.lineage.trust@1.0-service

# Updater
ifneq ($(TARGET_TEGRA_BOOTCTRL),)
AB_OTA_PARTITIONS += \
    boot \
    product \
    recovery \
    system \
    vbmeta \
    vbmeta_system \
    vendor \
    odm
ifeq ($(TARGET_PREBUILT_KERNEL),)
ifneq ($(TARGET_TEGRA_BOOTCTRL),)
AB_OTA_POSTINSTALL_CONFIG += \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true \
    POSTINSTALL_PATH_system=system/bin/nv_bootloader_payload_updater \
    RUN_POSTINSTALL_system=true
ifeq ($(TARGET_TEGRA_BOOTCTRL),smd)
PRODUCT_PACKAGES += \
    nv_bootloader_payload_updater \
    bl_update_payload \
    bmp_update_payload
endif
endif
endif
endif
