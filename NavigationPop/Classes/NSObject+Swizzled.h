//
//  NSObject+Swizzled.h
//  PercentDrivenInteractiveTransitionDemo
//
//  Created by lishuai on 2018/12/4.
//  Copyright © 2018 lishuai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Swizzled)
+ (void)swizzleSEL:(SEL)originalSEL withSEL:(SEL)swizzledSEL;
@end

NS_ASSUME_NONNULL_END
