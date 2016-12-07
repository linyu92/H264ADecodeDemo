//
//  PvrTextureInfo.m
//  practicework
//
//  Created by bleach on 16/6/8.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "PvrTextureInfo.h"
#import "FileUtil.h"

#define PVR_TEXTURE_FLAG_TYPE_MASK	0xff

static char gPVRTexIdentifier[4] = "PVR!";

// v2
typedef NS_ENUM(NSInteger, PVRTextureFlagType) {
    kPVR2TexturePixelFormat_RGBA_4444= 0x10,
    kPVR2TexturePixelFormat_RGBA_5551,
    kPVR2TexturePixelFormat_RGBA_8888,
    kPVR2TexturePixelFormat_RGB_565,
    kPVR2TexturePixelFormat_RGB_555,
    kPVR2TexturePixelFormat_RGB_888,
    kPVR2TexturePixelFormat_I_8,
    kPVR2TexturePixelFormat_AI_88,
    kPVR2TexturePixelFormat_PVRTC_2BPP_RGBA,
    kPVR2TexturePixelFormat_PVRTC_4BPP_RGBA,
    kPVR2TexturePixelFormat_BGRA_8888,
    kPVR2TexturePixelFormat_A_8,
};

// v3
/* supported predefined formats */
#define kPVR3TexturePixelFormat_PVRTC_2BPP_RGB   0
#define kPVR3TexturePixelFormat_PVRTC_2BPP_RGBA  1
#define kPVR3TexturePixelFormat_PVRTC_4BPP_RGB   2
#define kPVR3TexturePixelFormat_PVRTC_4BPP_RGBA  3

/* supported channel type formats */
#define kPVR3TexturePixelFormat_BGRA_8888  0x0808080861726762ULL
#define kPVR3TexturePixelFormat_RGBA_8888  0x0808080861626772ULL
#define kPVR3TexturePixelFormat_RGBA_4444  0x0404040461626772ULL
#define kPVR3TexturePixelFormat_RGBA_5551  0x0105050561626772ULL
#define kPVR3TexturePixelFormat_RGB_565    0x0005060500626772ULL
#define kPVR3TexturePixelFormat_RGB_888    0x0008080800626772ULL
#define kPVR3TexturePixelFormat_A_8        0x0000000800000061ULL
#define kPVR3TexturePixelFormat_L_8        0x000000080000006cULL
#define kPVR3TexturePixelFormat_LA_88      0x000008080000616cULL

static const PVRTexturePixelFormatInfo PVRTableFormats[] = {
    // 0: BGRA_8888
    {GL_RGBA, GL_BGRA, GL_UNSIGNED_BYTE, 32, NO, YES, kTexture2DPixelFormat_RGBA8888},
    // 1: RGBA_8888
    {GL_RGBA, GL_RGBA, GL_UNSIGNED_BYTE, 32, NO, YES, kTexture2DPixelFormat_RGBA8888},
    // 2: RGBA_4444
    {GL_RGBA, GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4, 16, NO, YES, kTexture2DPixelFormat_RGBA4444},
    // 3: RGBA_5551
    {GL_RGBA, GL_RGBA, GL_UNSIGNED_SHORT_5_5_5_1, 16, NO, YES, kTexture2DPixelFormat_RGB5A1},
    // 4: RGB_565
    {GL_RGB, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, 16, NO, NO, kTexture2DPixelFormat_RGB565},
    // 5: RGB_888
    {GL_RGB, GL_RGB, GL_UNSIGNED_BYTE, 24, NO, NO, kTexture2DPixelFormat_RGB888},
    // 6: A_8
    {GL_ALPHA, GL_ALPHA, GL_UNSIGNED_BYTE, 8, NO, NO, kTexture2DPixelFormat_A8},
    // 7: L_8
    {GL_LUMINANCE, GL_LUMINANCE, GL_UNSIGNED_BYTE, 8, NO, NO, kTexture2DPixelFormat_I8},
    // 8: LA_88
    {GL_LUMINANCE_ALPHA, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 16, NO, YES, kTexture2DPixelFormat_AI88},
    
    // 9: PVRTC 2BPP RGB
    {GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG, -1, -1, 2, YES, NO, kTexture2DPixelFormat_PVRTC2},
    // 10: PVRTC 2BPP RGBA
    {GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG, -1, -1, 2, YES, YES, kTexture2DPixelFormat_PVRTC2},
    // 11: PVRTC 4BPP RGB
    {GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG, -1, -1, 4, YES, NO, kTexture2DPixelFormat_PVRTC4},
    // 12: PVRTC 4BPP RGBA
    {GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG, -1, -1, 4, YES, YES, kTexture2DPixelFormat_PVRTC4},
};

