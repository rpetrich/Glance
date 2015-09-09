TWEAK_NAME = Glance
Glance_FILES = Tweak.x
Glance_FRAMEWORKS = UIKit

IPHONE_ARCHS = armv7 arm64

ADDITIONAL_CFLAGS = -std=c99
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 7.0

INSTALL_TARGET_PROCESSES = SpringBoard

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
