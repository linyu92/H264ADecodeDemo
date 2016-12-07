//
//  GLRenderTexture.m
//  practicework
//
//  Created by bleach on 16/5/31.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLRenderTexture.h"

@interface GLRenderTexture()
//纹理设置
@property (nonatomic, assign) GLTextureOptions textureOptions;
//用于纹理
@property (nonatomic, assign) CGSize textureSize;
//纹理缓存
@property (nonatomic, retain) __attribute__((NSObject)) CVOpenGLESTextureCacheRef textureCache;
@property (nonatomic, retain) __attribute__((NSObject)) CVOpenGLESTextureRef renderTexture;
//
//@property (nonatomic, strong) PvrTextureInfo* pvrInfo;

@end

@implementation GLRenderTexture {
    SImageData* imageData;
}

- (id)initNormalTexture {
    GLTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_BGRA;
    defaultTextureOptions.type = GL_UNSIGNED_BYTE;
    defaultTextureOptions.mimap = GL_FALSE;
    
    if (!(self = [self initWithOptions:defaultTextureOptions])) {
        return nil;
    }
    
    return self;
}

- (id)initWithOptions:(GLTextureOptions)fboTextureOptions {
    if (!(self = [super init])) {
        return nil;
    }
    
    _textureOptions = fboTextureOptions;

    [self generateTexture];
    return self;
}

- (void)generateTexture {
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &_bindTexture);
    glBindTexture(GL_TEXTURE_2D, _bindTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _textureOptions.minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _textureOptions.magFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);
    if (_textureOptions.mimap) {
        glGenerateMipmap(GL_TEXTURE_2D);
    }
}

- (void)deinit {
    glDeleteTextures(1, &_bindTexture);
    _bindTexture = 0;
    
    if (imageData != NULL) {
        destroyImageData(imageData);
        imageData = NULL;
    }
}

- (GLuint)bindTexture {
    return _bindTexture;
}

- (void)updateTextureWithUIImage:(UIImage *)image {
    if (imageData != NULL) {
        destroyImageData(imageData);
        imageData = NULL;
    }
    
    imageData = imageDataFromUIImage(image, YES);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _bindTexture);
    if (_textureSize.width != imageData->width || _textureSize.height != imageData->height) {
        glTexImage2D(GL_TEXTURE_2D, 0, imageData->format, (GLint)imageData->width, (GLint)imageData->height, 0, imageData->format, imageData->type, imageData->data);
        _textureSize.width = imageData->width;
        _textureSize.height = imageData->height;
    } else {
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLint)imageData->width, (GLint)imageData->height, imageData->format, imageData->type, imageData->data);
    }
}

//- (void)updatePvrTextureWithName:(NSString *)pvrFilePath {
//    _pvrInfo = [PvrTextureInfo pvrTextureWithContentsOfFile:pvrFilePath];
//    if (_pvrInfo == nil) {
//        return;
//    }
//    
//    glPixelStorei(GL_UNPACK_ALIGNMENT,1);
//    glActiveTexture(GL_TEXTURE0);
//    glBindTexture(GL_TEXTURE_2D, _bindTexture);
//    
//    GLsizei width = _pvrInfo.width;
//    GLsizei height = _pvrInfo.height;
//    NSData* data = nil;
//    GLenum err = GL_NO_ERROR;
//    if(_pvrInfo.imageDatas.count == 1) {
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _textureOptions.minFilter);
//    } else {
//        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
//    }
//    
//    for (int i = 0; i < _pvrInfo.imageDatas.count; i++) {
//        data = [_pvrInfo.imageDatas objectAtIndex:i];
//        
//        if (_pvrInfo.compressed) {
//            glCompressedTexImage2D(GL_TEXTURE_2D, i, _pvrInfo.internalFormat, width, height, 0, (GLsizei)[data length], [data bytes]);
//        } else {
//            glTexImage2D(GL_TEXTURE_2D, 0, _pvrInfo.internalFormat, width, height, 0, _pvrInfo.format, _pvrInfo.type, [data bytes]);
//        }
//        
//        err = glGetError();
//        if (err != GL_NO_ERROR) {
//            NSLog(@"Error uploading compressed texture level: %d. glError: 0x%04X", i, err);
//            return;
//        }
//        
//        width = MAX(width >> 1, 1);
//        height = MAX(height >> 1, 1);
//    }
//}

- (void)updateTextureWithImageData:(SImageData *)cacheImageData {    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _bindTexture);
    if (_textureSize.width != cacheImageData->width || _textureSize.height != cacheImageData->height) {
        glTexImage2D(GL_TEXTURE_2D, 0, cacheImageData->format, (GLint)cacheImageData->width, (GLint)cacheImageData->height, 0, cacheImageData->format, cacheImageData->type, cacheImageData->data);
        _textureSize.width = cacheImageData->width;
        _textureSize.height = cacheImageData->height;
    } else {
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLint)cacheImageData->width, (GLint)cacheImageData->height, cacheImageData->format, cacheImageData->type, cacheImageData->data);
    }
}

@end