typedef struct PixelFormathash {
    uint64_t pixelFormat;
    const PVRTexturePixelFormatInfo * pixelFormatInfo;
}PixelFormathash;

typedef NS_ENUM(NSInteger, kPVR3TextureFlag) {
    kPVR3TextureFlagPremultipliedAlpha	= (1<<1)	// has premultiplied alpha
};

// v2
static struct PixelFormathash v2_pixel_formathash[] = {
    
    { kPVR2TexturePixelFormat_BGRA_8888,	&PVRTableFormats[0] },
    { kPVR2TexturePixelFormat_RGBA_8888,	&PVRTableFormats[1] },
    { kPVR2TexturePixelFormat_RGBA_4444,	&PVRTableFormats[2] },
    { kPVR2TexturePixelFormat_RGBA_5551,	&PVRTableFormats[3] },
    { kPVR2TexturePixelFormat_RGB_565,		&PVRTableFormats[4] },
    { kPVR2TexturePixelFormat_RGB_888,		&PVRTableFormats[5] },
    { kPVR2TexturePixelFormat_A_8,			&PVRTableFormats[6] },
    { kPVR2TexturePixelFormat_I_8,			&PVRTableFormats[7] },
    { kPVR2TexturePixelFormat_AI_88,		&PVRTableFormats[8] },
    
#ifdef GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG
    { kPVR2TexturePixelFormat_PVRTC_2BPP_RGBA,	&PVRTableFormats[10] },
    { kPVR2TexturePixelFormat_PVRTC_4BPP_RGBA,	&PVRTableFormats[12] },
#endif
};

#define PVR2_MAX_TABLE_ELEMENTS (sizeof(v2_pixel_formathash) / sizeof(v2_pixel_formathash[0]))

// v3
struct PixelFormathash v3_pixel_formathash[] = {
    {kPVR3TexturePixelFormat_BGRA_8888,	&PVRTableFormats[0] },
    {kPVR3TexturePixelFormat_RGBA_8888,	&PVRTableFormats[1] },
    {kPVR3TexturePixelFormat_RGBA_4444, &PVRTableFormats[2] },
    {kPVR3TexturePixelFormat_RGBA_5551, &PVRTableFormats[3] },
    {kPVR3TexturePixelFormat_RGB_565,	&PVRTableFormats[4] },
    {kPVR3TexturePixelFormat_RGB_888,	&PVRTableFormats[5] },
    {kPVR3TexturePixelFormat_A_8,		&PVRTableFormats[6] },
    {kPVR3TexturePixelFormat_L_8,		&PVRTableFormats[7] },
    {kPVR3TexturePixelFormat_LA_88,		&PVRTableFormats[8] },
    
#ifdef GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG
    {kPVR3TexturePixelFormat_PVRTC_2BPP_RGB,	&PVRTableFormats[9] },
    {kPVR3TexturePixelFormat_PVRTC_2BPP_RGBA,	&PVRTableFormats[10] },
    {kPVR3TexturePixelFormat_PVRTC_4BPP_RGB,	&PVRTableFormats[11] },
    {kPVR3TexturePixelFormat_PVRTC_4BPP_RGBA,	&PVRTableFormats[12] },
#endif
};

//Tells How large is tableFormats
#define PVR3_MAX_TABLE_ELEMENTS (sizeof(v3_pixel_formathash) / sizeof(v3_pixel_formathash[0]))

