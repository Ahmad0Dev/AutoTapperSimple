export THEOS ?= $(HOME)/theos
export THEOS_MAKE_PATH ?= $(THEOS)/makefiles

TARGET := iphone:clang:16.5:15.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoTapperSimple

AutoTapperSimple_FILES = main.m ATWatermark.m ATTerms.m \
                         ATSimplePanel.m \
                         ATHelpView.m \
                         ATMarker.m \
                         ATEngine.m \
                         ATTouchPool.m \
                         ATGuard.m \
                         ATSilencer.m \
                         CGGeometry-KIFAdditions.m \
                         UITouch-KIFAdditions.m \
                         UIEvent+KIFAdditions.m \
                         UIView-KIFAdditions.m \
                         UIApplication-KIFAdditions.m \
                         UIAccessibilityElement-KIFAdditions.m \
                         UIWindow-KIFAdditions.m \
                         NSError-KIFAdditions.m \
                         NSObject+KIFAdditions.m \
                         NSObject+KIFSwizzle.m \
                         IOHIDEvent+KIF.m \
                         KIFEventVisualizer.m \
                         KIFUITestActor.m

AutoTapperSimple_CFLAGS = -fobjc-arc \
                          -Wno-deprecated-declarations \
                          -Wno-unused-variable \
                          -Wno-unused-function \
                          -Wno-incompatible-pointer-types \
                          -Wno-unused-value \
                          -Wno-shorten-64-to-32 \
                          -DKIF_ENABLED=1

AutoTapperSimple_FRAMEWORKS = UIKit CoreGraphics WebKit QuartzCore Security
AutoTapperSimple_LIBRARIES = dl
AutoTapperSimple_LDFLAGS = -framework IOKit -ObjC

include $(THEOS_MAKE_PATH)/tweak.mk
