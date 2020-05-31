include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AlbumPrefSettings
AlbumPrefSettings_FILES = /mnt/d/codes/albumpref/albumprefsettings/AlbumPrefSettingsController.mm
AlbumPrefSettings_INSTALL_PATH = /Library/PreferenceBundles
AlbumPrefSettings_FRAMEWORKS = UIKit QuartzCore CoreGraphics MessageUI Social Twitter Photos
AlbumPrefSettings_PRIVATE_FRAMEWORKS = Preferences
AlbumPrefSettings_CFLAGS = -fobjc-arc

AlbumPrefSettings_ARCHS = armv7 armv7s arm64 arm64e
export ARCHS = armv7 armv7s arm64 arm64e

include $(THEOS_MAKE_PATH)/bundle.mk

all::
