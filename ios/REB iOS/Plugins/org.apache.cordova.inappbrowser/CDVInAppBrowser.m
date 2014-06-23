/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVInAppBrowser.h"
#import <Cordova/CDVPluginResult.h>
#import <Cordova/CDVUserAgentUtil.h>
#import <Cordova/CDVJSON.h>
#import <Social/Social.h>
#import <MobileCoreServices/MobileCoreServices.h>
//#import "WebViewJavascriptBridge.h" //source can be found @ https://github.com/gazeing/WebViewJavascriptBridge
#import <Foundation/NSException.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <MobileCoreServices/MobileCoreServices.h>
//#import "MISLinkedinShare.h"
#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>
#import <JavaScriptCore/JavaScriptCore.h>



#define    kInAppBrowserTargetSelf @"_self"
#define    kInAppBrowserTargetSystem @"_system"
#define    kInAppBrowserTargetBlank @"_blank"

#define    kInAppBrowserToolbarBarPositionBottom @"bottom"
#define    kInAppBrowserToolbarBarPositionTop @"top"

#define    TOOLBAR_HEIGHT 44.0
#define    LOCATIONBAR_HEIGHT 21.0
#define    FOOTER_HEIGHT ((TOOLBAR_HEIGHT) + (LOCATIONBAR_HEIGHT))

#pragma mark CDVInAppBrowser

@interface CDVInAppBrowser () {
    NSInteger _previousStatusBarStyle;
    //after loren edit
   // UINavigationController *_navigationController;
}

@end


@implementation CDVInAppBrowser

- (CDVInAppBrowser*)initWithWebView:(UIWebView*)theWebView
{
    
    NSLog(@"begin    initWithWebView %@",theWebView);
    self = [super initWithWebView:theWebView];
    if (self != nil) {
        _previousStatusBarStyle = -1;
        _callbackIdPattern = nil;
    }
    

    

    

    return self;
}

- (void)dialogDidSucceed:(NSURL*)url {
    NSLog(@"dialogDidSucceed");
}

- (void)onReset
{
    [self close:nil];
}

- (void)close:(CDVInvokedUrlCommand*)command
{
    if (self.inAppBrowserViewController == nil) {
        NSLog(@"IAB.close() called but it was already closed.");
        return;
    }
    // Things are cleaned up in browserExit.
    [self.inAppBrowserViewController close];
}

- (BOOL) isSystemUrl:(NSURL*)url
{
	if ([[url host] isEqualToString:@"itunes.apple.com"]) {
		return YES;
	}
	
	return NO;
}

-(NSString *) URLEncodeString:(NSString *) str
{
    
    NSMutableString *tempStr = [NSMutableString stringWithString:str];
    [tempStr replaceOccurrencesOfString:@" " withString:@"+" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [tempStr length])];
    
    
    return [[NSString stringWithFormat:@"%@",tempStr] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (void)open:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;

    NSString* url = [command argumentAtIndex:0];
    NSString* target = [command argumentAtIndex:1 withDefault:kInAppBrowserTargetSelf];
    NSString* options = [command argumentAtIndex:2 withDefault:@"" andClass:[NSString class]];

    self.callbackId = command.callbackId;
    
    


    if (url != nil) {
        
        
        NSURL* baseUrl = [self.webView.request URL];
        
        //added by steven 13-06-2014
        //for the issue that cannot open url contains '%'
        
        NSLog(@"NSURL* baseUrl = %@",baseUrl);
        NSLog(@"NSURL* url = %@",url);
        
//        NSURL *URL = [NSURL URLWithString:url];
//        //url = [url stringByAddingPercentEscapesUsingDecoding:NSUTF8StringEncoding];
//        NSString *decodeurl = [[[URL path] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//        NSLog(@"decodeurl = %@",decodeurl);
        
        NSURL* absoluteUrl = [[NSURL URLWithString:url relativeToURL:baseUrl] absoluteURL];
        
        
//        NSString * urlToGrab = [url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//        NSLog(@"NSString* urlToGrab = %@",urlToGrab);
//
//        NSURL *absoluteUrl = [NSURL URLWithString:[urlToGrab stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        

//        NSURL* absoluteUrl = (NSURL*) url;
        
        NSLog(@"absoluteUrl = %@",absoluteUrl);
        
        
        //add end
        if ([self isSystemUrl:absoluteUrl]) {
            target = kInAppBrowserTargetSystem;
        }

        if ([target isEqualToString:kInAppBrowserTargetSelf]) {
            [self openInCordovaWebView:absoluteUrl withOptions:options];
        } else if ([target isEqualToString:kInAppBrowserTargetSystem]) {
            [self openInSystem:absoluteUrl];
        } else { // _blank or anything else
            [self openInInAppBrowser:absoluteUrl withOptions:options];
        }

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"incorrect number of arguments"];
    }

    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)openInInAppBrowser:(NSURL*)url withOptions:(NSString*)options
{
    
    NSLog(@"openInInAppBrowser");
    CDVInAppBrowserOptions* browserOptions = [CDVInAppBrowserOptions parseOptions:options];

    if (browserOptions.clearcache) {
        NSHTTPCookie *cookie;
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (cookie in [storage cookies])
        {
            if (![cookie.domain isEqual: @".^filecookies^"]) {
                [storage deleteCookie:cookie];
            }
        }
    }

    if (browserOptions.clearsessioncache) {
        NSHTTPCookie *cookie;
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (cookie in [storage cookies])
        {
            if (![cookie.domain isEqual: @".^filecookies^"] && cookie.isSessionOnly) {
                [storage deleteCookie:cookie];
            }
        }
    }

    if (self.inAppBrowserViewController == nil) {
        NSString* originalUA = [CDVUserAgentUtil originalUserAgent];
        self.inAppBrowserViewController = [[CDVInAppBrowserViewController alloc] initWithUserAgent:originalUA prevUserAgent:[self.commandDelegate userAgent] browserOptions: browserOptions];
        //add by steven 23-06-14  to store default browser option for showtoolbar
        self.inAppBrowserViewController.defaultBrowserOptions = browserOptions;
        self.inAppBrowserViewController.navigationDelegate = self;

        if ([self.viewController conformsToProtocol:@protocol(CDVScreenOrientationDelegate)]) {
            self.inAppBrowserViewController.orientationDelegate = (UIViewController <CDVScreenOrientationDelegate>*)self.viewController;
        }
    }

    [self.inAppBrowserViewController showLocationBar:browserOptions.location];
    [self.inAppBrowserViewController showToolBar:browserOptions.toolbar :browserOptions.toolbarposition];
    if (browserOptions.closebuttoncaption != nil) {
        [self.inAppBrowserViewController setCloseButtonTitle:browserOptions.closebuttoncaption];
    }
    // Set Presentation Style
    UIModalPresentationStyle presentationStyle = UIModalPresentationFullScreen; // default
    if (browserOptions.presentationstyle != nil) {
        if ([[browserOptions.presentationstyle lowercaseString] isEqualToString:@"pagesheet"]) {
            presentationStyle = UIModalPresentationPageSheet;
        } else if ([[browserOptions.presentationstyle lowercaseString] isEqualToString:@"formsheet"]) {
            presentationStyle = UIModalPresentationFormSheet;
        }
    }
    self.inAppBrowserViewController.modalPresentationStyle = presentationStyle;

    // Set Transition Style
    UIModalTransitionStyle transitionStyle = UIModalTransitionStyleCoverVertical; // default
    if (browserOptions.transitionstyle != nil) {
        if ([[browserOptions.transitionstyle lowercaseString] isEqualToString:@"fliphorizontal"]) {
            transitionStyle = UIModalTransitionStyleFlipHorizontal;
        } else if ([[browserOptions.transitionstyle lowercaseString] isEqualToString:@"crossdissolve"]) {
            transitionStyle = UIModalTransitionStyleCrossDissolve;
        }
    }
    self.inAppBrowserViewController.modalTransitionStyle = transitionStyle;

    // prevent webView from bouncing
    if (browserOptions.disallowoverscroll) {
        if ([self.inAppBrowserViewController.webView respondsToSelector:@selector(scrollView)]) {
            ((UIScrollView*)[self.inAppBrowserViewController.webView scrollView]).bounces = NO;
        } else {
            for (id subview in self.inAppBrowserViewController.webView.subviews) {
                if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
                    ((UIScrollView*)subview).bounces = NO;
                }
            }
        }
    }
  
    // UIWebView options
    self.inAppBrowserViewController.webView.scalesPageToFit = browserOptions.enableviewportscale;
    self.inAppBrowserViewController.webView.mediaPlaybackRequiresUserAction = browserOptions.mediaplaybackrequiresuseraction;
    self.inAppBrowserViewController.webView.allowsInlineMediaPlayback = browserOptions.allowinlinemediaplayback;
    if (IsAtLeastiOSVersion(@"6.0")) {
        self.inAppBrowserViewController.webView.keyboardDisplayRequiresUserAction = browserOptions.keyboarddisplayrequiresuseraction;
        self.inAppBrowserViewController.webView.suppressesIncrementalRendering = browserOptions.suppressesincrementalrendering;
    }
  
    NSLog(@"self.inAppBrowserViewController navigateTo: %@", url);
    
    [self.inAppBrowserViewController navigateTo:url];
    if (!browserOptions.hidden) {
        [self show:nil];
    }
}

