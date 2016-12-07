//
//  GLBaseRenderer.h
//  practicework
//
//  Created by bleach on 16/5/20.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GLCommon.h"

static CGFloat GLRenderFPS_60 = 0.017f;
static CGFloat GLRenderFPS_55 = 0.018f;
static CGFloat GLRenderFPS_50 = 0.02f;
static CGFloat GLRenderFPS_40 = 0.025f;
static CGFloat GLRenderFPS_30 = 0.033f;
static CGFloat GLRenderFPS_15 = 0.067f;
static CGFloat GLRenderFPS_5 = 0.2f;
static CGFloat GLRenderFPS_2 = 0.5f;

//每一个需要画出自己想要的图像的,继承这个类吧,然后定制自己的数据
@interface GLBaseRenderer : NSObject {
    GLint viewWidth;
    GLint viewHeight;
}

typedef NS_ENUM(NSInteger, GLRenderFrameInterval) {
    GLRenderFrameIntervalUnknown = 0,               //未定义的渲染帧间隔
    GLRenderFrameInterval60 = 1,                    //每秒60帧渲染
    GLRenderFrameInterval30 = 2,                    //每秒30帧渲染
    GLRenderFrameInterval20 = 3,                    //每秒20帧渲染
    GLRenderFrameInterval15 = 4,                    //每秒15帧渲染
    GLRenderFrameInterval5 = 12,                    //每秒5帧渲染
    GLRenderFrameInterval2 = 30,                    //每秒2帧渲染
    GLRenderFrameInterval1 = 60,                    //每秒1帧渲染
};

- (instancetype)initWithContext:(EAGLContext*)glContext AndDrawable:(id<EAGLDrawable>)drawable;

- (void)render;

- (BOOL)resizeFromLayer:(CAEAGLLayer*)layer;


// should overwrite
- (BOOL)doRender;
- (void)doResize; //layer尺寸变化，需要同步filter
- (void)deinit;

@end
