LOCAL_PATH := $(call my-dir)

TEGRAFLASH_PATH := $(BUILD_TOP)/vendor/nvidia/common/r35/tegraflash
T194_BL         := $(BUILD_TOP)/vendor/nvidia/t194/r35/bootloader
T194_FW         := $(BUILD_TOP)/vendor/nvidia/t194/r35/firmware
GALEN_BL        := $(BUILD_TOP)/vendor/nvidia/galen/r35/bootloader
GALEN_BCT       := $(BUILD_TOP)/vendor/nvidia/galen/r35/BCT
GALEN_FLASH     := $(BUILD_TOP)/device/nvidia/galen/flash_package
COMMON_FLASH    := $(BUILD_TOP)/device/nvidia/tegra-common/flash_package

INSTALLED_KERNEL_TARGET        := $(PRODUCT_OUT)/kernel
INSTALLED_RECOVERYIMAGE_TARGET := $(PRODUCT_OUT)/recovery.img
INSTALLED_SUPER_EMPTY_TARGET   := $(PRODUCT_OUT)/super_empty.img
INSTALLED_VENDORBOOT_TARGET    := $(PRODUCT_OUT)/vendor_boot.img
INSTALLED_TOS_TARGET           := $(PRODUCT_OUT)/tos-$(if $(filter software,$(TARGET_TEGRA_TOS)),mon-only,$(TARGET_TEGRA_TOS)).img
INSTALLED_NVDISP_INIT_TARGET   := $(PRODUCT_OUT)/nvdisp-init.bin
INSTALLED_TIANOCORE_TARGET     := $(PRODUCT_OUT)/tianocore.bin
INSTALLED_EDK2_DTBO_TARGET     := $(PRODUCT_OUT)/AndroidConfiguration.dtbo

TOYBOX_HOST  := $(HOST_OUT_EXECUTABLES)/toybox
AVBTOOL_HOST := $(HOST_OUT_EXECUTABLES)/avbtool
LPFLASH_HOST := $(HOST_OUT_EXECUTABLES)/lpflash

ifneq ($(TARGET_PREBUILT_KERNEL),)
DTB_PATH := $(dir $(TARGET_PREBUILT_KERNEL))
else ifneq ($(filter 4.9, $(TARGET_TEGRA_KERNEL)),)
DTB_PATH := $(abspath $(KERNEL_OUT)/arch/arm64/boot/dts)
else ifneq ($(findstring dtstree,$(TARGET_KERNEL_ADDITIONAL_FLAGS)),)
DTB_PATH := $(abspath $(KERNEL_OUT)/../lineage-oot/device-tree/platform/generic-dts/t19x/lineage)
else
DTB_PATH := $(abspath $(KERNEL_OUT)/arch/arm64/boot/dts/nvidia)
endif

include $(CLEAR_VARS)
LOCAL_MODULE        := p2972_flash_package
LOCAL_MODULE_SUFFIX := .txz
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)