- (void)show:(CDVInvokedUrlCommand*)command
{
    if (self.inAppBrowserViewController == nil) {
        NSLog(@"Tried to show IAB after it was closed.");
        return;
    }
    if (_previousStatusBarStyle != -1) {
        NSLog(@"Tried to show IAB while already shown");
        return;
    }
    
    _previousStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;

    CDVInAppBrowserNavigationController* nav = [[CDVInAppBrowserNavigationController alloc]
                                   initWithRootViewController:self.inAppBrowserViewController];
    nav.orientationDelegate = self.inAppBrowserViewController;
    nav.navigationBarHidden = YES;
    // Run later to avoid the "took a long time" log message.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.inAppBrowserViewController != nil) {
            [self.viewController presentViewController:nav animated:YES completion:nil];
        }
    });
}

- (void)openInCordovaWebView:(NSURL*)url withOptions:(NSString*)options
{
    if ([self.commandDelegate URLIsWhitelisted:url]) {
        NSURLRequest* request = [NSURLRequest requestWithURL:url];
        NSLog(@"openInCordovaWebView: %@", url);
        
        //added on 31/MAR/2014 (cachePolicy: NSURLRequestReloadRevalidatingCacheData timeoutInterval:10.0)
    //    NSURLRequest* request = [NSURLRequest requestWithURL:url cachePolicy: NSURLRequestReloadRevalidatingCacheData timeoutInterval:10.0];
        [self.webView loadRequest:request];
    } else { // this assumes the InAppBrowser can be excepted from the white-list
        NSLog(@"openInInAppBrowser: %@", url);
        [self openInInAppBrowser:url withOptions:options];
    }
}

- (void)openInSystem:(NSURL*)url
{
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else { // handle any custom schemes to plugins
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];
    }
}

// This is a helper method for the inject{Script|Style}{Code|File} API calls, which
// provides a consistent method for injecting JavaScript code into the document.
//
// If a wrapper string is supplied, then the source string will be JSON-encoded (adding
// quotes) and wrapped using string formatting. (The wrapper string should have a single
// '%@' marker).
//
// If no wrapper is supplied, then the source string is executed directly.

- (void)injectDeferredObject:(NSString*)source withWrapper:(NSString*)jsWrapper
{
    if (!_injectedIframeBridge) {
        _injectedIframeBridge = YES;
        // Create an iframe bridge in the new document to communicate with the CDVInAppBrowserViewController
        [self.inAppBrowserViewController.webView stringByEvaluatingJavaScriptFromString:@"(function(d){var e = _cdvIframeBridge = d.createElement('iframe');e.style.display='none';d.body.appendChild(e);})(document)"];
    }

    if (jsWrapper != nil) {
        NSString* sourceArrayString = [@[source] JSONString];
        if (sourceArrayString) {
            NSString* sourceString = [sourceArrayString substringWithRange:NSMakeRange(1, [sourceArrayString length] - 2)];
            NSString* jsToInject = [NSString stringWithFormat:jsWrapper, sourceString];
            [self.inAppBrowserViewController.webView stringByEvaluatingJavaScriptFromString:jsToInject];
        }
    } else {
        [self.inAppBrowserViewController.webView stringByEvaluatingJavaScriptFromString:source];
    }
}

- (void)injectScriptCode:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper = nil;

    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"_cdvIframeBridge.src='gap-iab://%@/'+encodeURIComponent(JSON.stringify([eval(%%@)]));", command.callbackId];
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectScriptFile:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
     NSLog(@"injectScriptFile");

    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('script'); c.src = %%@; c.onload = function() { _cdvIframeBridge.src='gap-iab://%@'; }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('script'); c.src = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectStyleCode:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;

    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('style'); c.innerHTML = %%@; c.onload = function() { _cdvIframeBridge.src='gap-iab://%@'; }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('style'); c.innerHTML = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectStyleFile:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;

    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('link'); c.rel='stylesheet'; c.type='text/css'; c.href = %%@; c.onload = function() { _cdvIframeBridge.src='gap-iab://%@'; }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('link'); c.rel='stylesheet', c.type='text/css'; c.href = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (BOOL)isValidCallbackId:(NSString *)callbackId
{
    NSError *err = nil;
    // Initialize on first use
    if (self.callbackIdPattern == nil) {
        self.callbackIdPattern = [NSRegularExpression regularExpressionWithPattern:@"^InAppBrowser[0-9]{1,10}$" options:0 error:&err];
        if (err != nil) {
            // Couldn't initialize Regex; No is safer than Yes.
            return NO;
        }
    }
    if ([self.callbackIdPattern firstMatchInString:callbackId options:0 range:NSMakeRange(0, [callbackId length])]) {
        return YES;
    }
    return NO;
}

