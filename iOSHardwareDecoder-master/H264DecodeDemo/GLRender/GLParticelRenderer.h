//
//  GLParticelRenderer.h
//  practicework
//
//  Created by bleach on 16/6/19.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLBaseRenderer.h"

@interface GLParticelRenderer : GLBaseRenderer

@property (nonatomic, strong) NSArray* particlesImageForUpdate;
//- (void)addParticelV1;
//- (void)addParticelV2;
//- (void)addParticelV3;

- (BOOL)addParticelV3From:(NSInteger)from length:(NSInteger)length type:(PraiseParticleType)type;

- (void)updateParticlesWithImagesIfNeed;

- (void)deinit;

- (void)cleanParticles;

@end
