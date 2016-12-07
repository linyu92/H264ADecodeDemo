//
//  PixelBufferUtils.h
//  practicework
//
//  Created by bleach on 16/5/15.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

typedef struct SImageData {
    GLubyte* data;
    GLuint width;
    GLuint height;
    GLenum format;
    GLenum type;
    GLuint rowByteSize;
} SImageData;

/**
 * 将UIImage转化成SImageData
 */
SImageData* imageDataFromUIImage(UIImage* uiImage, BOOL flipVertical);
SImageData* imageDataFromCGImage(CGImageRef cgImage, BOOL flipVertical);
SImageData* imageDataFromCGImageFaster(CGImageRef cgImage);
void destroyImageData(SImageData* imageData);

@interface PixelBufferUtils : NSObject

/**
 * 将pixelBuffer转化成UIImage
 */
+ (UIImage *)uiImageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/**
 * 将UIImage转化成pixelBuffer
 */
+ (CVPixelBufferRef)pixelBufferFromUIImage:(UIImage *)uiImage;
+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)ciImage;
+ (CVPixelBufferRef)pixelBufferFromUIImageFaster:(UIImage *)uiImage;
+ (CVPixelBufferRef)pixelBufferFromCGImageFaster:(CGImageRef)ciImage;

@end
