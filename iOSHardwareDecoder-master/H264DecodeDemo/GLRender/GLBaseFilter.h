//
//  GLBaseFilter.h
//  practicework
//
//  Created by bleach on 16/5/25.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLProgram.h"
#import "GLMatrix.h"
#import "GLRenderTexture.h"

extern NSString* const kBaseVertexShaderString;
extern NSString* const kBaseFragmentShaderString;

extern const GLfloat kBaseTextureCoordinates[];
extern const GLfloat kBaseVerticalFlipTextureCoordinates[];

@interface GLBaseFilter : NSObject {
    GLint filterPositionAttribute;
    GLint filterTextureCoordinateAttribute;
    GLint filterModelViewProjMatrixUniform;
    GLint filterInputTextureUniform;
    GLProgram* baseProgram;
    GLRenderTexture* baseTexture;
    GLMatrix* baseMatrix;
}

@property (nonatomic, assign) GLColor bgColor;
@property (nonatomic, assign) CGSize viewSize;

- (id)initWithSize:(CGSize)viewSize;
- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString viewSize:(CGSize)viewSize;
- (id)initWithVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString viewSize:(CGSize)viewSize;

/**
 * 初始化着色器Attribute,子类可重写此方法添加新的属性
 */
- (void)initializeAttributes;
- (void)doinitializeAttributes;

/**
 * 更新视图尺寸
 */
- (void)updateViewSize:(CGSize)newViewSize;

/**
 * 渲染
 */
- (void)renderFullFrameWithTextureCoordinates:(const GLfloat *)textureCoordinates;
- (void)renderWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates pointCount:(const GLsizei)pointCount;
- (void)renderElementWithPackBuffer:(const GLuint)packBuffer indexBuffer:(const GLuint)indexBuffer elementCount:(const GLsizei)elementCount needUpdate:(BOOL)needUpdate;
- (void)renderFrameWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates pointCount:(const GLsizei)pointCount textureId:(GLuint)textureId;

/**
 * 更新纹理
 */
- (void)updateTextureWithUIImage:(UIImage *)image;
//- (void)updatePvrTextureWithName:(NSString *)pvrFilePath;
- (void)updateTextureWithImageData:(SImageData *)imageData;

/**
 * 需要重载的
 */
- (void)doRenderPrepare;
- (void)doRenderEnd;
- (void)doRenderBuffer;
- (void)deinit;

/**
 * 属性更新
 */
- (void)setFloat:(GLuint)location floatValue:(GLfloat)floatValue;

/**
 *  清空画布
 */
- (void)doClearViewport;
@end
