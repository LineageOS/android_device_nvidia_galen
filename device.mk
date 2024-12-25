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

TARGET_TEGRA_MODELS := $(shell awk -F, '/tegra_init::devices/{ f = 1; next } /};/{ f = 0 } f{ gsub(/"/, "", $$3); gsub(/ /, "", $$3); print $$3 }' device/nvidia/$(TARGET_REFERENCE_DEVICE)/init/init_$(TARGET_REFERENCE_DEVICE).cpp |sort |uniq)
TARGET_TEGRA_VARIANTS := $(shell awk -F, '/tegra_init::devices/{ f = 1; next } /};/{ f = 0 } f{ gsub(/"/, "", $$2); gsub(/ /, "", $$2); print $$2 }' device/nvidia/$(TARGET_REFERENCE_DEVICE)/init/init_$(TARGET_REFERENCE_DEVICE).cpp |sort |uniq)

TARGET_TEGRA_BOOTCTRL ?= efi
TARGET_TEGRA_BT       ?= btlinux
TARGET_TEGRA_CAMERA   ?= rel-shield-r
TARGET_TEGRA_HEALTH   ?= nobattery
TARGET_TEGRA_KERNEL   ?= 5.10
TARGET_TEGRA_TOS      ?= software
TARGET_TEGRA_LIGHT    ?= lineage
TARGET_TEGRA_THERMAL  ?= lineage
TARGET_TEGRA_WIDEVINE ?= rel-shield-r
TARGET_TEGRA_WIFI     ?= rtl8822ce

include device/nvidia/t194-common/t194.mk

# System properties
include device/nvidia/galen/system_prop.mk

PRODUCT_CHARACTERISTICS   := tv
PRODUCT_AAPT_PREBUILT_DPI := xxhdpi xhdpi hdpi mdpi hdpi tvdpi
PRODUCT_AAPT_PREF_CONFIG  := xhdpi

PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := true

$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)

PRODUCT_USE_DYNAMIC_PARTITIONS := true

include device/nvidia/galen/vendor/galen-vendor.mk

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += device/nvidia/galen

# Init related
PRODUCT_COPY_FILES += \
    $(foreach model,$(TARGET_TEGRA_MODELS),device/nvidia/galen/initfiles/fstab.galen:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.$(model)) \
    $(foreach model,$(TARGET_TEGRA_MODELS),device/nvidia/galen/initfiles/fstab.galen:$(TARGET_COPY_OUT_RAMDISK)/fstab.$(model)) \
    $(foreach model,$(TARGET_TEGRA_MODELS),device/nvidia/galen/initfiles/init.galen.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.$(model).rc) \
    $(foreach model,$(TARGET_TEGRA_MODELS),device/nvidia/galen/initfiles/init.recovery.galen.rc:$(TARGET_COPY_OUT_RAMDISK)/init.recovery.$(model).rc) \
    $(foreach model,$(TARGET_TEGRA_MODELS),device/nvidia/galen/initfiles/power.galen.rc:$(TARGET_COPY_OUT_ODM)/etc/power.$(model).rc) \
    device/nvidia/galen/initfiles/init.galen_common.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.galen_common.rc

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
ifneq ($(filter rel-shield-r, $(TARGET_TEGRA_AUDIO)),)
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

# Loadable kernel modules
PRODUCT_PACKAGES += \
    init.lkm.rc \
    lkm_loader

# Media config
ifneq ($(filter rel-shield-r, $(TARGET_TEGRA_OMX)),)
PRODUCT_PACKAGES += \
    media_codecs.xml \
    media_codecs_performance.xml \
    media_profiles_V1_0.xml \
    enctune.conf
endif

# PHS
ifneq ($(TARGET_TEGRA_PHS),)
PRODUCT_COPY_FILES += \
    device/nvidia/galen/nvphs/nvphsd.conf.t194:$(TARGET_COPY_OUT_ODM)/etc/nvphsd.conf
endif

# PModel
PRODUCT_PACKAGES += \
    nvpmodel
PRODUCT_COPY_FILES += \
    device/nvidia/galen/nvpmodel/nvpmodel_t194.conf:$(TARGET_COPY_OUT_ODM)/etc/nvpmodel_t194.conf \
    device/nvidia/galen/nvpmodel/nvpmodel_t194_p3668.conf:$(TARGET_COPY_OUT_ODM)/etc/nvpmodel_t194_p3668.conf

# Thermal
ifneq ($(TARGET_TEGRA_THERMAL),)
PRODUCT_COPY_FILES += \
    $(foreach variant,$(TARGET_TEGRA_VARIANTS),device/nvidia/galen/thermal/thermalhal.$(variant).xml:$(TARGET_COPY_OUT_VENDOR)/etc/thermalhal.$(variant).xml)
endif

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
    vendor_boot \
    odm
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
else ifeq ($(TARGET_TEGRA_BOOTCTRL),efi)
PRODUCT_PACKAGES += \
    nv_bootloader_payload_updater-efi
endif
endif
endif
