//
//  GLWebpRender.m
//  ourtimes
//
//  Created by linyu on 7/19/16.
//  Copyright © 2016 YY. All rights reserved.
//

#import "GLWebpRenderer.h"
#import "GLBaseFilter.h"

@interface GLWebpRenderer()

@property (nonatomic, strong) GLBaseFilter* filter;

@end


@implementation GLWebpRenderer

- (void)dealloc{
    NSLog(@"dealloc");
}

- (instancetype)initWithContext:(EAGLContext*)glContext AndDrawable:(id<EAGLDrawable>)drawable {
    self = [super initWithContext:glContext AndDrawable:drawable];
    if (self) {
        [self initData];
        [self initBuffer];
    }
    return self;
}



- (void)initData {
    if (!_filter) {
        _filter = [[GLBaseFilter alloc] initWithSize:CGSizeMake(viewWidth, viewHeight)];
    }
}

- (void)initBuffer {
    //没有额外buffer
}

- (void)updateCurrentTexture:(UIImage *)image{
    if (_filter) {
        [_filter updateTextureWithUIImage:image];
    }
}

#pragma mark - overwrite
- (BOOL)doRender {
    if (_filter) {
        if (self.clearOnce) {
            [_filter doClearViewport];
            self.clearOnce = NO;
        }else{
            [_filter renderFullFrameWithTextureCoordinates:kBaseTextureCoordinates];
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