_p2972_package_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_p2972_package_archive := $(_p2972_package_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

$(_p2972_package_archive): $(INSTALLED_KERNEL_TARGET) $(INSTALLED_RECOVERYIMAGE_TARGET) $(INSTALLED_VENDORBOOT_TARGET) $(TOYBOX_HOST) $(AVBTOOL_HOST) $(INSTALLED_SUPER_EMPTY_TARGET) $(LPFLASH_HOST) $(INSTALLED_TOS_TARGET) $(INSTALLED_NVDISP_INIT_TARGET) $(INSTALLED_TIANOCORE_TARGET) $(INSTALLED_EDK2_DTBO_TARGET)
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
	@rm $(dir $@)/tos-mon-only_t194.img
	@cp $(INSTALLED_TOS_TARGET) $(dir $@)/tos-mon-only_t194.img
	@rm $(dir $@)/BOOTAA64.efi
	@rm $(dir $@)/nvdisp-init.bin
	@cp $(INSTALLED_NVDISP_INIT_TARGET) $(dir $@)/
	@truncate -s 393216 $(dir $@)/nvdisp-init.bin
	@cat $(dir $@)/nvdisp-init.bin $(INSTALLED_TIANOCORE_TARGET) > $(dir $@)/nvdisp_uefi_jetson.bin
	@rm $(dir $@)/nvdisp-init.bin
	@rm $(dir $@)/uefi_jetson.bin
	@cp $(T194_FW)/xusb/tegra19x_xusb_firmware $(dir $@)/xusb_sil_rel_fw
	@$(AVBTOOL_HOST) make_vbmeta_image --flags 2 --padding_size 256 --output $(dir $@)/vbmeta_skip.img
	@cp $(INSTALLED_RECOVERYIMAGE_TARGET) $(dir $@)/
	@cp $(INSTALLED_VENDORBOOT_TARGET) $(dir $@)/
	@touch $(dir $@)/super_meta_only.img
	@$(LPFLASH_HOST) $(dir $@)/super_meta_only.img $(INSTALLED_SUPER_EMPTY_TARGET)
	@cp $(GALEN_BL)/tegra194-p2888-0001-p2822-0000.dtb $(dir $@)/tegra194-p2888-0001-p2822-0000-bl.dtb
	@cp $(PRODUCT_OUT)/AndroidConfiguration.dtbo $(dir $@)/
	@cp $(DTB_PATH)/tegra194-p2888-0001-p2822-0000.dtb $(dir $@)/
	@cp $(DTB_PATH)/tegra194-p2888-0001-p2822-0000-overlay.dtbo $(dir $@)/
	@cp $(DTB_PATH)/tegra194-p2888-0005-overlay.dtbo $(dir $@)/
	@cp $(GALEN_BCT)/*p2888* $(dir $@)/
	@mv $(dir $@)/tegra194-a02-bpmp-p2888-a04.dtb $(dir $@)/tegra194-a02-bpmp-p2888-0001-a04.dtb
	@cp $(GALEN_BCT)/tegra194-br-bct-sdmmc.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-br-bct_b-sdmmc.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-bct-misc-*.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-bct-scr-cbb-mini.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-soft-fuses-l4t.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-memcfg-sw-override.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra19x-mb1-bct-device-sdmmc.cfg $(dir $@)/
	@echo -n boot-recovery > $(dir $@)/misc.txt
	@cd $(dir $@); tar -cJf $(abspath $@) *

include $(BUILD_SYSTEM)/base_rules.mk

include $(CLEAR_VARS)
LOCAL_MODULE        := p3518_flash_package
LOCAL_MODULE_SUFFIX := .txz
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)

_p3518_package_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_p3518_package_archive := $(_p3518_package_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

$(_p3518_package_archive): $(INSTALLED_KERNEL_TARGET) $(INSTALLED_RECOVERYIMAGE_TARGET) $(INSTALLED_VENDORBOOT_TARGET) $(TOYBOX_HOST) $(AVBTOOL_HOST) $(INSTALLED_SUPER_EMPTY_TARGET) $(LPFLASH_HOST) $(INSTALLED_TOS_TARGET) $(INSTALLED_NVDISP_INIT_TARGET) $(INSTALLED_TIANOCORE_TARGET) $(INSTALLED_EDK2_DTBO_TARGET)
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
	@rm $(dir $@)/tos-mon-only_t194.img
	@cp $(INSTALLED_TOS_TARGET) $(dir $@)/tos-mon-only_t194.img
	@rm $(dir $@)/BOOTAA64.efi
	@rm $(dir $@)/nvdisp-init.bin
	@cp $(INSTALLED_NVDISP_INIT_TARGET) $(dir $@)/
	@truncate -s 393216 $(dir $@)/nvdisp-init.bin
	@cat $(dir $@)/nvdisp-init.bin $(INSTALLED_TIANOCORE_TARGET) > $(dir $@)/nvdisp_uefi_jetson.bin
	@rm $(dir $@)/nvdisp-init.bin
	@rm $(dir $@)/uefi_jetson.bin
	@cp $(T194_FW)/xusb/tegra19x_xusb_firmware $(dir $@)/xusb_sil_rel_fw
	@$(AVBTOOL_HOST) make_vbmeta_image --flags 2 --padding_size 256 --output $(dir $@)/vbmeta_skip.img
	@cp $(INSTALLED_RECOVERYIMAGE_TARGET) $(dir $@)/
	@cp $(INSTALLED_VENDORBOOT_TARGET) $(dir $@)/
	@touch $(dir $@)/super_meta_only.img
	@$(LPFLASH_HOST) $(dir $@)/super_meta_only.img $(INSTALLED_SUPER_EMPTY_TARGET)
	@cp $(GALEN_BL)/tegra194-p3668-0000-p3509-0000.dtb $(dir $@)/tegra194-p3668-0000-p3509-0000-bl.dtb
	@cp $(GALEN_BL)/tegra194-p3668-0001-p3509-0000.dtb $(dir $@)/tegra194-p3668-0001-p3509-0000-bl.dtb
	@cp $(PRODUCT_OUT)/AndroidConfiguration.dtbo $(dir $@)/
	@cp $(DTB_PATH)/tegra194-p3668-0000-p3509-0000-android.dtb $(dir $@)/
	@cp $(DTB_PATH)/tegra194-p3668-0001-p3509-0000-android.dtb $(dir $@)/
	@cp $(DTB_PATH)/tegra194-p3668-p3509-overlay.dtbo $(dir $@)/
	@cp $(GALEN_BCT)/*p3668* $(dir $@)/
	@mv $(dir $@)/tegra194-a02-bpmp-p3668-a00.dtb $(dir $@)/tegra194-a02-bpmp.dtb
	@cp $(GALEN_BCT)/tegra194-br-bct-qspi-l4t.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-br-bct_b-qspi-l4t.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-bct-misc-*.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-soft-fuses-l4t.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-memcfg-sw-override.cfg $(dir $@)/
	@echo -n boot-recovery > $(dir $@)/misc.txt
	@cd $(dir $@); tar -cJf $(abspath $@) *

include $(BUILD_SYSTEM)/base_rules.mk
