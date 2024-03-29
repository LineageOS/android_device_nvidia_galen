# Copyright (C) 2020 The LineageOS Project
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

# Inherit some common lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_tv.mk)

# Inherit device configuration for galen.
include device/nvidia/galen/lineage.mk
$(call inherit-product, device/nvidia/galen/full_galen.mk)

PRODUCT_NAME := lineage_galen
PRODUCT_DEVICE := galen
