//
//  UIScrollView+Demo.h
//  ScrollViewNestDemo
//
//  Created by XuNing on 2017/11/12.
//  Copyright © 2017年 xuning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (Demo)

- (CGFloat)maxContentOffsetY;
- (BOOL)isReachBottom;
- (BOOL)isReachTop;
- (void)scrollToTopWithAnimated:(BOOL)animated;

@end
