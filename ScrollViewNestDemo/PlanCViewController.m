//
//  PlanCViewController.m
//  ScrollViewNestDemo
//
//  Created by XuNing on 2017/11/12.
//  Copyright © 2017年 xuning. All rights reserved.
//

#import "PlanCViewController.h"
#import <Masonry.h>
#import "CommentTableViewController.h"
#import "UIScrollView+Demo.h"
#import "DynamicItem.h"

#define APP_HEIGHT [UIScreen mainScreen].applicationFrame.size.height

@interface PlanCViewController () <UIGestureRecognizerDelegate, UIDynamicAnimatorDelegate, UIWebViewDelegate>
@property(nonatomic, strong) UIWebView *webView;
@property(nonatomic, strong) CommentTableViewController *commentTableViewController;
@property(nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property(nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
@property(nonatomic, weak) UIDynamicItemBehavior *inertialBehavior;
@property(nonatomic, weak) UIAttachmentBehavior *bounceBehavior;

@property(nonatomic) BOOL isObservingWebContentSize;
@property(nonatomic) CGFloat bounceDistanceThreshold; //边缘处能上拉或下拉的最大距离
@end

@implementation PlanCViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 11.0, *)) {
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    self.bounceDistanceThreshold = self.view.frame.size.height * 0.66;
    [self.view addGestureRecognizer:self.panRecognizer];
    
    [self.view addSubview:self.webView];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    NSString *htmlString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"2" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:htmlString baseURL:nil];
}

- (void)dealloc {
    _panRecognizer.delegate = nil;
    [_webView loadHTMLString:@"" baseURL:nil];
    [_webView stopLoading];
    _webView.delegate = nil;
    [_webView removeFromSuperview];
    [self removeObserverForWebViewContentSize];
}

// 滚动中单击可以停止滚动
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    [self.dynamicAnimator removeAllBehaviors];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.webView.scrollView &&
        [change[NSKeyValueChangeNewKey] CGSizeValue].height != [change[NSKeyValueChangeOldKey] CGSizeValue].height) {
        //取消监听，因为这里会调整contentSize，避免无限递归
        [self removeObserverForWebViewContentSize];
        [self changeWebViewContentSize];
        [self addObserverForWebViewContentSize];
    }
}

#pragma mark - UIGestureRecognizerDelegate
// 避免影响横滑手势
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:self.view];
    return fabs(velocity.y) > fabs(velocity.x);
}

#pragma mark - UIDynamicAnimatorDelegate
//防止误触tableView的点击事件
- (void)dynamicAnimatorWillResume:(UIDynamicAnimator *)animator {
    self.webView.userInteractionEnabled = NO;
    self.commentTableViewController.tableView.userInteractionEnabled = NO;
}

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    self.webView.userInteractionEnabled = YES;
    self.commentTableViewController.tableView.userInteractionEnabled = YES;
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (!self.commentTableViewController.parentViewController) {
        [self addChildViewController:self.commentTableViewController];
        [self.webView.scrollView addSubview:self.commentTableViewController.view];
        [self.commentTableViewController didMoveToParentViewController:self];
        
        // 为了简化逻辑，这里写死了评论列表的尺寸。实际业务可能会有不同尺寸的空列表视图等，就要同时监听评论列表的尺寸
        self.commentTableViewController.view.frame = CGRectMake(0, APP_HEIGHT, self.webView.frame.size.width, APP_HEIGHT);
    }
}

