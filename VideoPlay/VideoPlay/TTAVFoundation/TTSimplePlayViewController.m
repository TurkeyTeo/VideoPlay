//
//  TTSimplePlayViewController.m
//  VideoPlay
//
//  Created by Teo on 2017/9/17.
//  Copyright © 2017年 Teo. All rights reserved.
//

#import "TTSimplePlayViewController.h"
//#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface TTSimplePlayViewController ()


@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic, strong) AVPlayerItem *avPlayerItem;
@property (nonatomic, strong) AVPlayerLayer *avPlayerLayer;
@property (nonatomic, assign) BOOL isPlay;



@end

@implementation TTSimplePlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.avPlayerItem = [AVPlayerItem playerItemWithURL:self.url];
//    [self.avPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    self.avPlayer = [AVPlayer playerWithPlayerItem:self.avPlayerItem];
    self.avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    self.avPlayerLayer.frame = self.view.frame;
    [self.view.layer addSublayer:self.avPlayerLayer];
    
    [self readyToPlay];
    UITapGestureRecognizer *playTap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playOrPause)];
    [self.view addGestureRecognizer:playTap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playingEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];

}

-(void)playOrPause{
    if (self.isPlay) {
        [self.avPlayer pause];
        
    }else{
        [self.avPlayer play];
    }
    self.isPlay = !self.isPlay;
}


- (void)playingEnd:(NSNotification *)notification
{
    [self readyToPlay];
}

- (void)readyToPlay
{
    [self.avPlayerItem seekToTime:kCMTimeZero];
    [self.avPlayer play];
    self.isPlay = YES;
}



//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
//    
//    if ([keyPath isEqualToString:@"status"]) {
//        AVPlayerItem *playerItem = (AVPlayerItem *)object;
//        AVPlayerItemStatus status = playerItem.status;
//        switch (status) {
//            case AVPlayerItemStatusUnknown:{
//                
//            }
//                break;
//            case AVPlayerItemStatusReadyToPlay:{
//                [self.avPlayer play];
//                
//            }
//                break;
//            case AVPlayerItemStatusFailed:{
//                
//            }
//                break;
//            default:
//                break;
//        }
//    }
//}


@end
