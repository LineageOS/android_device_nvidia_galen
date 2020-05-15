/*
   Copyright (c) 2013, The Linux Foundation. All rights reserved.
   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of The Linux Foundation nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
   THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
   ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
   BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
   OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "init_tegra.h"

#include <map>

void vendor_set_usb_product_ids(tegra_init *ti)
{
	std::map<std::string, std::string> mCommonUsbIds, mDeviceUsbIds;

	mCommonUsbIds["ro.vendor.nv.usb.vid"]                  = "0955";
	mCommonUsbIds["ro.vendor.nv.usb.pid.rndis.acm.adb"]    = "AF00";
	mCommonUsbIds["ro.vendor.nv.usb.pid.adb"]              = "7104";
	mCommonUsbIds["ro.vendor.nv.usb.pid.accessory.adb"]    = "7105";
	mCommonUsbIds["ro.vendor.nv.usb.pid.audio_source.adb"] = "7106";
	mCommonUsbIds["ro.vendor.nv.usb.pid.ncm"]              = "7107";
	mCommonUsbIds["ro.vendor.nv.usb.pid.ncm.adb"]          = "7108";
	mCommonUsbIds["ro.vendor.nv.usb.pid.midi"]             = "7109";
	mCommonUsbIds["ro.vendor.nv.usb.pid.midi.adb"]         = "710A";
	mCommonUsbIds["ro.vendor.nv.usb.pid.ecm"]              = "710B";
	mCommonUsbIds["ro.vendor.nv.usb.pid.ecm.adb"]          = "710C";

	mDeviceUsbIds["ro.vendor.nv.usb.pid.mtp"]              = "EE02";
	mDeviceUsbIds["ro.vendor.nv.usb.pid.mtp.adb"]          = "EE03";
	mDeviceUsbIds["ro.vendor.nv.usb.pid.ptp"]              = "EE04";
	mDeviceUsbIds["ro.vendor.nv.usb.pid.ptp.adb"]          = "EE05";
	mDeviceUsbIds["ro.vendor.nv.usb.pid.rndis"]            = "EE08";
	mDeviceUsbIds["ro.vendor.nv.usb.pid.rndis.adb"]        = "EE09";

	for (auto const& id : mDeviceUsbIds)
		ti->property_set(id.first, id.second);

	for (auto const& id : mCommonUsbIds)
		ti->property_set(id.first, id.second);
}

void vendor_load_properties()
{
	//                                              device    name            model              id    sku  boot device type                 api dpi
	std::vector<tegra_init::devices> devices = { { "galen", "jetson-xavier", "Jetson Xavier",    2972,   0, tegra_init::boot_dev_type::EMMC, 28, 320 },
	                                             { "rey"  , "rey",           "Jetson Xavier NX", 3668,   1, tegra_init::boot_dev_type::EMMC, 28, 320 },
	                                             { "rey"  , "rey",           "Jetson Xavier NX", 3668,   0, tegra_init::boot_dev_type::SD,   28, 320 } };
	tegra_init::build_version tav = { "9", "PPR1.180610.011", "4199485_1739.5219" };

	tegra_init ti(devices);
	ti.set_properties();
	ti.set_fingerprints(tav);

	if (ti.recovery_context()) {
		ti.property_set("ro.product.vendor.model", ti.property_get("ro.product.model"));
		ti.property_set("ro.product.vendor.manufacturer", ti.property_get("ro.product.manufacturer"));
	}

	if (ti.vendor_context() || ti.recovery_context()) {
		vendor_set_usb_product_ids(&ti);

		if (ti.is_model(3668, 0)) {
			ti.property_set("ro.vendor.smd_path", "/dev/block/mtdblock0");
			ti.property_set("ro.vendor.smd_offset", "0x00B00000");
		}
	}

	// AB updates require set paths for certain partitions
	if (!ti.vendor_context()) {
		std::map<std::string,std::string> ab_parts;
		ab_parts.emplace("/dev/block/by-name/kernel_a", "/dev/block/by-name/boot_a");
		ab_parts.emplace("/dev/block/by-name/kernel_b", "/dev/block/by-name/boot_b");
		ab_parts.emplace("/dev/block/by-name/APP_a",    "/dev/block/by-name/system_a");
		ab_parts.emplace("/dev/block/by-name/APP_b",    "/dev/block/by-name/system_b");
		ab_parts.emplace("/dev/block/by-name/SOS_a",    "/dev/block/by-name/recovery_a");
		ab_parts.emplace("/dev/block/by-name/SOS_b",    "/dev/block/by-name/recovery_b");
		ti.make_symlinks(ab_parts);
	}
}
