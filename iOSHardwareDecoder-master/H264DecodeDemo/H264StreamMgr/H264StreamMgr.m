//
//  H264StreamMgr.m
//  H264DecodeDemo
//
//  Created by linyu on 11/24/16.
//  Copyright © 2016 duowan. All rights reserved.
//

#import "H264StreamMgr.h"
#import "VideoFileParser.h"
#import <VideoToolbox/VideoToolbox.h>

#define kMaxPixelBufferCacheNum 3

@interface H264StreamMgr()
{
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
    
    dispatch_semaphore_t _decodeSemaphore;
}
@property (nonatomic,strong) NSMutableArray *pixelBufferArray;
@property (nonatomic,strong) VideoFileParser *parser;

@end


@implementation H264StreamMgr

#pragma mark - VTDecode
static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}


-(BOOL)initH264Decoder {
    if(_deocderSession) {
        return YES;
    }
    
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    
    if(status == noErr) {
        CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
        //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
        //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL, attrs,
                                              &callBackRecord,
                                              &_deocderSession);
        CFRelease(attrs);
    } else {
        NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
    }
    
    return YES;
}

-(void)clearH264Deocder {
    if(_deocderSession) {
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    
    if (_sps != NULL) {
        free(_sps);
        _sps = NULL;
    }
    
    if (_pps != NULL) {
        free(_pps);
        _pps = NULL;
    }
    
    _spsSize = _ppsSize = 0;
}

-(CVPixelBufferRef)decode:(VideoPacket*)vp {
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)vp.buffer, vp.size,
                                                          kCFAllocatorNull,
                                                          NULL, 0, vp.size,
                                                          0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {vp.size};
        
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", decodeStatus);
            }
            
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    
    
    return outputPixelBuffer;
}


#pragma mark - life circle

- (id)init{
    self = [super init];
    if (self) {
        _decodeSemaphore = dispatch_semaphore_create(0);
        _pixelBufferArray = [NSMutableArray arrayWithCapacity:kMaxPixelBufferCacheNum];
    }
    return self;
}

-(void)dealloc{
    [_parser close];
    dispatch_semaphore_signal(_decodeSemaphore);
    
}

#pragma mark - public
- (BOOL)openH264File:(NSString *)filepath{
    if ([self.parser open:filepath]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self decodeThreadAction];
        });
        return YES;
    }
    return NO;
}

- (void)close{
    [self.parser close];
    [self clearH264Deocder];
}

- (BOOL)isStreamReading{
    return self.parser.isValid;
}

#pragma mark - decode
- (void)decodeThreadAction{
    VideoPacket *vp = nil;
    while(true) {
        BOOL shouldWait = NO;
        @synchronized (self.pixelBufferArray) {
            if (self.pixelBufferArray.count == kMaxPixelBufferCacheNum) {
                shouldWait = YES;
            }
        }
        if (shouldWait) {
            dispatch_semaphore_wait(_decodeSemaphore,DISPATCH_TIME_FOREVER);
        }
        
        vp = [self.parser nextPacket];
        if(vp == nil) {
            [self.parser close];
            break;
        }
        uint32_t nalSize = (uint32_t)(vp.size - 4);
        uint8_t *pNalSize = (uint8_t*)(&nalSize);
        vp.buffer[0] = *(pNalSize + 3);
        vp.buffer[1] = *(pNalSize + 2);
        vp.buffer[2] = *(pNalSize + 1);
        vp.buffer[3] = *(pNalSize);
        
        CVPixelBufferRef pixelBuffer = NULL;
        int nalType = vp.buffer[4] & 0x1F;
        switch (nalType) {
            case 0x05:
                if([self initH264Decoder]) {
                    pixelBuffer = [self decode:vp];
                }
                break;
            case 0x07:
                [self clearH264Deocder];
                _spsSize = vp.size - 4;
                _sps = malloc(_spsSize);
                memcpy(_sps, vp.buffer + 4, _spsSize);
                break;
            case 0x08:
                _ppsSize = vp.size - 4;
                _pps = malloc(_ppsSize);
                memcpy(_pps, vp.buffer + 4, _ppsSize);
                break;
            case 0x01:
                pixelBuffer = [self decode:vp];
                break;
            default:
                break;
        }
        
        if(pixelBuffer) {
            [self.pixelBufferArray addObject:CFBridgingRelease(pixelBuffer)];
        }
    }
}

- (CVPixelBufferRef)nextPixelBuffer{
    if (!self.pixelBufferArray.count) {
        return NULL;
    }
    
    BOOL needSignal = NO;
    CVPixelBufferRef pixel = NULL;
    @synchronized (self.pixelBufferArray) {
        pixel = (CVPixelBufferRef)CFBridgingRetain([self.pixelBufferArray firstObject]);
        if (pixel) {
            needSignal = (self.pixelBufferArray.count==kMaxPixelBufferCacheNum);
            [self.pixelBufferArray removeObjectAtIndex:0];
        }
    }
    if (needSignal) {
        dispatch_semaphore_signal(_decodeSemaphore);
    }
    return pixel;
}

#pragma mark - Getter
- (VideoFileParser *)parser{
    if (!_parser) {
        _parser = [[VideoFileParser alloc] init];
    }
    return _parser;
}
@end
