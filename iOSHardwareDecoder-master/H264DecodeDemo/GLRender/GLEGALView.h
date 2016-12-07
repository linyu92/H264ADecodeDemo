//
//  GLEGALView.h
//  H264DecodeDemo
//
//  Created by linyu on 11/22/16.
//  Copyright © 2016 duowan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLEGALView : UIView

- (void)startRenderWithH264File:(NSString *)path;

- (void)terminalRendering;

@end
