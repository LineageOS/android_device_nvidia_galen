#
# Copyright (C) 2022 The LineageOS Project
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
    spi_tegra114

# SPI MTD
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    qspi_mtd

# Tegra hdmi audio
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    snd_hda_tegra \
    snd_hda_codec_hdmi

# Tegra audio processing engine
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    snd_soc_spdif_tx \
    snd_soc_tegra210_sfc \
    snd_soc_tegra210_i2s \
    snd_soc_tegra210_mixer \
    snd_soc_tegra210_amx \
    snd_soc_tegra210_admaif \
    snd_soc_tegra210_adsp \
    snd_soc_tegra210_adx \
    snd_soc_tegra210_iqc \
    snd_soc_tegra210_afc \
    snd_soc_tegra210_dmic \
    snd_soc_tegra210_mvc \
    snd_soc_tegra210_ope \
    snd_soc_tegra186_dspk \
    snd_soc_tegra186_asrc \
    snd_soc_tegra_machine_driver

# Hardware Accelerated crypto
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    sha1_ce \
    sha2_ce \
    ghash_ce \
    aes_ce_blk \
    lzo_rle

# BPMP Thermal
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    tegra_bpmp_thermal

# Fan
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    pwm_fan

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

# USB Type C Gadget Support
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    ucsi_ccg

