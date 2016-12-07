//
//  GLNV12Render.m
//  H264DecodeDemo
//
//  Created by linyu on 11/22/16.
//  Copyright © 2016 duowan. All rights reserved.
//

#import "GLNV12Render.h"
#import "GLNV12Filter.h"
@interface GLNV12Render()
{

}

@property (nonatomic, strong) GLNV12Filter* filter;

@end



@implementation GLNV12Render

- (instancetype)initWithContext:(EAGLContext*)glContext AndDrawable:(id<EAGLDrawable>)drawable {
    id obj = [super initWithContext:glContext AndDrawable:drawable];
    [self initDataWithContext:glContext];
    [self initBuffer];
    return obj;
}

- (void)initDataWithContext:(EAGLContext*)glContext {
    if (!_filter) {
        _filter = [[GLNV12Filter alloc] initWithSize:CGSizeMake(viewWidth, viewHeight)];
        [_filter setupCacheRefWithContext:glContext];
    }
}

- (void)initBuffer {
    //没有额外buffer
}

- (void)updateCurrentTexture:(CVPixelBufferRef)pixelBuffer{
    if (_filter && pixelBuffer) {
        [_filter updateTextureWithPixelBuf:pixelBuffer];
    }
}

#pragma mark - overwrite
- (BOOL)doRender {
    if (_filter) {
        if (self.clearOnce) {
            [_filter doClearViewport];
            self.clearOnce = NO;
        }else{
            [_filter renderFullFrameWithTextureCoordinates:kBaseVerticalFlipTextureCoordinates];
        }
        return YES;
    }
    return NO;
}

- (void)doResize{
    if (_filter) {
        [_filter updateViewSize:CGSizeMake(viewWidth, viewHeight)];
    }
}

- (void)deinit {
    [super deinit];
    if (_filter) {
        [_filter deinit];
    }
    GetGLError();
}


@end
