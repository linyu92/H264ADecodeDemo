//
//  GLNV12Filter.m
//  H264DecodeDemo
//
//  Created by linyu on 11/22/16.
//  Copyright © 2016 duowan. All rights reserved.
//

#import "GLNV12Filter.h"

// Color Conversion Constants (YUV to RGB) including adjustment from 16-235/16-240 (video range)



NSString *const kNV12FragmentShaderString = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 vTextureCoordinate;
 uniform sampler2D uInputImageTexture_y;
 uniform sampler2D uInputImageTexture_uv;
 
 void main() {
     mediump vec3 yuv;
     lowp vec3 rgb;
     //yuv坐标点映射
     highp vec2 yuvCoordinate = vec2(vTextureCoordinate.r,vTextureCoordinate.g/2.0);
     //alpha坐标点映射
     highp vec2 alphaCoordinate = vec2(vTextureCoordinate.r,vTextureCoordinate.g/2.0+0.5);
     //取出alpha
     float a = texture2D(uInputImageTexture_y, alphaCoordinate).r;
     //将YUV换算成RGB
     yuv.x = texture2D(uInputImageTexture_y, yuvCoordinate).r;
     yuv.yz = (texture2D(uInputImageTexture_uv, yuvCoordinate).rg - vec2(0.5, 0.5));
     rgb.r = yuv.x +                 1.402 * yuv.z;
     rgb.g = yuv.x - 0.344 * yuv.y - 0.714 * yuv.z;
     rgb.b = yuv.x + 1.772 * yuv.y;
     gl_FragColor = vec4(rgb*a,a);
 }
 );

@interface GLNV12Filter()
{
    CVOpenGLESTextureCacheRef _videoTextureCache;
    
//    const GLfloat *_preferredConversion;
    
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    GLint _uniformSamplers[2];
    CVPixelBufferRef _pixelBuffer;
}
@end

@implementation GLNV12Filter

- (id)initWithSize:(CGSize)viewSize {
    if (!(self = [self initWithFragmentShaderFromString:kNV12FragmentShaderString viewSize:viewSize])) {
        return nil;
    }
    [self initUniforms];
    return self;
}

- (void)setupCacheRefWithContext:(EAGLContext *)context{
    // Create CVOpenGLESTextureCacheRef for optimal CVPixelBufferRef to GLES texture conversion.
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, &_videoTextureCache);
    if (err != noErr) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        return;
    }
}

- (void)initUniforms{
    _uniformSamplers[0] = [baseProgram uniformIndex:@"uInputImageTexture_y"];
    _uniformSamplers[1] = [baseProgram uniformIndex:@"uInputImageTexture_uv"];
}

- (void)doInit {
    
}

- (void)cleanUpTextures{
    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    
    if (_chromaTexture) {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
        _pixelBuffer = NULL;
    }
}

- (void)deinit {
    [self cleanUpTextures];
    
    if(_videoTextureCache){
        CFRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
}


- (void)updateTextureWithPixelBuf:(CVPixelBufferRef)pb{
    if(_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
    }
    _pixelBuffer = CVPixelBufferRetain(pb);
    
    if (_videoTextureCache == NULL) {
        NSLog(@"CVOpenGLESTextureCacheRef is nil");
        return;
    }
    
    CVReturn err;
    size_t planeCount = CVPixelBufferGetPlaneCount(_pixelBuffer);
    
    size_t pixwidth = CVPixelBufferGetWidth(_pixelBuffer);
    size_t pixheight = CVPixelBufferGetHeight(_pixelBuffer);
    
    glActiveTexture(GL_TEXTURE0);
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       _pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RED_EXT,
                                                       (GLsizei)pixwidth,
                                                       (GLsizei)pixheight,
                                                       GL_RED_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &_lumaTexture);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
 
    if(planeCount == 2) {
        // UV-plane.
        glActiveTexture(GL_TEXTURE1);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           _pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RG_EXT,
                                                           (GLsizei)pixwidth/2,
                                                           (GLsizei)pixheight/2,
                                                           GL_RG_EXT,
                                                           GL_UNSIGNED_BYTE,
                                                           1,
                                                           &_chromaTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    GetGLError();
}

- (void)renderFrameWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates pointCount:(const GLsizei)pointCount textureId:(GLuint)textureId {
    glViewport(0.0f, 0.0f, self.viewSize.width, self.viewSize.height);
    glClearColor(self.bgColor.red, self.bgColor.green, self.bgColor.blue, self.bgColor.alpha);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//    glEnable(GL_BLEND);
//    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    if (baseProgram == nil) {
        NSLog(@"BaseProgram is nil");
        return;
    }
    [baseProgram use];
    
    [self doRenderPrepare];
    glUniformMatrix4fv(filterModelViewProjMatrixUniform, 1, GL_FALSE, baseMatrix.mtxElements);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(_lumaTexture));
    glUniform1i(_uniformSamplers[0], 0);

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(_chromaTexture));
    glUniform1i(_uniformSamplers[1], 1);
    
    glVertexAttribPointer(filterPositionAttribute, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(filterPositionAttribute);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, GL_FALSE, 0, textureCoordinates);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, pointCount);
    
    glDisableVertexAttribArray(filterPositionAttribute);
    glDisableVertexAttribArray(filterTextureCoordinateAttribute);
    GetGLError();
    
    [self cleanUpTextures];
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}


@end
