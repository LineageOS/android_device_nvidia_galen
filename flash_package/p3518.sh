#!/bin/bash

# Copyright (C) 2021 The LineageOS Project
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

PATH=$(pwd)/tegraflash:${PATH}

TARGET_TEGRA_VERSION=t194nx;
TARGET_MODULE_ID=3668;
TARGET_CARRIER_ID=3509;

source $(pwd)/scripts/helpers.sh;

declare -a FLASH_CMD_EEPROM=(
  --applet mb1_t194_prod.bin
  --soft_fuses tegra194-mb1-soft-fuses-l4t.cfg
  --chip 0x19
  --bin "mb2_applet nvtboot_applet_t194.bin");

if ! get_interfaces; then
  exit -1;
fi;

if ! check_compatibility ${TARGET_MODULE_ID} ${TARGET_CARRIER_ID}; then
  echo "No Jetson Xavier NX Devkit found";
  exit -1;
fi;

FLASH_XML=;
REYSKU=;
MISCCBVAR=;
if [ ${MODULEINFO[sku]} -eq 1 -o ${MODULEINFO[sku]} -eq 3 ]; then
  FLASH_XML="flash_android_t194_spi_emmc_p3668.xml"
  REYSKU="0001";
elif [ ${MODULEINFO[sku]} -eq 0 ]; then
  FLASH_XML="flash_android_t194_spi_sd_p3668.xml"
  REYSKU="0000";
  MISCCBVAR="-sd";
else
  echo "Unsupported Xavier NX module sku: ${MODULEINFO[sku]}";
  exit -1;
fi;

# Generate version partition
if ! generate_version_bootblob_v4 qspi_bootblob_ver.txt REPLACEME; then
  echo "Failed to generate version bootblob";
  return -1;
fi;

# Add tnspec to Android Overlay
# Xavier NX cannot read carrier info in rcm, thus carrier id and sku are hardcoded
CARRIERINFO[boardid]=${TARGET_CARRIER_ID};
CARRIERINFO[sku]=0;
cp AndroidConfiguration.dtbo AndroidConfig.dtbo;
if ! generate_tnspec_dtbo AndroidConfig.dtbo; then
  echo "Failed to generate tnspec";
  return -1;
fi;

declare -a FLASH_CMD_FLASH=(
  --bl nvtboot_recovery_cpu_t194.bin
  --sdram_config tegra194-mb1-bct-memcfg-p3668-0001-a00.cfg,tegra194-memcfg-sw-override.cfg
  --overlay_dtb AndroidConfig.dtbo,tegra194-p3668-p3509-overlay.dtbo
  --bldtb tegra194-p3668-${REYSKU}-p3509-0000-android.dtb
  --odmdata 0xB8190000
  --applet mb1_t194_prod.bin
  --soft_fuses tegra194-mb1-soft-fuses-l4t.cfg
  --chip 0x19
  --device_config tegra19x-mb1-bct-device-qspi-p3668.cfg
  --misc_cold_boot_config tegra194-mb1-bct-misc${MISCCBVAR}-l4t.cfg
  --misc_config tegra194-mb1-bct-misc-flash.cfg
  --pinmux_config tegra19x-mb1-pinmux-p3668-a01.cfg
  --gpioint_config tegra194-mb1-bct-gpioint-p3668-0001-a00.cfg
  --pmic_config tegra194-mb1-bct-pmic-p3668-0001-a00.cfg
  --pmc_config tegra19x-mb1-padvoltage-p3668-a01.cfg
  --prod_config tegra19x-mb1-prod-p3668-0001-a00.cfg
  --scr_config tegra194-mb1-bct-scr-cbb-mini-p3668.cfg
  --scr_cold_boot_config tegra194-mb1-bct-scr-cbb-mini-p3668.cfg
  --br_cmd_config tegra194-mb1-bct-reset-p3668-0001-a00.cfg
  --dev_params tegra194-br-bct-qspi-l4t.cfg,tegra194-br-bct_b-qspi-l4t.cfg
  --secondary_gpt_backup
  --bct_backup
  --boot_chain A
  --bin "mb2_bootloader nvtboot_recovery_t194.bin; mts_preboot preboot_c10_prod_cr.bin; mts_mce mce_c10_prod_cr.bin; mts_proper mts_c10_prod_cr.bin; bpmp_fw bpmp_t194.bin; bpmp_fw_dtb tegra194-a02-bpmp.dtb; spe_fw spe_t194.bin; tlk tos-mon-only_t194.img; bootloader_dtb tegra194-p3668-${REYSKU}-p3509-0000-android.dtb");

tegraflash.py \
  "${FLASH_CMD_FLASH[@]}" \
  --instance ${INTERFACE} \
  --cfg ${FLASH_XML} \
  --cmd "flash; reboot"

rm -f qspi_bootblob_ver.txt AndroidConfig.dtbo;
