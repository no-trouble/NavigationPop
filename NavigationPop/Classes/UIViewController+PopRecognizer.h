//
//  BaseViewController+PopRecognizer.h
//  PercentDrivenInteractiveTransitionDemo
//
//  Created by lishuai on 2018/12/3.
//  Copyright © 2018 lishuai. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (PopRecognizer) <UIGestureRecognizerDelegate>

@property (nonatomic, strong, readonly) UIPercentDrivenInteractiveTransition *interactivePopTransition;
@property (nonatomic, strong) UIView *snapshot;

@end

NS_ASSUME_NONNULL_END
