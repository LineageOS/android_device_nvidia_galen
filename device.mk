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

TARGET_REFERENCE_DEVICE ?= galen
TARGET_TEGRA_VARIANT    ?= common

TARGET_TEGRA_AUDIO    ?= nvaudio
TARGET_TEGRA_CEC      ?= nvhdmi
TARGET_TEGRA_OMX      ?= nvmm

$(call inherit-product, device/nvidia/t194-common/t194.mk)

PRODUCT_CHARACTERISTICS  := tv
PRODUCT_AAPT_CONFIG      := xlarge large
PRODUCT_AAPT_PREF_CONFIG := xxhdpi
TARGET_SCREEN_HEIGHT     := 1920
TARGET_SCREEN_WIDTH      := 1080

$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)

# Init related
PRODUCT_PACKAGES += \
    fstab.jetson-xavier \
    fstab.rey \
    init.jetson-xavier.rc \
    init.rey.rc \
    init.jetson-xavier_common.rc \
    init.recovery.jetson-xavier.rc \
    init.recovery.rey.rc \
    power.jetson-xavier.rc \
    power.rey.rc

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml

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
PRODUCT_COPY_FILES += \
    $(TARGET_PREBUILT_KERNEL):kernel
endif

# Media config
PRODUCT_COPY_FILES += \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_ODM)/etc/media_codecs_google_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:$(TARGET_COPY_OUT_ODM)/etc/media_codecs_google_video.xml
PRODUCT_PACKAGES += \
    media_codecs.xml
ifeq ($(TARGET_TEGRA_OMX),nvmm)
PRODUCT_PACKAGES += \
    media_codecs_performance.xml \
    media_profiles.xml
endif
