//
//  GLTexture.h
//  practicework
//
//  Created by bleach on 16/5/31.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PixelBufferUtils.h"

@interface GLRenderTexture : NSObject

@property (nonatomic, assign) GLuint bindTexture;

- (id)initNormalTexture;

- (id)initWithOptions:(GLTextureOptions)fboTextureOptions;

- (void)updateTextureWithUIImage:(UIImage *)image;

//- (void)updatePvrTextureWithName:(NSString *)pvrFilePath;

- (void)updateTextureWithImageData:(SImageData *)cacheImageData;

- (void)deinit;

@end
