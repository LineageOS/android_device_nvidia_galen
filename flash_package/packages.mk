LOCAL_PATH := $(call my-dir)

TEGRAFLASH_PATH := $(BUILD_TOP)/vendor/nvidia/common/tegraflash
T194_BL         := $(BUILD_TOP)/vendor/nvidia/t194/bootloader
T194_FW         := $(BUILD_TOP)/vendor/nvidia/t194/firmware
GALEN_BCT       := $(BUILD_TOP)/vendor/nvidia/galen/BCT
GALEN_FLASH     := $(BUILD_TOP)/device/nvidia/galen/flash_package
COMMON_FLASH    := $(BUILD_TOP)/device/nvidia/tegra-common/flash_package

INSTALLED_KERNEL_TARGET        := $(PRODUCT_OUT)/kernel
INSTALLED_RECOVERYIMAGE_TARGET := $(PRODUCT_OUT)/recovery.img
INSTALLED_SUPER_EMPTY_TARGET   := $(PRODUCT_OUT)/super_empty.img
INSTALLED_NVDISP_INIT_TARGET   := $(PRODUCT_OUT)/nvdisp-init.bin
INSTALLED_TIANOCORE_TARGET     := $(PRODUCT_OUT)/tianocore.bin
INSTALLED_RLAUNCHER_TARGET     := $(PRODUCT_OUT)/AndroidLauncher-recovery.efi
INSTALLED_EDK2_DTBO_TARGET     := $(PRODUCT_OUT)/AndroidConfiguration.dtbo

TOYBOX_HOST  := $(HOST_OUT_EXECUTABLES)/toybox
AVBTOOL_HOST := $(HOST_OUT_EXECUTABLES)/avbtool
SMD_GEN_HOST := $(HOST_OUT_EXECUTABLES)/nv_smd_generator
MCOPY_HOST   := $(HOST_OUT_EXECUTABLES)/mcopy
MMD_HOST     := $(HOST_OUT_EXECUTABLES)/mmd
MKFSFAT_HOST := $(HOST_OUT_EXECUTABLES)/mformat
LPFLASH_HOST := $(HOST_OUT_EXECUTABLES)/lpflash

ifneq ($(TARGET_TEGRA_KERNEL),4.9)
DTB_SUBFOLDER := nvidia/
endif

include $(CLEAR_VARS)
LOCAL_MODULE        := p2972_flash_package
LOCAL_MODULE_SUFFIX := .txz
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)

