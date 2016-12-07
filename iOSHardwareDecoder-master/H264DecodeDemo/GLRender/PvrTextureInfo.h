//
//  PvrTextureInfo.h
//  practicework
//
//  Created by bleach on 16/6/8.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

typedef NS_ENUM(NSInteger, Texture2DPixelFormat) {
    //! 32-bit texture: RGBA8888
    kTexture2DPixelFormat_RGBA8888,
    //! 24-bit texture: RGBA888
    kTexture2DPixelFormat_RGB888,
    //! 16-bit texture without Alpha channel
    kTexture2DPixelFormat_RGB565,
    //! 8-bit textures used as masks
    kTexture2DPixelFormat_A8,
    //! 8-bit intensity texture
    kTexture2DPixelFormat_I8,
    //! 16-bit textures used as masks
    kTexture2DPixelFormat_AI88,
    //! 16-bit textures: RGBA4444
    kTexture2DPixelFormat_RGBA4444,
    //! 16-bit textures: RGB5A1
    kTexture2DPixelFormat_RGB5A1,
    //! 4-bit PVRTC-compressed texture: PVRTC4
    kTexture2DPixelFormat_PVRTC4,
    //! 2-bit PVRTC-compressed texture: PVRTC2
    kTexture2DPixelFormat_PVRTC2,
    
    //! Default texture format: RGBA8888
    kTexture2DPixelFormat_Default = kTexture2DPixelFormat_RGBA8888,
};

typedef struct PVRTexturePixelFormatInfo {
    GLenum internalFormat;
    GLenum format;
    GLenum type;
    uint32_t bpp;
    bool compressed;
    bool alpha;
    Texture2DPixelFormat pixelFormat;
}PVRTexturePixelFormatInfo;

typedef NS_ENUM(NSInteger, PVRMIPMAP) {
    PVRMIPMAP_MAX = 16,
};

@interface PvrTextureInfo : NSObject {
    const PVRTexturePixelFormatInfo *_pixelFormatInfo;
}

@property (nonatomic, readonly) uint32_t width;
@property (nonatomic, readonly) uint32_t height;
@property (nonatomic, readonly) GLenum internalFormat;
@property (nonatomic, readonly) GLenum format;
@property (nonatomic, readonly) GLenum type;
@property (nonatomic, readonly) BOOL compressed;

@property (nonatomic, strong) NSMutableArray* imageDatas;

@property (nonatomic, readonly) BOOL hasAlpha;
@property (nonatomic, readonly) BOOL hasPremultipliedAlpha;
@property (nonatomic, readonly) BOOL forcePremultipliedAlpha;
@property (nonatomic, readonly) NSUInteger numberOfMipmaps;
@property (nonatomic, readonly) Texture2DPixelFormat pixelFormat;

- (id)initWithContentsOfFile:(NSString *)path;
- (id)initWithContentsOfURL:(NSURL *)url;
+ (id)pvrTextureWithContentsOfFile:(NSString *)path;
+ (id)pvrTextureWithContentsOfURL:(NSURL *)url;

@end
