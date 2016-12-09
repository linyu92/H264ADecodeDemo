//
//  GLEGALView.m
//  H264DecodeDemo
//
//  Created by linyu on 11/22/16.
//  Copyright © 2016 duowan. All rights reserved.
//

#import "GLEGALView.h"
#import "GLNV12Render.h"
#import "VideoFileParser.h"
#import <VideoToolbox/VideoToolbox.h>
#import "H264StreamMgr.h"

//三分钟内没渲染注销GLContext
#define kStopRenderLoopSecond 180

@interface GLEGALView ()
{
    NSInteger _lazyRenderLoopCount;
    NSInteger _maxLazyRenderLoopTimes;
}

@property (nonatomic, assign) BOOL isInBackground;

@property (nonatomic,strong) NSString *h264FilePath;
//@property (nonatomic, strong) VideoFileParser *parser;
@property (nonatomic, strong) H264StreamMgr *h264StreamMgr;

@property (nonatomic, strong) GLNV12Render* renderer;

//渲染上下文
@property (nonatomic, strong) EAGLContext* glContext;
//渲染动力源(原动力)
@property (nonatomic, strong) CADisplayLink* displayLink;

@property (nonatomic, assign) GLRenderFrameInterval renderFrameInterval;

@property (nonatomic, strong) NSThread *renderThread;


@end

@implementation GLEGALView
#pragma mark - CAEAGLLayer
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_renderer) {
        [_renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        if (![self doInit]) {
            return nil;
        }
    }
    return self;
}

- (BOOL)doInit{
    [self doRegisterNotifications];
    self.h264StreamMgr = [[H264StreamMgr alloc] init];
    
    self.backgroundColor = [UIColor clearColor];
    CAEAGLLayer* eaglLayer = (CAEAGLLayer*)self.layer;
    eaglLayer.opaque = NO;
    eaglLayer.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking  :   @(NO),
                                      kEAGLDrawablePropertyColorFormat      :   kEAGLColorFormatRGBA8 };
    
    [self doInitEAGLContext];
    
    _renderFrameInterval = GLRenderFrameInterval15;
    _maxLazyRenderLoopTimes = kStopRenderLoopSecond * (60/_renderFrameInterval);
    _displayLink = nil;
    
    return YES;
}

- (void)doRegisterNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)onResignActive{
    _isInBackground = YES;
}

- (void)onBecomeActive{
    _isInBackground = NO;
}

- (void)onWillEnterForeground{
    _isInBackground = NO;
}

- (BOOL)doInitEAGLContext{
    if (_glContext == nil) {
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
            if (!_glContext || ![EAGLContext setCurrentContext:_glContext]) {
                return NO;
            }
        }else{
            return NO;
        }
    }
    return YES;
}

- (void)doInitDisplayLinkInThread{
    @autoreleasepool {
        [[NSThread currentThread] setName:@"com.ourtimes.propsAnimation"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        if (!_displayLink) {
            self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(doDrawing)];
            self.displayLink.frameInterval = _renderFrameInterval;
            [self.displayLink addToRunLoop:runLoop forMode:NSRunLoopCommonModes];
        }
        [runLoop run];
    }
}

- (void)terminalRendering{
    [_renderThread cancel];
}

- (BOOL)exitRenderThreadIfMust{
    if ([NSThread currentThread].isCancelled ||
        _lazyRenderLoopCount > _maxLazyRenderLoopTimes) {
        //因为displaylink非线程安全，所以需要哪个线程执行 哪个线程结束
        [_displayLink invalidate];
        _displayLink = nil;
        _renderThread = nil;
        //这里用了[NSThread exit] 会发生无法释放
        //context cleanup
        [self deInit];
        if ([EAGLContext currentContext] == _glContext) {
            [EAGLContext setCurrentContext:nil];
        }
        _glContext = nil;
        [_h264StreamMgr close];
        return YES;
    }
    return NO;
}


- (BOOL)doInitRenderer {
#ifdef SVGATest
    _renderer = [[GLSVGARenderer alloc] initWithContext:_glContext AndDrawable:(id<EAGLDrawable>)self.layer];
#else
    _renderer = [[GLNV12Render alloc] initWithContext:_glContext AndDrawable:(id<EAGLDrawable>)self.layer];
#endif
    
    
    if (!_renderer) {
        return NO;
    }
    
    return YES;
}

- (void)deInit {
    if (_glContext == nil) {
        return;
    }
    EAGLContext* oldContext = [EAGLContext currentContext];
    if (oldContext != _glContext) {
        if (![EAGLContext setCurrentContext:_glContext]) {
            return;
        }
    }
    
    if (_renderer != NULL) {
        [_renderer deinit];
        _renderer = nil;
    }
    
    if (oldContext != _glContext) {
        [EAGLContext setCurrentContext:oldContext];
    }
}

- (void)doDrawing {
    if ([self exitRenderThreadIfMust] || !_h264FilePath) {
        _lazyRenderLoopCount ++;
        return;
    }
    //
    if (![self doInitEAGLContext]) {
        return;
    }
    
    _lazyRenderLoopCount = 0;
    
    CVPixelBufferRef pixelBuffer = [self.h264StreamMgr nextPixelBuffer];
    if (!pixelBuffer && !self.h264StreamMgr.isStreamReading) {//没有缓存包并且文件已读取完毕
        if (!_isInBackground) {
            //清空画布
            if (_renderer) {
                EAGLContext* oldContext = [EAGLContext currentContext];
                if (oldContext != _glContext) {
                    if (![EAGLContext setCurrentContext:_glContext]) {
                        return;
                    }
                }
                _renderer.clearOnce = YES;
                [_renderer render];
            }
        }
        //主线程回调渲染完成
        _h264FilePath = nil;
        [self performSelectorOnMainThread:@selector(runRenderFinishAction) withObject:nil waitUntilDone:NO];
    }else if(pixelBuffer){
        if (!_isInBackground) {
            EAGLContext* oldContext = [EAGLContext currentContext];
            if (oldContext != _glContext) {
                if (![EAGLContext setCurrentContext:_glContext]) {
                    return;
                }
            }
            if (_renderer == NULL) {
                [self doInitRenderer];
            }
            //真正渲染数据
            if (_renderer) {
                [_renderer updateCurrentTexture:pixelBuffer];
                [_renderer render];
            }
        }
        CVPixelBufferRelease(pixelBuffer);
    }
}

- (void)startRenderWithH264File:(NSString *)path{
#if (TARGET_IPHONE_SIMULATOR)
    NSAssert(NO, @"Can not run on simulator!");
#endif
    if (_h264FilePath) {
        return;
    }
    if (self.h264StreamMgr.isStreamReading) {
        [self.h264StreamMgr close];
    }
    
    
    _lazyRenderLoopCount = 0;
    _h264FilePath = path;
    [self.h264StreamMgr openH264File:path];
    
    if (!_renderThread) {
        _renderThread = [[NSThread alloc] initWithTarget:self selector:@selector(doInitDisplayLinkInThread) object:nil];
        [_renderThread start];
    }
}


- (void)runRenderFinishAction{

}

@end
