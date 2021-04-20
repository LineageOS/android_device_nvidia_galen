LOCAL_PATH := $(call my-dir)

TEGRAFLASH_PATH := $(BUILD_TOP)/vendor/nvidia/common/tegraflash
T194_BL         := $(BUILD_TOP)/vendor/nvidia/t194/bootloader
T194_FW         := $(BUILD_TOP)/vendor/nvidia/t194/firmware
GALEN_BCT       := $(BUILD_TOP)/vendor/nvidia/galen/BCT
GALEN_FLASH     := $(BUILD_TOP)/device/nvidia/galen/flash_package
COMMON_FLASH    := $(BUILD_TOP)/device/nvidia/tegra-common/flash_package

TNSPEC_PY    := $(BUILD_TOP)/device/nvidia/tegra-common/tnspec/tnspec.py
GALEN_TNSPEC := $(BUILD_TOP)/device/nvidia/galen/tnspec/galen.json

INSTALLED_BMP_BLOB_TARGET      := $(PRODUCT_OUT)/bmp.blob
INSTALLED_CBOOT_TARGET         := $(PRODUCT_OUT)/cboot.bin
INSTALLED_RECOVERYIMAGE_TARGET := $(PRODUCT_OUT)/recovery.img

TOYBOX_HOST  := $(HOST_OUT_EXECUTABLES)/toybox
AWK_HOST     := $(HOST_OUT_EXECUTABLES)/one-true-awk
AVBTOOL_HOST := $(HOST_OUT_EXECUTABLES)/avbtool
SMD_GEN_HOST := $(HOST_OUT_EXECUTABLES)/nv_smd_generator

include $(CLEAR_VARS)
LOCAL_MODULE        := p2972_flash_package
LOCAL_MODULE_SUFFIX := .txz
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)

