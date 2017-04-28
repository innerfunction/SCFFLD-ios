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
//  Created by Julian Goacher on 22/10/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "SCSlideViewController.h"
#import "SCViewController.h"
#import "SCNavigationViewController.h"

@implementation SCSlideViewController

- (id)init {
    self = [super init];
    if (self) {
        self.slidePosition = @"left";
    }
    return self;
}

- (void)setSlideView:(id)slideView {
    if ([slideView isKindOfClass:[UIView class]]) {
        slideView = [[SCViewController alloc] initWithView:(UIView *)slideView];
    }
    if ([slideView isKindOfClass:[UIViewController class]]) {
        _slideView = slideView;
        self.rearViewController = slideView;
    }
}

- (void)setMainView:(id)mainView {
    if ([mainView isKindOfClass:[UIView class]]) {
        mainView = [[SCViewController alloc] initWithView:(UIView *)mainView];
    }
    if ([mainView isKindOfClass:[UIViewController class]]) {
        _mainView = mainView;
        self.frontViewController = mainView;
        //[self setFrontViewController:mainView animated:YES];
        
        // Set gesture receive on main view.
        if ([mainView isKindOfClass:[SCNavigationViewController class]]) {
            [(SCNavigationViewController *)mainView replaceBackSwipeGesture:self.panGestureRecognizer];
        }
        else {
            [((UIViewController *)mainView).view addGestureRecognizer:self.panGestureRecognizer];
        }
    }
}

- (void)setSlidePosition:(NSString *)slidePosition {
    if ([@"right" isEqualToString:slidePosition]) {
        slideOpenPosition = FrontViewPositionLeft;
        slideClosedPosition = FrontViewPositionRightMostRemoved;
    }
    else {
        slideOpenPosition = FrontViewPositionRight;
        slideClosedPosition = FrontViewPositionLeftSideMostRemoved;
    }
    self.frontViewPosition = slideClosedPosition;
}

#pragma mark - SCMessageRouter

- (BOOL)routeMessage:(SCMessage *)message sender:(id)sender {
    BOOL routed = NO;
    if ([message hasTarget:@"slideView"]) {
        message = [message popTargetHead];
        if ([message hasEmptyTarget] && [self.slideView conformsToProtocol:@protocol(SCMessageReceiver)]) {
            routed = [(id<SCMessageReceiver>)self.slideView receiveMessage:message sender:sender];
        }
        else if ([self.slideView conformsToProtocol:@protocol(SCMessageRouter)]) {
            routed = [(id<SCMessageRouter>)self.slideView routeMessage:message sender:sender];
        }
    }
    else if ([message hasTarget:@"mainView"]) {
        message = [message popTargetHead];
        if ([message hasEmptyTarget] && [self.mainView conformsToProtocol:@protocol(SCMessageReceiver)]) {
            routed = [(id<SCMessageReceiver>)self.mainView receiveMessage:message sender:sender];
        }
        else if ([self.mainView conformsToProtocol:@protocol(SCMessageRouter)]) {
            routed = [(id<SCMessageRouter>)self.mainView routeMessage:message sender:sender];
        }
        self.frontViewPosition = slideClosedPosition;
    }
    return routed;
}

#pragma mark - SCMessageReceiver

- (BOOL)receiveMessage:(SCMessage *)message sender:(id)sender {
    // NOTE 'open' is deprecated. Note also other deprecations below.
    if ([message hasName:@"show"] || [message hasName:@"open"]) {
        // Replace main view.
        self.mainView = [message.parameters valueForKey:@"view"];
        return YES;
    }
    if ([message hasName:@"show-in-slide"] || [message hasName:@"open-in-slide"]) {
        // Replace the slide view.
        self.slideView = [message.parameters valueForKey:@"view"];
        return YES;
    }
    if ([message hasName:@"open-slide"] || [message hasName:@"show-slide"]) {
        // Open the slide view.
        [self setFrontViewPosition:slideOpenPosition animated:YES];
        return YES;
    }
    if ([message hasName:@"close-slide"] || [message hasName:@"hide-slide"]) {
        // Close the slide view.
        [self setFrontViewPosition:slideClosedPosition animated:YES];
        return YES;
    }
    if ([message hasName:@"toggle-slide"]) {
        [self revealToggleAnimated:YES];
        return YES;
    }
    return NO;
}

@end
