LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE        := fstab.jetson-xavier
LOCAL_MODULE_CLASS  := ETC
LOCAL_SRC_FILES     := fstab.jetson-xavier
LOCAL_VENDOR_MODULE := true
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE               := init.jetson-xavier.rc
LOCAL_MODULE_CLASS         := ETC
LOCAL_SRC_FILES            := init.jetson-xavier.rc
LOCAL_VENDOR_MODULE        := true
LOCAL_MODULE_RELATIVE_PATH := init/hw
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE               := init.jetson-xavier_common.rc
LOCAL_MODULE_CLASS         := ETC
LOCAL_SRC_FILES            := init.jetson-xavier_common.rc
LOCAL_VENDOR_MODULE        := true
LOCAL_MODULE_RELATIVE_PATH := init/hw
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE       := init.recovery.jetson-xavier.rc
LOCAL_MODULE_CLASS := ETC
LOCAL_SRC_FILES    := init.recovery.jetson-xavier.rc
LOCAL_MODULE_PATH  := $(TARGET_ROOT_OUT)
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE       := power.jetson-xavier.rc
LOCAL_MODULE_CLASS := ETC
LOCAL_ODM_MODULE   := true
LOCAL_SRC_FILES    := power.jetson-xavier.rc
include $(BUILD_PREBUILT)
