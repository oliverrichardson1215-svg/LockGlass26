export THEOS_PACKAGE_SCHEME = rootless

ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LiquidLock26

LiquidLock26_FILES = Tweak.xm
LiquidLock26_CFLAGS = -fobjc-arc
LiquidLock26_FRAMEWORKS = UIKit QuartzCore

SUBPROJECTS += Preferences

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
