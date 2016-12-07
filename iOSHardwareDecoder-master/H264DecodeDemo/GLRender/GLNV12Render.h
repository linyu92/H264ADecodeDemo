//
//  GLNV12Render.h
//  H264DecodeDemo
//
//  Created by linyu on 11/22/16.
//  Copyright © 2016 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLBaseRenderer.h"

@interface GLNV12Render : GLBaseRenderer

@property (nonatomic , assign) BOOL clearOnce;

- (void)updateCurrentTexture:(CVPixelBufferRef)pixelBuffer;

@end
