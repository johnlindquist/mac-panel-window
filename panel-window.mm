#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <objc/objc-runtime.h>
#include "nan.h"

NAN_METHOD(MakePanel);
NAN_METHOD(MakeKeyWindow);
NAN_METHOD(MakeWindow);
NAN_METHOD(SetShouldAlwaysBeOnTop);

@interface PROPanel : NSWindow
- (void)setShouldAlwaysBeOnTop:(BOOL)value;
@end

@implementation PROPanel {
    BOOL shouldAlwaysBeOnTop;
}

- (void)setShouldAlwaysBeOnTop:(BOOL)value {
    shouldAlwaysBeOnTop = value;
}
- (NSWindowLevel)level {
    return shouldAlwaysBeOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel;
}

- (NSWindowStyleMask)styleMask {
  return NSWindowStyleMaskTexturedBackground | NSWindowStyleMaskResizable | NSWindowStyleMaskFullSizeContentView | NSWindowStyleMaskNonactivatingPanel;
}

- (NSWindowCollectionBehavior)collectionBehavior {
  return NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
}

- (BOOL)isFloatingPanel {
  return YES;
}

- (BOOL)canBecomeKeyWindow {
  return YES;
}

- (BOOL)canBecomeMainWindow {
  return YES;
}

- (BOOL)needsPanelToBecomeKey {
  return YES;
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context {
  if ([keyPath isEqualToString:@"_titlebarBackdropGroupName"]) {
    return;
  }

  if (context) {
    [super removeObserver:observer forKeyPath:keyPath context:context];
  } else {
    [super removeObserver:observer forKeyPath:keyPath];
  }
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
  [self removeObserver:observer forKeyPath:keyPath context:NULL];
}
@end

Class electronWindowClass;

NAN_METHOD(MakePanel) {
  v8::Local<v8::Object> handleBuffer = info[0].As<v8::Object>();
  char* buffer = node::Buffer::Data(handleBuffer);
  void *viewPointer = *reinterpret_cast<void**>(buffer);
  NSView *mainContentView = (__bridge NSView *)viewPointer;

  if (!mainContentView)
      return info.GetReturnValue().Set(false);

  electronWindowClass = [mainContentView.window class];
  NSWindow *nswindow = [mainContentView window];
  nswindow.titlebarAppearsTransparent = true;
  nswindow.titleVisibility = (NSWindowTitleVisibility)1;

  NSButton *closeButton = [nswindow standardWindowButton:NSWindowCloseButton];
  NSButton *miniaturizeButton = [nswindow standardWindowButton:NSWindowMiniaturizeButton];
  NSButton *zoomButton = [nswindow standardWindowButton:NSWindowZoomButton];

  closeButton.enabled = NO;
  miniaturizeButton.enabled = NO;
  zoomButton.enabled = NO;

  closeButton.hidden = YES;
  miniaturizeButton.hidden = YES;
  zoomButton.hidden = YES;

  NSVisualEffectView *visualEffectView = [[NSVisualEffectView alloc] initWithFrame:mainContentView.bounds];
  visualEffectView.material = NSVisualEffectMaterialHUDWindow;
  visualEffectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;

  [mainContentView addSubview:visualEffectView positioned:NSWindowBelow relativeTo:nil];

  object_setClass(mainContentView.window, [PROPanel class]);

  return info.GetReturnValue().Set(true);
}

NAN_METHOD(MakeKeyWindow) {
  v8::Local<v8::Object> handleBuffer = info[0].As<v8::Object>();
  char* buffer = node::Buffer::Data(handleBuffer);
  void *viewPointer = *reinterpret_cast<void**>(buffer);
  NSView *mainContentView = (__bridge NSView *)viewPointer;

  if (!mainContentView)
      return info.GetReturnValue().Set(false);

  [mainContentView.window makeKeyWindow];
  [mainContentView.window makeMainWindow];
  return info.GetReturnValue().Set(true);
}

NAN_METHOD(MakeWindow) {
  v8::Local<v8::Object> handleBuffer = info[0].As<v8::Object>();
  char* buffer = node::Buffer::Data(handleBuffer);
  void *viewPointer = *reinterpret_cast<void**>(buffer);
  NSView *mainContentView = (__bridge NSView *)viewPointer;

  if (!mainContentView)
      return info.GetReturnValue().Set(false);

  NSWindow* newWindow = mainContentView.window;
  object_setClass(newWindow, electronWindowClass);

  return info.GetReturnValue().Set(true);
}

NAN_METHOD(SetShouldAlwaysBeOnTop) {
    v8::Local<v8::Object> handleBuffer = info[0].As<v8::Object>();
    char* buffer = node::Buffer::Data(handleBuffer);
    void *viewPointer = *reinterpret_cast<void**>(buffer);
    NSView *mainContentView = (__bridge NSView *)viewPointer;

    if (!mainContentView)
        return info.GetReturnValue().Set(false);

    PROPanel *panel = (PROPanel *)mainContentView.window;
    BOOL flag = info[1]->BooleanValue(Nan::GetCurrentContext()->GetIsolate());
    [panel setShouldAlwaysBeOnTop:flag];

    return info.GetReturnValue().Set(true);
}

void Init(v8::Local<v8::Object> exports) {
    Nan::SetMethod(exports, "makePanel", MakePanel);
    Nan::SetMethod(exports, "makeKeyWindow", MakeKeyWindow);
    Nan::SetMethod(exports, "makeWindow", MakeWindow);
    Nan::SetMethod(exports, "setAlwaysOnTop", SetShouldAlwaysBeOnTop);
}

NODE_MODULE(addon, Init)
