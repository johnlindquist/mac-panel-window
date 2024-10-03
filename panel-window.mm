#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <objc/objc-runtime.h>
#include <napi.h>
#include <uv.h>

// Define a constant for the window's style combining several options:
const NSWindowStyleMask customWindowStyleMask = 
    NSWindowStyleMaskTitled | // The window will have a title bar.    
    NSWindowStyleMaskResizable | // The window can be resized by the user.
    NSWindowStyleMaskFullSizeContentView; // The window's content view will be the full size of the window, including the title bar area.

// Define a constant for the window's collection behavior combining several options:
const NSWindowCollectionBehavior customWindowCollectionBehavior = 
  NSWindowCollectionBehaviorManaged | // The window participates in the automatic window management system.
  NSWindowCollectionBehaviorFullScreenAuxiliary; // The window can appear on spaces designated for full screen applications.


@interface CustomWindow : NSWindow
@end

@implementation CustomWindow

- (NSWindowStyleMask)styleMask {
    return customWindowStyleMask;
}

- (NSWindowCollectionBehavior)collectionBehavior {
    return customWindowCollectionBehavior;
}

// Override necessary methods if needed
- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

- (void)disableKeyOrMainWindow {
    NSLog(@"disableKeyOrMainWindow called on CustomWindow");
}

@end

// Define a constant for the window's style combining several options:
const NSWindowStyleMask kCustomWindowStyleMask = 
    NSWindowStyleMaskTitled | // The window will have a title bar.    
    NSWindowStyleMaskResizable | // The window can be resized by the user.
    NSWindowStyleMaskFullSizeContentView | // The window's content view will be the full size of the window, including the title bar area.
    NSWindowStyleMaskNonactivatingPanel; // The window does not activate the app when clicked.

// Define a constant for the window's collection behavior combining several options:
const NSWindowCollectionBehavior kCustomWindowCollectionBehavior = 
  NSWindowCollectionBehaviorManaged | // The window participates in the automatic window management system.
  NSWindowCollectionBehaviorFullScreenAuxiliary; // The window can appear on spaces designated for full screen applications.

@interface PROPanel : NSWindow
@end

@implementation PROPanel

- (NSWindowStyleMask)styleMask {
    return NSWindowStyleMaskTitled | 
           NSWindowStyleMaskResizable | 
           NSWindowStyleMaskFullSizeContentView | 
           NSWindowStyleMaskNonactivatingPanel;
}

- (NSWindowCollectionBehavior)collectionBehavior {
  return kCustomWindowCollectionBehavior;
}

- (BOOL)isFloatingPanel {
  return YES;
}

