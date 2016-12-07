//
//  GLWebpRender.h
//  ourtimes
//
//  Created by linyu on 7/19/16.
//  Copyright © 2016 YY. All rights reserved.
//

#import "GLBaseRenderer.h"

@interface GLWebpRenderer : GLBaseRenderer

@property (nonatomic , assign) BOOL clearOnce;

- (void)updateCurrentTexture:(UIImage *)image;

@end
