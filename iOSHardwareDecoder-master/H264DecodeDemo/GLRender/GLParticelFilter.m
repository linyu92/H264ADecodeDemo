//
//  GLParticelFilter.m
//  ourtimes
//
//  Created by bleach on 16/7/8.
//  Copyright © 2016年 YY. All rights reserved.
//

#import "GLParticelFilter.h"
#import "GLCommon.h"

NSString *const kParticelVertexShaderString = SHADER_STRING
(
 attribute vec4 aPosition;
 attribute vec4 aInputTextureCoordinate;
 attribute float aAlpha;
 
 varying vec2 vTextureCoordinate;
 varying float vAlpha;
 
 uniform mat4 uModelViewProjMatrix;
 
 void main() {
     gl_Position = uModelViewProjMatrix * aPosition;
     vAlpha = aAlpha;
     vTextureCoordinate = aInputTextureCoordinate.xy;
 }
 );

NSString *const kParticelFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 varying mediump vec2 vTextureCoordinate;
 varying mediump float vAlpha;
 uniform sampler2D uInputImageTexture;
 
 void main() {
     vec4 textureColor = texture2D(uInputImageTexture, vTextureCoordinate);
     gl_FragColor = textureColor * vAlpha;
 }
 );

@implementation GLParticelFilter {
    GLfloat alpha;
}

- (id)initWithSize:(CGSize)viewSize {
    id obj = [super initWithVertexShaderFromString:kParticelVertexShaderString fragmentShaderFromString:kParticelFragmentShaderString viewSize:viewSize];
    [self initDefault];
    return obj;
}

- (void)initDefault {
    filterAlphaAttribute = [baseProgram attributeIndex:@"aAlpha"];
}

- (void)doinitializeAttributes {
    [baseProgram addAttribute:@"aAlpha"];
}

- (void)doInit {
    baseTexture = [[GLRenderTexture alloc] initNormalTexture];
}

- (void)doRenderPrepare {
    glEnableVertexAttribArray(filterAlphaAttribute);
}

- (void)doRenderBuffer {
    glVertexAttribPointer(filterAlphaAttribute, 1, GL_FLOAT, GL_FALSE, sizeof(GLPackData), (const GLvoid *)(ptrdiff_t)(sizeof(GLVertex4) + sizeof(GLTexcoord2)));
}

- (void)doRenderEnd {
    glDisableVertexAttribArray(filterAlphaAttribute);
}

- (void)deinit {
    [super deinit];
}

@end