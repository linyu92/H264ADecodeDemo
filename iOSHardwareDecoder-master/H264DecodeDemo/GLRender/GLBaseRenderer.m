//
//  GLBaseRenderer.m
//  practicework
//
//  Created by bleach on 16/5/20.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLBaseRenderer.h"
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@interface GLBaseRenderer()

@property (nonatomic, strong) EAGLContext* glContext;
@property (nonatomic, assign) GLuint framebuffer;
@property (nonatomic, assign) GLuint colorRenderbuffer;
@property (nonatomic, assign) GLuint depthRenderbuffer;
@property (nonatomic, assign) BOOL shouldResize;
@property (nonatomic, weak) CAEAGLLayer* drawLayer;

@end

@implementation GLBaseRenderer

- (instancetype)initWithContext:(EAGLContext*)glContext AndDrawable:(id<EAGLDrawable>)drawable {
    _glContext = glContext;
    
    glGenFramebuffers(1, &_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    // 设置渲染缓冲区
    glGenRenderbuffers(1, &_colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:drawable];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);
    
    // 获取视图的尺寸
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &viewWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &viewHeight);
    
    // 设置深度缓冲区
    glGenRenderbuffers(1, &_depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, viewWidth, viewHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer);
    
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return nil;
    }
    
    glViewport(0, 0, viewWidth, viewHeight);

    return self;
}

- (void)render {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        // do resize
        [self doResizeForLayer];
        
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        
        // draw something
        if ([self doRender]) {
            glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
            [_glContext presentRenderbuffer:GL_RENDERBUFFER];
        }
    }
}

- (BOOL)resizeFromLayer:(CAEAGLLayer*)layer {
    _shouldResize = YES;
    _drawLayer = layer;
    return YES;
}

- (BOOL)doResizeForLayer {
    if (!_shouldResize) {
        return NO;
    }
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_drawLayer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &viewWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &viewHeight);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, viewWidth, viewHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer);
    
    glViewport(0, 0, viewWidth, viewHeight);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    GetGLError();
    _shouldResize = NO;
    
    [self doResize];
    
    return YES;
}

#pragma --mark should overwrite
- (BOOL)doRender {
    return YES;
}

- (void)doRenderWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
}

- (void)doResize{
    
}

- (void)deinit {
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_colorRenderbuffer) {
        glDeleteRenderbuffers(1, &_colorRenderbuffer);
        _colorRenderbuffer = 0;
    }
    
    if (_depthRenderbuffer) {
        glDeleteRenderbuffers(1, &_depthRenderbuffer);
        _depthRenderbuffer = 0;
    }
}

- (void)dealloc {
    
}

@end
