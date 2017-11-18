//
//  PlanDTableController.m
//  ScrollViewNestDemo
//
//  Created by Joully on 2017/11/17.
//  Copyright © 2017年 xuning. All rights reserved.
//

#import "PlanDTableController.h"

@implementation MyTableView

- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event {
    BOOL isInside = [super pointInside:point withEvent:event];
    if (CGRectContainsPoint(self.tableHeaderView.frame, point)) {
        return NO;
    }
    return isInside;
}

@end

@interface PlanDTableController ()<UITableViewDataSource,UITableViewDelegate>

@end

@implementation PlanDTableController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView = [[MyTableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.decelerationRate = 0;
    [self.view addSubview:self.tableView];
    
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"UITableViewCell"];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"
                                                            forIndexPath:indexPath];
    cell.backgroundColor = [UIColor orangeColor];
    cell.textLabel.text = [NSString stringWithFormat:@"Comment %@", @(indexPath.row)];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.tableDidScrollBlock) {
        self.tableDidScrollBlock(scrollView.contentOffset);
    }
}

@end
