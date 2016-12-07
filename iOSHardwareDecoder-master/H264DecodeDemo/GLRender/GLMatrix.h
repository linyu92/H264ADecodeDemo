//
//  GLMatrix.h
//  practicework
//
//  Created by bleach on 16/5/29.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLCommon.h"

@interface GLMatrix : NSObject
{
    @public
    GLfloat* elements;
}

@property (nonatomic, readonly) GLfloat* mtxElements;

- (GLMatrix *)setIdentity;

- (GLMatrix *)setLookAt:(GLfloat)eyeX eyeY:(GLfloat)eyeY eyeZ:(GLfloat)eyeZ centerX:(GLfloat)centerX centerY:(GLfloat)centerY centerZ:(GLfloat)centerZ upX:(GLfloat)upX upY:(GLfloat)upY upZ:(GLfloat)upZ;

- (GLMatrix *)lookAt:(GLfloat)eyeX eyeY:(GLfloat)eyeY eyeZ:(GLfloat)eyeZ centerX:(GLfloat)centerX centerY:(GLfloat)centerY centerZ:(GLfloat)centerZ upX:(GLfloat)upX upY:(GLfloat)upY upZ:(GLfloat)upZ;

- (GLMatrix *)setOrthographic:(GLfloat)left right:(GLfloat)right bottom:(GLfloat)bottom top:(GLfloat)top nearZ:(GLfloat)nearZ  farZ:(GLfloat)farZ;

- (GLMatrix *)orthographic:(GLfloat)left right:(GLfloat)right bottom:(GLfloat)bottom top:(GLfloat)top nearZ:(GLfloat)nearZ  farZ:(GLfloat)farZ;

- (GLMatrix *)setTranslate:(GLfloat)x y:(GLfloat)y z:(GLfloat)z;

- (GLMatrix *)translate:(GLfloat)x y:(GLfloat)y z:(GLfloat)z;

- (GLMatrix *)setScale:(GLfloat)xScale yScale:(GLfloat)yScale zScale:(GLfloat)zScale;

- (GLMatrix *)scale:(GLfloat)xScale yScale:(GLfloat)yScale zScale:(GLfloat)zScale;

- (GLMatrix *)setRotate:(GLfloat)deg xAxis:(GLfloat)xAxis yAxis:(GLfloat)yAxis zAxis:(GLfloat)zAxis;

- (GLMatrix *)rotate:(GLfloat)deg xAxis:(GLfloat)xAxis yAxis:(GLfloat)yAxis zAxis:(GLfloat)zAxis;

- (GLMatrix *)multiply:(GLMatrix *)other;

/* 利用矩阵做转换的点 */
- (void)multiplyVector4:(GLVertex4 *)vector4;

@end
