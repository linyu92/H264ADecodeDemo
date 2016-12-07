//
//  GLParticelRenderer.m
//  practicework
//
//  Created by bleach on 16/6/19.
//  Copyright © 2016年 duowan. All rights reserved.
//

#import "GLParticelRenderer.h"
#import "ParticelInfo.h"
#import "ImageUtils.h"
#import "GLParticelFilter.h"
#import "SVDeviceUtil.h"

#define ParticelMaxQuadLength 20                 //同时存在的点赞数

#define ParticelMaxCount 20                 //同时存在的点赞数
#define ParticelScale 16.5f                 //默认大小
#define ParticelScaleFactor 0.6f                 //默认大小
#define ParticelBornX 2.0f                  //点赞产生时的X轴范围[-5.0f ~ 5.0f]
#define ParticelRotate 45.0f                //点赞产生时的旋转角度范围[-45.0f ~ 45.0f]
//以下参数是在30fps的情况下的取值，在60fps需要*0.5
#define ParticelSpeedX 0.05f                 //X轴的偏移速度
#define ParticelSpeedY 1.75f                 //Y轴的偏移速度
#define ParticelAlpyaY 0.25f                 //Y轴开始变透明的范围
#define ParticelDismissAlphaFactor 0.007f                 //Y轴开始变透明


// [0.8f ~ 1.2f]
static inline GLfloat scaleRandf() { return ((rand() % RAND_MAX) / (GLfloat)(RAND_MAX) - 0.5) / 3.0f + 1.f; }
// [-1.0f ~ 1.0f]
static inline GLfloat areaRandf() { return (rand() % RAND_MAX) / (GLfloat)(RAND_MAX) * 2.0f - 1.0f; }

@interface GLParticelRenderer()

@property (nonatomic, assign) GLuint particelCount;
@property (nonatomic, strong) GLParticelFilter* filter;

@property (nonatomic, assign) GLuint packBuffer;
@property (nonatomic, assign) GLuint indexBuffer;

@property (nonatomic, strong) NSMutableArray* particelArray;

//@property (nonatomic, strong) NSMutableArray* lazyParticleAry1;
//@property (nonatomic, strong) NSMutableArray* lazyParticleAry2;

@property (nonatomic, strong) NSArray* lazyParticleSection;

@end

@implementation GLParticelRenderer {
    GLQuad* _particelPackData;
    GLQuad* _packData;
    BOOL _needUpdate,_forceRender;
    GLfloat _alphaHeight;
    GLfloat _composeTexWidth;
    GLuint _composeCount;
}

- (void)dealloc{
    GLLogi(@"dealloc");
}

- (instancetype)initWithContext:(EAGLContext*)glContext AndDrawable:(id<EAGLDrawable>)drawable {
    id obj = [super initWithContext:glContext AndDrawable:drawable];
    [self initData];
    [self initBuffer];
    return obj;
}