typedef NS_ENUM(NSInteger, PVR2TextureFlag) {
    kPVR2TextureFlagMipmap         = (1<<8),        // has mip map levels
    kPVR2TextureFlagTwiddle        = (1<<9),        // is twiddled
    kPVR2TextureFlagBumpmap        = (1<<10),       // has normals encoded for a bump map
    kPVR2TextureFlagTiling         = (1<<11),       // is bordered for tiled pvr
    kPVR2TextureFlagCubemap        = (1<<12),       // is a cubemap/skybox
    kPVR2TextureFlagFalseMipCol    = (1<<13),       // are there false colored MIP levels
    kPVR2TextureFlagVolume         = (1<<14),       // is this a volume texture
    kPVR2TextureFlagAlpha          = (1<<15),       // v2.1 is there transparency info in the texture
    kPVR2TextureFlagVerticalFlip   = (1<<16),       // v2.1 is the texture vertically flipped
};

typedef struct PVRTexV2Header {
    uint32_t headerLength;
    uint32_t height;
    uint32_t width;
    uint32_t numMipmaps;
    uint32_t flags;
    uint32_t dataLength;
    uint32_t bpp;
    uint32_t bitmaskRed;
    uint32_t bitmaskGreen;
    uint32_t bitmaskBlue;
    uint32_t bitmaskAlpha;
    uint32_t pvrTag;
    uint32_t numSurfs;
}PVRTexV2Header;

typedef struct PVRTexV3Header {
    uint32_t version;
    uint32_t flags;
    uint64_t pixelFormat;
    uint32_t colorSpace;
    uint32_t channelType;
    uint32_t height;
    uint32_t width;
    uint32_t depth;
    uint32_t numberOfSurfaces;
    uint32_t numberOfFaces;
    uint32_t numberOfMipmaps;
    uint32_t metadataLength;
}__attribute__((packed)) PVRTexV3Header;

@interface PvrTextureInfo()

@end

@implementation PvrTextureInfo

- (BOOL)unpackPVRv2Data:(NSData *)data {
    if([data length] < sizeof(PVRTexV2Header)) {
        return NO;
    }
    
    BOOL success = NO;
    PVRTexV2Header *header = NULL;
    uint32_t flags, pvrTag;
    uint32_t dataLength = 0, dataOffset = 0, dataSize = 0;
    uint32_t blockSize = 0, widthBlocks = 0, heightBlocks = 0;
    uint32_t width = 0, height = 0, bpp = 4;
    uint8_t *bytes = NULL;
    uint32_t formatFlags;
    
    header = (PVRTexV2Header *)[data bytes];
    
    pvrTag = CFSwapInt32LittleToHost(header->pvrTag);
    
    if ((uint32_t)gPVRTexIdentifier[0] != ((pvrTag >>  0) & 0xff) ||
        (uint32_t)gPVRTexIdentifier[1] != ((pvrTag >>  8) & 0xff) ||
        (uint32_t)gPVRTexIdentifier[2] != ((pvrTag >> 16) & 0xff) ||
        (uint32_t)gPVRTexIdentifier[3] != ((pvrTag >> 24) & 0xff)) {
        return NO;
    }
    
    flags = CFSwapInt32LittleToHost(header->flags);
    formatFlags = flags & PVR_TEXTURE_FLAG_TYPE_MASK;
    
    for(NSUInteger i = 0; i < (unsigned int)PVR2_MAX_TABLE_ELEMENTS ; i++) {
        if(v2_pixel_formathash[i].pixelFormat == formatFlags) {
            _pixelFormatInfo = v2_pixel_formathash[i].pixelFormatInfo;
            _numberOfMipmaps = 0;
            
            _width = width = CFSwapInt32LittleToHost(header->width);
            _height = height = CFSwapInt32LittleToHost(header->height);
            
            if (CFSwapInt32LittleToHost(header->bitmaskAlpha)) {
                _hasAlpha = YES;
            } else {
                _hasAlpha = NO;
            }
            
            _pixelFormat = _pixelFormatInfo->pixelFormat;
            bpp = _pixelFormatInfo->bpp;
            dataLength = CFSwapInt32LittleToHost(header->dataLength);
            bytes = ((uint8_t *)[data bytes]) + sizeof(PVRTexV2Header);
            
            // Calculate the data size for each texture level and respect the minimum number of blocks
            while (dataOffset < dataLength) {
                switch (formatFlags) {
                    case kPVR2TexturePixelFormat_PVRTC_2BPP_RGBA: {
                        blockSize = 8 * 4; // Pixel by pixel block size for 2bpp
                        widthBlocks = width / 8;
                        heightBlocks = height / 4;
                    }
                        break;
                    case kPVR2TexturePixelFormat_PVRTC_4BPP_RGBA: {
                        blockSize = 4 * 4; // Pixel by pixel block size for 4bpp
                        widthBlocks = width / 4;
                        heightBlocks = height / 4;
                    }
                        break;
                    case kPVR2TexturePixelFormat_BGRA_8888: {
                        //这种格式需要检查GL扩展是否支持,现在默认不支持这种
                        return NO;
                    }
                        break;
                    default: {
                        blockSize = 1;
                        widthBlocks = width;
                        heightBlocks = height;
                    }
                        break;
                }
                
                // Clamp to minimum number of blocks
                if (widthBlocks < 2) {
                    widthBlocks = 2;
                }
                if (heightBlocks < 2) {
                    heightBlocks = 2;
                }
                
                dataSize = widthBlocks * heightBlocks * ((blockSize  * bpp) / 8);
                unsigned int packetLength = (dataLength - dataOffset);
                packetLength = packetLength > dataSize ? dataSize : packetLength;
                
                // Mipmap count
                [_imageDatas addObject:[NSData dataWithBytes:bytes+dataOffset length:packetLength]];
                _numberOfMipmaps++;
                
                NSAssert(_numberOfMipmaps < PVRMIPMAP_MAX, @"TexturePVR: Maximum number of mimpaps reached. Increate the PVRMIPMAP_MAX value");
                
                dataOffset += packetLength;
                width = MAX(width >> 1, 1);
                height = MAX(height >> 1, 1);
            }
            
            success = YES;
            break;
        }
    }
    
    if(!success) {
        NSLog(@"Unsupported PVR Pixel Format: 0x%2x. Re-encode it with a OpenGL pixel format variant", formatFlags);
    }
    
    return success;
}