_p2972_package_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_p2972_package_archive := $(_p2972_package_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

$(_p2972_package_archive): $(INSTALLED_KERNEL_TARGET) $(INSTALLED_RECOVERYIMAGE_TARGET) $(TOYBOX_HOST) $(AVBTOOL_HOST) $(SMD_GEN_HOST) $(INSTALLED_SUPER_EMPTY_TARGET) $(MCOPY_HOST) $(MMD_HOST) $(MKFSFAT_HOST) $(LPFLASH_HOST) $(INSTALLED_NVDISP_INIT_TARGET) $(INSTALLED_TIANOCORE_TARGET) $(INSTALLED_RLAUNCHER_TARGET) $(INSTALLED_EDK2_DTBO_TARGET)
	@mkdir -p $(dir $@)/tegraflash
	@mkdir -p $(dir $@)/scripts
	@cp $(TEGRAFLASH_PATH)/tegraflash* $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/*_v2 $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/tegraopenssl $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/tegrasign_v3* $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/sw_memcfg_overlay.pl $(dir $@)/tegraflash/
	@cp -R $(TEGRAFLASH_PATH)/pyfdt $(dir $@)/tegraflash/
	@cp $(COMMON_FLASH)/*.sh $(dir $@)/scripts/
	@cp $(GALEN_FLASH)/p2972.sh $(dir $@)/flash.sh
	@LINEAGEVER=$(shell BUILD_TOP=$(abspath $(BUILD_TOP)) python $(COMMON_FLASH)/get_branch_name.py) && \
	$(TOYBOX_HOST) sed -i "s/REPLACEME/$${LINEAGEVER}/" $(dir $@)/flash.sh
	@cp $(GALEN_FLASH)/flash_android_t194_sdmmc.xml $(dir $@)/
	@cp $(T194_BL)/* $(dir $@)/
	@rm $(dir $@)/BOOTAA64.efi
	@rm $(dir $@)/nvdisp-init.bin
	@cp $(INSTALLED_NVDISP_INIT_TARGET) $(dir $@)/
	@truncate -s 393216 $(dir $@)/nvdisp-init.bin
	@cat $(dir $@)/nvdisp-init.bin $(INSTALLED_TIANOCORE_TARGET) > $(dir $@)/nvdisp_uefi_jetson.bin
	@rm $(dir $@)/nvdisp-init.bin
	@rm $(dir $@)/uefi_jetson.bin
	@cp $(T194_FW)/xusb/tegra19x_xusb_firmware $(dir $@)/xusb_sil_rel_fw
	@$(SMD_GEN_HOST) $(dir $@)/slot_metadata.bin
	@$(AVBTOOL_HOST) make_vbmeta_image --flags 2 --padding_size 256 --output $(dir $@)/vbmeta_skip.img
	@cp $(INSTALLED_RECOVERYIMAGE_TARGET) $(dir $@)/
	@touch $(dir $@)/super_meta_only.img
	@$(LPFLASH_HOST) $(dir $@)/super_meta_only.img $(INSTALLED_SUPER_EMPTY_TARGET)
	@cp $(PRODUCT_OUT)/AndroidConfiguration.dtbo $(dir $@)/
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra194-p2888-0001-p2822-0000.dtb $(dir $@)/
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra194-p2888-0001-p2822-0000-overlay.dtbo $(dir $@)/
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra194-p2888-0005-overlay.dtbo $(dir $@)/
	@cp $(GALEN_BCT)/*p2888* $(dir $@)/
	@mv $(dir $@)/tegra194-a02-bpmp-p2888-a04.dtb $(dir $@)/tegra194-a02-bpmp-p2888-0001-a04.dtb
	@cp $(GALEN_BCT)/tegra194-br-bct-sdmmc.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-br-bct_b-sdmmc.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-bct-misc-*.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-bct-scr-cbb-mini.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-soft-fuses-l4t.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-memcfg-sw-override.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra19x-mb1-bct-device-sdmmc.cfg $(dir $@)/
	@dd if=/dev/zero of=$(dir $@)/esp.img bs=1M count=64
	@$(MKFSFAT_HOST) -F -i $(dir $@)/esp.img ::
	@$(MMD_HOST) -i $(dir $@)/esp.img ::/EFI
	@$(MMD_HOST) -i $(dir $@)/esp.img ::/EFI/BOOT
	@$(MCOPY_HOST) -i $(dir $@)/esp.img $(INSTALLED_RLAUNCHER_TARGET) ::/EFI/BOOT/BOOTAA64.efi
	@cd $(dir $@); tar -cJf $(abspath $@) *

include $(BUILD_SYSTEM)/base_rules.mk

include $(CLEAR_VARS)
LOCAL_MODULE        := p3518_flash_package
LOCAL_MODULE_SUFFIX := .txz
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)

_p3518_package_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_p3518_package_archive := $(_p3518_package_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

$(_p3518_package_archive): $(INSTALLED_KERNEL_TARGET) $(INSTALLED_RECOVERYIMAGE_TARGET) $(TOYBOX_HOST) $(AVBTOOL_HOST) $(SMD_GEN_HOST) $(INSTALLED_SUPER_EMPTY_TARGET) $(MCOPY_HOST) $(MMD_HOST) $(MKFSFAT_HOST) $(LPFLASH_HOST) $(INSTALLED_NVDISP_INIT_TARGET) $(INSTALLED_TIANOCORE_TARGET) $(INSTALLED_RLAUNCHER_TARGET) $(INSTALLED_EDK2_DTBO_TARGET)
	@mkdir -p $(dir $@)/tegraflash
	@mkdir -p $(dir $@)/scripts
	@cp $(TEGRAFLASH_PATH)/tegraflash* $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/*_v2 $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/tegraopenssl $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/tegrasign_v3* $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/sw_memcfg_overlay.pl $(dir $@)/tegraflash/
	@cp -R $(TEGRAFLASH_PATH)/pyfdt $(dir $@)/tegraflash/
	@cp $(COMMON_FLASH)/*.sh $(dir $@)/scripts/
	@cp $(GALEN_FLASH)/p3518.sh $(dir $@)/flash.sh
	@LINEAGEVER=$(shell BUILD_TOP=$(abspath $(BUILD_TOP)) python $(COMMON_FLASH)/get_branch_name.py) && \
	$(TOYBOX_HOST) sed -i "s/REPLACEME/$${LINEAGEVER}/" $(dir $@)/flash.sh
	@cp $(GALEN_FLASH)/flash_android_t194_spi_*_p3668.xml $(dir $@)/
	@cp $(T194_BL)/* $(dir $@)/
	@rm $(dir $@)/BOOTAA64.efi
	@rm $(dir $@)/nvdisp-init.bin
	@cp $(INSTALLED_NVDISP_INIT_TARGET) $(dir $@)/
	@truncate -s 393216 $(dir $@)/nvdisp-init.bin
	@cat $(dir $@)/nvdisp-init.bin $(INSTALLED_TIANOCORE_TARGET) > $(dir $@)/nvdisp_uefi_jetson.bin
	@rm $(dir $@)/nvdisp-init.bin
	@rm $(dir $@)/uefi_jetson.bin
	@cp $(T194_FW)/xusb/tegra19x_xusb_firmware $(dir $@)/xusb_sil_rel_fw
	@$(SMD_GEN_HOST) $(dir $@)/slot_metadata.bin
	@$(AVBTOOL_HOST) make_vbmeta_image --flags 2 --padding_size 256 --output $(dir $@)/vbmeta_skip.img
	@cp $(INSTALLED_RECOVERYIMAGE_TARGET) $(dir $@)/
	@touch $(dir $@)/super_meta_only.img
	@$(LPFLASH_HOST) $(dir $@)/super_meta_only.img $(INSTALLED_SUPER_EMPTY_TARGET)
	@cp $(PRODUCT_OUT)/AndroidConfiguration.dtbo $(dir $@)/
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra194-p3668-0000-p3509-0000-android.dtb $(dir $@)/
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra194-p3668-0001-p3509-0000-android.dtb $(dir $@)/
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)tegra194-p3668-p3509-overlay.dtbo $(dir $@)/
	@cp $(GALEN_BCT)/*p3668* $(dir $@)/
	@mv $(dir $@)/tegra194-a02-bpmp-p3668-a00.dtb $(dir $@)/tegra194-a02-bpmp.dtb
	@cp $(GALEN_BCT)/tegra194-br-bct-qspi-l4t.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-br-bct_b-qspi-l4t.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-bct-misc-*.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-soft-fuses-l4t.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-memcfg-sw-override.cfg $(dir $@)/
	@dd if=/dev/zero of=$(dir $@)/esp.img bs=1M count=64
	@$(MKFSFAT_HOST) -F -i $(dir $@)/esp.img ::
	@$(MMD_HOST) -i $(dir $@)/esp.img ::/EFI
	@$(MMD_HOST) -i $(dir $@)/esp.img ::/EFI/BOOT
	@$(MCOPY_HOST) -i $(dir $@)/esp.img $(INSTALLED_RLAUNCHER_TARGET) ::/EFI/BOOT/BOOTAA64.efi
	@cd $(dir $@); tar -cJf $(abspath $@) *

include $(BUILD_SYSTEM)/base_rules.mk