/**
 * The iframe bridge provided for the InAppBrowser is capable of executing any oustanding callback belonging
 * to the InAppBrowser plugin. Care has been taken that other callbacks cannot be triggered, and that no
 * other code execution is possible.
 *
 * To trigger the bridge, the iframe (or any other resource) should attempt to load a url of the form:
 *
 * gap-iab://<callbackId>/<arguments>
 *
 * where <callbackId> is the string id of the callback to trigger (something like "InAppBrowser0123456789")
 *
 * If present, the path component of the special gap-iab:// url is expected to be a URL-escaped JSON-encoded
 * value to pass to the callback. [NSURL path] should take care of the URL-unescaping, and a JSON_EXCEPTION
 * is returned if the JSON is invalid.
 */
- (BOOL)webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    
//    NSLog(@"shouldStartLoadWithRequest 2");
    NSURL* url = request.URL;
    BOOL isTopLevelNavigation = [request.URL isEqual:[request mainDocumentURL]];

    // See if the url uses the 'gap-iab' protocol. If so, the host should be the id of a callback to execute,
    // and the path, if present, should be a JSON-encoded value to pass to the callback.
    if ([[url scheme] isEqualToString:@"gap-iab"]) {
        NSString* scriptCallbackId = [url host];
        CDVPluginResult* pluginResult = nil;

        if ([self isValidCallbackId:scriptCallbackId]) {
            NSString* scriptResult = [url path];
            NSError* __autoreleasing error = nil;

            // The message should be a JSON-encoded array of the result of the script which executed.
            if ((scriptResult != nil) && ([scriptResult length] > 1)) {
                scriptResult = [scriptResult substringFromIndex:1];
                NSData* decodedResult = [NSJSONSerialization JSONObjectWithData:[scriptResult dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
                if ((error == nil) && [decodedResult isKindOfClass:[NSArray class]]) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:(NSArray*)decodedResult];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION];
                }
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:@[]];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:scriptCallbackId];
            return NO;
        }
    } else if ((self.callbackId != nil) && isTopLevelNavigation) {
        // Send a loadstart event for each top-level navigation (includes redirects).
        NSLog(@"Send a loadstart event");
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loadstart", @"url":[url absoluteString]}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }

    return YES;
}

- (void)webViewDidStartLoad:(UIWebView*)theWebView
{
//    NSLog(@"webViewDidStartLoad");
    _injectedIframeBridge = NO;
}

- (void)webViewDidFinishLoad:(UIWebView*)theWebView
{
    
     NSLog(@"webViewDidFinishLoad");
    if (self.callbackId != nil) {
        // TODO: It would be more useful to return the URL the page is actually on (e.g. if it's been redirected).
        NSString* url = [self.inAppBrowserViewController.currentURL absoluteString];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loadstop", @"url":url}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
}

- (void)webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error
{
    NSLog(@"didFailLoadWithError");
    
    if (self.callbackId != nil) {
        NSString* url = [self.inAppBrowserViewController.currentURL absoluteString];
        NSLog(@"URL: %@",url);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                      messageAsDictionary:@{@"type":@"loaderror", @"url":url, @"code": [NSNumber numberWithInt:error.code], @"message": error.localizedDescription}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
}

- (void)browserExit
{
     NSLog(@"browserExit");
    if (self.callbackId != nil) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"exit"}];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        self.callbackId = nil;
    }
    // Set navigationDelegate to nil to ensure no callbacks are received from it.
    self.inAppBrowserViewController.navigationDelegate = nil;
    // Don't recycle the ViewController since it may be consuming a lot of memory.
    // Also - this is required for the PDF/User-Agent bug work-around.
    self.inAppBrowserViewController = nil;
        
    _previousStatusBarStyle = -1;

    if (IsAtLeastiOSVersion(@"7.0")) {
        [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle];
    }
}

@end

#pragma mark CDVInAppBrowserViewController
//@interface CDVInAppBrowserViewController()
//@property WebViewJavascriptBridge* bridge;
//@end


@implementation CDVInAppBrowserViewController


@synthesize currentURL;

- (id)initWithUserAgent:(NSString*)userAgent prevUserAgent:(NSString*)prevUserAgent browserOptions: (CDVInAppBrowserOptions*) browserOptions
{
    self = [super init];
    if (self != nil) {
        _userAgent = userAgent;
        _prevUserAgent = prevUserAgent;
        _browserOptions = browserOptions;
        NSLog(@"_webViewDelegate = [[CDVWebViewDelegate alloc] initWithDelegate:self];");
        _webViewDelegate = [[CDVWebViewDelegate alloc] initWithDelegate:self];
        [self createViews];
    }

    return self;
}

