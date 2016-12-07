//
//  ImageUtils.m
//  practicework
//
//  Created by bleach on 16/6/26.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "ImageUtils.h"

@implementation ImageUtils

+ (UIImage *)composeImage:(NSArray *)images {
    if (images.count == 0) {
        return nil;
    }
    
    if (images.count == 1) {
        return [images objectAtIndex:0];
    }

    @autoreleasepool {
        CGSize imageSize = ((UIImage *)[images objectAtIndex:0]).size;
        CGFloat composeWidth = 0.0f;
        CGFloat composeHeight = imageSize.height;
        for (UIImage * image in images) {
            if (!CGSizeEqualToSize(imageSize, image.size)) {
                //合成需要是相等宽高的图片
                return nil;
            }
            composeWidth += image.size.width + 2.0f;
        }
        CGSize size = CGSizeMake(composeWidth, composeHeight);
        UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
        
        NSUInteger index = 0;
        for (UIImage * image in images) {
            [image drawInRect:CGRectMake(index * (imageSize.width + 2.0f) + 1.0f, 0.0f, imageSize.width, imageSize.height)];
            index++;
        }
        
        UIImage * resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return resultImage;
    }
}

+ (UIImage *)composeImage:(NSArray *)images quadIndexs:(GLQuad *)quads{
    if (images.count == 0) {
        return nil;
    }
    
    quads = (GLQuad *)malloc(sizeof(GLQuad)*images.count);
    
    if (images.count == 1) {
        quads = (GLQuad *)malloc(sizeof(GLQuad));
        memcpy(quads, GLSquareData, sizeof(GLQuad));
        return [images objectAtIndex:0];
    }
    
    @autoreleasepool {
        CGFloat composeWidth = 0.0f;
        CGFloat composeHeight = 0.0f;
        for (UIImage * image in images) {
            composeWidth += image.size.width + 2.0f;
            composeHeight = MAX(composeHeight, image.size.height);
        }
        CGSize size = CGSizeMake(composeWidth, composeHeight);
        UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
        
        GLfloat _lastTexCursor = 0;
        GLfloat _lastTexPosition = 0;
        NSUInteger index = 0;
        for (UIImage * image in images) {
            [image drawInRect:CGRectMake(_lastTexPosition + 1.0f, 0.0f, image.size.width, image.size.height)];
            GLQuad *quad = (GLQuad *)malloc(sizeof(GLQuad));
            memcpy(quad, GLSquareData, sizeof(GLQuad));
            
            GLfloat texWidth = (image.size.width+2)/composeWidth;
            GLfloat texHeight = image.size.height/composeHeight;
            
            quad->data[0].texcoord.tx = _lastTexCursor;
            quad->data[0].texcoord.ty = texHeight;
            quad->data[1].texcoord.tx = _lastTexCursor;
            quad->data[1].texcoord.ty = 0.0f;
            quad->data[2].texcoord.tx = _lastTexCursor+texWidth;
            quad->data[2].texcoord.ty = 0.0f;
            quad->data[3].texcoord.tx = _lastTexCursor+texWidth;
            quad->data[3].texcoord.ty = texHeight;
            
            memcpy(&quads[index], quad, sizeof(GLQuad));
            free(quad);
            
            _lastTexCursor += texWidth;
            _lastTexPosition += image.size.width + 2;
            
            index++;
        }
        
        UIImage * resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return resultImage;
    }
    
}

@end
