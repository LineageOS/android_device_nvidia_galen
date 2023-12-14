#
# Copyright (C) 2022-2023 The LineageOS Project
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

# Proprietary gpu driver
BOARD_VENDOR_KERNEL_MODULES_LOAD := \
    nvgpu

# Tegra SPI
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    spi-tegra114

# SPI MTD
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    qspi_mtd

# Tegra hdmi audio
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    snd-hda-tegra \
    snd-hda-codec-hdmi

# Tegra audio processing engine
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    snd-soc-spdif-tx \
    snd-soc-tegra210-sfc \
    snd-soc-tegra210-i2s \
    snd-soc-tegra210-mixer \
    snd-soc-tegra210-amx \
    snd-soc-tegra210-admaif \
    snd-soc-tegra210-adsp \
    snd-soc-tegra210-adx \
    snd-soc-tegra210-iqc \
    snd-soc-tegra210-afc \
    snd-soc-tegra210-dmic \
    snd-soc-tegra210-mvc \
    snd-soc-tegra210-ope \
    snd-soc-tegra186-dspk \
    snd-soc-tegra186-asrc \
    snd-soc-tegra-machine-driver

# Hardware Accelerated crypto
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    sha1-ce \
    sha2-ce \
    ghash-ce \
    aes-ce-blk \
    lzo-rle

# BPMP Thermal
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    tegra-bpmp-thermal

# Fan
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    pwm-fan

# Temperature Monitor
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    nct1008

# Power Monitor
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    ina3221

# Realtek 8822ce wireless
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    rtk_btusb \
    rtl8822ce


# Copy to recovery
BOARD_RECOVERY_RAMDISK_KERNEL_MODULES_LOAD := \
    hid-nvidia-blake \
    hid-jarvis-remote \
    tegra-bpmp-thermal \
    pwm-fan

RECOVERY_KERNEL_MODULES := $(addsuffix .ko,$(BOARD_RECOVERY_RAMDISK_KERNEL_MODULES_LOAD))