#pragma mark - Event Response
- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            [self.dynamicAnimator removeAllBehaviors];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [recognizer translationInView:self.view];
            [self scrollViewsWithDeltaY:translation.y];
            [recognizer setTranslation:CGPointZero inView:self.view];
        }
            break;
        case UIGestureRecognizerStateEnded: {
            // 这个if是为了避免在拉到边缘时，以一个非常小的初速度松手不回弹的问题
            if (fabs([recognizer velocityInView:self.view].y) < 120) {
                if ([self.commentTableViewController.tableView isReachTop] &&
                    [self.webView.scrollView isReachTop]) {
                    [self performBounceForScrollView:self.webView.scrollView isAtTop:YES];
                } else if ([self.commentTableViewController.tableView isReachBottom] &&
                           [self.webView.scrollView isReachBottom]) {
                    if (self.commentTableViewController.view.frame.size.height < APP_HEIGHT) { //commentTableView不足一屏，webView bounce
                        [self performBounceForScrollView:self.webView.scrollView isAtTop:NO];
                    } else {
                        [self performBounceForScrollView:self.commentTableViewController.tableView isAtTop:NO];
                    }
                }
                return;
            }
            DynamicItem *item = [[DynamicItem alloc] init];
            item.center = CGPointZero;
            __block CGFloat lastCenterY = 0;
            UIDynamicItemBehavior *inertialBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[item]];
            [inertialBehavior addLinearVelocity:CGPointMake(0, -[recognizer velocityInView:self.view].y) forItem:item];
            inertialBehavior.resistance = 2;
            __weak typeof(self) weakSelf = self;
            inertialBehavior.action = ^{
                [weakSelf scrollViewsWithDeltaY:lastCenterY - item.center.y];
                lastCenterY = item.center.y;
            };
            self.inertialBehavior = inertialBehavior;
            [self.dynamicAnimator addBehavior:inertialBehavior];
        }
            break;
        default:
            break;
    }
}

#pragma mark - Private Method
- (void)scrollViewsWithDeltaY:(CGFloat)deltaY {
    if (deltaY < 0) { //上滑
        if ([self.webView.scrollView isReachBottom]) { //webView已滑到底，此时应滑动tableView
            if ([self.commentTableViewController.tableView isReachBottom]) { //tableView也到底
                if (self.commentTableViewController.view.frame.size.height < APP_HEIGHT) { //commentTableView不足一屏，webView bounce
                    self.commentTableViewController.tableView.contentOffset = CGPointMake(0, self.commentTableViewController.tableView.contentSize.height - self.commentTableViewController.tableView.frame.size.height);
                    CGFloat bounceDelta = MAX(0, (self.bounceDistanceThreshold - fabs(self.webView.scrollView.contentOffset.y - self.webView.scrollView.maxContentOffsetY)) / self.bounceDistanceThreshold) * 0.5;
                    self.webView.scrollView.contentOffset = CGPointMake(0, self.webView.scrollView.contentOffset.y - deltaY * bounceDelta);
                    [self performBounceIfNeededForScrollView:self.webView.scrollView isAtTop:NO];
                } else {
                    CGFloat bounceDelta = MAX(0, (self.bounceDistanceThreshold - fabs(self.commentTableViewController.tableView.contentOffset.y - self.commentTableViewController.tableView.maxContentOffsetY)) / self.bounceDistanceThreshold) * 0.5;
                    self.commentTableViewController.tableView.contentOffset = CGPointMake(0, self.commentTableViewController.tableView.contentOffset.y - deltaY * bounceDelta);
                    [self performBounceIfNeededForScrollView:self.commentTableViewController.tableView isAtTop:NO];
                }
            } else {
                self.commentTableViewController.tableView.contentOffset = CGPointMake(0, MIN(self.commentTableViewController.tableView.contentOffset.y - deltaY, [self.commentTableViewController.tableView maxContentOffsetY]));
            }
        } else {
            self.webView.scrollView.contentOffset = CGPointMake(0, MIN(self.webView.scrollView.contentOffset.y - deltaY, [self.webView.scrollView maxContentOffsetY]));
        }
    } else if (deltaY > 0) { //下滑
        if ([self.commentTableViewController.tableView isReachTop]) { //tableView已滑到顶，此时应滑动webView
            if ([self.webView.scrollView isReachTop]) { //webView也到顶
                CGFloat bounceDelta = MAX(0, (self.bounceDistanceThreshold - fabs(self.webView.scrollView.contentOffset.y)) / self.bounceDistanceThreshold) * 0.5;
                self.webView.scrollView.contentOffset = CGPointMake(0, self.webView.scrollView.contentOffset.y - deltaY * bounceDelta);
                [self performBounceIfNeededForScrollView:self.webView.scrollView isAtTop:YES];
            } else {
                self.webView.scrollView.contentOffset = CGPointMake(0, MAX(self.webView.scrollView.contentOffset.y - deltaY, 0));
            }
        } else {
            self.commentTableViewController.tableView.contentOffset = CGPointMake(0, MAX(self.commentTableViewController.tableView.contentOffset.y - deltaY, 0));
        }
    }
}

