// Copyright 2016 InnerFunction Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Created by Julian Goacher on 23/10/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "SCWebViewController.h"
#import "UIViewController+ImageView.h"
#import "SCAppContainer.h"
#import "SCResource.h"
#import "SCRegExp.h"

@interface SCWebViewController ()

- (void)loadContent;
- (void)showLoadingIndicatorWithCompletion:(void(^)(void))completion;
- (void)hideLoadingImage;

@end

@interface UIActivityIndicatorView (FullScreen) @end

@implementation UIActivityIndicatorView (FullScreen)

- (void)didMoveToSuperview {
    self.frame = self.superview.frame;
}

@end

@implementation SCWebViewController

- (id)init {
    self = [super init];
    if (self) {
        _backgroundColor = [UIColor whiteColor];
        _useHTMLTitle = YES;
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
        _webView = [[UIWebView alloc] init];
        _webView.delegate = self;
        
        self.view = _webView;
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.externalURLSchemes = @[ @"http", @"https" ];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _loadingImageView.frame = _webView.bounds;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadContent];
}

#pragma mark - SCIOCConfigurationAware

- (void)afterIOCConfiguration:(id)configuration {
    [super afterIOCConfiguration:configuration];
    _webView.backgroundColor = _backgroundColor;
    _webView.opaque = _opaque;
    _webView.scrollView.bounces = _scrollViewBounces;
    if (_loadingImage) {
        _loadingImageView = [[UIImageView alloc] initWithImage:_loadingImage];
        _loadingImageView.contentMode = UIViewContentModeCenter;
        _loadingImageView.backgroundColor = _backgroundColor;
        [self.view addSubview:_loadingImageView];
    }
    if (_showLoadingIndicator) {
        _loadingIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:_webView.frame];
        _loadingIndicatorView.hidden = YES;
        [self.view addSubview:_loadingIndicatorView];
    }
}

#pragma mark - web view delegate

- (void)webViewDidFinishLoad:(UIWebView *)view {
    [self hideLoadingImage];
    if (_loadingIndicatorView) {
        _loadingIndicatorView.hidden = YES;
    }
    if (_useHTMLTitle) {
        NSString *title = [view stringByEvaluatingJavaScriptFromString:@"document.title"];
        if ([title length]) {
            self.title = title;
            if (self.parentViewController) {
                self.parentViewController.title = title;
            }
        }
    }
    // Disable long touch events. See http://stackoverflow.com/questions/4314193/how-to-disable-long-touch-in-uiwebview
    [_webView stringByEvaluatingJavaScriptFromString:@"document.body.style.webkitTouchCallout='none'; document.body.style.KhtmlUserSelect='none'"];
    // Change console.log to use the epConsoleLog function.
    //[view stringByEvaluatingJavaScriptFromString:@"console.log = epConsoleLog"];
    _webViewLoaded = YES;
}

// TODO: Note that the web view will URI encode any square brackets in the URL - this can interfere with compound URI parsing.
// TODO: Would be useful to have some way to automatically promote HTML file references - e.g. app:file.html - to something like
//       post:#show+view@[new:WebView+content@app:file.html]
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = [request URL];
    // Allow pre-configured URLs to load.
    if (_allowedExternalURLs) {
        NSString *urlString = [url description];
        for (NSString *allowedURL in _allowedExternalURLs) {
            if ([urlString hasPrefix:allowedURL]) {
                return YES;
            }
        }
    }
    // Load images (identified by file extension) when requested by a user action.
    NSString *ext = [url.pathExtension lowercaseString];
    if ( navigationType == UIWebViewNavigationTypeLinkClicked && (
            [@"jpeg" isEqualToString:ext] ||
            [@"jpg" isEqualToString:ext] ||
            [@"png" isEqualToString:ext] ||
            [@"gif" isEqualToString:ext]) ) {
        [self showImageAtURL:url referenceView:self.view];
        return NO;
    }
    // Always load file: URLs.
    if ([@"file" isEqualToString:url.scheme]) {
        _loadingExternalURL = NO;
        return YES;
    }
    // Always load data: URLs.
    if ([@"data" isEqualToString:url.scheme]) {
        _loadingExternalURL = NO;
        return YES;
    }
    // If loading a pre-configured exernal URL...
    if (_loadingExternalURL) {
        _loadingExternalURL = NO;
        return YES;
    }
    else if (_loadExternalLinks && [_externalURLSchemes containsObject:url.scheme]) {
        return YES;
    }
    else if (_webViewLoaded && (navigationType != UIWebViewNavigationTypeOther)) {
        NSString *message;
        if ([_appContainer isInternalURISchemeName:url.scheme]) {
            message = [url absoluteString];
            // NSURL will present URIs such like 'post:#fragment' as 'post:%23fragment' (i.e. it
            // will escape the leading #; it won't do this for URIs such as post:name#fragment).
            SCRegExp *re = [[SCRegExp alloc] initWithPattern:@"(\\w+):%23(.*)"];
            NSArray *groups = [re match:message];
            if (groups) {
                message = [NSString stringWithFormat:@"%@:#%@", groups[1], groups[2]];
            }
        }
        else {
            message = [NSString stringWithFormat:@"post:#open-url+url=%@", url];
        }
        [self postMessage:message];
        return NO;
    }
    return YES;
}

#pragma mark - private

- (void)loadContent {
    NSURL *contentURL = [NSURL URLWithString:_contentURL];
    // Specified content takes precedence over a contentURL property. Note that contentURL
    // can still be used to specify the content base URL in those cases where it can't
    // otherwise be determined.
    if (_content) {
        if ([_content isKindOfClass:[SCResource class]]) {
            SCResource *resource = (SCResource *)_content;
            NSString *html = [resource asString];
            // Allow a resource to specify the base URL if one isn't explicitly set.
            if (!contentURL && resource.externalURL) {
                contentURL = resource.externalURL;
            }
            [_webView loadHTMLString:html baseURL:contentURL];
        }
        else {
            // Assume content's description will yield valid HTML.
            NSString *html = [_content description];
            [_webView loadHTMLString:html baseURL:contentURL];
        }
    }
    else if (_contentURL) {
        NSURLRequest* req = [NSURLRequest requestWithURL:contentURL];
        _loadingExternalURL = YES;
        [_webView loadRequest:req];
    }
}

- (void)showLoadingIndicatorWithCompletion:(void(^)(void))completion {
    if (_loadingIndicatorView) {
        _loadingIndicatorView.hidden = NO;
        // Execute the completion on the main ui thread, after the spinner has had a chance to display.
        dispatch_async(dispatch_get_main_queue(), completion );
    }
    else completion();
}

- (void)hideLoadingImage {
    if (_loadingImageView && !_loadingImageView.hidden) {
        [UIView animateWithDuration: 0.5f
                              delay: 0.0f
                            options: UIViewAnimationOptionCurveLinear
                         animations: ^{ _loadingImageView.alpha = 0.0; }
                         completion: ^(BOOL finished) { _loadingImageView.hidden = YES; }];
    }
}

#pragma mark - SCMessageReceiver

- (BOOL)receiveMessage:(SCMessage *)message sender:(id)sender {
    if ([message hasName:@"load"]) {
        self.content = [message.parameters objectForKey:@"content"];
        [self loadContent];
        return YES;
    }
    return [super receiveMessage:message sender:sender];
}

@end
