#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <objc/objc-runtime.h>
#include <nan.h>

 @implementation NSWindow (NSWindowAdditions)
- (NSWindowStyleMask)styleMask {
    return NSWindowStyleMaskTitled | NSWindowStyleMaskResizable | NSWindowStyleMaskTexturedBackground | NSWindowStyleMaskFullSizeContentView | NSWindowStyleMaskNonactivatingPanel;
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
@end

NAN_METHOD(MakePanel) {
  NSLog(@"makePanel");
  v8::Local<v8::Object> handleBuffer = info[0].As<v8::Object>();
  char* buffer = node::Buffer::Data(handleBuffer);
  void *viewPointer = *reinterpret_cast<void**>(buffer);
  NSView *mainContentView = (__bridge NSView *)viewPointer;


  if (!mainContentView)
      return info.GetReturnValue().Set(false);

  NSWindow *nswindow = [mainContentView window];

  mainContentView.window.styleMask |= NSWindowStyleMaskNonactivatingPanel;
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
  if (@available(macOS 10.14, *)) {
  visualEffectView.material = NSVisualEffectMaterialHUDWindow;
} else {
  // Fallback for earlier versions
}

  visualEffectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;

  [mainContentView addSubview:visualEffectView positioned:NSWindowBelow relativeTo:nil];

  return info.GetReturnValue().Set(true);
}

NAN_METHOD(MakeKeyWindow) {
  NSLog(@"makeKeyWindow");
  v8::Local<v8::Object> handleBuffer = info[0].As<v8::Object>();
  char* buffer = node::Buffer::Data(handleBuffer);
  void *viewPointer = *reinterpret_cast<void**>(buffer);
  NSView *mainContentView = (__bridge NSView *)viewPointer;

  if (!mainContentView)
      return info.GetReturnValue().Set(false);

  [mainContentView.window makeKeyAndOrderFront:nil];

  [mainContentView.window setCollectionBehavior: NSWindowStyleMaskNonactivatingPanel | NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary];

  
  [mainContentView.window setLevel:NSScreenSaverWindowLevel];

  return info.GetReturnValue().Set(true);
}


NAN_METHOD(MakeWindow) {
  NSLog(@"makeWindow");
  v8::Local<v8::Object> handleBuffer = info[0].As<v8::Object>();
  char* buffer = node::Buffer::Data(handleBuffer);
  void *viewPointer = *reinterpret_cast<void**>(buffer);
  NSView *mainContentView = (__bridge NSView *)viewPointer;

  // Set the collectionBehavior to NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorFullScreenAuxiliary;
  [mainContentView.window setCollectionBehavior: NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorFullScreenAuxiliary];
  [mainContentView.window setLevel:NSNormalWindowLevel];

  NSLog(@"makeWindow: mainContentView: %@", mainContentView);
  if (!mainContentView)
      return info.GetReturnValue().Set(false);

  return info.GetReturnValue().Set(true);
}

NAN_METHOD(HideInstant) {
  NSLog(@"hideInstant");
  v8::Local<v8::Object> handleBuffer = info[0].As<v8::Object>();
  char* buffer = node::Buffer::Data(handleBuffer);
  void *viewPointer = *reinterpret_cast<void**>(buffer);
  NSView *mainContentView = (__bridge NSView *)viewPointer;

  if (!mainContentView)
      return info.GetReturnValue().Set(false);

  NSWindow *nswindow = [mainContentView window];
  [nswindow orderOut:nil]; // Immediately hides the window without animation

  return info.GetReturnValue().Set(true);
}


void Init(v8::Local<v8::Object> exports) {
  Nan::SetMethod(exports, "makePanel", MakePanel);
  Nan::SetMethod(exports, "makeKeyWindow", MakeKeyWindow);
  Nan::SetMethod(exports, "makeWindow", MakeWindow);
  Nan::SetMethod(exports, "hideInstant", HideInstant);
}

NODE_MODULE(addon, Init)