//区分滚动到边缘处回弹 和 拉到边缘后以极小的初速度滚动
- (void)performBounceIfNeededForScrollView:(UIScrollView *)scrollView isAtTop:(BOOL)isTop {
    if (self.inertialBehavior) {
        [self performBounceForScrollView:scrollView isAtTop:isTop];
    }
}

- (void)performBounceForScrollView:(UIScrollView *)scrollView isAtTop:(BOOL)isTop {
    if (!self.bounceBehavior) {
        [self.dynamicAnimator removeBehavior:self.inertialBehavior];
        
        DynamicItem *item = [[DynamicItem alloc] init];
        item.center = scrollView.contentOffset;
        CGFloat attachedToAnchorY = 0;
        if (scrollView == self.webView.scrollView) {
            attachedToAnchorY = isTop ? 0 : [self.webView.scrollView maxContentOffsetY];
        } else {
            attachedToAnchorY = [self.commentTableViewController.tableView maxContentOffsetY];
        }
        UIAttachmentBehavior *bounceBehavior = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:CGPointMake(0, attachedToAnchorY)];
        bounceBehavior.length = 0;
        bounceBehavior.damping = 1;
        bounceBehavior.frequency = 2;
        __weak typeof(bounceBehavior) weakBounceBehavior = bounceBehavior;
        __weak typeof(self) weakSelf = self;
        bounceBehavior.action = ^{
            scrollView.contentOffset = CGPointMake(0, item.center.y);
            if (fabs(scrollView.contentOffset.y - attachedToAnchorY) < FLT_EPSILON) {
                [weakSelf.dynamicAnimator removeBehavior:weakBounceBehavior];
            }
        };
        self.bounceBehavior = bounceBehavior;
        [self.dynamicAnimator addBehavior:bounceBehavior];
    }
}

- (void)disableDynamicAnimator {
    [self.dynamicAnimator removeAllBehaviors];
}

- (void)addObserverForWebViewContentSize {
    [self.webView.scrollView addObserver:self
                              forKeyPath:@"contentSize"
                                 options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                                 context:nil];
    self.isObservingWebContentSize = YES;
}

- (void)removeObserverForWebViewContentSize {
    if (self.isObservingWebContentSize) {
        [self.webView.scrollView removeObserver:self forKeyPath:@"contentSize"];
        self.isObservingWebContentSize = NO;
    }
}

- (void)changeWebViewContentSize {
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"changeHeight(%f)", self.commentTableViewController.view.frame.size.height]];
    
    //将commentTableViewController位置调整到最底部
    CGRect frame = self.commentTableViewController.view.frame;
    frame.origin.y = self.webView.scrollView.contentSize.height - self.commentTableViewController.view.frame.size.height;
    self.commentTableViewController.view.frame = frame;
    
    //如果commentTableViewController已经有滚动，调整位置后滚回顶部
    if (self.webView.scrollView.contentOffset.y > [self separatorYBetweenArticleAndComment] &&
        self.webView.scrollView.contentOffset.y < [self.webView.scrollView maxContentOffsetY] &&
        self.commentTableViewController.tableView.contentOffset.y > 0) {
        [self.commentTableViewController.tableView scrollToTopWithAnimated:NO];
    }
}

- (CGFloat)separatorYBetweenArticleAndComment {
    return self.webView.scrollView.contentSize.height - self.commentTableViewController.view.frame.size.height - self.webView.scrollView.frame.size.height;
}

#pragma mark - Getters
- (UIWebView *)webView {
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        _webView.scrollView.scrollEnabled = NO;
        _webView.delegate = self;
        [self addObserverForWebViewContentSize];
    }
    return _webView;
}

- (CommentTableViewController *)commentTableViewController {
    if (!_commentTableViewController) {
        _commentTableViewController = [[CommentTableViewController alloc] initWithStyle:UITableViewStylePlain];
        _commentTableViewController.tableView.scrollEnabled = NO;
    }
    return _commentTableViewController;
}

- (UIPanGestureRecognizer *)panRecognizer {
    if (!_panRecognizer) {
        _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
        _panRecognizer.delegate = self;
    }
    return _panRecognizer;
}

- (UIDynamicAnimator *)dynamicAnimator {
    if (!_dynamicAnimator) {
        _dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
        _dynamicAnimator.delegate = self;
    }
    return _dynamicAnimator;
}

@end
