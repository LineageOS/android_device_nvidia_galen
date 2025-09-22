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

# The new qspi settings fail to initialize in cboot, revert to what was used in l4t r32
function patch_rey_qspi_bct() {
  echo -n "Patching rey qspi bct...";

  sed -i 's/interface-frequency = 50/interface-frequency = 133/' ${LINEAGE_ROOT}/${OUTDIR}/galen/r35/BCT/tegra19x-mb1-bct-device-qspi-p3668.cfg
  sed -i 's/maximum-bus-width = 0/maximum-bus-width = 2/' ${LINEAGE_ROOT}/${OUTDIR}/galen/r35/BCT/tegra19x-mb1-bct-device-qspi-p3668.cfg
  sed -i 's/trimmer2-val = 0/trimmer2-val = 0x10/' ${LINEAGE_ROOT}/${OUTDIR}/galen/r35/BCT/tegra19x-mb1-bct-device-qspi-p3668.cfg

  echo "";
}

function patch_rey_bpmp_dtb() {
  echo -n "Patching rey bpmp dtb...";

  fdtput -p -t bx ${LINEAGE_ROOT}/${OUTDIR}/galen/r32/BCT/tegra194-a02-bpmp-p3668-a00.dtb /uphy pcie-xbar-config $(printf "PCIE_XBAR_8_1_1_0_1\0" |xxd -p |sed 's/../& /g');
  fdtput -p -t bx ${LINEAGE_ROOT}/${OUTDIR}/galen/r32/BCT/tegra194-a02-bpmp-p3668-a00.dtb /uphy ufs-config $(printf "UFS_DISABLED\0" |xxd -p |sed 's/../& /g');

  fdtput -p -t bx ${LINEAGE_ROOT}/${OUTDIR}/galen/r35/BCT/tegra194-a02-bpmp-p3668-a00.dtb /uphy pcie-xbar-config $(printf "PCIE_XBAR_8_1_1_0_1\0" |xxd -p |sed 's/../& /g');
  fdtput -p -t bx ${LINEAGE_ROOT}/${OUTDIR}/galen/r35/BCT/tegra194-a02-bpmp-p3668-a00.dtb /uphy ufs-config $(printf "UFS_DISABLED\0" |xxd -p |sed 's/../& /g');

  echo "";
}

# Increase heap carveout to 512MB for large bootloader images and vendor_boot
function patch_misc_bct() {
  echo -n "Patching bct to increase cpubl carveout...";

  sed -i 's/carveout.cpubl.size = 0x0b000000; # 176MB/carveout.cpubl.size = 0x20000000; # 512MB/' ${LINEAGE_ROOT}/${OUTDIR}/galen/r32/BCT/tegra194-mb1-bct-misc-l4t.cfg
  sed -i 's/carveout.cpubl.size = 0x0b000000; # 176MB/carveout.cpubl.size = 0x20000000; # 512MB/' ${LINEAGE_ROOT}/${OUTDIR}/galen/r32/BCT/tegra194-mb1-bct-misc-sd-l4t.cfg

  echo "";
}

patch_rey_qspi_bct;
patch_rey_bpmp_dtb;
patch_misc_bct;
