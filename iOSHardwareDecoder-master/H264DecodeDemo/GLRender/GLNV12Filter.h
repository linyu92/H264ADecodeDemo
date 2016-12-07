//
//  GLNV12Filter.h
//  H264DecodeDemo
//
//  Created by linyu on 11/22/16.
//  Copyright © 2016 duowan. All rights reserved.
//

#import "GLBaseFilter.h"

@interface GLNV12Filter : GLBaseFilter

- (void)setupCacheRefWithContext:(EAGLContext *)context;

- (void)updateTextureWithPixelBuf:(CVPixelBufferRef)pixelbuffer;

@end
