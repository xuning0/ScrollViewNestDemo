//
//  PlanDTableController.h
//  ScrollViewNestDemo
//
//  Created by Joully on 2017/11/17.
//  Copyright © 2017年 xuning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyTableView : UITableView

@end

@interface PlanDTableController : UIViewController

@property (nonatomic,strong) MyTableView *tableView;
@property (nonatomic, copy) void(^tableDidScrollBlock)(CGPoint contentOffset);

@end
