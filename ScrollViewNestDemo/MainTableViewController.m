//
//  MainTableViewController.m
//  ScrollViewNestDemo
//
//  Created by XuNing on 2017/11/12.
//  Copyright © 2017年 xuning. All rights reserved.
//

#import "MainTableViewController.h"
#import "PlanAViewController.h"
#import "PlanCViewController.h"

@interface MainTableViewController ()

@end

@implementation MainTableViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"嵌套方案";
    
    self.tableView.rowHeight = 120;
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"UITableViewCell"];
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"
                                                            forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 0;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"撑到内容高度的webView作为tableView的header\n\n【可能会爆掉内存】";
            break;
        case 1:
            cell.textLabel.text = @"系统自己判断滚动哪个。略\n\n【在临界时会顿一下，需要手指抬起重新滚动】";
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        case 2:
            cell.textLabel.text = @"UIPanGestureRecognizer+UIDynamicAnimator自己管理滚动事件\n\n【简书目前的方案】";
            break;
        default:
            break;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0: {
            PlanAViewController *vc = [[PlanAViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 2: {
            PlanCViewController *vc = [[PlanCViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        default:
            break;
    }
}

@end
