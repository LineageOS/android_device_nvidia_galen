LOCAL_PATH := $(call my-dir)

TEGRAFLASH_PATH := $(BUILD_TOP)/vendor/nvidia/common/tegraflash
T194_BL         := $(BUILD_TOP)/vendor/nvidia/t194/bootloader
GALEN_BCT       := $(BUILD_TOP)/vendor/nvidia/galen/BCT
GALEN_FLASH     := $(BUILD_TOP)/device/nvidia/galen/flash_package
COMMON_FLASH    := $(BUILD_TOP)/device/nvidia/tegra-common/flash_package

CAPSULE_PATH    := $(BUILD_TOP)/bootable/tianocore/edk2/BaseTools/Source/Python/Capsule
CAPSULE_CERTS   ?= $(BUILD_TOP)/bootable/tianocore/edk2/BaseTools/Source/Python/Pkcs7Sign
CAPSULE_PRIVATE ?= $(CAPSULE_CERTS)/TestCert.pem
CAPSULE_OTHER   ?= $(CAPSULE_CERTS)/TestSub.pub.pem
CAPSULE_TRUSTED ?= $(CAPSULE_CERTS)/TestRoot.pub.pem

INSTALLED_KERNEL_TARGET      := $(PRODUCT_OUT)/kernel
INSTALLED_NVDISP_INIT_TARGET := $(PRODUCT_OUT)/nvdisp-init.bin
INSTALLED_TIANOCORE_TARGET   := $(PRODUCT_OUT)/tianocore.bin
INSTALLED_EDK2_DTBO_TARGET   := $(PRODUCT_OUT)/AndroidConfiguration.dtbo

TOYBOX_HOST  := $(HOST_OUT_EXECUTABLES)/toybox
SMD_GEN_HOST := $(HOST_OUT_EXECUTABLES)/nv_smd_generator

LINEAGEVER   := $(shell python $(COMMON_FLASH)/get_branch_name.py)

KERNEL_OUT ?= $(PRODUCT_OUT)/obj/KERNEL_OBJ

FDTPUT_HOST := $(HOST_OUT_EXECUTABLES)/fdtput

E :=
SPACE := $(E) $(E)

ifneq ($(TARGET_TEGRA_KERNEL),4.9)
DTB_SUBFOLDER := nvidia/
endif

include $(CLEAR_VARS)
LOCAL_MODULE               := TEGRA_BL.Cap
LOCAL_MODULE_CLASS         := ETC
LOCAL_MODULE_RELATIVE_PATH := firmware

