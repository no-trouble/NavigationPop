//
//  UINavigationController+Extend.m
//  PercentDrivenInteractiveTransitionDemo
//
//  Created by lishuai on 2018/12/4.
//  Copyright © 2018 lishuai. All rights reserved.
//

#import "UINavigationController+Extend.h"
#import "NSObject+Swizzled.h"
#import "UIViewController+PopRecognizer.h"

@interface ATTAnimatedTransitioningObject : NSObject <UIViewControllerAnimatedTransitioning>
@property (nonatomic, assign, readonly) UINavigationControllerOperation operation;
@property (nonatomic, strong, readonly) UIViewController *fromVc;
@property (nonatomic, strong, readonly) UIViewController *toVc;
- (instancetype)initWithOperation:(UINavigationControllerOperation)operation fromVc:(UIViewController *)fromVc toVc:(UIViewController *)toVc;
@end

@implementation ATTAnimatedTransitioningObject

- (instancetype)initWithOperation:(UINavigationControllerOperation)operation fromVc:(UIViewController *)fromVc toVc:(UIViewController *)toVc {
    self = [super init];
    if (self) {
        _operation = operation;
        _fromVc = fromVc;
        _toVc = toVc;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.5;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController   = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    if (self.operation == UINavigationControllerOperationPush) { // push
        [[transitionContext containerView] addSubview:fromViewController.snapshot];
        fromViewController.view.hidden = YES;
        
        CGRect frame = [transitionContext finalFrameForViewController:toViewController];
        toViewController.view.frame = CGRectOffset(frame, CGRectGetWidth(frame), 0);
        [[transitionContext containerView] addSubview:toViewController.view];
        
        [UIView animateWithDuration:duration
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             fromViewController.snapshot.alpha = 0.0;
                             fromViewController.snapshot.frame = CGRectInset(fromViewController.view.frame, 20, 20);
                             toViewController.view.frame = CGRectOffset(toViewController.view.frame, -CGRectGetWidth(toViewController.view.frame), 0);
                         }
                         completion:^(BOOL finished) {
                             fromViewController.view.hidden = NO;
                             [fromViewController.snapshot removeFromSuperview];
                             [transitionContext completeTransition:YES];
                         }];
    } else if (self.operation == UINavigationControllerOperationPop) { // pop
        [UIApplication sharedApplication].delegate.window.backgroundColor = [UIColor blackColor];
        
        [fromViewController.view addSubview:fromViewController.snapshot];
        
        BOOL tabBarHidden = fromViewController.tabBarController.tabBar.hidden;
        
        fromViewController.navigationController.navigationBar.hidden = YES;
        fromViewController.tabBarController.tabBar.hidden = YES;
        
        toViewController.snapshot.alpha = 0.5;
        toViewController.snapshot.transform = CGAffineTransformMakeScale(0.97, 0.97);
        
        UIView *toViewWrapperView = [[UIView alloc] initWithFrame:[transitionContext containerView].bounds];
        toViewWrapperView.backgroundColor = UIColor.purpleColor;
        [toViewWrapperView addSubview:toViewController.view];
        
        toViewWrapperView.hidden = YES;
        [transitionContext containerView].backgroundColor = UIColor.blackColor;
        [[transitionContext containerView] addSubview:toViewWrapperView];
        [[transitionContext containerView] addSubview:toViewController.snapshot];
        [[transitionContext containerView] bringSubviewToFront:fromViewController.view];
        
        [UIView animateWithDuration:duration
                              delay:0.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             fromViewController.view.frame = CGRectOffset(fromViewController.view.frame, CGRectGetWidth(fromViewController.view.frame), 0);
                             toViewController.snapshot.alpha = 1.0;
                             toViewController.snapshot.transform = CGAffineTransformIdentity;
                         }
                         completion:^(BOOL finished) {
                             [UIApplication sharedApplication].delegate.window.backgroundColor = [UIColor whiteColor];
                             
                             toViewController.navigationController.navigationBar.hidden = NO;
                             toViewController.tabBarController.tabBar.hidden = tabBarHidden;
                             
                             [fromViewController.snapshot removeFromSuperview];
                             [toViewController.snapshot removeFromSuperview];
                             
                             [toViewWrapperView removeFromSuperview];
                             
                             if (![transitionContext transitionWasCancelled]) {
                                 for (UIView *subview in toViewWrapperView.subviews) {
                                     [[transitionContext containerView] addSubview:subview];
                                 }
                             }
                             
                             [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                         }];
    }
    
}


@end

@implementation UINavigationController (Extend)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleSEL:@selector(viewDidLoad) withSEL:@selector(ss_navViewDidLoad)];
        [self swizzleSEL:@selector(pushViewController:animated:) withSEL:@selector(ss_pushViewController:animated:)];
    });
}

- (void)ss_navViewDidLoad {
    [self ss_navViewDidLoad];
    self.delegate = self;
}

- (void)ss_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    UIViewController *topVc = self.viewControllers.lastObject;
    if (topVc.tabBarController) {
        topVc.snapshot = [topVc.tabBarController.view snapshotViewAfterScreenUpdates:NO];
    } else {
        topVc.snapshot = [topVc.navigationController.view snapshotViewAfterScreenUpdates:NO];
    }
    viewController.hidesBottomBarWhenPushed = YES;
    
    [self ss_pushViewController:viewController animated:animated];
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    return ((ATTAnimatedTransitioningObject *)animationController).fromVc.interactivePopTransition;
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    if (fromVC.interactivePopTransition != nil) {
        return [[ATTAnimatedTransitioningObject alloc] initWithOperation:operation fromVc:fromVC toVc:toVC];
    }
    return nil;
}

@end