- (void)updateParticlesWithImagesIfNeed{
    if (!self.particlesImageForUpdate)
        return;
    
    [self updateParticlesWithImages:self.particlesImageForUpdate];
    self.particlesImageForUpdate = nil; //设置完后置空
}
- (void)updateParticlesWithImages:(NSArray *)images{
    [_particelArray removeAllObjects];
    [_lazyParticleSection[PraiseParticleType_Mine] removeAllObjects];
    [_lazyParticleSection[PraiseParticleType_Other] removeAllObjects];

    _needUpdate = YES;
    _particelCount = 0;
    
    UIImage* composeImage = [ImageUtils composeImage:images];
    if (composeImage == nil) {
        NSAssert(NO, @"Compose Image Error");
    }
    _composeCount = (GLuint)images.count;
    _composeTexWidth = 1.0f / _composeCount;
    
    if (_filter) {
        [_filter updateTextureWithUIImage:composeImage];
    }
    
    GLfloat squareData[] = {
        -1.0f, 1.0f, 0.0f, 1.0f,    0.0f, 1.0f,     1.0f,
        -1.0f, -1.0f, 0.0f, 1.0f,   0.0f, 0.0f,     1.0f,
        1.0f, -1.0f, 0.0f, 1.0f,    1.0f, 0.0f,     1.0f,
        1.0f, 1.0f, 0.0f, 1.0f,     1.0f, 1.0f,     1.0f,
    };
    
    //_packData 因为纹理数量可能不同，需要重新构造
    if (_packData != NULL) {
        free(_packData);
        _packData = NULL;
    }
    _packData = (GLQuad *)malloc(sizeof(GLQuad) * _composeCount);
    for (GLuint index = 0; index < _composeCount; index++) {
        memcpy(&_packData[index], squareData, sizeof(GLQuad));
        GLQuad* quad = (GLQuad *)&_packData[index];
        quad->data[0].texcoord.tx = index * _composeTexWidth;
        quad->data[0].texcoord.ty = 1.0f;
        quad->data[1].texcoord.tx = index * _composeTexWidth;
        quad->data[1].texcoord.ty = 0.0f;
        quad->data[2].texcoord.tx = (index + 1) * _composeTexWidth;
        quad->data[2].texcoord.ty = 0.0f;
        quad->data[3].texcoord.tx = (index + 1) * _composeTexWidth;
        quad->data[3].texcoord.ty = 1.0f;
    }
    
    //_particelPackData 粒子激活数固定不变，所以置位即可
    memset(_particelPackData, 0, sizeof(_particelPackData) / sizeof(_particelPackData[0]));
}

- (void)initData {
    _particelArray = [[NSMutableArray alloc] initWithCapacity:ParticelMaxCount];
    NSMutableArray *mineParticle = [[NSMutableArray alloc] initWithCapacity:ParticelMaxCount];
    NSMutableArray *otherParticle = [[NSMutableArray alloc] initWithCapacity:ParticelMaxCount];
    _lazyParticleSection = @[mineParticle,otherParticle];
    
    _needUpdate = YES;
    _particelCount = 0;
    _particelPackData = (GLQuad *)malloc(sizeof(GLQuad) * ParticelMaxCount);
    _alphaHeight = ParticelAlpyaY * viewHeight / 2.0f;
    memset(_particelPackData, 0, sizeof(_particelPackData) / sizeof(_particelPackData[0]));
    
    if (!_filter) {
        _filter = [[GLParticelFilter alloc] initWithSize:CGSizeMake(viewWidth, viewHeight)];
    }
}

- (void)initBuffer {
    uint16_t vertexIndexs[6 * ParticelMaxCount];
    for (GLuint index = 0; index < ParticelMaxCount; index++) {
        vertexIndexs[index * 6] = index * 4;
        vertexIndexs[index * 6 + 1] = index * 4 + 1;
        vertexIndexs[index * 6 + 2] = index * 4 + 2;
        vertexIndexs[index * 6 + 3] = index * 4;
        vertexIndexs[index * 6 + 4] = index * 4 + 2;
        vertexIndexs[index * 6 + 5] = index * 4 + 3;
    }
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 6 * ParticelMaxCount * sizeof(uint16_t), vertexIndexs, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_packBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _packBuffer);
    glBufferData(GL_ARRAY_BUFFER, ParticelMaxCount * sizeof(struct GLQuad), NULL, GL_DYNAMIC_DRAW);
}

- (BOOL)doRender {
    if (_filter && (_particelArray.count > 0 || _forceRender)) {
        if (_particelArray.count == 0) {
            _forceRender = NO;
        }
        [self updateParticelV3];
        [_filter renderElementWithPackBuffer:_packBuffer indexBuffer:_indexBuffer elementCount:_particelCount needUpdate:_needUpdate];
        _needUpdate = NO;
        return YES;
    }
    return NO;
}

- (void)doResize{
    if (_filter) {
        [_filter updateViewSize:CGSizeMake(viewWidth, viewHeight)];
    }
}