- (BOOL)unpackPVRv3Data:(NSData *)data {
    if([data length] < sizeof(PVRTexV3Header)) {
        return NO;
    }
    
    PVRTexV3Header *header = (PVRTexV3Header *)[data bytes];
    if(CFSwapInt32BigToHost(header->version) != 0x50565203) {
        NSLog(@"pvr file version mismatch");
        return NO;
    }
    
    uint64_t pixelFormat = header->pixelFormat;
    BOOL infoValid = NO;
    for(int i = 0; i < PVR3_MAX_TABLE_ELEMENTS; i++) {
        if(v3_pixel_formathash[i].pixelFormat == pixelFormat) {
            _pixelFormatInfo = v3_pixel_formathash[i].pixelFormatInfo;
            _hasAlpha = _pixelFormatInfo->alpha;
            infoValid = YES;
            break;
        }
    }
    
    if(!infoValid) {
        NSLog(@"unsupported pvr pixelformat: %llx", pixelFormat);
        return NO;
    }
    
    uint32_t flags = CFSwapInt32LittleToHost(header->flags);
    
    _forcePremultipliedAlpha = YES;
    if(flags & kPVR3TextureFlagPremultipliedAlpha) {
        _hasPremultipliedAlpha = YES;
    }
    
    uint32_t dataLength = (uint32_t)[data length];
    uint32_t width = CFSwapInt32LittleToHost(header->width);
    uint32_t height = CFSwapInt32LittleToHost(header->height);
    _width = width;
    _height = height;
    uint32_t dataOffset = 0, dataSize = 0;
    uint32_t blockSize = 0, widthBlocks = 0, heightBlocks = 0;
    uint8_t *bytes = NULL;
    
    dataOffset = (sizeof(PVRTexV3Header) + header->metadataLength);
    bytes = (uint8_t *)[data bytes];
    
    _numberOfMipmaps = header->numberOfMipmaps;
    NSAssert(_numberOfMipmaps < PVRMIPMAP_MAX, @"TexturePVR: Maximum number of mimpaps reached. Increate the PVRMIPMAP_MAX value");
    
    for(int i = 0; i < _numberOfMipmaps; i++) {
        
        switch(pixelFormat) {
            case kPVR3TexturePixelFormat_PVRTC_2BPP_RGB :
            case kPVR3TexturePixelFormat_PVRTC_2BPP_RGBA : {
                blockSize = 8 * 4; // Pixel by pixel block size for 2bpp
                widthBlocks = width / 8;
                heightBlocks = height / 4;
            }
                break;
            case kPVR3TexturePixelFormat_PVRTC_4BPP_RGB :
            case kPVR3TexturePixelFormat_PVRTC_4BPP_RGBA : {
                blockSize = 4 * 4; // Pixel by pixel block size for 4bpp
                widthBlocks = width / 4;
                heightBlocks = height / 4;
            }
                break;
            case kPVR3TexturePixelFormat_BGRA_8888: {
                //这种格式需要检查GL扩展是否支持,现在默认不支持这种
                return NO;
            }
                break;
            default: {
                blockSize = 1;
                widthBlocks = width;
                heightBlocks = height;
            }
                break;
        }
        
        // Clamp to minimum number of blocks
        if (widthBlocks < 2) {
            widthBlocks = 2;
        }
        if (heightBlocks < 2) {
            heightBlocks = 2;
        }
        
        dataSize = widthBlocks * heightBlocks * ((blockSize  * _pixelFormatInfo->bpp) / 8);
        unsigned int packetLength = ((unsigned int)dataLength - dataOffset);
        packetLength = packetLength > dataSize ? dataSize : packetLength;
        
        // Mipmap countx
        [_imageDatas addObject:[NSData dataWithBytes:bytes + dataOffset length:packetLength]];
        
        dataOffset += packetLength;
        NSAssert(dataOffset <= dataLength, @"TexurePVR: Invalid length");
        
        width = MAX(width >> 1, 1);
        height = MAX(height >> 1, 1);
    }
    
    return YES;
}

