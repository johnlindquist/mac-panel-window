#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <objc/objc-runtime.h>
#include <napi.h>
#include <uv.h>

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

Napi::Value MakePanel(const Napi::CallbackInfo& info) {
  NSLog(@"makePanel");
  Napi::Object handleBuffer = info[0].As<Napi::Object>();
  char* buffer = handleBuffer.As<Napi::Buffer<char>>().Data();
  void *viewPointer = *reinterpret_cast<void**>(buffer);
  NSView *mainContentView = (__bridge NSView *)viewPointer;


  if (!mainContentView)
      return Napi::Boolean::New(info.Env(), false);

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

  return Napi::Boolean::New(info.Env(), true);
}

Napi::Value MakeKeyWindow(const Napi::CallbackInfo& info) {
  NSLog(@"makeKeyWindow");
  Napi::Object handleBuffer = info[0].As<Napi::Object>();
  char* buffer = handleBuffer.As<Napi::Buffer<char>>().Data();
  void *viewPointer = *reinterpret_cast<void**>(buffer);
  NSView *mainContentView = (__bridge NSView *)viewPointer;

  if (!mainContentView)
       return Napi::Boolean::New(info.Env(), false);

  [mainContentView.window makeKeyAndOrderFront:nil];

  [mainContentView.window setCollectionBehavior: NSWindowStyleMaskNonactivatingPanel | NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary];

  
  [mainContentView.window setLevel:NSScreenSaverWindowLevel];

  return Napi::Boolean::New(info.Env(), true);
}


Napi::Value MakeWindow(const Napi::CallbackInfo& info) {
  NSLog(@"makeWindow");
  Napi::Object handleBuffer = info[0].As<Napi::Object>();
  char* buffer = handleBuffer.As<Napi::Buffer<char>>().Data();
  void *viewPointer = *reinterpret_cast<void**>(buffer);
  NSView *mainContentView = (__bridge NSView *)viewPointer;

  // Set the collectionBehavior to NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorFullScreenAuxiliary;
  [mainContentView.window setCollectionBehavior: NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorFullScreenAuxiliary];
  [mainContentView.window setLevel:NSNormalWindowLevel];

  NSLog(@"makeWindow: mainContentView: %@", mainContentView);
  if (!mainContentView)
       return Napi::Boolean::New(info.Env(), false);

  return Napi::Boolean::New(info.Env(), true);
}

Napi::Value HideInstant(const Napi::CallbackInfo& info) {
  NSLog(@"hideInstant");
  Napi::Object handleBuffer = info[0].As<Napi::Object>();
  char* buffer = handleBuffer.As<Napi::Buffer<char>>().Data();
  void *viewPointer = *reinterpret_cast<void**>(buffer);
  NSView *mainContentView = (__bridge NSView *)viewPointer;

  if (!mainContentView)
       return Napi::Boolean::New(info.Env(), false);

  NSWindow *nswindow = [mainContentView window];
  [nswindow orderOut:nil]; // Immediately hides the window without animation

  return Napi::Boolean::New(info.Env(), true);
}


Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set(Napi::String::New(env, "makePanel"), Napi::Function::New(env, MakePanel));
  exports.Set(Napi::String::New(env, "makeKeyWindow"), Napi::Function::New(env, MakeKeyWindow));
  exports.Set(Napi::String::New(env, "makeWindow"), Napi::Function::New(env, MakeWindow));
  exports.Set(Napi::String::New(env, "hideInstant"), Napi::Function::New(env, HideInstant));
  return exports;
}

NODE_API_MODULE(addon, Init)