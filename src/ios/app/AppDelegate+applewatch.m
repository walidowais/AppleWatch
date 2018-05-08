#import "AppDelegate+applewatch.h"
#import "AppleWatch.h"
#import <objc/runtime.h>
#import "MainViewController.h"

@implementation AppDelegate (applewatch)

- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void(^)(NSDictionary *replyInfo))reply {
  // requesting a bit of background processing time, useful when the app was killed instead of running in the background
   __block UIBackgroundTaskIdentifier watchKitHandler;
   watchKitHandler = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"backgroundTask"
                                                                  expirationHandler:^{
                                                                 watchKitHandler = UIBackgroundTaskInvalid;
                                                               }];
   dispatch_after( dispatch_time( DISPATCH_TIME_NOW, (int64_t)NSEC_PER_SEC * 30 ), dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
     [[UIApplication sharedApplication] endBackgroundTask:watchKitHandler];
   } );

  NSString* jsFunction = [userInfo objectForKey:@"action"];

  NSLog(@"In handleWatchKitExtensionRequest, jsFunction: %@", jsFunction);

  NSString* params;
  // TODO 'onVoted' should not be hardcoded!
  if ([jsFunction isEqualToString:@"onVoted"]) {
    if ([[userInfo objectForKey:@"params"] isKindOfClass:[NSData class]]) {
      // animated gif
      params = [NSString stringWithFormat:@"{'type':'base64img', 'data':'data:image/gif;base64,%@'}", [[userInfo objectForKey:@"params"] base64EncodedStringWithOptions:0]];
    } else {
      // text label, emoji, dictated text
      params = [NSString stringWithFormat:@"{'type':'text', 'data':'%@'}", [userInfo objectForKey:@"params"]];
    }
  } else {
    params = [NSString stringWithFormat:@"'%@'", [userInfo objectForKey:@"params"]];
  }

  NSString* result = [NSString stringWithFormat:@"%@(%@)", jsFunction, params == nil ? @"" : params];
  [self callJavascriptFunctionWhenAvailable:result];

  // no need to wait as data is passed back async
  reply(@{});
}

// check every x seconds for the phone  app to be ready, or stop from glance.didDeactivate
// TODO stop after x tries
- (void) callJavascriptFunctionWhenAvailable:(NSString*)function {
  AppleWatch *appleWatch = [self.viewController getCommandInstance:@"AppleWatch"];
  if (appleWatch.initDone) {
    [((UIWebView *)appleWatch.webView) stringByEvaluatingJavaScriptFromString:function];
  } else {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 80 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
      [self callJavascriptFunctionWhenAvailable:function];
    });
  }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

@end