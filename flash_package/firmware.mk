LOCAL_PATH := $(call my-dir)

TEGRAFLASH_PATH := $(BUILD_TOP)/vendor/nvidia/common/tegraflash
T194_BL         := $(BUILD_TOP)/vendor/nvidia/t194/bootloader
GALEN_BCT       := $(BUILD_TOP)/vendor/nvidia/galen/BCT
GALEN_FLASH     := $(BUILD_TOP)/device/nvidia/galen/flash_package

INSTALLED_CBOOT_TARGET  := $(PRODUCT_OUT)/cboot.bin
INSTALLED_KERNEL_TARGET := $(PRODUCT_OUT)/kernel

ifeq ($(PRODUCT_USE_DYNAMIC_PARTITIONS),true)
GALEN_PARTS    := flash_android_t194_sdmmc.dynamic.xml
REY_EMMC_PARTS := flash_android_t194_spi_emmc_p3668.dynamic.xml
REY_SD_PARTS   := flash_android_t194_spi_sd_p3668.dynamic.xml
else
GALEN_PARTS    := flash_android_t194_sdmmc.xml
REY_EMMC_PARTS := flash_android_t194_spi_emmc_p3668.xml
REY_SD_PARTS   := flash_android_t194_spi_sd_p3668.xml
endif

include $(CLEAR_VARS)
LOCAL_MODULE               := bl_update_payload
LOCAL_MODULE_CLASS         := ETC
LOCAL_MODULE_RELATIVE_PATH := firmware