- (void)createViews
{
    // We create the views in code for primarily for ease of upgrades and not requiring an external .xib to be included

    CGRect webViewBounds = self.view.bounds;
    BOOL toolbarIsAtBottom = ![_browserOptions.toolbarposition isEqualToString:kInAppBrowserToolbarBarPositionTop];
    webViewBounds.size.height -= _browserOptions.location ? FOOTER_HEIGHT : TOOLBAR_HEIGHT;
    self.webView = [[UIWebView alloc] initWithFrame:webViewBounds];
    
    self.webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

    [self.view addSubview:self.webView];
    [self.view sendSubviewToBack:self.webView];

    NSLog(@"self.webView.delegate = _webViewDelegate;");
    self.webView.delegate = _webViewDelegate;
//    self.webView.delegate = self;
    self.webView.backgroundColor = [UIColor whiteColor];

    self.webView.clearsContextBeforeDrawing = YES;
    self.webView.clipsToBounds = YES;
    self.webView.contentMode = UIViewContentModeScaleToFill;
    self.webView.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
    self.webView.multipleTouchEnabled = YES;
    self.webView.opaque = YES;
    self.webView.scalesPageToFit = NO;
    self.webView.userInteractionEnabled = YES;
    
    // overwrite the 'window.open' to be a 'open://' URL (see above)
    NSError *error = nil;
    NSString *jsFromFile = [NSString stringWithContentsOfURL:[[NSBundle mainBundle]
                                                              URLForResource:@"JS1" withExtension:@"txt"]
                                                    encoding:NSUTF8StringEncoding error:&error];
    __unused NSString *jsOverrides = [self.webView
                                      stringByEvaluatingJavaScriptFromString:jsFromFile];
    
    
    NSLog(@"self.webView   createViews");

    [self createSpinner];


    self.closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    self.closeButton.enabled = YES;


    flexibleSpaceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    fixedSpaceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpaceButton.width = 20;

    float toolbarY = toolbarIsAtBottom ? self.view.bounds.size.height - TOOLBAR_HEIGHT : 0.0;
    CGRect toolbarFrame = CGRectMake(0.0, toolbarY, self.view.bounds.size.width, TOOLBAR_HEIGHT);
    
    self.toolbar = [[UIToolbar alloc] initWithFrame:toolbarFrame];
    self.toolbar.alpha = 1.000;
    self.toolbar.autoresizesSubviews = YES;
    self.toolbar.autoresizingMask = toolbarIsAtBottom ? (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin) : UIViewAutoresizingFlexibleWidth;
    self.toolbar.barStyle = UIBarStyleBlackOpaque;
    self.toolbar.clearsContextBeforeDrawing = NO;
    self.toolbar.clipsToBounds = NO;
    self.toolbar.contentMode = UIViewContentModeScaleToFill;
    self.toolbar.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
    self.toolbar.hidden = NO;
    self.toolbar.multipleTouchEnabled = NO;
    self.toolbar.opaque = NO;
    self.toolbar.userInteractionEnabled = YES;

    CGFloat labelInset = 5.0;
    float locationBarY = toolbarIsAtBottom ? self.view.bounds.size.height - FOOTER_HEIGHT : self.view.bounds.size.height - LOCATIONBAR_HEIGHT;
    
    self.addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelInset, locationBarY, self.view.bounds.size.width - labelInset, LOCATIONBAR_HEIGHT)];
    self.addressLabel.adjustsFontSizeToFitWidth = NO;
    self.addressLabel.alpha = 1.000;
    self.addressLabel.autoresizesSubviews = YES;
    self.addressLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    self.addressLabel.backgroundColor = [UIColor clearColor];
    self.addressLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    self.addressLabel.clearsContextBeforeDrawing = YES;
    self.addressLabel.clipsToBounds = YES;
    self.addressLabel.contentMode = UIViewContentModeScaleToFill;
    self.addressLabel.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
    self.addressLabel.enabled = YES;
    self.addressLabel.hidden = NO;
    self.addressLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    if ([self.addressLabel respondsToSelector:NSSelectorFromString(@"setMinimumScaleFactor:")]) {
        [self.addressLabel setValue:@(10.0/[UIFont labelFontSize]) forKey:@"minimumScaleFactor"];
    } else if ([self.addressLabel respondsToSelector:NSSelectorFromString(@"setMinimumFontSize:")]) {
        [self.addressLabel setValue:@(10.0) forKey:@"minimumFontSize"];
    }

    self.addressLabel.multipleTouchEnabled = NO;
    self.addressLabel.numberOfLines = 1;
    self.addressLabel.opaque = NO;
    self.addressLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    self.addressLabel.text = NSLocalizedString(@"Loading...", nil);
    self.addressLabel.textAlignment = NSTextAlignmentLeft;
    self.addressLabel.textColor = [UIColor colorWithWhite:1.000 alpha:1.000];
    self.addressLabel.userInteractionEnabled = NO;

    NSString* frontArrowString = NSLocalizedString(@"►", nil); // create arrow from Unicode char
    self.forwardButton = [[UIBarButtonItem alloc] initWithTitle:frontArrowString style:UIBarButtonItemStylePlain target:self action:@selector(goForward:)];
    self.forwardButton.enabled = YES;
    self.forwardButton.imageInsets = UIEdgeInsetsZero;

    NSString* backArrowString = NSLocalizedString(@"◄", nil); // create arrow from Unicode char
    self.backButton = [[UIBarButtonItem alloc] initWithTitle:backArrowString style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
    self.backButton.enabled = YES;
    self.backButton.imageInsets = UIEdgeInsetsZero;

    //added by steven 20-06-2014 to remove closebutton
    [self.toolbar setItems:@[self.closeButton, flexibleSpaceButton, self.backButton, fixedSpaceButton, self.forwardButton]];
//    [self.toolbar setItems:@[ flexibleSpaceButton, self.backButton, fixedSpaceButton, self.forwardButton]];

    self.view.backgroundColor = [UIColor grayColor];
    [self.view addSubview:self.toolbar];
    [self.view addSubview:self.addressLabel];
    [self.view addSubview:self.spinner];
    
    
    
    //added by steven for js bridge 13-06-2014
    
    //    WebScriptObject *wso = self.webView.windowScriptObject;
    //    [wso setValue:[WebScriptBridge getWebScriptBridge] forKey:@"yourBridge"];
    
    [self createJavaScriptBridge];
    

    
    
    //add pickerView
    
    [self createPickerView];
    
    
    
    
    //add end
}

























////added by steven 13/06/2014
//
//- (void)viewDidLoad {
//    NSLog(@"viewDidLoad");
//    [super viewDidLoad];
//    
//}

- (void) createSpinner{
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.spinner.alpha = 1.000;
    self.spinner.autoresizesSubviews = YES;
    self.spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    self.spinner.clearsContextBeforeDrawing = NO;
    self.spinner.clipsToBounds = NO;
    self.spinner.contentMode = UIViewContentModeScaleToFill;
    self.spinner.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
    self.spinner.frame = CGRectMake(454.0, 231.0, 20.0, 20.0);
    self.spinner.hidden = YES;
    self.spinner.hidesWhenStopped = YES;
    self.spinner.multipleTouchEnabled = NO;
    self.spinner.opaque = NO;
    self.spinner.userInteractionEnabled = NO;
    [self.spinner stopAnimating];
}

- (void) createJavaScriptBridge{
    if(_bridge){
        NSLog(@"bridge is exist");
        
    }else{
        [WebViewJavascriptBridge enableLogging];
        _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self.webView.delegate handler:^(id data, WVJBResponseCallback responseCallback) {
            NSLog(@"Received message from javascript: %@", data);
            responseCallback(@"Right back atcha");
            [self shareLink:data];
        }];
    }
}


- (void) shareLink : (NSString *) data{
    
    
    NSData *jsonData = [data dataUsingEncoding:NSUTF8StringEncoding];
    NSError *e;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&e];
    NSString *action = [dict valueForKey:@"shareAction"];
    shareUrl = [dict valueForKey:@"shareURL"];
    shareTitle  = [dict valueForKey:@"shareTitle"];
    
    NSLog(@"the action = %@",action);
    NSLog(@"the url = %@",shareUrl);
    NSLog(@"the title = %@",shareTitle);
    
    if ([action isEqual:@"openExternal"]){
        
        if(![shareUrl hasPrefix:@"http"]){
            shareUrl = [@"http://" stringByAppendingString:shareUrl];
        }
        
        NSURL *urlToOpen = [NSURL URLWithString:shareUrl];
        NSLog(@"urlToOpen = %@",urlToOpen);
        if ([[UIApplication sharedApplication] canOpenURL:urlToOpen]) {
            [[UIApplication sharedApplication] openURL:urlToOpen];
        }
    }else{
    
    if (![shareUrl length]==0) {
        if(![myPickerView isEqual:[NSNull null]]){

            [self.view addSubview:myPickerView];

            
        }
    }
        
}
    

    
//    [self shareLinkVia:action TitleToDisplay:title UrlToShare:url];
    
}

