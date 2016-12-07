//
//  ViewController.m
//  H264DecodeDemo
//
//  Created by Yao Dong on 15/8/6.
//  Copyright (c) 2015年 duowan. All rights reserved.
//

#import "ViewController.h"

#import "GLEGALView.h"


@interface ViewController ()
{
    GLEGALView *_playerView;
}
@end

@implementation ViewController


-(IBAction)on_playButton_clicked:(id)sender {
    NSString *string = [NSString stringWithFormat:@"test_%d",[sender tag]];
    NSString *path = [[NSBundle mainBundle] pathForResource:string ofType:@"h264"];
    [_playerView startRenderWithH264File:path];
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        [self decodeFile:@"ds2" fileExt:@"h264"];
//    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    self.view.backgroundColor = [UIColor grayColor];
    
    CGFloat width = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat height = width;
    _playerView = [[GLEGALView alloc] initWithFrame:CGRectMake(0, 160, width, height)];
    [self.view addSubview:_playerView];
//    _glLayer = [[AAPLEAGLLayer alloc] initWithFrame:self.view.bounds];
//    [self.view.layer addSublayer:_glLayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
