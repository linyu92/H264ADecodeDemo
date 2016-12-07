//
//  SVGAParticleInfo.m
//  ourtimes
//
//  Created by linyu on 7/29/16.
//  Copyright © 2016 YY. All rights reserved.
//

#import "SVGAParticleInfo.h"

@implementation SVGAParticleInfo

-(void)dealloc{
    if (_quadData) {
        free(_quadData);
        _quadData = NULL;
    }
}

@end