- (NSWindowLevel)level {
  return NSFloatingWindowLevel;
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

- (void)setDisableKeyOrMainWindow:(BOOL)disable {
    // No-op or implement desired behavior
    NSLog(@"setDisableKeyOrMainWindow called with: %d", disable);
}


- (void)disableKeyOrMainWindow {
    NSLog(@"disableKeyOrMainWindow called on PROPanel");
}

- (void)setVibrancy:(BOOL)vibrant {
    if (vibrant) {
        self.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
    } else {
        self.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    }
}

- (void)becomeKeyWindow {
    [super becomeKeyWindow];
    [self orderFrontRegardless];
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
  return [NSColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0 
                         green:((rgbValue & 0xFF00) >> 8) / 255.0 
                          blue:(rgbValue & 0xFF) / 255.0 
                         alpha:1.0];
}
@end

NSView* GetMainContentViewFromArgs(const Napi::CallbackInfo& info) {
    Napi::Object handleBuffer = info[0].As<Napi::Object>();
    char* buffer = handleBuffer.As<Napi::Buffer<char>>().Data();
    void *viewPointer = *reinterpret_cast<void**>(buffer);
    return (__bridge NSView *)viewPointer;
}

Class electronWindowClass;

Napi::Value MakePanel(const Napi::CallbackInfo& info) {
    NSLog(@"MAC-PANEL-WINDOW: makePanel");
    NSView *mainContentView = GetMainContentViewFromArgs(info);

    if (!mainContentView)
        return Napi::Boolean::New(info.Env(), true);

    // Store the original window class if not already stored
    if (!electronWindowClass) {
        electronWindowClass = [mainContentView.window class];
    }

    NSWindow *nswindow = [mainContentView window];
    nswindow.titlebarAppearsTransparent = YES;
    nswindow.titleVisibility = NSWindowTitleHidden;
    nswindow.backgroundColor = [[NSColor windowBackgroundColor] colorWithAlphaComponent:1];
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

    // Convert the NSWindow class to PROPanel
    object_setClass(nswindow, [PROPanel class]);

    // Set vibrancy to popover style
    // if ([nswindow isKindOfClass:[PROPanel class]]) {
    //     [(PROPanel *)nswindow setVibrancy:YES];
    // }

    return Napi::Boolean::New(info.Env(), true);
}

Napi::Value MakeKeyWindow(const Napi::CallbackInfo& info) {
    NSLog(@"MAC-PANEL-WINDOW: makeKeyWindow");
    NSView *mainContentView = GetMainContentViewFromArgs(info);

    if (!mainContentView) {
        NSLog(@"MAC-PANEL-WINDOW: Error: mainContentView is nil");
        return Napi::Boolean::New(info.Env(), false);
    }

    NSWindow* nswindow = mainContentView.window;

    dispatch_async(dispatch_get_main_queue(), ^{
        [nswindow makeKeyAndOrderFront:nil];
        [nswindow makeMainWindow];
    });

    NSLog(@"MAC-PANEL-WINDOW: Window made key - window: %@, isKeyWindow: %d", nswindow, nswindow.isKeyWindow);

    return Napi::Boolean::New(info.Env(), true);
}

Napi::Value PrepForClose(const Napi::CallbackInfo& info) {
    NSLog(@"MAC-PANEL-WINDOW: prepForClose");
    NSView *mainContentView = GetMainContentViewFromArgs(info);
    NSWindow* nswindow = mainContentView.window;

    if ([nswindow isKeyWindow]) {
        [nswindow resignKeyWindow];
        NSLog(@"MAC-PANEL-WINDOW: Window resigned as key window before electron window reset.");
    }

    // Convert the PROPanel back to the original NSWindow class
    if (electronWindowClass) {
        object_setClass(nswindow, electronWindowClass);
    } else {
        NSLog(@"MAC-PANEL-WINDOW: Error: Original Electron window class not stored.");
        return Napi::Boolean::New(info.Env(), false);
    }

        // **Add the following code to resign the key window status**
    if ([nswindow isKeyWindow]) {
        [nswindow resignKeyWindow];
        NSLog(@"MAC-PANEL-WINDOW: Window resigned as key window after electron window reset.");
    }

    return Napi::Boolean::New(info.Env(), true);
}

Napi::Value MakeWindow(const Napi::CallbackInfo& info) {
    NSLog(@"MAC-PANEL-WINDOW: makeWindow");
    NSView *mainContentView = GetMainContentViewFromArgs(info);
    NSWindow* nswindow = mainContentView.window;

    // Re-enable standard window buttons
    [[nswindow standardWindowButton:NSWindowCloseButton] setEnabled:YES];
    [[nswindow standardWindowButton:NSWindowMiniaturizeButton] setEnabled:YES];
    [[nswindow standardWindowButton:NSWindowZoomButton] setEnabled:YES];

    [[nswindow standardWindowButton:NSWindowCloseButton] setHidden:NO];
    [[nswindow standardWindowButton:NSWindowMiniaturizeButton] setHidden:NO];
    [[nswindow standardWindowButton:NSWindowZoomButton] setHidden:NO];

    // Reset other properties that might have been changed
    nswindow.titlebarAppearsTransparent = NO;
    nswindow.titleVisibility = NSWindowTitleVisible;

    object_setClass(nswindow, [CustomWindow class]);
    // nswindow.level = NSNormalWindowLevel;




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

    dispatch_async(dispatch_get_main_queue(), ^{
        [nswindow orderOut:nil]; // Immediately hides the window without animation
    });

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

Napi::Value SetAppearance(const Napi::CallbackInfo& info) {
    NSLog(@"MAC-PANEL-WINDOW: setAppearance");
    NSView *mainContentView = GetMainContentViewFromArgs(info);
    
    if (!mainContentView) {
        NSLog(@"MAC-PANEL-WINDOW: Error: mainContentView is nil");
        return Napi::Boolean::New(info.Env(), false);
    }

    NSString *appearanceName = [NSString stringWithUTF8String:info[1].As<Napi::String>().Utf8Value().c_str()];
    NSWindow *nswindow = [mainContentView window];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([appearanceName isEqualToString:@"dark"]) {
            nswindow.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
        } else if ([appearanceName isEqualToString:@"light"]) {
            nswindow.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
        } else if ([appearanceName isEqualToString:@"auto"]) {
            nswindow.appearance = nil; // This will make the window follow the system appearance
        } else {
            NSLog(@"MAC-PANEL-WINDOW: Invalid appearance name: %@", appearanceName);
        }
    });

    if ([appearanceName isEqualToString:@"dark"] || [appearanceName isEqualToString:@"light"] || [appearanceName isEqualToString:@"auto"]) {
        return Napi::Boolean::New(info.Env(), true);
    } else {
        return Napi::Boolean::New(info.Env(), false);
    }
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
    exports.Set(Napi::String::New(env, "makePanel"), Napi::Function::New(env, MakePanel));
    exports.Set(Napi::String::New(env, "makeKeyWindow"), Napi::Function::New(env, MakeKeyWindow));
    exports.Set(Napi::String::New(env, "makeWindow"), Napi::Function::New(env, MakeWindow));
    exports.Set(Napi::String::New(env, "hideInstant"), Napi::Function::New(env, HideInstant));
    exports.Set(Napi::String::New(env, "getWindowBackgroundColor"), Napi::Function::New(env, GetWindowBackgroundColor));
    exports.Set(Napi::String::New(env, "getLabelColor"), Napi::Function::New(env, GetLabelColor));
    exports.Set(Napi::String::New(env, "getTextColor"), Napi::Function::New(env, GetTextColor));
    exports.Set(Napi::String::New(env, "setAppearance"), Napi::Function::New(env, SetAppearance));
    exports.Set(Napi::String::New(env, "prepForClose"), Napi::Function::New(env, PrepForClose));
    return exports;
}

NODE_API_MODULE(addon, Init)
