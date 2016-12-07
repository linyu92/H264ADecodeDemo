//
//  PixelBufferUtils.m
//  practicework
//
//  Created by bleach on 16/5/15.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "PixelBufferUtils.h"
#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>

@implementation PixelBufferUtils

+ (UIImage*)uiImageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CIImage* ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    CIContext* context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(YES)}];

    CGRect rect = CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    CGImageRef videoImage = [context createCGImage:ciImage fromRect:rect];
    
    UIImage* image = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    
    return image;
}

+ (CVPixelBufferRef)pixelBufferFromUIImage:(UIImage*)uiImage {
    CGImageRef imageRef = [uiImage CGImage];
    return [PixelBufferUtils pixelBufferFromCGImage:imageRef];
}

+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)ciImage {
    CGSize frameSize = CGSizeMake(CGImageGetWidth(ciImage), CGImageGetHeight(ciImage));
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:NO], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width, frameSize.height, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)options, &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void* pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width, frameSize.height, 8, 4 * frameSize.width, rgbColorSpace, kCGImageAlphaNoneSkipLast);
    
    CGContextTranslateCTM(context, 0, frameSize.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(ciImage), CGImageGetHeight(ciImage)), ciImage);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (CVPixelBufferRef)pixelBufferFromUIImageFaster:(UIImage *)uiImage {
    CGImageRef imageRef = [uiImage CGImage];
    return [PixelBufferUtils pixelBufferFromCGImageFaster:imageRef];
}

+ (CVPixelBufferRef)pixelBufferFromCGImageFaster:(CGImageRef)cgImage {
    CVPixelBufferRef pxbuffer = NULL;
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    size_t width =  CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
    
    CFDataRef dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
    GLubyte* imageData = (GLubyte *)CFDataGetBytePtr(dataFromImageDataProvider);
    
    CVPixelBufferCreateWithBytes(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, imageData,bytesPerRow, NULL, NULL, (__bridge CFDictionaryRef)options, &pxbuffer);
    
    CFRelease(dataFromImageDataProvider);
    
    return pxbuffer;
}

SImageData* imageDataFromUIImage(UIImage* uiImage, BOOL flipVertical) {
    CGImageRef cgImage = uiImage.CGImage;
    if (!cgImage) {
        return NULL;
    }
    return imageDataFromCGImage(cgImage, flipVertical);
}

SImageData* imageDataFromCGImage(CGImageRef cgImage, BOOL flipVertical) {
    GLuint width = (GLuint)CGImageGetWidth(cgImage);
    GLuint height = (GLuint)CGImageGetHeight(cgImage);
    
    SImageData* imageData = (SImageData *)malloc(sizeof(SImageData));
    imageData->width = (GLuint)CGImageGetWidth(cgImage);
    imageData->height = (GLuint)CGImageGetHeight(cgImage);
    imageData->rowByteSize = width * 4;
    imageData->data = (GLubyte *)malloc(height * imageData->rowByteSize);
    imageData->format = GL_RGBA;
    imageData->type = GL_UNSIGNED_BYTE;
    
    CGContextRef context = CGBitmapContextCreate(imageData->data, imageData->width, imageData->height, 8, imageData->rowByteSize, CGImageGetColorSpace(cgImage), kCGBitmapAlphaInfoMask & kCGImageAlphaNoneSkipLast);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    if(flipVertical) {
        CGContextTranslateCTM(context, 0.0, imageData->height);        
        CGContextScaleCTM(context, 1.0, -1.0);
    }
    CGContextDrawImage(context, CGRectMake(0.0, 0.0, imageData->width, imageData->height), cgImage);
    CGContextRelease(context);
    
    if(NULL == imageData->data) {
        destroyImageData(imageData);
        return NULL;
    }
    
    return imageData;
}

SImageData* imageDataFromCGImageFaster(CGImageRef cgImage) {
    GLuint width = (GLuint)CGImageGetWidth(cgImage);
    GLuint height = (GLuint)CGImageGetHeight(cgImage);
    
    CFDataRef dataFromImageDataProvider = NULL;
    GLenum format = GL_BGRA;
    BOOL shouldRedrawUsingCoreGraphics = NO;
    if (CGImageGetBytesPerRow(cgImage) != CGImageGetWidth(cgImage) * 4 ||
        CGImageGetBitsPerPixel(cgImage) != 32 ||
        CGImageGetBitsPerComponent(cgImage) != 8)
    {
        shouldRedrawUsingCoreGraphics = YES;
    } else {
        /* Check that the bitmap pixel format is compatible with GL */
        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(cgImage);
        if ((bitmapInfo & kCGBitmapFloatComponents) != 0) {
            /* We don't support float components for use directly in GL */
            shouldRedrawUsingCoreGraphics = YES;
        } else {
            CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
            if (byteOrderInfo == kCGBitmapByteOrder32Little) {
                /* Little endian, for alpha-first we can use this bitmap directly in GL */
                CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
                if (alphaInfo != kCGImageAlphaPremultipliedFirst && alphaInfo != kCGImageAlphaFirst &&
                    alphaInfo != kCGImageAlphaNoneSkipFirst) {
                    shouldRedrawUsingCoreGraphics = YES;
                }
            } else if (byteOrderInfo == kCGBitmapByteOrderDefault || byteOrderInfo == kCGBitmapByteOrder32Big) {
                /* Big endian, for alpha-last we can use this bitmap directly in GL */
                CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
                if (alphaInfo != kCGImageAlphaPremultipliedLast && alphaInfo != kCGImageAlphaLast &&
                    alphaInfo != kCGImageAlphaNoneSkipLast) {
                    shouldRedrawUsingCoreGraphics = YES;
                } else {
                    /* Can access directly using GL_RGBA pixel format */
                    format = GL_RGBA;
                }
            }
        }
    }
    
    SImageData* imageData = (SImageData *)malloc(sizeof(SImageData));
    imageData->width = width;
    imageData->height = height;
    imageData->rowByteSize = width * 4;
    imageData->format = GL_RGBA;
    imageData->type = GL_UNSIGNED_BYTE;
    
    if (shouldRedrawUsingCoreGraphics){
        imageData->data = (GLubyte *)calloc(1, (width * height * 4));
        CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
        CGContextRef spriteContext = CGBitmapContextCreate(imageData->data, width, height, 8, width*4, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGContextDrawImage(spriteContext, CGRectMake(0.0, 0.0, width, height), cgImage);
        
        CGContextRelease(spriteContext);
        CGColorSpaceRelease(genericRGBColorspace);
    } else {
        dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
        imageData->data = (GLubyte *)CFDataGetBytePtr(dataFromImageDataProvider);
    }

    if(NULL == imageData->data) {
        destroyImageData(imageData);
        return NULL;
    }
    
    return imageData;
}

void destroyImageData(SImageData* imageData) {
    free(imageData->data);
    free(imageData);
}

@end
