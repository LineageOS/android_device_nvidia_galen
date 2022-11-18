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
  sed -i 's/interface-frequency = 50/interface-frequency = 133/' ${LINEAGE_ROOT}/${OUTDIR}/galen/r35/BCT/tegra19x-mb1-bct-device-qspi-p3668.cfg
  sed -i 's/maximum-bus-width = 0/maximum-bus-width = 2/' ${LINEAGE_ROOT}/${OUTDIR}/galen/r35/BCT/tegra19x-mb1-bct-device-qspi-p3668.cfg
  sed -i 's/trimmer2-val = 0/trimmer2-val = 0x10/' ${LINEAGE_ROOT}/${OUTDIR}/galen/r35/BCT/tegra19x-mb1-bct-device-qspi-p3668.cfg
}

function patch_rey_bpmp_dtb() {
  git -C ${LINEAGE_ROOT}/${OUTDIR} apply -q ${LINEAGE_ROOT}/device/nvidia/galen/extract/rey_bpmp.patch
}

patch_rey_qspi_bct;
patch_rey_bpmp_dtb;
