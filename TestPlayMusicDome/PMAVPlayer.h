//
//  PMAVPlayer.h
//  TestPlayMusicDome
//
//  Created by qujie on 2018/1/3.
//  Copyright © 2018年 linkin. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, PMAVPlayerMode) {
    PMAVPlayerModeSequenceList,//顺序播放，列表循环
    PMAVPlayerModeRandomList,//随机播放
    PMAVPlayerModeOnce, //单曲播放，播完结束
    PMAVPlayerModeSingleLoop//单曲循环
};
typedef NS_ENUM(NSInteger, PMAVPlayerItemStatus) {
    PMAVPlayerItemStatusUnknown        ,     // 未知 , system
    PMAVPlayerItemStatusReadyToPlay    ,     // 准备就绪 ，可以播放 , system
    PMAVPlayerItemStatusFailed         ,     // 播放失败 , system
    PMAVPlayerItemStatusWillBeginPlay  ,     // 将要开始播放
    PMAVPlayerItemStatusBeginningPlay  ,     // 已经开始播放
    PMAVPlayerItemStatusPause          ,     // 暂停播放
    PMAVPlayerItemStatusPlayFinish     ,     // 播放当前音频结束
};

@class PMAVPlayer ;

/**
 播放状态改变 block 定义

 @param player 当前播放器
 @param playerStatus 状态
 */
typedef void(^PlayerItemStatuDidChangedBlock)(PMAVPlayer * player , PMAVPlayerItemStatus playerStatus) ;

/**
 播放进度 block 定义

 @param player 当前播放器
 @param currentTime 当前播放时间, 单位为秒
 @param restTime 剩余时间, 单位为秒
 @param progress 进度 0.0 ~ 1.0
 */
typedef void(^PlayerItemProgressingChangedBlock)(PMAVPlayer * player , NSTimeInterval currentTime , NSTimeInterval restTime , CGFloat progress) ;


/**
 播放被中断

 @param player 当前播放器
 */
typedef void(^PlayerItemPlayingInterruptionBlock)(PMAVPlayer * player) ;



@interface PMAVPlayer : AVPlayer

/**
 设置播放模式 , 默认 AVPlayerModeSequenceList 顺序播放，列表循环
 */
@property (nonatomic , assign) PMAVPlayerMode playerModel ;

/**
 设置播放速度 , 默认 1
 */
@property (nonatomic , assign) int32_t playerSpeed ;

/**
 设置当前进度，0.0f ~ 1.0f
 */
@property (nonatomic , assign) CGFloat currentProgress ;

/**
 是否正在播放
 */
@property (nonatomic , assign , readonly , getter=isPlaying) BOOL playing ;

/**
 正在播放的音频 所在 列表的位置下标 , 默认 0 位置开始
 */
@property (nonatomic , assign , readonly) NSUInteger currentPlayingIndex ;
/**
 当前音频已经播放的时长，单位为秒
 */
@property (nonatomic , assign , readonly) NSTimeInterval currentPlayingTime ;
/**
 当前音频总时长，单位为秒
 */
@property (nonatomic , assign , readonly) NSTimeInterval duration;

/**
 播放状态改变 block 回调
 */
@property (nonatomic , copy) PlayerItemStatuDidChangedBlock playerItemStatuDidChangedBlock ;
/**
播放进度改变 block 回调
 */
@property (nonatomic , copy) PlayerItemProgressingChangedBlock playerItemProgressingChangeBlock ;

/**
 播放被中断
 */
@property (nonatomic , copy) PlayerItemPlayingInterruptionBlock playerItemPlayingInterruptionBlock ;


/**
 添加音频到播放列表的方法

 @param itemURL 音频URL
 */
-(void)addVoiceItemURLFromURL:(NSURL *) itemURL ;
-(void)addVoiceItemURLsFromArray:(NSArray<NSURL *> *) itemURLs ;

/**
 从播放列表中获取音频
 */
-(NSURL *)getVoiceItemWithIndex:(NSUInteger)index ;
-(NSArray<NSURL *> *)getVoiceItemsFromIndex:(NSUInteger)fromIndex ;
-(NSArray<NSURL *> *)getVoiceItemsToIndex:(NSUInteger)toIndex ;
-(NSArray<NSURL *> *)getVoiceItemsFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
-(NSArray<NSURL *> *)getAllVoiceItems ;

/**
 从播放列表中删除音频
 */
-(void)removeVoiceItemAtIndex:(NSUInteger)index ;
-(void)removeVoiceItemWithURL:(NSURL *)itemURL ;
-(void)removeVoiceItemsFromIndex:(NSUInteger)fromIndex ;
-(void)removeVoiceItemsToIndex:(NSUInteger)toIndex ;
-(void)removeVoiceItemsFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex ;
-(void)removeVoiceItemsWithURLs:(NSArray<NSURL *> *)itemURLs ;
-(void)removeAllVoiceItems ;


/**
 锁屏下，在屏幕上显示音频的信息
 
 @param albumName 专辑名称
 @param artist 歌手名
 @param songName 歌曲名称
 @param artworkImage 显示的图片 ， 图片不能为空
 */
-(void)setWhenLockScreenShowAlbumName:(NSString *)albumName artist:(NSString *)artist songName:(NSString *)songName artworkImage:(UIImage *)artworkImage ;


#pragma mark - 播放音频相关
/**
 播放
 */
-(void)play ;
-(void)playAtIndex:(NSUInteger)index ;

/**
 暂停
 */
-(void)pause ;

/**
 下一首
 */
-(void)next ;

/**
 上一首
 */
-(void)previous ;

/**
 滑动播放的位置
 
 @param currentTime 当前播放时间
 @param speed 播放速度
 */
-(void)seekToCurrentTime:(int64_t)currentTime speed:(int32_t)speed ;

@end
