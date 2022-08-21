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

TARGET_TEGRA_VERSION=t194;
TARGET_MODULE_ID=2888;
TARGET_CARRIER_ID=2822;

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
  echo "No Jetson AGX Xavier Devkit found";
  exit -1;
fi;

if   [ "${MODULEINFO[sku]}" == 1 -a "${MODULEINFO[fab]}" \> "300" -a "${MODULEINFO[revmaj]}" \> "68" ]; then
  cp tegra194-a02-bpmp-p2888-0001-a04.dtb tegra194-a02-bpmp.dtb;
elif [ "${MODULEINFO[sku]}" == 4 -a "${MODULEINFO[fab]}" \> "300" ]; then
  cp tegra194-a02-bpmp-p2888-0001-a04.dtb tegra194-a02-bpmp.dtb;
elif [ "${MODULEINFO[sku]}" == 5 -a "${MODULEINFO[fab]}" \> "300" ]; then
  cp tegra194-a02-bpmp-p2888-0005-a04.dtb tegra194-a02-bpmp.dtb;
else
  echo "Jetson AGX Xavier module SKU ${MODULEINFO[sku]}, FAB ${MODULEINFO[fab]}, and Rev ${MODULEINFO[revmaj]}:${MODULEINFO[revmin]} is not supported";
  exit -1;
fi;

# Generate version partition
if ! generate_version_bootblob_v4 emmc_bootblob_ver.txt REPLACEME; then
  echo "Failed to generate version bootblob";
  return -1;
fi;

# Add tnspec to Android Overlay
cp AndroidConfiguration.dtbo AndroidConfig.dtbo;
if ! generate_tnspec_dtbo AndroidConfig.dtbo; then
  echo "Failed to generate tnspec";
  return -1;
fi;

declare -a FLASH_CMD_FLASH=(
  --bl nvtboot_recovery_cpu_t194.bin
  --sdram_config tegra194-mb1-bct-memcfg-p2888.cfg,tegra194-memcfg-sw-override.cfg
  --overlay_dtb AndroidConfig.dtbo,tegra194-p2888-0005-overlay.dtbo,tegra194-p2888-0001-p2822-0000-overlay.dtbo
  --bldtb tegra194-p2888-0001-p2822-0000.dtb
  --odmdata 0x9190000
  --applet mb1_t194_prod.bin
  --soft_fuses tegra194-mb1-soft-fuses-l4t.cfg
  --chip 0x19
  --uphy_config tegra194-mb1-uphy-lane-p2888-0000-p2822-0000.cfg
  --device_config tegra19x-mb1-bct-device-sdmmc.cfg
  --misc_cold_boot_config tegra194-mb1-bct-misc-l4t.cfg
  --misc_config tegra194-mb1-bct-misc-flash.cfg
  --pinmux_config tegra19x-mb1-pinmux-p2888-0000-a04-p2822-0000-b01.cfg
  --gpioint_config tegra194-mb1-bct-gpioint-p2888-0000-p2822-0000.cfg
  --pmic_config tegra194-mb1-bct-pmic-p2888-0001-a04-E-0-p2822-0000.cfg
  --pmc_config tegra19x-mb1-padvoltage-p2888-0000-a00-p2822-0000-a00.cfg
  --prod_config tegra19x-mb1-prod-p2888-0000-p2822-0000.cfg
  --scr_config tegra194-mb1-bct-scr-cbb-mini.cfg
  --scr_cold_boot_config tegra194-mb1-bct-scr-cbb-mini.cfg
  --br_cmd_config tegra194-mb1-bct-reset-p2888-0000-p2822-0000.cfg
  --dev_params tegra194-br-bct-sdmmc.cfg,tegra194-br-bct_b-sdmmc.cfg
  --secondary_gpt_backup
  --bct_backup
  --boot_chain A
  --bin "mb2_bootloader nvtboot_recovery_t194.bin; mts_preboot preboot_c10_prod_cr.bin; mts_mce mce_c10_prod_cr.bin; mts_proper mts_c10_prod_cr.bin; bpmp_fw bpmp_t194.bin; bpmp_fw_dtb tegra194-a02-bpmp.dtb; spe_fw spe_t194.bin; tlk tos-mon-only_t194.img; bootloader_dtb tegra194-p2888-0001-p2822-0000.dtb");

tegraflash.py \
  "${FLASH_CMD_FLASH[@]}" \
  --instance ${INTERFACE} \
  --cfg flash_android_t194_sdmmc.xml \
  --cmd "flash; reboot"

rm tegra194-a02-bpmp.dtb emmc_bootblob_ver.txt AndroidConfig.dtbo;