- (void)deinit {
    [super deinit];
    if (_filter) {
        [_filter deinit];
    }
    if (_indexBuffer != 0) {
        glDeleteBuffers(1, &_indexBuffer);
        _indexBuffer = 0;
    }
    if (_packBuffer != 0) {
        glDeleteBuffers(1, &_packBuffer);
        _packBuffer = 0;
    }
    if (_packData != NULL) {
        free(_packData);
        _packData = NULL;
    }
    if (_particelPackData != NULL) {
        free(_particelPackData);
        _particelPackData = NULL;
    }
    GetGLError();
}

#pragma mark - public
- (void)addParticelV1 {
    if (_particelCount >= ParticelMaxCount) {
        return;
    }
    
    GLfloat particelScale = ParticelScale * scaleRandf();                   //最终的目标大小
    GLfloat particelRotate = ParticelRotate * areaRandf();                  //旋转的角度
    GLfloat particelBornX = ParticelBornX * areaRandf();                    //产生时的X轴位置
    
    GLMatrix* matrix = [[GLMatrix alloc] init];
    [matrix setTranslate:particelBornX y:-viewHeight / 2.0f z:0.0f];
    [matrix rotate:particelRotate xAxis:0.0f yAxis:0.0f zAxis:1.0f];
    [matrix scale:particelScale yScale:particelScale zScale:1.0f];
    
    GLPackData* vertexPack = NULL;
    memcpy(&_particelPackData[_particelCount], _packData, sizeof(GLQuad));
    GLQuad* quadData = &_particelPackData[_particelCount];
    for (GLuint index = 0; index < 4; index++) {
        vertexPack = &quadData->data[index];
        [matrix multiplyVector4:&vertexPack->vertex];
    }
    _particelCount++;
    
    glBindBuffer(GL_ARRAY_BUFFER, _packBuffer);
    glBufferSubData(GL_ARRAY_BUFFER, 0,  _particelCount * sizeof(struct GLQuad), _particelPackData);
}

- (void)addParticelV2 {
    if (_particelArray.count >= ParticelMaxCount) {
        return;
    }
    
    GLfloat particelScale = ParticelScale * scaleRandf();                   //最终的目标大小
    GLfloat particelRotate = ParticelRotate * areaRandf();                  //旋转的角度
    GLfloat particelBornX = ParticelBornX * areaRandf();                    //产生时的X轴位置
    GLfloat particelSpeedX = ParticelSpeedX * areaRandf();                  //X轴的偏移速度
    GLfloat particelSpeedY = ParticelSpeedY * scaleRandf();                 //Y轴的偏移速度
    GLuint imageIndex = rand() % _composeCount;                             //指定随机哪个图片
    
    ParticelInfo* particelInfo = [[ParticelInfo alloc] init];
    particelInfo.postion = CGPointMake(particelBornX, -viewHeight / 2.0f);
    particelInfo.rotate = particelRotate;
    particelInfo.speedX = particelSpeedX;
    particelInfo.speedY = particelSpeedY;
    particelInfo.maxScale = particelScale;
    particelInfo.scaleFactor = 0.7f;
    particelInfo.imageIndex = imageIndex;
    [_particelArray addObject:particelInfo];
}

