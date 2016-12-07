#import <Foundation/Foundation.h>
#include "VideoFileParser.h"

#define BUFFER_START_CODE_LENGTH(x) (x==1?4:3)

const uint8_t KStartCode[4] = {0, 0, 0, 1};
const uint8_t KStartCode4[4] = {0, 0, 0, 1};
const uint8_t KStartCode3[3] = {0, 0, 1};

@implementation VideoPacket
- (instancetype)initWithSize:(NSInteger)size
{
    self = [super init];
    self.buffer = malloc(size);
    self.size = size;
    
    return self;
}

-(void)dealloc
{
    free(self.buffer);
}
@end

@interface VideoFileParser ()
{
    uint8_t *_buffer;
    NSInteger _bufferSize;
    NSInteger _bufferCap;
}
@property NSString *fileName;
@property NSInputStream *fileStream;
@end

@implementation VideoFileParser

-(BOOL)open:(NSString *)fileName
{
    if (_isValid) {
        return NO;
    }
    
    _bufferSize = 0;
    _bufferCap = 512 * 1024;
    _buffer = malloc(_bufferCap);
    self.fileName = fileName;
    self.fileStream = [NSInputStream inputStreamWithFileAtPath:fileName];
    [self.fileStream open];

    _isValid = YES;
    return YES;
}

-(VideoPacket*)nextPacket
{
    if (_buffer== NULL) {
        return nil;
    }
    
    if(_bufferSize < _bufferCap && self.fileStream.hasBytesAvailable) {
        NSInteger readBytes = [self.fileStream read:_buffer + _bufferSize maxLength:_bufferCap - _bufferSize];
        _bufferSize += readBytes;
    }
    
    BOOL valid = NO;
    int startcode = 4;
    int verbose = 0;
    
    if (memcmp(_buffer, KStartCode4, 4) == 0) {
        startcode = 4;
        verbose = 0;
        valid = YES;
    }else if(memcmp(_buffer, KStartCode3, 3) == 0){
        startcode = 3;
        verbose = 1;
        valid = YES;
    }
    
    if (!valid) {
        return nil;
    }
    
    if(_bufferSize >= 5) {
        uint8_t *bufferBegin = _buffer + startcode;
        uint8_t *bufferEnd = _buffer + _bufferSize;
        
        while(bufferBegin != bufferEnd) {
            if(*bufferBegin == 0x01) {
                if(memcmp(bufferBegin - 3, KStartCode4, 4) == 0) {
                    NSInteger packetSize = bufferBegin - _buffer - 3;
                    
                    VideoPacket *vp = [[VideoPacket alloc] initWithSize:packetSize+verbose];
                    memcpy(vp.buffer+verbose, _buffer, packetSize);
                    
                    memmove(_buffer, _buffer + packetSize, _bufferSize - packetSize);
                    _bufferSize -= packetSize;
                    
                    return vp;
                }else if(memcmp(bufferBegin - 2, KStartCode3, 3) == 0) {
                    NSInteger packetSize = bufferBegin - _buffer - 2;
                    
                    VideoPacket *vp = [[VideoPacket alloc] initWithSize:packetSize+verbose];
                    memcpy(vp.buffer+verbose, _buffer, packetSize);
                    
                    memmove(_buffer, _buffer + packetSize, _bufferSize - packetSize);
                    _bufferSize -= packetSize;
                    
                    return vp;
                }
            }
            ++bufferBegin;
        }
    }

    return nil;
}

-(void)close
{
    _isValid = NO;
    
    if (_buffer!= NULL) {
        free(_buffer);
        _buffer = NULL;
    }
    if (self.fileStream) {
        [self.fileStream close];
    }
}

@end
