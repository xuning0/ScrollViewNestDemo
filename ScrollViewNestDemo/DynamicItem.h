//
//  DynamicItem.h
//  ScrollViewNestDemo
//
//  Created by XuNing on 2017/11/12.
//  Copyright © 2017年 xuning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DynamicItem : NSObject <UIDynamicItem>

@property (nonatomic, readwrite) CGPoint center;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readwrite) CGAffineTransform transform;

@end