- (BOOL)addParticelV3From:(NSInteger)from length:(NSInteger)length type:(PraiseParticleType)type{
    if (_particelArray.count >= ParticelMaxCount) {
        return NO;
    }
    
    if ([_lazyParticleSection[type] count]) {
        NSInteger count = [_lazyParticleSection[type] count];
        NSInteger index = arc4random()%count;
        ParticelInfo* particelInfo = _lazyParticleSection[type][index];
        particelInfo.pathQuadIndex = 0;
        GLuint aIndex = rand() % length;
        GLuint imageIndex = (GLuint)(from + aIndex);     //图片重新指定
        if (imageIndex >= _composeCount) {
            particelInfo.imageIndex = rand() % _composeCount;
        }else{
            particelInfo.imageIndex = imageIndex;
        }
        [_lazyParticleSection[type] removeObjectAtIndex:index];
        [_particelArray addObject:particelInfo];
    }else{
        GLfloat particelScale = ParticelScale*scaleRandf();
        //ParticelScale * scaleRandf();                   //最终的目标大小
        GLfloat particelRotate = ParticelRotate * areaRandf();                  //旋转的角度
        GLfloat particelBornX = ParticelBornX * areaRandf();                    //产生时的X轴位置
        GLfloat particelSpeedX = ParticelSpeedX * areaRandf();                  //X轴的偏移速度
        GLfloat particelSpeedY = ParticelSpeedY * scaleRandf();                 //Y轴的偏移速度
        GLfloat particelScaleFactor = ParticelScaleFactor;
        GLfloat particelDismissAlphaFactor = ParticelDismissAlphaFactor;
        
//        if (![SVDeviceUtil isDeviceIphone5]) {
//            particelSpeedX = particelSpeedX/2;
//            particelSpeedY = particelSpeedY/2;
//            particelScaleFactor = particelScaleFactor/2;
//            particelDismissAlphaFactor = particelDismissAlphaFactor/2;
//        }
        
        ParticelInfo* particelInfo = [[ParticelInfo alloc] init];
        particelInfo.type = type;
        particelInfo.postion = CGPointMake(particelBornX, -viewHeight / 2);
        particelInfo.rotate = particelRotate;
        particelInfo.speedX = particelSpeedX;
        particelInfo.speedY = particelSpeedY;
        particelInfo.maxScale = particelScale;
        particelInfo.scaleFactor = particelScaleFactor;
        particelInfo.alphaFactor = particelDismissAlphaFactor;
        particelInfo.pathQuadIndex = 0;
        particelInfo.pathQuadLength = viewHeight/particelSpeedY;
        particelInfo.pathQuadData = (GLQuad *)malloc(sizeof(GLQuad)*particelInfo.pathQuadLength);
        GLuint aIndex = rand() % length;
        GLuint imageIndex = (GLuint)(from + aIndex);     //指定随机哪个图片
        if (imageIndex >= _composeCount) {
            particelInfo.imageIndex = rand() % _composeCount;
        }else{
            particelInfo.imageIndex = imageIndex;
        }
        
        [_particelArray addObject:particelInfo];
    }
    return YES;
}

#pragma mark - inner
- (void)updateParticelV1 {
    GLPackData* vertexPack = NULL;
    GLMatrix* matrix = [[GLMatrix alloc] init];
    [matrix setTranslate:0.0f y:ParticelSpeedY z:0.0f];
    for (GLuint particelCounter = 0; particelCounter < _particelCount; particelCounter++) {
        GLQuad* quadData = &_particelPackData[particelCounter];
        for (GLuint index = 0; index < 4; index++) {
            vertexPack = &quadData->data[index];
            [matrix multiplyVector4:&vertexPack->vertex];
        }
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, _packBuffer);
    glBufferSubData(GL_ARRAY_BUFFER, 0, _particelCount * sizeof(struct GLQuad), _particelPackData);
}

- (void)updateParticelV2 {
    GLPackData* vertexPack = NULL;
    GLMatrix* matrix = [[GLMatrix alloc] init];
    GLfloat halfViewHeight = viewHeight / 2.0f;
    NSMutableArray* activeArray = [[NSMutableArray alloc] initWithCapacity:_particelArray.count];
    for (ParticelInfo * info in _particelArray) {
        info.postion = CGPointMake(info.postion.x + info.speedX, info.postion.y + info.speedY);
        GLfloat curScale = info.curScale + info.scaleFactor;
        info.curScale = curScale > info.maxScale ? info.maxScale : curScale;
        
        if (info.postion.y > halfViewHeight) {
            continue;
        }
        
        [matrix setTranslate:info.postion.x y:info.postion.y z:0.0f];
        [matrix rotate:info.rotate xAxis:0.0f yAxis:0.0f zAxis:1.0f];
        [matrix scale:info.curScale yScale:info.curScale zScale:1.0f];
        memcpy(&_particelPackData[activeArray.count], &_packData[info.imageIndex], sizeof(GLQuad));
        GLQuad* quadData = &_particelPackData[activeArray.count];
        for (GLuint index = 0; index < 4; index++) {
            vertexPack = &quadData->data[index];
            [matrix multiplyVector4:&vertexPack->vertex];
            if (info.postion.y > _alphaHeight) {
                info.alpha -= info.alphaFactor;
                if (info.alpha < 0.0f) {
                    info.alpha = 0.0f;
                }
                vertexPack->alpha = info.alpha;
            }
        }
        [activeArray addObject:info];
    }
    
    _particelArray = activeArray;
    _particelCount = (GLuint)activeArray.count;
    glBindBuffer(GL_ARRAY_BUFFER, _packBuffer);
    glBufferSubData(GL_ARRAY_BUFFER, 0, _particelCount * sizeof(struct GLQuad), _particelPackData);
}

