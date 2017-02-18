//
//  TopBottomLayoutViewController.m
//  SCCFLD-testapp
//
//  Created by Julian Goacher on 14/02/2017.
//  Copyright © 2017 InnerFunction. All rights reserved.
//

#import "TopBottomLayoutViewController.h"

@implementation TopBottomLayoutViewController

- (id)init {
    self = [super init];
    self.layoutName = @"TopBottomLayout";
    self.useAutoLayout = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    return self;
}

- (void)setTopView:(id)topView {
    _topView = topView;
    [self addViewComponent:topView withName:@"topView"];
}

- (void)setBottomView:(id)bottomView {
    _bottomView = bottomView;
    [self addViewComponent:bottomView withName:@"bottomView"];
}

@end
