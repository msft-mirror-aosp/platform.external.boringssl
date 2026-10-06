# Copyright (C) 2015 The Android Open Source Project.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
# OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# This file is not used in the Android build process! It's used only by Trusty.


LOCAL_DIR := $(GET_LOCAL_DIR)
LOCAL_PATH := $(GET_LOCAL_DIR)

MODULE := $(LOCAL_DIR)

TARGET_ARCH := $(ARCH)
TARGET_2ND_ARCH := $(ARCH)

# Reset local variables
LOCAL_CFLAGS :=
LOCAL_C_INCLUDES :=
LOCAL_SRC_FILES :=
LOCAL_SRC_FILES_$(TARGET_ARCH) :=
LOCAL_SRC_FILES_$(TARGET_2ND_ARCH) :=
LOCAL_CFLAGS_$(TARGET_ARCH) :=
LOCAL_CFLAGS_$(TARGET_2ND_ARCH) :=
LOCAL_ADDITIONAL_DEPENDENCIES :=

# get target_c_flags, target_c_includes, target_src_files
MODULE_SRCDEPS += $(LOCAL_DIR)/src/gen/sources.mk
include $(LOCAL_DIR)/src/gen/sources.mk

LOCAL_CFLAGS += -I$(LOCAL_PATH)/src/include -Wno-unused-parameter -DBORINGSSL_ANDROID_SYSTEM
LOCAL_ASFLAGS += -I$(LOCAL_PATH)/src/include -Wno-unused-parameter
LOCAL_SRC_FILES += $(addprefix src/,$(boringssl_bcm_sources) $(boringssl_bcm_sources_asm) $(boringssl_crypto_sources) $(boringssl_crypto_sources_asm))

# The AOSP stdatomic.h clang header does not build against musl. Disable C11
# atomics.
MODULE_CFLAGS += -D__STDC_NO_ATOMICS__

# Define static armcap based on lk build variables
MODULE_STATIC_ARMCAP := -DOPENSSL_STATIC_ARMCAP
toarmcap = $(if $(filter-out 0 false,$(2)),-DOPENSSL_STATIC_ARMCAP_$(1),)
MODULE_STATIC_ARMCAP += $(call toarmcap,NEON,$(USE_ARM_V7_NEON))
MODULE_STATIC_ARMCAP += $(call toarmcap,AES,$(USE_ARM_V8_AES))
MODULE_STATIC_ARMCAP += $(call toarmcap,PMULL,$(USE_ARM_V8_PMULL))
MODULE_STATIC_ARMCAP += $(call toarmcap,SHA1,$(USE_ARM_V8_SHA1))
MODULE_STATIC_ARMCAP += $(call toarmcap,SHA256,$(USE_ARM_V8_SHA2))
MODULE_COMPILEFLAGS += $(MODULE_STATIC_ARMCAP)

ifeq (true,$(call TOBOOL,$(OPENSSL_SMALL)))
# Use space efficient options; mainly reduces precomputed lookup tables
MODULE_DEFINES += OPENSSL_SMALL=1
endif

MODULE_SRCS += $(addprefix $(LOCAL_DIR)/,$(LOCAL_SRC_FILES))
MODULE_SRCS += $(addprefix $(LOCAL_DIR)/,$(LOCAL_SRC_FILES_$(ARCH)))

MODULE_EXPORT_INCLUDES += $(LOCAL_DIR)/src/include

include trusty/user/base/lib/openssl-stubs/openssl-stubs-inc.mk

include make/library.mk