- (void)updateParticelV3 {    
    @autoreleasepool {
        GLPackData* vertexPack = NULL;
        GLMatrix* matrix = [[GLMatrix alloc] init];
        GLfloat halfViewHeight = viewHeight / 2.0f;
        NSMutableArray* activeArray = [[NSMutableArray alloc] initWithCapacity:_particelArray.count];
        for (ParticelInfo * info in _particelArray) {
            if (info.isReuse) {
                if (info.pathQuadIndex >= info.pathQuadLength) {
                    [_lazyParticleSection[info.type] addObject:info];
                    continue;
                }
                memcpy(&_particelPackData[activeArray.count],&info.pathQuadData[info.pathQuadIndex++], sizeof(GLQuad));
                [activeArray addObject:info];
            }else{
                info.postion = CGPointMake(info.postion.x + info.speedX, info.postion.y + info.speedY);
                GLfloat curScale = info.curScale + info.scaleFactor;
                info.curScale = curScale > info.maxScale ? info.maxScale : curScale;
                if (info.postion.y > halfViewHeight || info.pathQuadIndex >= info.pathQuadLength) {
                    //reuse it
                    info.isReuse = YES;
                    [_lazyParticleSection[info.type] addObject:info];
                    continue;
                }
                if (info.curScale < info.maxScale) {
                    [matrix setTranslate:info.postion.x y:info.postion.y z:0.0f];
                    [matrix rotate:info.rotate xAxis:0.0f yAxis:0.0f zAxis:1.0f];
                    [matrix scale:info.curScale yScale:info.curScale zScale:1.0f];
                    memcpy(&_particelPackData[activeArray.count], &_packData[info.imageIndex], sizeof(GLQuad));
                } else {
                    [matrix setTranslate:info.speedX y:info.speedY z:0.0f];
                    memcpy(&_particelPackData[activeArray.count], &info.pathQuadData[info.pathQuadIndex-1], sizeof(GLQuad));
                }
                
                GLQuad* quadData = &_particelPackData[activeArray.count];
                for (GLuint index = 0; index < 4; index++) {
                    vertexPack = &quadData->data[index];
                    [matrix multiplyVector4:&vertexPack->vertex];
                    if (info.postion.y > _alphaHeight) {
                        info.alpha -= info.alphaFactor;
                        if (info.alpha < 0.0f) {
                            info.alpha = 0.0f;
                        }
                        vertexPack->alpha = info.alpha;
                    }
                }
                //            info.pathQuadData[info.pathQuadIndex], sizeof(GLQuad));
                memcpy(&info.pathQuadData[info.pathQuadIndex], quadData, sizeof(GLQuad));
                
                [activeArray addObject:info];
                
                info.pathQuadIndex ++;
            }
        }
        
        _particelArray = activeArray;
        _particelCount = (GLuint)activeArray.count;
        glBindBuffer(GL_ARRAY_BUFFER, _packBuffer);
        glBufferSubData(GL_ARRAY_BUFFER, 0, _particelCount * sizeof(struct GLQuad), _particelPackData);
    }
}

- (void)cleanParticles{
    [_particelArray removeAllObjects];
    _particelCount = (GLuint)_particelArray.count;
    memset(_particelPackData, 0, sizeof(_particelPackData) / sizeof(_particelPackData[0]));
    _forceRender = YES;
}

@end