_p2972_package_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_p2972_package_archive := $(_p2972_package_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

$(_p2972_package_archive): $(INSTALLED_BMP_BLOB_TARGET) $(INSTALLED_CBOOT_TARGET) $(INSTALLED_RECOVERYIMAGE_TARGET) $(AWK_HOST) $(TOYBOX_HOST) $(AVBTOOL_HOST) $(SMD_GEN_HOST)
	@mkdir -p $(dir $@)/tegraflash
	@mkdir -p $(dir $@)/scripts
	@cp $(TEGRAFLASH_PATH)/tegraflash* $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/*_v2 $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/sw_memcfg_overlay.pl $(dir $@)/tegraflash/
	@cp $(COMMON_FLASH)/*.sh $(dir $@)/scripts/
	@cp $(GALEN_FLASH)/p2972.sh $(dir $@)/flash.sh
	@cp $(GALEN_FLASH)/flash_android_t194_sdmmc.xml $(dir $@)/
	@cp $(T194_BL)/* $(dir $@)/
	@cp $(T194_FW)/xusb/tegra19x_xusb_firmware $(dir $@)/xusb_sil_rel_fw
	@python2 $(TNSPEC_PY) nct new p2972-0004-devkit-e00 -o $(dir $@)/p2972-0004-devkit-e00.bin --spec $(GALEN_TNSPEC)
	@cp $(INSTALLED_BMP_BLOB_TARGET) $(dir $@)/
	@$(SMD_GEN_HOST) $(dir $@)/slot_metadata.bin
	@$(AVBTOOL_HOST) make_vbmeta_image --flags 2 --padding_size 256 --output $(dir $@)/vbmeta_skip.img
	@cp $(INSTALLED_CBOOT_TARGET) $(dir $@)/cboot_t194.bin
	@cp $(INSTALLED_RECOVERYIMAGE_TARGET) $(dir $@)/
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/tegra194-p2888-0001-p2822-0000.dtb $(dir $@)/
	@cp $(GALEN_BCT)/*p2888* $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-br-bct-sdmmc.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-bct-misc-*.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-bct-scr-cbb-mini.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-soft-fuses-l4t.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-memcfg-sw-override.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra19x-mb1-bct-device-sdmmc.cfg $(dir $@)/
	@echo "NV3" > $(dir $@)/emmc_bootblob_ver.txt
	@echo "# R17 , REVISION: 1" >> $(dir $@)/emmc_bootblob_ver.txt
	@echo "BOARDID=2888 BOARDSKU=0001 FAB=400" >> $(dir $@)/emmc_bootblob_ver.txt
	@$(TOYBOX_HOST) date '+%Y%m%d%H%M%S' >> $(dir $@)/emmc_bootblob_ver.txt
	@$(TOYBOX_HOST) cksum $(dir $@)/emmc_bootblob_ver.txt |$(AWK_HOST) '{ print "BYTES:" $$2, "CRC32:" $$1 }' >> $(dir $@)/emmc_bootblob_ver.txt
	@cd $(dir $@); tar -cJf $(abspath $@) *

include $(BUILD_SYSTEM)/base_rules.mk

include $(CLEAR_VARS)
LOCAL_MODULE        := p3518_flash_package
LOCAL_MODULE_SUFFIX := .txz
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)

_p3518_package_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_p3518_package_archive := $(_p3518_package_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

$(_p3518_package_archive): $(INSTALLED_BMP_BLOB_TARGET) $(INSTALLED_CBOOT_TARGET) $(INSTALLED_RECOVERYIMAGE_TARGET) $(AWK_HOST) $(TOYBOX_HOST) $(AVBTOOL_HOST) $(SMD_GEN_HOST)
	@mkdir -p $(dir $@)/tegraflash
	@mkdir -p $(dir $@)/scripts
	@cp $(TEGRAFLASH_PATH)/tegraflash* $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/*_v2 $(dir $@)/tegraflash/
	@cp $(TEGRAFLASH_PATH)/sw_memcfg_overlay.pl $(dir $@)/tegraflash/
	@cp $(COMMON_FLASH)/*.sh $(dir $@)/scripts/
	@cp $(GALEN_FLASH)/p3518.sh $(dir $@)/flash.sh
	@cp $(GALEN_FLASH)/flash_android_t194_spi_*_p3668.xml $(dir $@)/
	@cp $(T194_BL)/* $(dir $@)/
	@cp $(T194_FW)/xusb/tegra19x_xusb_firmware $(dir $@)/xusb_sil_rel_fw
	@python2 $(TNSPEC_PY) nct new p3518-0000-devkit -o $(dir $@)/p3518-0000-devkit.bin --spec $(GALEN_TNSPEC)
	@python2 $(TNSPEC_PY) nct new p3518-0001-devkit -o $(dir $@)/p3518-0001-devkit.bin --spec $(GALEN_TNSPEC)
	@cp $(INSTALLED_BMP_BLOB_TARGET) $(dir $@)/
	@$(SMD_GEN_HOST) $(dir $@)/slot_metadata.bin
	@$(AVBTOOL_HOST) make_vbmeta_image --flags 2 --padding_size 256 --output $(dir $@)/vbmeta_skip.img
	@cp $(INSTALLED_CBOOT_TARGET) $(dir $@)/cboot_t194.bin
	@cp $(INSTALLED_RECOVERYIMAGE_TARGET) $(dir $@)/
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/tegra194-p3668-all-p3509-0000-android.dtb $(dir $@)/
	@cp $(GALEN_BCT)/*p3668* $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-br-bct-qspi.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-bct-misc-*.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-mb1-soft-fuses-l4t.cfg $(dir $@)/
	@cp $(GALEN_BCT)/tegra194-memcfg-sw-override.cfg $(dir $@)/
	@echo "NV3" > $(dir $@)/qspi_sd_bootblob_ver.txt
	@echo "# R17 , REVISION: 1" >> $(dir $@)/qspi_sd_bootblob_ver.txt
	@echo "BOARDID=3668 BOARDSKU=0000 FAB=100" >> $(dir $@)/qspi_sd_bootblob_ver.txt
	@$(TOYBOX_HOST) date '+%Y%m%d%H%M%S' >> $(dir $@)/qspi_sd_bootblob_ver.txt
	@$(TOYBOX_HOST) cksum $(dir $@)/qspi_sd_bootblob_ver.txt |$(AWK_HOST) '{ print "BYTES:" $$2, "CRC32:" $$1 }' >> $(dir $@)/qspi_sd_bootblob_ver.txt
	@echo "NV3" > $(dir $@)/qspi_emmc_bootblob_ver.txt
	@echo "# R17 , REVISION: 1" >> $(dir $@)/qspi_emmc_bootblob_ver.txt
	@echo "BOARDID=3668 BOARDSKU=0001 FAB=100" >> $(dir $@)/qspi_emmc_bootblob_ver.txt
	@$(TOYBOX_HOST) date '+%Y%m%d%H%M%S' >> $(dir $@)/qspi_emmc_bootblob_ver.txt
	@$(TOYBOX_HOST) cksum $(dir $@)/qspi_emmc_bootblob_ver.txt |$(AWK_HOST) '{ print "BYTES:" $$2, "CRC32:" $$1 }' >> $(dir $@)/qspi_emmc_bootblob_ver.txt
	@cd $(dir $@); tar -cJf $(abspath $@) *

include $(BUILD_SYSTEM)/base_rules.mk