- (GLenum)internalFormat {
    if (_pixelFormatInfo) {
        return _pixelFormatInfo->internalFormat;
    }
    return GL_RGBA;
}

- (GLenum)format {
    if (_pixelFormatInfo) {
        return _pixelFormatInfo->format;
    }
    return GL_RGBA;
}

- (GLenum)type {
    if (_pixelFormatInfo) {
        return _pixelFormatInfo->type;
    }
    return GL_UNSIGNED_BYTE;
}

- (BOOL)compressed {
    if (_pixelFormatInfo) {
        return _pixelFormatInfo->compressed;
    }
    
    return NO;
}

- (id)initWithContentsOfFile:(NSString *)path {
    if (self = [super init]) {
        unsigned char* pvrData = NULL;
        NSInteger pvrlen = 0;
        NSString* lowerCase = [path lowercaseString];
        
        NSData* data = nil;
        if ([lowerCase hasSuffix:@".ccz"]) {
            pvrlen = inflateCCZFile([path UTF8String], &pvrData);
            if (pvrlen > 0) {
                data = [NSData dataWithBytes:pvrData length:pvrlen];
            }
        } else if([lowerCase hasSuffix:@".gz"]) {
            pvrlen = inflateGZipFile( [path UTF8String], &pvrData);
            if (pvrlen > 0) {
                data = [NSData dataWithBytes:pvrData length:pvrlen];
            }
        } else {
            data = [NSData dataWithContentsOfFile:path];
        }
        
        if(data == nil) {
            return nil;
        }
        
        _imageDatas = [[NSMutableArray alloc] initWithCapacity:10];

        _width = _height = 0;
        _hasAlpha = NO;
        _pixelFormatInfo = NULL;
        
        if (!data || (![self unpackPVRv2Data:data] && ![self unpackPVRv3Data:data])) {
            self = nil;
        }
    }
    
    return self;
}

- (id)initWithContentsOfURL:(NSURL *)url {
    if (![url isFileURL]) {
        return nil;
    }
    
    return [self initWithContentsOfFile:[url path]];
}


+ (id)pvrTextureWithContentsOfFile:(NSString *)path {
    return [[self alloc] initWithContentsOfFile:path];
}

+ (id)pvrTextureWithContentsOfURL:(NSURL *)url {
    if (![url isFileURL])
        return nil;
    
    return [PvrTextureInfo pvrTextureWithContentsOfFile:[url path]];
}

@end