- (void) shareLinkVia : (NSString *) action TitleToDisplay:(NSString*)title UrlToShare:(NSString*)urlString{
    if(urlString==NULL){return;}
    if ([action isEqual:@"facebook"]) {

        SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [composeViewController setInitialText:title];
        if (urlString != (id)[NSNull null]) {
//            [composeViewController addURL:[NSURL URLWithString:urlString]];
            [composeViewController addURL:[NSURL URLWithString:urlString]];
        }
        [self presentViewController:composeViewController animated:YES completion:nil];
        [composeViewController setCompletionHandler:^(SLComposeViewControllerResult result) {
            // now check for availability of the app and invoke the correct callback

            
            NSLog(@"composeViewController finish: %d",result);
        }];
        
    }else if ([action isEqual:@"twitter"]){
        SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [composeViewController setInitialText:title];
        if (urlString != (id)[NSNull null]) {
            //            [composeViewController addURL:[NSURL URLWithString:urlString]];
            [composeViewController addURL:[NSURL URLWithString:urlString]];
        }
        [self presentViewController:composeViewController animated:YES completion:nil];
        [composeViewController setCompletionHandler:^(SLComposeViewControllerResult result) {
            // now check for availability of the app and invoke the correct callback
            
            
            NSLog(@"composeViewController finish: %d",result);
        }];

        
    }else if ([action isEqual:@"whatsapp"]){
        
        [self shareViaWhatsApp:title UrlToShare:urlString];
    }else if ([action isEqual:@"email"]){
        
        [self shareViaEmail:title UrlToShare:urlString];
    }
    else if ([action isEqual:@"google+"]){
        
        [self shareViaGooglePlus:title UrlToShare:urlString];
    }
    else if ([action isEqual:@"linkedin"]){
        
        [self shareViaLinkedIn:title UrlToShare:urlString];
    }
}



- (void) shareViaLinkedIn:(NSString*)title UrlToShare:(NSString*)urlString{
    
    
    NSString *linkedinLink = @"http://www.linkedin.com/shareArticle?mini=true&url=";
    linkedinLink = [linkedinLink stringByAppendingString:urlString];
    linkedinLink = [linkedinLink stringByAppendingString:@"&title="];
    linkedinLink = [linkedinLink stringByAppendingString:title];

    NSLog(@"linkedinLink =  %@",linkedinLink);
    NSString* webStringURL = [linkedinLink stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"webStringURL =  %@",webStringURL);
    NSURL *url = [NSURL URLWithString:webStringURL];
    NSLog(@"url =  %@",url);
    
    if (![[UIApplication sharedApplication] openURL:url]){
        
        NSLog(@"%@%@",@"Failed to open url:",[url description]);
        [self showAlert :@"Failed to share url:"];
    }
}



-(void)googlePlusSignIn{
    signIn = [GPPSignIn sharedInstance];
    signIn.shouldFetchGooglePlusUser = YES;
    //signIn.shouldFetchGoogleUserEmail = YES;  // Uncomment to get the user's email
    
    // You previously set kClientId in the "Initialize the Google+ client" step
    signIn.clientID = @"1054240877036-e2nprkqhn5p5n2cieg6ph6lr8e846f0o.apps.googleusercontent.com";
    //    signIn.clientID = kClientId;
    // Uncomment one of these two statements for the scope you chose in the previous step
    signIn.scopes = @[ kGTLAuthScopePlusLogin ];  // "https://www.googleapis.com/auth/plus.login" scope
//    signIn.scopes = @[ @"profile" ];            // "profile" scope
    
    // Optional: declare signIn.actions, see "app activities"
    signIn.delegate = self;
    [signIn authenticate];
}
- (void)finishedWithAuth: (GTMOAuth2Authentication *)auth
                   error: (NSError *) error {
    if (error) {
        NSLog(@"Received error %@ and auth object %@",error, auth);
        [self showAlert :@"Google+ is not working on your phone, please check it."];
    }else{
        NSLog(@"login success %@", auth);
        [self shareViaGooglePlus:shareTitle UrlToShare:shareUrl];
        
    }
}

- (void)presentSignInViewController:(UIViewController *)viewController {
    // This is an example of how you can implement it if your app is navigation-based.
    [[self navigationController] pushViewController:viewController animated:YES];
}

-(void)shareViaGooglePlus:(NSString*)title UrlToShare:(NSString*)urlString{

    if (!signIn.authentication) {
         [self googlePlusSignIn];
    }
    else{
//        [signIn trySilentAuthentication];

        id<GPPNativeShareBuilder> shareBuilder = [[GPPShare sharedInstance] nativeShareDialog];
        
        // This line will fill out the title, description, and thumbnail from
        // the URL that you are sharing and includes a link to that URL.
        [shareBuilder setURLToShare:[NSURL URLWithString:urlString]];
        
        [shareBuilder open];
    }

}


- (bool)isEmailAvailable {
    Class messageClass = (NSClassFromString(@"MFMailComposeViewController"));
    return messageClass != nil && [messageClass canSendMail];
}
- (void)shareViaEmail:(NSString*)title UrlToShare:(NSString*)urlString {
    if ([self isEmailAvailable]) {
        MFMailComposeViewController* draft = [[MFMailComposeViewController alloc] init];
        draft.mailComposeDelegate = self;
        
        if (urlString != (id)[NSNull null]) {
            NSString *message =urlString;
            BOOL isHTML = [message rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch].location != NSNotFound;
            [draft setMessageBody:message isHTML:isHTML];
        }
        
        if (title != (id)[NSNull null]) {
            [draft setSubject: title];
        }
        

        
        if (draft) [self presentModalViewController:draft animated:YES];

        
    } else {
        [self showAlert :@"Mail is not working on your phone, please check it."];
    }


}

/**
 * Delegate will be called after the mail composer did finish an action
 * to dismiss the view.
 */
- (void) mailComposeController:(MFMailComposeViewController*)controller
           didFinishWithResult:(MFMailComposeResult)result
                         error:(NSError*)error {
//    bool ok = result == MFMailComposeResultSent;
    [self dismissViewControllerAnimated:YES completion:nil];

}


- (bool)canShareViaWhatsApp {
    return [[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString:@"whatsapp://app"]];
}

