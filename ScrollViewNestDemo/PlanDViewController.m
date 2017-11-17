//
//  PlanDViewController.m
//  ScrollViewNestDemo
//
//  Created by Joully on 2017/11/14.
//  Copyright © 2017年 xuning. All rights reserved.
//

#import "PlanDViewController.h"
#import "PlanDTableController.h"

@interface PlanDViewController ()<UIWebViewDelegate,UIScrollViewDelegate>
@property(nonatomic, strong) UIWebView *webView;
@property(nonatomic, strong) PlanDTableController *commentTableViewController;
@property(nonatomic, strong) UIView *placeHolderHeadView;

@end

@implementation PlanDViewController

- (void)dealloc {
    [_webView loadHTMLString:@"" baseURL:nil];
    [_webView stopLoading];
    _webView.delegate = nil;
    [_webView removeFromSuperview];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    _webView.delegate = self;
    _webView.scrollView.delegate = self;
    _webView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_webView];
    
    _commentTableViewController = [[PlanDTableController alloc] init];
    [_commentTableViewController.view setFrame:self.view.bounds];
    [_commentTableViewController.tableView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.commentTableViewController.tableView];
    
    //超出headView之后,webview自身不能滚动，它的contentOffset随着tableView而变
    __weak typeof(self) weakSelf = self;
    _commentTableViewController.tableDidScrollBlock = ^(CGPoint contentOffset) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf.webView.scrollView.contentOffset = contentOffset;
    };
    
    _placeHolderHeadView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, _commentTableViewController.tableView.frame.size.width, 0)];
    [_placeHolderHeadView setBackgroundColor:[UIColor clearColor]];
    _commentTableViewController.tableView.tableHeaderView = _placeHolderHeadView;
    //重要！这句可以使得tableHead的触摸事件穿透给webview，而不影响其他cell的正常点击！
    _commentTableViewController.tableView.tableHeaderView.userInteractionEnabled = NO;
    
    NSString *htmlString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"1" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:htmlString baseURL:nil];
    
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    //以下“获取webView内容高度，重设headView高度的操作，实际业务里不要放在这里，更优的方案是由服务端下发图片尺寸，在图片未开始加载的时候就计算出实际内容高度”
    
    CGFloat contentHeight = [webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight;"].floatValue;
    [_placeHolderHeadView setFrame:CGRectMake(0, 0, _commentTableViewController.tableView.frame.size.width, contentHeight)];
    [self.commentTableViewController.tableView beginUpdates];
    self.commentTableViewController.tableView.tableHeaderView = _placeHolderHeadView;
    [self.commentTableViewController.tableView endUpdates];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView.superview isKindOfClass:[UIWebView class]]) {
        self.commentTableViewController.tableView.contentOffset = scrollView.contentOffset;
        self.webView.scrollView.contentSize = CGSizeMake(self.commentTableViewController.tableView.contentSize.width, self.commentTableViewController.tableView.contentSize.height);
        return;
    }
}


@end
