#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <objc/objc-runtime.h>
#include <napi.h>
#include <uv.h>

// Define a constant for the window's style combining several options:
const NSWindowStyleMask kCustomWindowStyleMask = 
    // NSWindowStyleMaskTitled | // The window will have a title bar.
    NSWindowStyleMaskResizable | // The window can be resized by the user.
    NSWindowStyleMaskTexturedBackground | // The window background is textured.
    NSWindowStyleMaskFullSizeContentView | // The window's content view will be the full size of the window, including the title bar area.
    NSWindowStyleMaskNonactivatingPanel; // The window does not activate the app when clicked.

// Define a constant for the window's collection behavior combining several options:
const NSWindowCollectionBehavior kCustomWindowCollectionBehavior = 
  NSWindowCollectionBehaviorManaged | // The window participates in the automatic window management system.
  NSWindowCollectionBehaviorFullScreenAuxiliary; // The window can appear on spaces designated for full screen applications.

@implementation NSWindow (NSWindowAdditions)
- (NSWindowStyleMask)styleMask {
    return kCustomWindowStyleMask;
}
@end

@interface NSColor (HexColorAdditions)
- (NSString *)hexadecimalValue;
+ (NSColor *)colorWithHexString:(NSString *)hexString;
@end

@implementation NSColor (HexColorAdditions)
- (NSString *)hexadecimalValue {
  NSColor *color = [self colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
  return [NSString stringWithFormat:@"#%02X%02X%02X", (int)(color.redComponent * 255), (int)(color.greenComponent * 255), (int)(color.blueComponent * 255)];
}

+ (NSColor *)colorWithHexString:(NSString *)hexString {
  unsigned rgbValue = 0;
  NSScanner *scanner = [NSScanner scannerWithString:hexString];
  [scanner setScanLocation:1]; // Bypass '#' character
  [scanner scanHexInt:&rgbValue];
  return [NSColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0 green:((rgbValue & 0xFF00) >> 8) / 255.0 blue:(rgbValue & 0xFF) / 255.0 alpha:1.0];
}
@end

NSView* GetMainContentViewFromArgs(const Napi::CallbackInfo& info) {
  Napi::Object handleBuffer = info[0].As<Napi::Object>();
  char* buffer = handleBuffer.As<Napi::Buffer<char>>().Data();
  void *viewPointer = *reinterpret_cast<void**>(buffer);
  return (__bridge NSView *)viewPointer;
}

NSWindow* CreateWindow(NSView *mainContentView) {
  NSWindow *nswindow = [mainContentView window];

  NSLog(@"MAC-PANEL-WINDOW: Creating window: %@", nswindow);
  NSLog(@"MAC-PANEL-WINDOW: Initial window properties - styleMask: %lu, titlebarAppearsTransparent: %d, titleVisibility: %ld, hasShadow: %d, backgroundColor: %@",
        (unsigned long)nswindow.styleMask, nswindow.titlebarAppearsTransparent, (long)nswindow.titleVisibility, nswindow.hasShadow, nswindow.backgroundColor);

  // There was a bug in Electron's Tray where starting with NSWindowStyleMaskTitled caused the initial tray clicks to be ignored.
  // Moving NSWindowStyleMaskTitled to be added here, instead of in the constant, fixed the issue.
  // Unfortunately, I don't know.
  nswindow.styleMask = kCustomWindowStyleMask | NSWindowStyleMaskTitled;
  nswindow.titlebarAppearsTransparent = true;
  nswindow.titleVisibility = (NSWindowTitleVisibility)1;
  nswindow.backgroundColor = [[NSColor windowBackgroundColor] colorWithAlphaComponent:0.15];
  nswindow.hasShadow = YES;

  NSButton *closeButton = [nswindow standardWindowButton:NSWindowCloseButton];
  NSButton *miniaturizeButton = [nswindow standardWindowButton:NSWindowMiniaturizeButton];
  NSButton *zoomButton = [nswindow standardWindowButton:NSWindowZoomButton];

  closeButton.enabled = NO;
  miniaturizeButton.enabled = NO;
  zoomButton.enabled = NO;

  closeButton.hidden = YES;
  miniaturizeButton.hidden = YES;
  zoomButton.hidden = YES;

  NSLog(@"MAC-PANEL-WINDOW: Window created - styleMask: %lu, titlebarAppearsTransparent: %d, titleVisibility: %ld, hasShadow: %d, backgroundColor: %@",
        (unsigned long)nswindow.styleMask, nswindow.titlebarAppearsTransparent, (long)nswindow.titleVisibility, nswindow.hasShadow, nswindow.backgroundColor);

  return nswindow;
}

Napi::Value MakePanel(const Napi::CallbackInfo& info) {
  NSLog(@"MAC-PANEL-WINDOW: makePanel");
  NSView *mainContentView = GetMainContentViewFromArgs(info);

  if (!mainContentView) {
    NSLog(@"MAC-PANEL-WINDOW: Error: mainContentView is nil");
    return Napi::Boolean::New(info.Env(), false);
  }

  NSWindow *nswindow = CreateWindow(mainContentView);

  NSVisualEffectView *visualEffectView = [[NSVisualEffectView alloc] initWithFrame:mainContentView.bounds];
  if (@available(macOS 10.14, *)) {
    visualEffectView.material = NSVisualEffectMaterialHUDWindow;
  } else {
    // Fallback for earlier versions
  }

  visualEffectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;

  [mainContentView addSubview:visualEffectView positioned:NSWindowBelow relativeTo:nil];

  NSLog(@"MAC-PANEL-WINDOW: Panel created - window: %@, visualEffectView material: %ld, blendingMode: %ld",
        nswindow, (long)visualEffectView.material, (long)visualEffectView.blendingMode);

  return Napi::Boolean::New(info.Env(), true);
}

Napi::Value MakeKeyWindow(const Napi::CallbackInfo& info) {
  NSLog(@"MAC-PANEL-WINDOW: makeKeyWindow");
  NSView *mainContentView = GetMainContentViewFromArgs(info);

  if (!mainContentView) {
    NSLog(@"MAC-PANEL-WINDOW: Error: mainContentView is nil");
    return Napi::Boolean::New(info.Env(), false);
  }

  NSWindow *nswindow = CreateWindow(mainContentView);

  [nswindow makeKeyAndOrderFront:nil];
  [nswindow setCollectionBehavior:kCustomWindowCollectionBehavior];
  [nswindow setLevel:NSScreenSaverWindowLevel];

  NSLog(@"MAC-PANEL-WINDOW: Window made key - window: %@, collectionBehavior: %lu, level: %ld",
        nswindow, (unsigned long)nswindow.collectionBehavior, (long)nswindow.level);

  return Napi::Boolean::New(info.Env(), true);
}

Napi::Value MakeWindow(const Napi::CallbackInfo& info) {
  NSLog(@"MAC-PANEL-WINDOW: makeWindow");
  NSView *mainContentView = GetMainContentViewFromArgs(info);

  if (!mainContentView) {
    NSLog(@"MAC-PANEL-WINDOW: Error: mainContentView is nil");
    return Napi::Boolean::New(info.Env(), false);
  }

  NSWindow *nswindow = CreateWindow(mainContentView);

  [nswindow setCollectionBehavior:kCustomWindowCollectionBehavior];
  [nswindow setLevel:NSNormalWindowLevel];

  NSLog(@"MAC-PANEL-WINDOW: Window made - window: %@, collectionBehavior: %lu, level: %ld",
        nswindow, (unsigned long)nswindow.collectionBehavior, (long)nswindow.level);

  return Napi::Boolean::New(info.Env(), true);
}

Napi::Value HideInstant(const Napi::CallbackInfo& info) {
  NSLog(@"MAC-PANEL-WINDOW: hideInstant");
  NSView *mainContentView = GetMainContentViewFromArgs(info);

  if (!mainContentView) {
    NSLog(@"MAC-PANEL-WINDOW: Error: mainContentView is nil");
    return Napi::Boolean::New(info.Env(), false);
  }

  NSWindow *nswindow = [mainContentView window];
  NSLog(@"MAC-PANEL-WINDOW: Hiding window: %@", nswindow);

  [nswindow orderOut:nil]; // Immediately hides the window without animation

  NSLog(@"MAC-PANEL-WINDOW: Window hidden - window: %@", nswindow);

  return Napi::Boolean::New(info.Env(), true);
}

Napi::Value GetWindowBackgroundColor(const Napi::CallbackInfo& info) {
  NSColor *color = [NSColor windowBackgroundColor];
  return Napi::String::New(info.Env(), [[color hexadecimalValue] UTF8String]);
}

Napi::Value GetLabelColor(const Napi::CallbackInfo& info) {
  NSColor *color = [NSColor labelColor];
  return Napi::String::New(info.Env(), [[color hexadecimalValue] UTF8String]);
}

Napi::Value GetTextColor(const Napi::CallbackInfo& info) {
  NSColor *color = [NSColor textColor];
  return Napi::String::New(info.Env(), [[color hexadecimalValue] UTF8String]);
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set(Napi::String::New(env, "makePanel"), Napi::Function::New(env, MakePanel));
  exports.Set(Napi::String::New(env, "makeKeyWindow"), Napi::Function::New(env, MakeKeyWindow));
  exports.Set(Napi::String::New(env, "makeWindow"), Napi::Function::New(env, MakeWindow));
  exports.Set(Napi::String::New(env, "hideInstant"), Napi::Function::New(env, HideInstant));
  exports.Set(Napi::String::New(env, "getWindowBackgroundColor"), Napi::Function::New(env, GetWindowBackgroundColor));
  exports.Set(Napi::String::New(env, "getLabelColor"), Napi::Function::New(env, GetLabelColor));
  exports.Set(Napi::String::New(env, "getTextColor"), Napi::Function::New(env, GetTextColor));
  return exports;
}

NODE_API_MODULE(addon, Init)