_galen_blob_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_galen_blob := $(_galen_blob_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

GALEN_SIGNED_PATH    := $(_galen_blob_intermediates)/p2972-signed
REY_SD_SIGNED_PATH   := $(_galen_blob_intermediates)/p3518-0000-signed
REY_EMMC_SIGNED_PATH := $(_galen_blob_intermediates)/p3518-0001-signed

_galen_br_bct    := $(GALEN_SIGNED_PATH)/br_bct_BR.bct
_rey_sd_br_bct   := $(REY_SD_SIGNED_PATH)/br_bct_BR.bct
_rey_emmc_br_bct := $(REY_EMMC_SIGNED_PATH)/br_bct_BR.bct

$(_galen_br_bct): $(INSTALLED_CBOOT_TARGET) $(INSTALLED_KERNEL_TARGET)
	@mkdir -p $(dir $@)
	@cp $(GALEN_FLASH)/$(GALEN_PARTS) $(dir $@)/flash_android_t194_sdmmc.xml.tmp
	@cp $(T194_BL)/* $(dir $@)/
	@cp $(INSTALLED_CBOOT_TARGET) $(dir $@)/cboot_t194.bin
	@cp $(GALEN_BCT)/tegra194-a02-bpmp-p2888-a04.dtb $(dir $@)/
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/tegra194-p2888-0001-p2822-0000.dtb $(dir $@)/
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraparser_v2 --pt flash_android_t194_sdmmc.xml.tmp
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 0 --partitionlayout flash_android_t194_sdmmc.xml.bin --list images_list.xml zerosbk
	cd $(dir $@); $(TEGRAFLASH_PATH)/sw_memcfg_overlay.pl -c $(GALEN_BCT)/tegra194-mb1-bct-memcfg-p2888.cfg -s $(GALEN_BCT)/tegra194-memcfg-sw-override.cfg -o memcfg.cfg
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --dev_param $(GALEN_BCT)/tegra194-br-bct-sdmmc.cfg --sdram memcfg.cfg --brbct br_bct.cfg --sfuse $(GALEN_BCT)/tegra194-mb1-soft-fuses-l4t.cfg --chip 0x19 0
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x19 0 --updateblinfo flash_android_t194_sdmmc.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrasign_v2 --key None --list images_list.xml --pubkeyhash pub_key.key
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --dev_param $(GALEN_BCT)/tegra194-br-bct-sdmmc.cfg --sdram memcfg.cfg --brbct br_bct.cfg --sfuse $(GALEN_BCT)/tegra194-mb1-soft-fuses-l4t.cfg --chip 0x19 0
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x19 0 --updateblinfo flash_android_t194_sdmmc.xml.bin --updatesig images_list_signed.xml
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x19 --updatesmdinfo flash_android_t194_sdmmc.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraparser_v2 --chip 0x19 --updatecustinfo br_bct_BR.bct
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x19 0 --updatefields "Odmdata =0x9190000"
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x19 0 --listbct bct_list.xml
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrasign_v2 --key None --list bct_list.xml --pubkeyhash pub_key.key --getmontgomeryvalues montgomery.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x19 0 --updatesig bct_list_signed.xml
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x19 0 --mb1bct mb1_cold_boot_bct.cfg --sdram memcfg.cfg --misc $(GALEN_BCT)/tegra194-mb1-bct-misc-l4t.cfg --scr $(GALEN_BCT)/tegra194-mb1-bct-scr-cbb-mini.cfg --pinmux $(GALEN_BCT)/tegra19x-mb1-pinmux-p2888-0000-a04-p2822-0000-b01.cfg --pmc $(GALEN_BCT)/tegra19x-mb1-padvoltage-p2888-0000-a00-p2822-0000-a00.cfg --pmic $(GALEN_BCT)/tegra194-mb1-bct-pmic-p2888-0001-a04-E-0-p2822-0000.cfg --brcommand $(GALEN_BCT)/tegra194-mb1-bct-reset-p2888-0000-p2822-0000.cfg --prod $(GALEN_BCT)/tegra19x-mb1-prod-p2888-0000-p2822-0000.cfg --gpioint $(GALEN_BCT)/tegra194-mb1-bct-gpioint-p2888-0000-p2822-0000.cfg --uphy $(GALEN_BCT)/tegra194-mb1-uphy-lane-p2888-0000-p2822-0000.cfg --device $(GALEN_BCT)/tegra19x-mb1-bct-device-sdmmc.cfg
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x19 --mb1bct mb1_cold_boot_bct_MB1.bct --updatefwinfo flash_android_t194_sdmmc.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x19 --mb1bct mb1_cold_boot_bct_MB1.bct --updatestorageinfo flash_android_t194_sdmmc.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 --align mb1_cold_boot_bct_MB1.bct
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 0 --magicid MBCT --appendsigheader mb1_cold_boot_bct_MB1.bct zerosbk
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraflash.py --chip 0x19 --cmd "sign mb1_cold_boot_bct_MB1_sigheader.bct"
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x19 0 --sdram memcfg.cfg --membct memcfg_1.bct memcfg_2.bct memcfg_3.bct memcfg_4.bct
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 0 --blocksize 512 --magicid MEMB --addsigheader_multi memcfg_1.bct memcfg_2.bct memcfg_3.bct memcfg_4.bct
	@mv $(dir $@)/memcfg_1_sigheader.bct $(dir $@)/mem_coldboot.bct
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 --align mem_coldboot.bct
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 0 --magicid MEMB --appendsigheader mem_coldboot.bct zerosbk
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraflash.py --chip 0x19 --cmd "sign mem_coldboot_sigheader.bct"
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 0 --partitionlayout flash_android_t194_sdmmc.xml.bin --updatesig images_list_signed.xml

$(_rey_emmc_br_bct): $(INSTALLED_CBOOT_TARGET) $(INSTALLED_KERNEL_TARGET)
	@mkdir -p $(dir $@)
	@cp $(GALEN_FLASH)/$(REY_EMMC_PARTS) $(dir $@)/flash_android_t194_spi_emmc_p3668.xml.tmp
	@cp $(T194_BL)/* $(dir $@)/
	@cp $(INSTALLED_CBOOT_TARGET) $(dir $@)/cboot_t194.bin
	@cp $(GALEN_BCT)/tegra194-a02-bpmp-p3668-a00.dtb $(dir $@)/
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/tegra194-p3668-all-p3509-0000-android.dtb $(dir $@)/
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraparser_v2 --pt flash_android_t194_spi_emmc_p3668.xml.tmp
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 0 --partitionlayout flash_android_t194_spi_emmc_p3668.xml.bin --list images_list.xml zerosbk
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrasign_v2 --key None --list images_list.xml --pubkeyhash pub_key.key
	cd $(dir $@); $(TEGRAFLASH_PATH)/sw_memcfg_overlay.pl -c $(GALEN_BCT)/tegra194-mb1-bct-memcfg-p3668-0001-a00.cfg -s $(GALEN_BCT)/tegra194-memcfg-sw-override.cfg -o memcfg.cfg
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x19 0 --mb1bct mb1_cold_boot_bct.cfg --sdram memcfg.cfg --misc $(GALEN_BCT)/tegra194-mb1-bct-misc-l4t.cfg --scr $(GALEN_BCT)/tegra194-mb1-bct-scr-cbb-mini-p3668.cfg --pinmux $(GALEN_BCT)/tegra19x-mb1-pinmux-p3668-a01.cfg --pmc $(GALEN_BCT)/tegra19x-mb1-padvoltage-p3668-a01.cfg --pmic $(GALEN_BCT)/tegra194-mb1-bct-pmic-p3668-0001-a00.cfg --brcommand $(GALEN_BCT)/tegra194-mb1-bct-reset-p3668-0001-a00.cfg --prod $(GALEN_BCT)/tegra19x-mb1-prod-p3668-0001-a00.cfg --gpioint $(GALEN_BCT)/tegra194-mb1-bct-gpioint-p3668-0001-a00.cfg --device $(GALEN_BCT)/tegra19x-mb1-bct-device-qspi-p3668.cfg
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x19 --mb1bct mb1_cold_boot_bct_MB1.bct --updatefwinfo flash_android_t194_spi_emmc_p3668.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x19 --mb1bct mb1_cold_boot_bct_MB1.bct --updatestorageinfo flash_android_t194_spi_emmc_p3668.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 --align mb1_cold_boot_bct_MB1.bct
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 0 --magicid MBCT --appendsigheader mb1_cold_boot_bct_MB1.bct zerosbk
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraflash.py --chip 0x19 --cmd "sign mb1_cold_boot_bct_MB1_sigheader.bct"

$(_rey_sd_br_bct): $(INSTALLED_CBOOT_TARGET) $(INSTALLED_KERNEL_TARGET)
	@mkdir -p $(dir $@)
	@cp $(GALEN_FLASH)/$(REY_SD_PARTS) $(dir $@)/flash_android_t194_spi_sd_p3668.xml.tmp
	@cp $(T194_BL)/* $(dir $@)/
	@cp $(INSTALLED_CBOOT_TARGET) $(dir $@)/cboot_t194.bin
	@cp $(GALEN_BCT)/tegra194-a02-bpmp-p3668-a00.dtb $(dir $@)/
	@cp $(KERNEL_OUT)/arch/arm64/boot/dts/tegra194-p3668-all-p3509-0000-android.dtb $(dir $@)/
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraparser_v2 --pt flash_android_t194_spi_sd_p3668.xml.tmp
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 0 --partitionlayout flash_android_t194_spi_sd_p3668.xml.bin --list images_list.xml zerosbk
	cd $(dir $@); $(TEGRAFLASH_PATH)/sw_memcfg_overlay.pl -c $(GALEN_BCT)/tegra194-mb1-bct-memcfg-p3668-0001-a00.cfg -s $(GALEN_BCT)/tegra194-memcfg-sw-override.cfg -o memcfg.cfg
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --dev_param $(GALEN_BCT)/tegra194-br-bct-qspi.cfg --sdram memcfg.cfg --brbct br_bct.cfg --sfuse $(GALEN_BCT)/tegra194-mb1-soft-fuses-l4t.cfg --chip 0x19 0
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x19 0 --updateblinfo flash_android_t194_spi_sd_p3668.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrasign_v2 --key None --list images_list.xml --pubkeyhash pub_key.key
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --dev_param $(GALEN_BCT)/tegra194-br-bct-qspi.cfg --sdram memcfg.cfg --brbct br_bct.cfg --sfuse $(GALEN_BCT)/tegra194-mb1-soft-fuses-l4t.cfg --chip 0x19 0
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x19 0 --updateblinfo flash_android_t194_spi_sd_p3668.xml.bin --updatesig images_list_signed.xml
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x19 --updatesmdinfo flash_android_t194_spi_sd_p3668.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraparser_v2 --chip 0x19 --updatecustinfo br_bct_BR.bct
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x19 0 --updatefields "Odmdata =0xB8190000"
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x19 0 --listbct bct_list.xml
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrasign_v2 --key None --list bct_list.xml --pubkeyhash pub_key.key --getmontgomeryvalues montgomery.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --brbct br_bct_BR.bct --chip 0x19 0 --updatesig bct_list_signed.xml
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x19 0 --mb1bct mb1_cold_boot_bct.cfg --sdram memcfg.cfg --misc $(GALEN_BCT)/tegra194-mb1-bct-misc-l4t.cfg --scr $(GALEN_BCT)/tegra194-mb1-bct-scr-cbb-mini-p3668.cfg --pinmux $(GALEN_BCT)/tegra19x-mb1-pinmux-p3668-a01.cfg --pmc $(GALEN_BCT)/tegra19x-mb1-padvoltage-p3668-a01.cfg --pmic $(GALEN_BCT)/tegra194-mb1-bct-pmic-p3668-0001-a00.cfg --brcommand $(GALEN_BCT)/tegra194-mb1-bct-reset-p3668-0001-a00.cfg --prod $(GALEN_BCT)/tegra19x-mb1-prod-p3668-0001-a00.cfg --gpioint $(GALEN_BCT)/tegra194-mb1-bct-gpioint-p3668-0001-a00.cfg --device $(GALEN_BCT)/tegra19x-mb1-bct-device-qspi-p3668.cfg
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x19 --mb1bct mb1_cold_boot_bct_MB1.bct --updatefwinfo flash_android_t194_spi_sd_p3668.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x19 --mb1bct mb1_cold_boot_bct_MB1.bct --updatestorageinfo flash_android_t194_spi_sd_p3668.xml.bin
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 --align mb1_cold_boot_bct_MB1.bct
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 0 --magicid MBCT --appendsigheader mb1_cold_boot_bct_MB1.bct zerosbk
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraflash.py --chip 0x19 --cmd "sign mb1_cold_boot_bct_MB1_sigheader.bct"
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrabct_v2 --chip 0x19 0 --sdram memcfg.cfg --membct memcfg_1.bct memcfg_2.bct memcfg_3.bct memcfg_4.bct
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 0 --blocksize 512 --magicid MEMB --addsigheader_multi memcfg_1.bct memcfg_2.bct memcfg_3.bct memcfg_4.bct
	@mv $(dir $@)/memcfg_1_sigheader.bct $(dir $@)/mem_coldboot.bct
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 --align mem_coldboot.bct
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 0 --magicid MEMB --appendsigheader mem_coldboot.bct zerosbk
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegraflash.py --chip 0x19 --cmd "sign mem_coldboot_sigheader.bct"
	cd $(dir $@); $(TEGRAFLASH_PATH)/tegrahost_v2 --chip 0x19 0 --partitionlayout flash_android_t194_spi_sd_p3668.xml.bin --updatesig images_list_signed.xml

$(_galen_blob): $(_galen_br_bct) $(_rey_sd_br_bct) $(_rey_emmc_br_bct) $(INSTALLED_KERNEL_TARGET)
	@mkdir -p $(dir $@)
	OUT=$(dir $@) TOP=$(BUILD_TOP) python2 $(TEGRAFLASH_PATH)/BUP_generator.py -t update -e \
		"$(GALEN_SIGNED_PATH)/spe_t194_sigheader.bin.encrypt spe-fw 2 0 common; \
		 $(GALEN_SIGNED_PATH)/nvtboot_t194_sigheader.bin.encrypt mb2 2 0 common; \
		 $(GALEN_SIGNED_PATH)/cboot_t194_sigheader.bin.encrypt cpu-bootloader 2 0 common; \
		 $(GALEN_SIGNED_PATH)/tos-mon-only_t194_sigheader.img.encrypt secure-os 2 0 common; \
		 $(GALEN_SIGNED_PATH)/bpmp_t194_sigheader.bin.encrypt bpmp-fw 2 0 common; \
		 $(GALEN_SIGNED_PATH)/adsp-fw_sigheader.bin.encrypt adsp-fw 2 0 common; \
		 $(GALEN_SIGNED_PATH)/camera-rtcpu-rce_sigheader.img.encrypt rce-fw 2 0 common; \
		 $(GALEN_SIGNED_PATH)/preboot_c10_prod_cr_sigheader.bin.encrypt mts-preboot 2 2 common; \
		 $(GALEN_SIGNED_PATH)/mce_c10_prod_cr_sigheader.bin.encrypt mts-mce 2 2 common; \
		 $(GALEN_SIGNED_PATH)/mts_c10_prod_cr_sigheader.bin.encrypt mts-proper 2 2 common; \
		 $(GALEN_SIGNED_PATH)/warmboot_t194_prod_sigheader.bin.encrypt sc7 2 2 common; \
		 $(GALEN_SIGNED_PATH)/mb1_t194_prod_sigheader.bin.encrypt mb1 2 2 P2972-0004-DEVKIT-E00.default; \
		 $(GALEN_SIGNED_PATH)/tegra194-a02-bpmp-p2888-a04_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 P2972-0004-DEVKIT-E00.default; \
		 $(GALEN_SIGNED_PATH)/tegra194-p2888-0001-p2822-0000_sigheader.dtb.encrypt bootloader-dtb 2 0 P2972-0004-DEVKIT-E00.default; \
		 $(KERNEL_OUT)/arch/arm64/boot/dts/tegra194-p2888-0001-p2822-0000.dtb kernel-dtb 2 0 P2972-0004-DEVKIT-E00.default; \
		 $(GALEN_SIGNED_PATH)/br_bct_BR.bct BCT 2 2 P2972-0004-DEVKIT-E00.default; \
		 $(GALEN_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct MB1_BCT 2 0 P2972-0004-DEVKIT-E00.default; \
		 $(GALEN_SIGNED_PATH)/mem_coldboot_sigheader.bct MEM_BCT 2 0 P2972-0004-DEVKIT-E00.default; \
		 $(REY_SD_SIGNED_PATH)/mb1_t194_prod_sigheader.bin.encrypt mb1 2 2 P3518-0000-DEVKIT.default; \
		 $(REY_SD_SIGNED_PATH)/tegra194-a02-bpmp-p3668-a00_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 P3518-0000-DEVKIT.default; \
		 $(REY_SD_SIGNED_PATH)/tegra194-p3668-all-p3509-0000-android_sigheader.dtb.encrypt bootloader-dtb 2 0 P3518-0000-DEVKIT.default; \
		 $(KERNEL_OUT)/arch/arm64/boot/dts/tegra194-p3668-all-p3509-0000-android.dtb kernel-dtb 2 0 P3518-0000-DEVKIT.default; \
		 $(REY_SD_SIGNED_PATH)/br_bct_BR.bct BCT 2 2 P3518-0000-DEVKIT.default; \
		 $(REY_SD_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct MB1_BCT 2 0 P3518-0000-DEVKIT.default; \
		 $(REY_SD_SIGNED_PATH)/mem_coldboot_sigheader.bct MEM_BCT 2 0 P3518-0000-DEVKIT.default; \
		 $(REY_SD_SIGNED_PATH)/mb1_t194_prod_sigheader.bin.encrypt mb1 2 2 P3518-0001-DEVKIT.default; \
		 $(REY_SD_SIGNED_PATH)/tegra194-a02-bpmp-p3668-a00_sigheader.dtb.encrypt bpmp-fw-dtb 2 0 P3518-0001-DEVKIT.default; \
		 $(REY_SD_SIGNED_PATH)/tegra194-p3668-all-p3509-0000-android_sigheader.dtb.encrypt bootloader-dtb 2 0 P3518-0001-DEVKIT.default; \
		 $(KERNEL_OUT)/arch/arm64/boot/dts/tegra194-p3668-all-p3509-0000-android.dtb kernel-dtb 2 0 P3518-0001-DEVKIT.default; \
		 $(REY_SD_SIGNED_PATH)/br_bct_BR.bct BCT 2 2 P3518-0001-DEVKIT.default; \
		 $(REY_EMMC_SIGNED_PATH)/mb1_cold_boot_bct_MB1_sigheader.bct MB1_BCT 2 0 P3518-0001-DEVKIT.default; \
		 $(REY_SD_SIGNED_PATH)/mem_coldboot_sigheader.bct MEM_BCT 2 0 P3518-0001-DEVKIT.default"
	@mv $(dir $@)/ota.blob $@

include $(BUILD_SYSTEM)/base_rules.mk

include $(CLEAR_VARS)
LOCAL_MODULE               := bmp_update_payload
LOCAL_MODULE_STEM          := bmp.blob
LOCAL_MODULE_CLASS         := ETC
LOCAL_MODULE_RELATIVE_PATH := firmware

INSTALLED_BMP_BLOB_TARGET := $(PRODUCT_OUT)/bmp.blob

_bmp_blob_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_bmp_blob := $(_bmp_blob_intermediates)/$(LOCAL_MODULE_STEM)

$(_bmp_blob): $(INSTALLED_BMP_BLOB_TARGET)
	@mkdir -p $(dir $@)
	@cp $(INSTALLED_BMP_BLOB_TARGET) $@

include $(BUILD_SYSTEM)/base_rules.mk
