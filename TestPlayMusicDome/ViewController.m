//
//  ViewController.m
//  TestPlayMusicDome
//
//  Created by qujie on 2018/1/2.
//  Copyright © 2018年 linkin. All rights reserved.
//

#import "ViewController.h"
#import "PMAVPlayer.h"

@interface ViewController ()

@property (nonatomic , strong) PMAVPlayer * player ;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.player = [[PMAVPlayer alloc] init];
    self.player.playerModel = PMAVPlayerModeSequenceList ;
    self.player.playerItemStatuDidChangedBlock = ^(PMAVPlayer *player, PMAVPlayerItemStatus playerStatus) {
        NSLog(@"状态改变 = %ld",playerStatus);
    };
    __weak typeof(self) weakSelf = self ;
    self.player.playerItemProgressingChangeBlock = ^(PMAVPlayer *player, NSTimeInterval currentTime, NSTimeInterval restTime, CGFloat progress) {
        NSLog(@"进度改变 = (%f , %f)-> %f",currentTime , restTime , progress);
        
        if (currentTime > 10) {
            weakSelf.player.playerSpeed = 10 ;
        }
    };
    
    [self.player addVoiceItemURLFromURL:[NSURL URLWithString:@"http://audio.xmcdn.com/group29/M04/BE/DA/wKgJWVle4BjzvgpgAS4Y4A7PBjQ631.m4a"]];
    [self.player play];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
