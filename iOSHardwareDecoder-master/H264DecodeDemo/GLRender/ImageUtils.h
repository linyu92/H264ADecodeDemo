//
//  ImageUtils.h
//  practicework
//
//  Created by bleach on 16/6/26.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageUtils : NSObject

/* 此合成只会合成一排 */
+ (UIImage *)composeImage:(NSArray *)images;

+ (UIImage *)composeImage:(NSArray *)images quadIndexs:(GLQuad *)quads;

@end
