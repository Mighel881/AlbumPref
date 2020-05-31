include $(THEOS)/makefiles/common.mk

SUBPROJECTS += albumprefhook
SUBPROJECTS += albumprefsettings

include $(THEOS_MAKE_PATH)/aggregate.mk

all::
	