- (void)shareViaWhatsApp:(NSString*)title UrlToShare:(NSString*)urlString {
    if ([self canShareViaWhatsApp]) {
        NSString *message   = title;

        {
            // append an url to a message, if both are passed
            NSString * shareString = @"";
            if (message != (id)[NSNull null]) {
                shareString = message;
            }
            if (urlString != (id)[NSNull null]) {
                if ([shareString isEqual: @""]) {
                    shareString = urlString;
                } else {
                    shareString = [NSString stringWithFormat:@"%@ %@", shareString, urlString];
                }
            }
            NSString * encodedShareString = [shareString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            // also encode the '=' character
            encodedShareString = [encodedShareString stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
            NSString * encodedShareStringForWhatsApp = [NSString stringWithFormat:@"whatsapp://send?text=%@", encodedShareString];
            
            NSURL *whatsappURL = [NSURL URLWithString:encodedShareStringForWhatsApp];
            [[UIApplication sharedApplication] openURL: whatsappURL];
        }

        
    } else {
        
        [self showAlert :@"WhatsApp is not working on your phone, please check it."];

    }
}

-(void) showAlert:(NSString *) alertMsg{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                    message:alertMsg
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

//implementation for picker view

- (void)createPickerView{
    myPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 300,300, 616)];
    myPickerView.backgroundColor = [UIColor whiteColor];
    myPickerView.delegate = self;
    myPickerView.showsSelectionIndicator = YES;
    
    
    shareApps = [NSArray arrayWithObjects:
                 @"Facebook",
                 @"Twitter",
                 @"Whatsapp",
                 @"Email",
                 @"Google+",
                 @"LinkedIn",
                 nil];
}

//- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
//    UILabel* label = (UILabel*)view;
//    if (view == nil){
//        label= [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 190, 44)];
//        
////        label.textAlignment = UITextAlignmentRight;
//        //Set other properties if you need like font, text color etc
////        ...
//    }
//    label.text = @"test title";
//    return label;
//}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    // Handle the selection
    NSLog(@"didSelectRow : %ld",(long)row);
    
    [self shareLinkVia:[[shareApps objectAtIndex:row] lowercaseString] TitleToDisplay:shareTitle UrlToShare:shareUrl];
    [myPickerView removeFromSuperview];

}

// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
//    NSUInteger numRows = 5;
    
    return [shareApps count];
}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *title;
    title = [shareApps objectAtIndex:row];
    
    return title;
}

// tell the picker the width of each row for a given component
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    int sectionWidth = 300;
    
    return sectionWidth;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




//add end
























- (void) setWebViewFrame : (CGRect) frame {
//    NSLog(@"Setting the WebView's frame to %@", NSStringFromCGRect(frame));
    [self.webView setFrame:frame];
}

- (void)setCloseButtonTitle:(NSString*)title
{
    // the advantage of using UIBarButtonSystemItemDone is the system will localize it for you automatically
    // but, if you want to set this yourself, knock yourself out (we can't set the title for a system Done button, so we have to create a new one)
    self.closeButton = nil;
    self.closeButton = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    self.closeButton.enabled = YES;
    self.closeButton.tintColor = [UIColor colorWithRed:60.0 / 255.0 green:136.0 / 255.0 blue:230.0 / 255.0 alpha:1];

    NSMutableArray* items = [self.toolbar.items mutableCopy];
    [items replaceObjectAtIndex:0 withObject:self.closeButton];
    [self.toolbar setItems:items];
}

- (void)showLocationBar:(BOOL)show
{
    CGRect locationbarFrame = self.addressLabel.frame;

    BOOL toolbarVisible = !self.toolbar.hidden;

    // prevent double show/hide
    if (show == !(self.addressLabel.hidden)) {
        return;
    }

    if (show) {
        self.addressLabel.hidden = NO;

        if (toolbarVisible) {
            // toolBar at the bottom, leave as is
            // put locationBar on top of the toolBar

            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= FOOTER_HEIGHT;
            [self setWebViewFrame:webViewBounds];

            locationbarFrame.origin.y = webViewBounds.size.height;
            self.addressLabel.frame = locationbarFrame;
        } else {
            // no toolBar, so put locationBar at the bottom

            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= LOCATIONBAR_HEIGHT;
            [self setWebViewFrame:webViewBounds];

            locationbarFrame.origin.y = webViewBounds.size.height;
            self.addressLabel.frame = locationbarFrame;
        }
    } else {
        self.addressLabel.hidden = YES;

        if (toolbarVisible) {
            // locationBar is on top of toolBar, hide locationBar

            // webView take up whole height less toolBar height
            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= TOOLBAR_HEIGHT;
            [self setWebViewFrame:webViewBounds];
        } else {
            // no toolBar, expand webView to screen dimensions
            [self setWebViewFrame:self.view.bounds];
        }
    }
}

- (void)showToolBar:(BOOL)show : (NSString *) toolbarPosition
{

    NSLog(@"showToolBar=====%hhd",show);
    
    CGRect toolbarFrame = self.toolbar.frame;
    CGRect locationbarFrame = self.addressLabel.frame;

    BOOL locationbarVisible = !self.addressLabel.hidden;

    // prevent double show/hide
    if (show == !(self.toolbar.hidden)) {
        return;
    }

    if (show) {
        self.toolbar.hidden = NO;
        CGRect webViewBounds = self.view.bounds;
        
        if (locationbarVisible) {
            // locationBar at the bottom, move locationBar up
            // put toolBar at the bottom
            webViewBounds.size.height -= FOOTER_HEIGHT;
            locationbarFrame.origin.y = webViewBounds.size.height;
            self.addressLabel.frame = locationbarFrame;
            self.toolbar.frame = toolbarFrame;
        } else {
            // no locationBar, so put toolBar at the bottom
            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= TOOLBAR_HEIGHT;
            self.toolbar.frame = toolbarFrame;
        }
        
        if ([toolbarPosition isEqualToString:kInAppBrowserToolbarBarPositionTop]) {
            toolbarFrame.origin.y = 0;
            webViewBounds.origin.y += toolbarFrame.size.height;
            [self setWebViewFrame:webViewBounds];
        } else {
            toolbarFrame.origin.y = (webViewBounds.size.height + LOCATIONBAR_HEIGHT);
        }
        [self setWebViewFrame:webViewBounds];
        
    } else {
        self.toolbar.hidden = YES;

        if (locationbarVisible) {
            // locationBar is on top of toolBar, hide toolBar
            // put locationBar at the bottom

            // webView take up whole height less locationBar height
            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= LOCATIONBAR_HEIGHT;
            [self setWebViewFrame:webViewBounds];

            // move locationBar down
            locationbarFrame.origin.y = webViewBounds.size.height;
            self.addressLabel.frame = locationbarFrame;
        } else {
            // no locationBar, expand webView to screen dimensions
            [self setWebViewFrame:self.view.bounds];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self.webView loadHTMLString:nil baseURL:nil];
    [CDVUserAgentUtil releaseLock:&_userAgentLockToken];
    [super viewDidUnload];
}
    
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)closePopUp{
    [wvPopUp removeFromSuperview];
    wvPopUp = nil;
    //restore the default setting of toolbar
    [self showToolBar:self.defaultBrowserOptions.toolbar  :self.defaultBrowserOptions.toolbarposition];
    [self showLocationBar:self.defaultBrowserOptions.location];
}

