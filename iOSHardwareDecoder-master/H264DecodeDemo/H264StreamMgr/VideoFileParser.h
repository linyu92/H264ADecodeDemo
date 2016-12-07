#include <objc/NSObject.h>

@interface VideoPacket : NSObject

@property uint8_t* buffer;
@property NSInteger size;

- (instancetype)initWithSize:(NSInteger)size;

@end

@interface VideoFileParser : NSObject

@property (nonatomic,assign,readonly) BOOL isValid;

-(BOOL)open:(NSString*)fileName;
-(VideoPacket *)nextPacket;
-(void)close;



@end