_galen_blob_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_galen_blob := $(_galen_blob_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

P2972-0001_SIGNED_PATH := $(_galen_blob_intermediates)/p2972-0001-signed
P2972-0004_SIGNED_PATH := $(_galen_blob_intermediates)/p2972-0004-signed
P2972-0005_SIGNED_PATH := $(_galen_blob_intermediates)/p2972-0005-signed
P3518-0000_SIGNED_PATH := $(_galen_blob_intermediates)/p3518-0000-signed
P3518-0001_SIGNED_PATH := $(_galen_blob_intermediates)/p3518-0001-signed
P3518-0003_SIGNED_PATH := $(_galen_blob_intermediates)/p3518-0003-signed

_p2972-0001_br_bct := $(P2972-0001_SIGNED_PATH)/br_bct_BR.bct
_p2972-0004_br_bct := $(P2972-0004_SIGNED_PATH)/br_bct_BR.bct
_p2972-0005_br_bct := $(P2972-0005_SIGNED_PATH)/br_bct_BR.bct
_p3518-0000_br_bct := $(P3518-0000_SIGNED_PATH)/br_bct_BR.bct
_p3518-0001_br_bct := $(P3518-0001_SIGNED_PATH)/br_bct_BR.bct
_p3518-0003_br_bct := $(P3518-0003_SIGNED_PATH)/br_bct_BR.bct

# Parameters
# $1  Intermediates path
# $2  Partition xml
# $3  BPMP dtb
# $4  Kernel dtb
# $5  ODM data
# $6  BL dtbo list
# $7  Sdram config
# $8  Soft fuses
# $9  Uphy config
# $10 Device config
# $11 Mb1 cold boot config
# $12 Pinmux config
# $13 Gpioint config
# $14 Pmic config
# $15 Pmc config
# $16 Prod config
# $17 Scr cold boot config
# $18 Br cmd config
# $19 Dev params slot 1
# $20 Dev params slot 2
# $21 Module board id
# $22 Module sku
# $23 Carrier board id
# $24 Carrier sku
define t194_bl_signing_rule
$(strip $1)/br_bct_BR.bct: $(INSTALLED_KERNEL_TARGET) $(INSTALLED_NVDISP_INIT_TARGET) $(INSTALLED_TIANOCORE_TARGET) $(INSTALLED_EDK2_DTBO_TARGET) $(TOYBOX_HOST) $(FDTPUT_HOST) $(SMD_GEN_HOST)
	@mkdir -p $(strip $1)
	@cp $(GALEN_FLASH)/$(strip $2) $(strip $1)/
	@cp $(T194_BL)/* $(strip $1)/
	@rm $(strip $1)/BOOTAA64.efi
	@rm $(strip $1)/uefi_jetson.bin
	@rm $(strip $1)/nvdisp-init.bin
	@cp $(INSTALLED_NVDISP_INIT_TARGET) $(strip $1)/
	@truncate -s 393216 $(strip $1)/nvdisp-init.bin
	@cat $(strip $1)/nvdisp-init.bin $(INSTALLED_TIANOCORE_TARGET) > $(strip $1)/nvdisp_uefi_jetson.bin
	@rm $(strip $1)/nvdisp-init.bin
	@cp $(GALEN_BCT)/$(strip $3) $(strip $1)/tegra194-a02-bpmp.dtb
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)$(strip $4) $(strip $1)/
	@cp $(PRODUCT_OUT)/AndroidConfiguration.dtbo $(strip $1)/
	$(FDTPUT_HOST) -p -t bx $(strip $1)/AndroidConfiguration.dtbo /fragment@0/__overlay__/firmware/uefi/variables/gNVIDIAPublicVariableGuid/TegraPlatformSpec data $(shell printf "p%04d-%04d+p%04d-%04d.android\0" $(strip $(21)) $(strip $(22)) $(strip $(23)) $(strip $(24)) |xxd -p |sed 's/../& /g');
	$(FDTPUT_HOST) -p $(strip $1)/AndroidConfiguration.dtbo /fragment@0/__overlay__/firmware/uefi/variables/gNVIDIAPublicVariableGuid/TegraPlatformSpec runtime;
	$(FDTPUT_HOST) -p $(strip $1)/AndroidConfiguration.dtbo /fragment@0/__overlay__/firmware/uefi/variables/gNVIDIAPublicVariableGuid/TegraPlatformSpec locked;
	echo "NV4" > $(strip $1)/bootblob_ver.txt
	echo "# R$(word 1,$(subst ., ,$(LINEAGEVER))) , REVISION: $(word 2,$(subst ., ,$(LINEAGEVER)))" >> $(strip $1)/bootblob_ver.txt
	echo "BOARDID=$(strip $(21)) BOARDSKU=$(strip $(22)) FAB=" >> $(strip $1)/bootblob_ver.txt
	$(TOYBOX_HOST) date '+%Y%m%d%H%M%S' >> $(strip $1)/bootblob_ver.txt
	echo "$(shell printf "0x%x" $$(( $(word 1,$(subst ., ,$(LINEAGEVER)))<<16 | $(word 2,$(subst ., ,$(LINEAGEVER)))<<8 )) )" >> $(strip $1)/bootblob_ver.txt
	python -c 'import zlib; print("%X"%(zlib.crc32(open("'"$(strip $1)/bootblob_ver.txt"'", "rb").read()) & 0xFFFFFFFF))' > $(strip $1)/crc.txt
	wc -c < $(strip $1)/bootblob_ver.txt | tr -d '\n' > $(strip $1)/bytes.txt
	echo -n "BYTES:" >> $(strip $1)/bootblob_ver.txt
	cat $(strip $1)/bytes.txt >> $(strip $1)/bootblob_ver.txt
	echo -n " CRC32:" >> $(strip $1)/bootblob_ver.txt
	cat $(strip $1)/crc.txt >> $(strip $1)/bootblob_ver.txt
	sed -i 's/emmc_bootblob/bootblob/' $(strip $1)/$(strip $(2))
	sed -i 's/qspi_bootblob/bootblob/' $(strip $1)/$(strip $(2))
	sed -i '/esp.img/d' $(strip $1)/$(strip $(2))
	sed -i '/recovery.img/d' $(strip $1)/$(strip $(2))
	sed -i '/super_meta_only.img/d' $(strip $1)/$(strip $(2))
	sed -i '/vbmeta_skip.img/d' $(strip $1)/$(strip $(2))
	sed -i '/xusb_sil_rel_fw/d' $(strip $1)/$(strip $(2))
	@$(SMD_GEN_HOST) $(strip $(1))/slot_metadata.bin
	cd $(strip $1); PYTHONDONTWRITEBYTECODE=1 $(TEGRAFLASH_PATH)/tegraflash.py \
		--chip 0x19 \
		--bl nvtboot_recovery_cpu_t194.bin \
		--applet mb1_t194_prod.bin \
		--cmd "sign" \
		--cfg $(strip $(2)) \
		--odmdata $(strip $(5)) \
		--overlay_dtb AndroidConfiguration.dtbo,$(subst $(SPACE),,$(foreach dtbo,$(strip $(6)),$(KERNEL_OUT)/arch/arm64/boot/dts/nvidia/$(dtbo),)) \
		--bldtb $(strip $(4)) \
		--sdram_config $(GALEN_BCT)/$(strip $(7)),$(GALEN_BCT)/tegra194-memcfg-sw-override.cfg \
		--soft_fuses $(GALEN_BCT)/$(strip $(8)) \
		$(9) \
		--device_config $(GALEN_BCT)/$(strip $(10)) \
		--misc_cold_boot_config $(GALEN_BCT)/$(strip $(11)) \
		--misc_config $(GALEN_BCT)/tegra194-mb1-bct-misc-flash.cfg \
		--pinmux_config $(GALEN_BCT)/$(strip $(12)) \
		--gpioint_config $(GALEN_BCT)/$(strip $(13)) \
		--pmic_config $(GALEN_BCT)/$(strip $(14)) \
		--pmc_config $(GALEN_BCT)/$(strip $(15)) \
		--prod_config $(GALEN_BCT)/$(strip $(16)) \
		--scr_config $(GALEN_BCT)/$(strip $(17)) \
		--scr_cold_boot_config $(GALEN_BCT)/$(strip $(17)) \
		--br_cmd_config $(GALEN_BCT)/$(strip $(18)) \
		--dev_params $(GALEN_BCT)/$(strip $(19)),$(GALEN_BCT)/$(strip $(20))
	@mv $(strip $1)/signed/* $(strip $1)/
endef

# $1 Intermediates path
# $2 Module sku
# $3 Bpmp dtb sku
define p2972_bl_signing_rule
$(call t194_bl_signing_rule, \
  $(strip $1), \
  flash_android_t194_sdmmc.xml, \
  tegra194-a02-bpmp-p2888$(strip $3)-a04.dtb, \
  tegra194-p2888-0001-p2822-0000.dtb, \
  0x9190000, \
  tegra194-p2888-0005-overlay.dtbo tegra194-p2888-0001-p2822-0000-overlay.dtbo, \
  tegra194-mb1-bct-memcfg-p2888.cfg, \
  tegra194-mb1-soft-fuses-l4t.cfg, \
  --uphy_config $(GALEN_BCT)/tegra194-mb1-uphy-lane-p2888-0000-p2822-0000.cfg, \
  tegra19x-mb1-bct-device-sdmmc.cfg, \
  tegra194-mb1-bct-misc-l4t.cfg, \
  tegra19x-mb1-pinmux-p2888-0000-a04-p2822-0000-b01.cfg, \
  tegra194-mb1-bct-gpioint-p2888-0000-p2822-0000.cfg, \
  tegra194-mb1-bct-pmic-p2888-0001-a04-E-0-p2822-0000.cfg, \
  tegra19x-mb1-padvoltage-p2888-0000-a00-p2822-0000-a00.cfg, \
  tegra19x-mb1-prod-p2888-0000-p2822-0000.cfg, \
  tegra194-mb1-bct-scr-cbb-mini.cfg, \
  tegra194-mb1-bct-reset-p2888-0000-p2822-0000.cfg, \
  tegra194-br-bct-sdmmc.cfg, \
  tegra194-br-bct_b-sdmmc.cfg, \
  2888, \
  $(strip $2), \
  2822, \
  0 \
)
endef

# $1 Intermediates path
# $2 Partition xml variant
# $3 Kernel dtb sku
# $4 Module sku
# $5 Mb1 cold boot variant
define p3518_bl_signing_rule
$(call t194_bl_signing_rule, \
  $(strip $1), \
  flash_android_t194_spi_$(strip $2)_p3668.xml, \
  tegra194-a02-bpmp-p3668-a00.dtb, \
  tegra194-p3668-$(strip $3)-p3509-0000-android.dtb, \
  0xB8190000, \
  tegra194-p3668-p3509-overlay.dtbo, \
  tegra194-mb1-bct-memcfg-p3668-0001-a00.cfg, \
  tegra194-mb1-soft-fuses-l4t.cfg, \
  , \
  tegra19x-mb1-bct-device-qspi-p3668.cfg, \
  tegra194-mb1-bct-misc$(strip $5)-l4t.cfg, \
  tegra19x-mb1-pinmux-p3668-a01.cfg, \
  tegra194-mb1-bct-gpioint-p3668-0001-a00.cfg, \
  tegra194-mb1-bct-pmic-p3668-0001-a00.cfg, \
  tegra19x-mb1-padvoltage-p3668-a01.cfg, \
  tegra19x-mb1-prod-p3668-0001-a00.cfg, \
  tegra194-mb1-bct-scr-cbb-mini-p3668.cfg, \
  tegra194-mb1-bct-reset-p3668-0001-a00.cfg, \
  tegra194-br-bct-qspi-l4t.cfg, \
  tegra194-br-bct_b-qspi-l4t.cfg, \
  3668, \
  $(strip $4), \
  3509, \
  0 \
)
endef

$(eval $(call p2972_bl_signing_rule, $(P2972-0001_SIGNED_PATH), 0001))
$(eval $(call p2972_bl_signing_rule, $(P2972-0004_SIGNED_PATH), 0004))
$(eval $(call p2972_bl_signing_rule, $(P2972-0005_SIGNED_PATH), 0005, -0005))

$(eval $(call p3518_bl_signing_rule, $(P3518-0000_SIGNED_PATH), sd,   0000, 0000, -sd))
$(eval $(call p3518_bl_signing_rule, $(P3518-0001_SIGNED_PATH), emmc, 0001, 0001))
$(eval $(call p3518_bl_signing_rule, $(P3518-0003_SIGNED_PATH), emmc, 0001, 0003))

$(_galen_blob): $(_p2972-0001_br_bct) $(_p2972-0004_br_bct) $(_p2972-0005_br_bct) $(_p3518-0000_br_bct) $(_p3518-0001_br_bct) $(_p3518-0003_br_bct)
	@mkdir -p $(dir $@)
	OUT=$(dir $@) TOP=$(BUILD_TOP) python2 $(TEGRAFLASH_PATH)/BUP_generator.py -t update -e \
		"$(P2972-0001_SIGNED_PATH)/spe_t194_sigheader.bin.encrypt spe-fw 2 0 common; \
		 $(P2972-0001_SIGNED_PATH)/nvtboot_t194_sigheader.bin.encrypt mb2 2 0 common; \
		 $(P2972-0001_SIGNED_PATH)/nvdisp_uefi_jetson_sigheader.bin.encrypt cpu-bootloader 2 0 common; \
		 $(P2972-0001_SIGNED_PATH)/tos-mon-only_t194_sigheader.img.encrypt secure-os 2 0 common; \
		 $(P2972-0001_SIGNED_PATH)/bpmp_t194_sigheader.bin.encrypt bpmp-fw 2 0 common; \
		 $(P2972-0001_SIGNED_PATH)/adsp-fw_sigheader.bin.encrypt adsp-fw 2 0 common; \
		 $(P2972-0001_SIGNED_PATH)/camera-rtcpu-t194-rce_sigheader.img.encrypt rce-fw 2 0 common; \
		 $(P2972-0001_SIGNED_PATH)/preboot_c10_prod_cr_sigheader.bin.encrypt mts-preboot 2 2 common; \
		 $(P2972-0001_SIGNED_PATH)/mce_c10_prod_cr_sigheader.bin.encrypt mts-mce 2 2 common; \
		 $(P2972-0001_SIGNED_PATH)/mts_c10_prod_cr_sigheader.bin.encrypt mts-proper 2 2 common; \
		 $(P2972-0001_SIGNED_PATH)/warmboot_t194_prod_sigheader.bin.encrypt sc7 2 2 common; \
		 $(P2972-0001_SIGNED_PATH)/mb1_t194_prod_aligned_sigheader.bin.encrypt mb1 2 2 p2888-0001+p2822-0000.android; \
		 $(P2972-0001_SIGNED_PATH)/tegra194-a02-bpmp_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 p2888-0001+p2822-0000.android; \
		 $(P2972-0001_SIGNED_PATH)/tegra194-p2888-0001-p2822-0000_sigheader.dtb.encrypt bootloader-dtb 2 0 p2888-0001+p2822-0000.android; \
		 $(P2972-0001_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct.encrypt MB1_BCT 2 0 p2888-0001+p2822-0000.android; \
		 $(P2972-0001_SIGNED_PATH)/mem_coldboot_sigheader.bct.encrypt MEM_BCT 2 0 p2888-0001+p2822-0000.android; \
		 $(P2972-0001_SIGNED_PATH)/bootblob_ver.txt VER 2 0 p2888-0001+p2822-0000.android; \
		 $(P2972-0004_SIGNED_PATH)/mb1_t194_prod_aligned_sigheader.bin.encrypt mb1 2 2 p2888-0004+p2822-0000.android; \
		 $(P2972-0004_SIGNED_PATH)/tegra194-a02-bpmp_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 p2888-0004+p2822-0000.android; \
		 $(P2972-0004_SIGNED_PATH)/tegra194-p2888-0001-p2822-0000_sigheader.dtb.encrypt bootloader-dtb 2 0 p2888-0004+p2822-0000.android; \
		 $(P2972-0004_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct.encrypt MB1_BCT 2 0 p2888-0004+p2822-0000.android; \
		 $(P2972-0004_SIGNED_PATH)/mem_coldboot_sigheader.bct.encrypt MEM_BCT 2 0 p2888-0004+p2822-0000.android; \
		 $(P2972-0004_SIGNED_PATH)/bootblob_ver.txt VER 2 0 p2888-0004+p2822-0000.android; \
		 $(P2972-0005_SIGNED_PATH)/mb1_t194_prod_aligned_sigheader.bin.encrypt mb1 2 2 p2888-0005+p2822-0000.android; \
		 $(P2972-0005_SIGNED_PATH)/tegra194-a02-bpmp_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 p2888-0005+p2822-0000.android; \
		 $(P2972-0005_SIGNED_PATH)/tegra194-p2888-0001-p2822-0000_sigheader.dtb.encrypt bootloader-dtb 2 0 p2888-0005+p2822-0000.android; \
		 $(P2972-0005_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct.encrypt MB1_BCT 2 0 p2888-0005+p2822-0000.android; \
		 $(P2972-0005_SIGNED_PATH)/mem_coldboot_sigheader.bct.encrypt MEM_BCT 2 0 p2888-0005+p2822-0000.android; \
		 $(P2972-0005_SIGNED_PATH)/bootblob_ver.txt VER 2 0 p2888-0005+p2822-0000.android; \
		 $(P3518-0000_SIGNED_PATH)/mb1_t194_prod_aligned_sigheader.bin.encrypt mb1 2 2 p3668-0000+p3509-0000.android; \
		 $(P3518-0000_SIGNED_PATH)/tegra194-a02-bpmp_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 p3668-0000+p3509-0000.android; \
		 $(P3518-0000_SIGNED_PATH)/tegra194-p3668-0000-p3509-0000-android_sigheader.dtb.encrypt bootloader-dtb 2 0 p3668-0000+p3509-0000.android; \
		 $(P3518-0000_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct.encrypt MB1_BCT 2 0 p3668-0000+p3509-0000.android; \
		 $(P3518-0000_SIGNED_PATH)/mem_coldboot_sigheader.bct.encrypt MEM_BCT 2 0 p3668-0000+p3509-0000.android; \
		 $(P3518-0000_SIGNED_PATH)/bootblob_ver.txt VER 2 0 p3668-0000+p3509-0000.android; \
		 $(P3518-0001_SIGNED_PATH)/mb1_t194_prod_aligned_sigheader.bin.encrypt mb1 2 2 p3668-0001+p3509-0000.android; \
		 $(P3518-0001_SIGNED_PATH)/tegra194-a02-bpmp_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 p3668-0001+p3509-0000.android; \
		 $(P3518-0001_SIGNED_PATH)/tegra194-p3668-0001-p3509-0000-android_sigheader.dtb.encrypt bootloader-dtb 2 0 p3668-0001+p3509-0000.android; \
		 $(P3518-0001_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct.encrypt MB1_BCT 2 0 p3668-0001+p3509-0000.android; \
		 $(P3518-0001_SIGNED_PATH)/mem_coldboot_sigheader.bct.encrypt MEM_BCT 2 0 p3668-0001+p3509-0000.android; \
		 $(P3518-0001_SIGNED_PATH)/bootblob_ver.txt VER 2 0 p3668-0001+p3509-0000.android; \
		 $(P3518-0003_SIGNED_PATH)/mb1_t194_prod_aligned_sigheader.bin.encrypt mb1 2 2 p3668-0003+p3509-0000.android; \
		 $(P3518-0003_SIGNED_PATH)/tegra194-a02-bpmp_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 p3668-0003+p3509-0000.android; \
		 $(P3518-0003_SIGNED_PATH)/tegra194-p3668-0001-p3509-0000-android_sigheader.dtb.encrypt bootloader-dtb 2 0 p3668-0003+p3509-0000.android; \
		 $(P3518-0003_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct.encrypt MB1_BCT 2 0 p3668-0003+p3509-0000.android; \
		 $(P3518-0003_SIGNED_PATH)/mem_coldboot_sigheader.bct.encrypt MEM_BCT 2 0 p3668-0003+p3509-0000.android; \
		 $(P3518-0003_SIGNED_PATH)/bootblob_ver.txt VER 2 0 p3668-0003+p3509-0000.android"
	PYTHONPATH=$$PYTHONPATH:$(dir $(CAPSULE_PATH)) python3 $(CAPSULE_PATH)/GenerateCapsule.py -v --encode --monotonic-count 1 --fw-version "0x00000000" --lsv "0x00000000" --guid "be3f5d68-7654-4ed2-838c-2a2faf901a78" --signer-private-cert "$(CAPSULE_PRIVATE)" --other-public-cert "$(CAPSULE_OTHER)" --trusted-public-cert "$(CAPSULE_TRUSTED)" -o "$@" "$(dir $@)/ota.blob"

include $(BUILD_SYSTEM)/base_rules.mk

include $(CLEAR_VARS)
LOCAL_MODULE               := kernel_only_payload
LOCAL_MODULE_CLASS         := ETC
LOCAL_MODULE_RELATIVE_PATH := firmware

_kernel_blob_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_kernel_blob := $(_kernel_blob_intermediates)/$(LOCAL_MODULE)

$(_kernel_blob): $(INSTALLED_KERNEL_TARGET)
	@mkdir -p $(dir $@)
	OUT=$(dir $@) TOP=$(BUILD_TOP) python2 $(TEGRAFLASH_PATH)/BUP_generator.py -t update -e \
		"$(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra194-p2888-0001-p2822-0000.dtb kernel-dtb 2 0 p2888-0001+p2822-0000.android; \
		 $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra194-p2888-0001-p2822-0000.dtb kernel-dtb 2 0 p2888-0004+p2822-0000.android; \
		 $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra194-p2888-0001-p2822-0000.dtb kernel-dtb 2 0 p2888-0005+p2822-0000.android; \
		 $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra194-p3668-0000-p3509-0000-android.dtb kernel-dtb 2 0 p3668-0000+p3509-0000.android; \
		 $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra194-p3668-0001-p3509-0000-android.dtb kernel-dtb 2 0 p3668-0001+p3509-0000.android; \
		 $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra194-p3668-0001-p3509-0000-android.dtb kernel-dtb 2 0 p3668-0003+p3509-0000.android"
	@mv $(dir $@)/ota.blob $@

include $(BUILD_SYSTEM)/base_rules.mk