- (void)close
{
    //added by steven, if the popup window exist, then close it.
    if (wvPopUp) {

        [self closePopUp];
    }else{
    
    
        [CDVUserAgentUtil releaseLock:&_userAgentLockToken];
        self.currentURL = nil;
    
        if ((self.navigationDelegate != nil) && [self.navigationDelegate respondsToSelector:@selector(browserExit)])    {
            [self.navigationDelegate browserExit];
        }

        // Run later to avoid the "took a long time" log message.
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self respondsToSelector:@selector(presentingViewController)]) {
                [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
            } else {
                [[self parentViewController] dismissModalViewControllerAnimated:YES];
            }
        });
    }
}

- (void)navigateTo:(NSURL*)url
{
   
    NSLog(@"navigateTo ===%@",url);
    NSURLRequest* request = [NSURLRequest requestWithURL:url];

    if (_userAgentLockToken != 0) {
        [self.webView loadRequest:request];
    } else {
        [CDVUserAgentUtil acquireLock:^(NSInteger lockToken) {
            _userAgentLockToken = lockToken;
            [CDVUserAgentUtil setUserAgent:_userAgent lockToken:lockToken];
            [self.webView loadRequest:request];
        }];
    }
}

- (void)goBack:(id)sender
{
    [self.webView goBack];
}

- (void)goForward:(id)sender
{
    [self.webView goForward];
}
    
- (void)viewWillAppear:(BOOL)animated
{
    if (IsAtLeastiOSVersion(@"7.0")) {
        [[UIApplication sharedApplication] setStatusBarStyle:[self preferredStatusBarStyle]];
    }
    [self rePositionViews];
    
    [super viewWillAppear:animated];
}

//
// On iOS 7 the status bar is part of the view's dimensions, therefore it's height has to be taken into account.
// The height of it could be hardcoded as 20 pixels, but that would assume that the upcoming releases of iOS won't
// change that value.
//
- (float) getStatusBarOffset {
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    float statusBarOffset = IsAtLeastiOSVersion(@"7.0") ? MIN(statusBarFrame.size.width, statusBarFrame.size.height) : 0.0;
    return statusBarOffset;
}

- (void) rePositionViews {
    if ([_browserOptions.toolbarposition isEqualToString:kInAppBrowserToolbarBarPositionTop]) {
        [self.webView setFrame:CGRectMake(self.webView.frame.origin.x, TOOLBAR_HEIGHT, self.webView.frame.size.width, self.webView.frame.size.height)];
        [self.toolbar setFrame:CGRectMake(self.toolbar.frame.origin.x, [self getStatusBarOffset], self.toolbar.frame.size.width, self.toolbar.frame.size.height)];
    }
}

#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView*)theWebView
{
    // loading url, start spinner, update back/forward
    
//     NSLog(@"webViewDidStartLoad");

    self.addressLabel.text = NSLocalizedString(@"Loading...", nil);
    self.backButton.enabled = theWebView.canGoBack;
    self.forwardButton.enabled = theWebView.canGoForward;

    [self.spinner startAnimating];

    return [self.navigationDelegate webViewDidStartLoad:theWebView];
}



- (BOOL)webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    
//    NSLog(@"webViewDidStartLoad 1");
    BOOL isTopLevelNavigation = [request.URL isEqual:[request mainDocumentURL]];

    if (isTopLevelNavigation) {
        self.currentURL = request.URL;
    }
    
    
    
    //added by steven for popup window
    NSString *realUrl = request.URL.absoluteString;
    NSLog(@"realUrl: %@", realUrl);
    BOOL isLinkForLogin = [realUrl hasPrefix:@"https://disqus.com"]
//            ||[realUrl hasPrefix:@"https://www.facebook.com"]
            ||[realUrl hasPrefix:@"https://twitter.com/oauth/"]
            ||[realUrl hasPrefix:@"http://disqus.com/_ax"]
            ||[realUrl hasPrefix:@"https://m.facebook.com/"];
    
    // 3. time has been selected - close the pop-up window
    if ([realUrl rangeOfString:@"back"].location == 0)
    {
        [self closePopUp];
        return NO;
    }
    
    if (isLinkForLogin) {

        
        // 2. we're loading it and have already created it, etc. so just let it load
        if (wvPopUp)
            return YES;
        
        // 1. we have a 'popup' request - create the new view and display it
        UIWebView *wv = [self popUpWebview];
        [wv loadRequest:request];
        return NO;
    }

 
    
    
    
    
    return [self.navigationDelegate webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType];
}


//added by steven for popup window and close it

- (UIWebView *) popUpWebview
{
    CGRect webViewBounds = self.view.bounds;
//    BOOL toolbarIsAtBottom = ![_browserOptions.toolbarposition isEqualToString:kInAppBrowserToolbarBarPositionTop];
    webViewBounds.size.height -= true ? FOOTER_HEIGHT : TOOLBAR_HEIGHT;
//    self.webView = [[UIWebView alloc] initWithFrame:webViewBounds];
    // Create a web view that fills the entire window, minus the toolbar height
    UIWebView *webView = [[UIWebView alloc]
                          initWithFrame:webViewBounds];
//                          CGRectMake(0, 0, (float)self.view.bounds.size.width,
//                                                   (float)self.view.bounds.size.height)];
    webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    webView.scalesPageToFit = YES;
    webView.delegate = self;
    // Add to windows array and make active window
    wvPopUp = webView;
    

    [self.view addSubview:webView];
//    [self.view sendSubviewToBack:webView];
//    [self.toolbar setItems:@[self.closeButton, flexibleSpaceButton, self.backButton, fixedSpaceButton, self.forwardButton]];
//    [self.toolbar setItems:@[ flexibleSpaceButton, self.backButton, fixedSpaceButton, self.forwardButton]];
    
    self.view.backgroundColor = [UIColor grayColor];
    [self.view addSubview:self.toolbar];
    [self.view addSubview:self.addressLabel];
    [self.view addSubview:self.spinner];
    
    [self setCloseButtonTitle:@"Done"];
    [self.spinner startAnimating];
    [self showLocationBar:true];
    [self showToolBar:true :self.defaultBrowserOptions.toolbarposition];
   
    return webView;
}

