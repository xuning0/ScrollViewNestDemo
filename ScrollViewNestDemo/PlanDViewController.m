//
//  PlanDViewController.m
//  ScrollViewNestDemo
//
//  Created by Joully on 2017/11/14.
//  Copyright © 2017年 xuning. All rights reserved.
//

#import "PlanDViewController.h"
#import "CommentTableViewController.h"

@interface PlanDViewController ()<UIWebViewDelegate>
@property(nonatomic, strong) UIWebView *webView;
@property(nonatomic, strong) CommentTableViewController *commentTableViewController;
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
    _webView.scrollView.scrollEnabled = NO;
    _webView.delegate = self;
    _webView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_webView];
    
    _commentTableViewController = [[CommentTableViewController alloc] initWithStyle:UITableViewStylePlain];
    [_commentTableViewController.tableView setBackgroundColor:[UIColor clearColor]];
    [_commentTableViewController.view setBackgroundColor:[UIColor clearColor]];
    [self addChildViewController:self.commentTableViewController];
    [self.view addSubview:self.commentTableViewController.view];
    [self.commentTableViewController didMoveToParentViewController:self];
    
    //webview自身不能滚动，它的contentOffset随着tableView而变，这样在操作滚动tableView的时候视觉上webview在滚动
    __weak typeof(self) weakSelf = self;
    _commentTableViewController.tableDidScrollBlock = ^(CGPoint contentOffset) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf.webView.scrollView.contentOffset = contentOffset;
    };
    
    _placeHolderHeadView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, _commentTableViewController.tableView.frame.size.width, 0)];
    [_placeHolderHeadView setBackgroundColor:[UIColor clearColor]];
    _commentTableViewController.tableView.tableHeaderView = _placeHolderHeadView;
    
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


@end
