#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <objc/objc-runtime.h>
#include "nan.h"

NAN_METHOD(MakePanel);
NAN_METHOD(MakeKeyWindow);
NAN_METHOD(MakeWindow);

@interface PROPanel : NSWindow
@property (nonatomic, assign) NSInteger previousLevel;
@end

@implementation PROPanel

- (instancetype)init {
    self = [super init];
    if (self) {
        _previousLevel = NSNormalWindowLevel;
    }
    return self;
}


- (NSWindowStyleMask)styleMask {
  return NSWindowStyleMaskTexturedBackground | NSWindowStyleMaskResizable | NSWindowStyleMaskFullSizeContentView | NSWindowStyleMaskNonactivatingPanel;
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

- (void) observeWindowLevel {
    [self addObserver:self forKeyPath:@"level" options:NSKeyValueObservingOptionNew context:NULL];
    NSLog(@"Started observing window level");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"level"]) {
        NSInteger newLevel = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];

        if (newLevel == self.previousLevel) {
            return;
        }

        self.previousLevel = newLevel;
        
        NSWindowCollectionBehavior currentBehavior = self.collectionBehavior;
        NSWindowCollectionBehavior newBehavior;
        
        if (newLevel == NSNormalWindowLevel) {
            newBehavior = NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorFullScreenAuxiliary;
        } else {
            newBehavior = NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
        }

        if (newBehavior != currentBehavior) {
            if (newBehavior & NSWindowCollectionBehaviorCanJoinAllSpaces) {
                NSLog(@"observeValueForKeyPath: ADDING NSWindowCollectionBehaviorCanJoinAllSpaces. Changing collectionBehavior from %ld to %ld", (long)currentBehavior, (long)newBehavior);
            } else {
                NSLog(@"observeValueForKeyPath: REMOVING NSWindowCollectionBehaviorCanJoinAllSpaces. Changing collectionBehavior from %ld to %ld", (long)currentBehavior, (long)newBehavior);
            }
            self.collectionBehavior = newBehavior;
        }
    }
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
  if (@available(macOS 10.14, *)) {
  visualEffectView.material = NSVisualEffectMaterialHUDWindow;
} else {
  // Fallback for earlier versions
}

  visualEffectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;

  [mainContentView addSubview:visualEffectView positioned:NSWindowBelow relativeTo:nil];

  object_setClass(mainContentView.window, [PROPanel class]);

  PROPanel *proPanel = (PROPanel *)mainContentView.window;
  [proPanel observeWindowLevel];  // This will start observing when you call MakePanel

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

void Init(v8::Local<v8::Object> exports) {
  Nan::SetMethod(exports, "makePanel", MakePanel);
  Nan::SetMethod(exports, "makeKeyWindow", MakeKeyWindow);
  Nan::SetMethod(exports, "makeWindow", MakeWindow);
}

NODE_MODULE(addon, Init)