- (void)webViewDidFinishLoad:(UIWebView*)theWebView
{
    // update url, stop spinner, update back/forward
    
//    NSLog(@"webViewDidFinishLoad");
    
//    //add by steven 23-06-14
//    //if the link go to other website for login then show toolbar
//    //if stay in our website, keep the origin setting of toolbar
//    NSString *realUrl =[self.currentURL absoluteString];
////    if ([realUrl hasPrefix:@"http://www.rebonline.com.au"]) {
////        self.lastUrlBeforeLogin = realUrl;
////         NSLog(@"self.lastUrlBeforeLogin = %@",self.lastUrlBeforeLogin);
////    }
//    BOOL isLinkForLogin = [realUrl hasPrefix:@"https://disqus.com"]
//    ||[realUrl hasPrefix:@"https://www.facebook.com"]
//    ||[realUrl hasPrefix:@"https://twitter.com"]
//    ||[realUrl hasPrefix:@"https://accounts.google.com"]
//    ||[realUrl hasPrefix:@"https://m.facebook.com/"];
////    NSLog(@"request.URL = %@",self.currentURL);
//    NSLog(@"NSString *realUrl = %@",realUrl);
//    if (isLinkForLogin) {
//        [self showToolBar:true  :self.defaultBrowserOptions.toolbarposition];
//    }else{
//        [self showToolBar:self.defaultBrowserOptions.toolbar  :self.defaultBrowserOptions.toolbarposition];
//    }
//    
//    BOOL isLinkLoginSuccess = [realUrl hasPrefix:@"http://disqus.com/next/login-success/"];
//    if (isLinkLoginSuccess) {
////        [self navigateTo:[NSURL URLWithString:self.lastUrlBeforeLogin]];
//        
//
//            [self.webView goBack];
//            [self.webView goBack];
//   
//    }
    
    // this is a pop-up window
    if (wvPopUp)
    {
        // overwrite the 'window.close' to be a 'back://' URL (see above)
        NSError *error = nil;
        NSString *jsFromFile = [NSString stringWithContentsOfURL:[[NSBundle mainBundle]
                                                                  URLForResource:@"JS2" withExtension:@"txt"]
                                                        encoding:NSUTF8StringEncoding error:&error];
        __unused NSString *jsOverrides = [wvPopUp
                                          stringByEvaluatingJavaScriptFromString:jsFromFile];   
    }
    
    
    

    self.addressLabel.text = [self.currentURL absoluteString];
    self.backButton.enabled = theWebView.canGoBack;
    self.forwardButton.enabled = theWebView.canGoForward;

    [self.spinner stopAnimating];

    // Work around a bug where the first time a PDF is opened, all UIWebViews
    // reload their User-Agent from NSUserDefaults.
    // This work-around makes the following assumptions:
    // 1. The app has only a single Cordova Webview. If not, then the app should
    //    take it upon themselves to load a PDF in the background as a part of
    //    their start-up flow.
    // 2. That the PDF does not require any additional network requests. We change
    //    the user-agent here back to that of the CDVViewController, so requests
    //    from it must pass through its white-list. This *does* break PDFs that
    //    contain links to other remote PDF/websites.
    // More info at https://issues.apache.org/jira/browse/CB-2225
    BOOL isPDF = [@"true" isEqualToString :[theWebView stringByEvaluatingJavaScriptFromString:@"document.body==null"]];
    if (isPDF) {
        [CDVUserAgentUtil setUserAgent:_prevUserAgent lockToken:_userAgentLockToken];
    }

    [self.navigationDelegate webViewDidFinishLoad:theWebView];
}

- (void)webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error
{
    //added on 31/MAR/2014
    if(error.code == -999 || error.code == -1009)
        return;
    // log fail message, stop spinner, update back/forward
    NSLog(@"webView:didFailLoadWithError - %ld: %@", (long)error.code, [error localizedDescription]);

    self.backButton.enabled = theWebView.canGoBack;
    self.forwardButton.enabled = theWebView.canGoForward;
    [self.spinner stopAnimating];

    self.addressLabel.text = NSLocalizedString(@"Load Error", nil);

    [self.navigationDelegate webView:theWebView didFailLoadWithError:error];
}

#pragma mark CDVScreenOrientationDelegate

- (BOOL)shouldAutorotate
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(shouldAutorotate)]) {
        return [self.orientationDelegate shouldAutorotate];
    }
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        return [self.orientationDelegate supportedInterfaceOrientations];
    }

    return 1 << UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(shouldAutorotateToInterfaceOrientation:)]) {
        return [self.orientationDelegate shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }

    return YES;
}





@end

@implementation CDVInAppBrowserOptions

- (id)init
{
    if (self = [super init]) {
        // default values
        self.location = YES;
        self.toolbar = YES;
        self.closebuttoncaption = nil;
        self.toolbarposition = kInAppBrowserToolbarBarPositionBottom;
        self.clearcache = NO;
        self.clearsessioncache = NO;

        self.enableviewportscale = NO;
        self.mediaplaybackrequiresuseraction = NO;
        self.allowinlinemediaplayback = NO;
        self.keyboarddisplayrequiresuseraction = YES;
        self.suppressesincrementalrendering = NO;
        self.hidden = NO;
        self.disallowoverscroll = NO;
    }

    return self;
}

+ (CDVInAppBrowserOptions*)parseOptions:(NSString*)options
{
    CDVInAppBrowserOptions* obj = [[CDVInAppBrowserOptions alloc] init];

    // NOTE: this parsing does not handle quotes within values
    NSArray* pairs = [options componentsSeparatedByString:@","];

    // parse keys and values, set the properties
    for (NSString* pair in pairs) {
        NSArray* keyvalue = [pair componentsSeparatedByString:@"="];

        if ([keyvalue count] == 2) {
            NSString* key = [[keyvalue objectAtIndex:0] lowercaseString];
            NSString* value = [keyvalue objectAtIndex:1];
            NSString* value_lc = [value lowercaseString];

            BOOL isBoolean = [value_lc isEqualToString:@"yes"] || [value_lc isEqualToString:@"no"];
            NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setAllowsFloats:YES];
            BOOL isNumber = [numberFormatter numberFromString:value_lc] != nil;

            // set the property according to the key name
            if ([obj respondsToSelector:NSSelectorFromString(key)]) {
                if (isNumber) {
                    [obj setValue:[numberFormatter numberFromString:value_lc] forKey:key];
                } else if (isBoolean) {
                    [obj setValue:[NSNumber numberWithBool:[value_lc isEqualToString:@"yes"]] forKey:key];
                } else {
                    [obj setValue:value forKey:key];
                }
            }
        }
    }

    return obj;
}

@end

@implementation CDVInAppBrowserNavigationController : UINavigationController

#pragma mark CDVScreenOrientationDelegate

- (BOOL)shouldAutorotate
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(shouldAutorotate)]) {
        return [self.orientationDelegate shouldAutorotate];
    }
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        return [self.orientationDelegate supportedInterfaceOrientations];
    }

    return 1 << UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(shouldAutorotateToInterfaceOrientation:)]) {
        return [self.orientationDelegate shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }

    return YES;
}


@end

