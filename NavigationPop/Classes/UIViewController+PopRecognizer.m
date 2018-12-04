//
//  BaseViewController+PopRecognizer.m
//  PercentDrivenInteractiveTransitionDemo
//
//  Created by lishuai on 2018/12/3.
//  Copyright © 2018 lishuai. All rights reserved.
//

#import "UIViewController+PopRecognizer.h"
#import "NSObject+Swizzled.h"
#import <objc/runtime.h>

const void *const kSnapshotKey = &kSnapshotKey;
const void *const kInteractivePopTransitionKey = &kInteractivePopTransitionKey;

@implementation UIViewController (PopRecognizer)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleSEL:@selector(viewWillDisappear:) withSEL:@selector(ss_viewWillDisappear:)];
        [self swizzleSEL:@selector(viewDidLoad) withSEL:@selector(ss_viewDidLoad)];
    });
}

- (void)ss_viewDidLoad {
    [self ss_viewDidLoad];
    if (self.navigationController != nil && self != self.navigationController.viewControllers.firstObject) {
        UIPanGestureRecognizer *popRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePopRecognizer:)];
        [self.view addGestureRecognizer:popRecognizer];
        popRecognizer.delegate = self;
    }
}

- (void)ss_viewWillDisappear:(BOOL)animated {
    [self ss_viewWillDisappear:animated];
    // Being popped, take a snapshot
    if ([self isMovingFromParentViewController]) {
        self.snapshot = [self.navigationController.view snapshotViewAfterScreenUpdates:NO];
    }
}

- (void)setSnapshot:(UIView *)snapshot {
    objc_setAssociatedObject(self, kSnapshotKey, snapshot, OBJC_ASSOCIATION_RETAIN);
}

- (UIView *)snapshot {
    return objc_getAssociatedObject(self, kSnapshotKey);
}

- (UIPercentDrivenInteractiveTransition *)interactivePopTransition {
    return objc_getAssociatedObject(self, kInteractivePopTransitionKey);
}

#pragma mark - UIPanGestureRecognizer handlers

- (void)handlePopRecognizer:(UIPanGestureRecognizer *)recognizer {
    CGFloat progress = [recognizer translationInView:self.view].x / CGRectGetWidth(self.view.frame);
    progress = MIN(1.0, MAX(0.0, progress));
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // Create a interactive transition and pop the view controller
        UIPercentDrivenInteractiveTransition *interaction = UIPercentDrivenInteractiveTransition.new;
        objc_setAssociatedObject(self, kInteractivePopTransitionKey, interaction, OBJC_ASSOCIATION_RETAIN);
        [self.navigationController popViewControllerAnimated:YES];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        // Update the interactive transition's progress
        [self.interactivePopTransition updateInteractiveTransition:progress];
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        // Finish or cancel the interactive transition
        if (progress > 0.2) {
            [self.interactivePopTransition finishInteractiveTransition];
        } else {
            [self.interactivePopTransition cancelInteractiveTransition];
        }
        
        objc_setAssociatedObject(self, kInteractivePopTransitionKey, nil, OBJC_ASSOCIATION_RETAIN);
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)recognizer {
    return [recognizer velocityInView:self.view].x > 0;
}

@end
