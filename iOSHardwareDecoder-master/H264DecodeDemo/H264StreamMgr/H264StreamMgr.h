//
//  H264StreamMgr.h
//  H264DecodeDemo
//
//  Created by linyu on 11/24/16.
//  Copyright © 2016 duowan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface H264StreamMgr : NSObject

@property (nonatomic,assign,readonly) BOOL isStreamReading;

- (BOOL)openH264File:(NSString *)filepath;

- (void)close;

- (CVPixelBufferRef)nextPixelBuffer;

@end
