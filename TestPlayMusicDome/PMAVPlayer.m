//
//  PMAVPlayer.m
//  TestPlayMusicDome
//
//  Created by qujie on 2018/1/3.
//  Copyright © 2018年 linkin. All rights reserved.
//

#import "PMAVPlayer.h"
#import <MediaPlayer/MediaPlayer.h>

@interface PMAVPlayer ()
/**
 设置是否后台播放，默认为 YES
 */
@property (nonatomic , getter=isPlayOnBackground) BOOL playOnBackground ;

@property (nonatomic , strong) NSMutableArray<NSURL *> * playList ;

@property (nonatomic , strong) AVPlayerItem * curItem ;

@property (nonatomic , copy) NSString * albumName ;
@property (nonatomic , copy) NSString * artist ;
@property (nonatomic , copy) NSString * songName ;
@property (nonatomic , strong) UIImage * artworkImage ;

@end

@implementation PMAVPlayer
@synthesize playing = _playing ;
@synthesize currentPlayingIndex = _currentPlayingIndex ;
@synthesize duration = _duration ;
@synthesize currentPlayingTime = _currentPlayingTime ;

-(instancetype)init
{
    if (self = [super init]) {
        
        self.playOnBackground = YES ;
        self.playerModel = PMAVPlayerModeSequenceList ;
        self.currentProgress = 0 ;
        self.playerSpeed = 1 ;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voicePlayDidAutoFinished) name:AVPlayerItemDidPlayToEndTimeNotification object:[AVAudioSession sharedInstance]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChangeNotification:) name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
        //处理中断事件的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterreption:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLockedScreenMusic) name:UIApplicationDidEnterBackgroundNotification object:nil];

        [self observerPlayingProgressing];
        [self setWhenLockScreenShowAlbumName:@"专辑名称" artist:@"歌手" songName:@"歌曲名称" artworkImage:nil];
    }
    return self ;
}

-(void)observerPlayingProgressing
{
    __weak typeof(self) weakSelf = self;
    [self addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:DISPATCH_QUEUE_PRIORITY_DEFAULT usingBlock:^(CMTime time) {
        _currentPlayingTime = CMTimeGetSeconds(time);
        _currentProgress = weakSelf.currentPlayingTime / weakSelf.duration ;
        if (weakSelf.playerItemProgressingChangeBlock) {
            weakSelf.playerItemProgressingChangeBlock(weakSelf, weakSelf.currentPlayingTime, weakSelf.duration - weakSelf.currentPlayingTime, weakSelf.currentProgress);
        }
    }];
}

-(void)setWhenLockScreenShowAlbumName:(NSString *)albumName artist:(NSString *)artist songName:(NSString *)songName artworkImage:(UIImage *)artworkImage
{
    if (artworkImage == nil) {
        artworkImage = [UIImage imageNamed:@"popup_ic_weixin"];
    }
    self.albumName = [albumName copy];
    self.artist = [artist copy];
    self.songName = [songName copy];
    self.artworkImage = artworkImage ;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.curItem) {
        [self.curItem removeObserver:self forKeyPath:@"status"];
    }
}

/**
 锁屏下看到的播放信息
 */
- (void)updateLockedScreenMusic{
    //TODO: 屏时候的音乐信息更新，建议1秒更新一次
    // 播放信息中心
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    
    // 初始化播放信息
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    // 专辑名称
    info[MPMediaItemPropertyAlbumTitle] = self.albumName;
    // 歌手
    info[MPMediaItemPropertyArtist] = self.artist;
    // 歌曲名称
    info[MPMediaItemPropertyTitle] = self.songName;
    // 设置图片
    info[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:self.artworkImage];
    // 设置持续时间（歌曲的总时间）
    [info setObject:[NSNumber numberWithFloat:CMTimeGetSeconds([self.currentItem duration])] forKey:MPMediaItemPropertyPlaybackDuration];
    // 设置当前播放进度
    [info setObject:[NSNumber numberWithFloat:CMTimeGetSeconds(CMTimeMake(self.currentPlayingTime, self.playerSpeed))] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    
    // 切换播放信息
    center.nowPlayingInfo = info;
}

-(void)routeChangeNotification:(NSNotification *)not
{
    NSLog(@"%@",not.userInfo);
    int changeReason= [not.userInfo[AVAudioSessionRouteChangeReasonKey] intValue];
    //等于AVAudioSessionRouteChangeReasonOldDeviceUnavailable表示旧输出不可用
    if (changeReason==AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        AVAudioSessionRouteDescription *routeDescription=not.userInfo[AVAudioSessionRouteChangePreviousRouteKey];
        AVAudioSessionPortDescription *portDescription= [routeDescription.outputs firstObject];
        //原设备为耳机说明由耳机拔出来了，则暂停
        if ([portDescription.portType isEqualToString:@"Headphones"]) {
            [self pause];
        }
    }
}

//-->实现接收到中断通知时的方法
//处理中断事件
-(void)handleInterreption:(NSNotification *)sender
{
    if (self.playing) {
        [self pause];
    }
    
    if (self.playerItemPlayingInterruptionBlock) {
        self.playerItemPlayingInterruptionBlock(self);
    }
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        [self executStatusChangeBlcok:(PMAVPlayerItemStatus)self.currentItem.status];
    }
}
-(AVPlayerItem *)playerItemWithIndex:(NSUInteger)index
{
    if (index > self.playList.count) {
        return nil ;
    }
    AVPlayerItem * playerItem = [AVPlayerItem playerItemWithURL:[self getVoiceItemWithIndex:index]] ;
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    return playerItem;
}

#pragma mark - 监听音频播放结束通知
-(void)voicePlayDidAutoFinished
{
    self.currentProgress = 0.0 ;
    _playing = NO ;
    [self executStatusChangeBlcok:PMAVPlayerItemStatusPlayFinish];
    
    if (self.playerModel == PMAVPlayerModeOnce) { // 只播放一次
      
    }
    else if(self.playerModel == PMAVPlayerModeSingleLoop){ //单曲循环
        
        [self play];
    }
    else{ // 自动切换音频
        [self next];
    }
}

#pragma mark - 播放相关
-(void)executStatusChangeBlcok:(PMAVPlayerItemStatus)status
{
    if (self.playerItemStatuDidChangedBlock) {
        self.playerItemStatuDidChangedBlock(self, status);
    }
}

-(void)play
{
    if (!self.playList.count) {
        return ;
    }
    
    if (!self.playing) {
        [self playAtIndex:self.currentPlayingIndex];
    }
}
-(void)playAtIndex:(NSUInteger)index
{
    if ((self.currentPlayingIndex == index && self.isPlaying) || index >= self.playList.count) {
        return ;
    }
    
    _currentPlayingIndex = index ;
    if (self.currentItem == nil) {
        [self replaceCurrentItemWithPlayerItem:self.curItem];
    }
    
    [self executStatusChangeBlcok:PMAVPlayerItemStatusWillBeginPlay];
    [super play];
    _playing = YES ;
    [self executStatusChangeBlcok:PMAVPlayerItemStatusBeginningPlay];
}
-(void)pause
{
    if (!self.playList.count) {
        return ;
    }
    
    if (self.playing) {
        [super pause];
        _playing = NO ;
        [self executStatusChangeBlcok:PMAVPlayerItemStatusPause];
    }
}
-(void)next
{
    [self turnVoiceWithNext:YES];
}
-(void)previous
{
    [self turnVoiceWithNext:NO];
}
-(void)turnVoiceWithNext:(BOOL)isNext
{
    [self pause];
    
    if (!self.playList.count) {
        return ;
    }

    if (self.playerModel == PMAVPlayerModeRandomList) { //随机播放
        _currentPlayingIndex = [self getRandomItemIndex];
    }
    else{
        if (isNext) {
            _currentPlayingIndex = (_currentPlayingIndex + 1) >= self.playList.count ? 0 : _currentPlayingIndex + 1 ;
        }
        else{
            _currentPlayingIndex = _currentPlayingIndex == 0 ? self.playList.count - 1 : _currentPlayingIndex - 1 ;
        }
    }
    
    [self replaceCurrentItemWithPlayerItem:self.curItem];
    
    [self play];
}
- (NSInteger)getRandomItemIndex{
    
    if (self.playList.count <= 1 ) {
        return self.playList.count ;
    }
    
    //TODO: 从播放列表获取一个随机音乐下标
    NSInteger random = arc4random() % [self.playList count];
    if(self.currentPlayingIndex == random)
        if([self.playList count] > 1)
            [self getRandomItemIndex];
    
    return random;
}

/**
 滑动播放的位置

 @param currentTime 当前播放时间
 @param speed 播放速度
 */
-(void)seekToCurrentTime:(int64_t)currentTime speed:(int32_t)speed
{
    if (self.currentItem) {
        [self seekToTime:CMTimeMake(currentTime, speed)];
    }
}

#pragma mark - 进度转对应音频的时间(单位 秒)
-(int64_t)timeWithProgressOnCurrentItem:(CGFloat)progress
{
    if (self.currentItem) {
        return CMTimeGetSeconds(self.currentItem.duration) * progress ;
    }
    return 0 ;
}

#pragma mark - 添加音频到播放列表的方法
-(void)addVoiceItemURLFromURL:(NSURL *)itemURL
{
    if (itemURL) {
        if ([itemURL isKindOfClass:[NSString class]]) {
            itemURL = [NSURL URLWithString:(NSString *)itemURL];
        }
        else if([itemURL isKindOfClass:[NSURL class]]){
            [self.playList addObject:itemURL];
        }
    }
}
-(void)addVoiceItemURLsFromArray:(NSArray<NSURL *> *) itemURLs
{
    for (NSURL * itemURL in itemURLs) {
        [self addVoiceItemURLFromURL:itemURL];
    }
}

#pragma mark - 从播放列表中获取音频
-(NSURL *)getVoiceItemWithIndex:(NSUInteger)index
{
    if (self.playList.count > index) {
        return [self.playList objectAtIndex:index];
    }
    return nil ;
}
-(NSArray<NSURL *> *)getVoiceItemsFromIndex:(NSUInteger)fromIndex
{
    return [self getVoiceItemsFromIndex:fromIndex toIndex:self.playList.count] ;
}
-(NSArray<NSURL *> *)getVoiceItemsToIndex:(NSUInteger)toIndex
{
    return [self getVoiceItemsFromIndex:0 toIndex:toIndex] ;
}
-(NSArray<NSURL *> *)getVoiceItemsFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    toIndex = toIndex > self.playList.count ? self.playList.count : toIndex ;
    NSMutableArray<NSURL *> * items = [[NSMutableArray alloc] init];
    for (; fromIndex < toIndex; fromIndex++) {
        [items addObject:[self getVoiceItemWithIndex:fromIndex]];
    }
    NSArray * itms = [items copy];
    
    return itms ;
}
-(NSArray<NSURL *> *)getAllVoiceItems
{
    return [NSArray arrayWithArray:self.playList];
}

#pragma mark - 从播放列表中删除音频
-(void)removeVoiceItemAtIndex:(NSUInteger)index
{
    if (self.playList.count > index) {
        [self.playList removeObjectAtIndex:index];
    }
}
-(void)removeVoiceItemWithURL:(NSURL *)itemURL
{
    if (itemURL) {
        [self.playList removeObject:itemURL];
    }
}
-(void)removeVoiceItemsFromIndex:(NSUInteger)fromIndex
{
    [self removeVoiceItemsFromIndex:fromIndex toIndex:self.playList.count];
}
-(void)removeVoiceItemsToIndex:(NSUInteger)toIndex
{
    [self removeVoiceItemsFromIndex:0 toIndex:toIndex];
}
-(void)removeVoiceItemsFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    toIndex = toIndex > self.playList.count ? self.playList.count : toIndex ;
    for (; fromIndex < toIndex; fromIndex++) {
        [self removeVoiceItemAtIndex:fromIndex];
    }
}
-(void)removeVoiceItemsWithURLs:(NSArray<NSURL *> *)itemURLs
{
    if (itemURLs.count) {
        [self.playList removeObjectsInArray:itemURLs];
    }
}
-(void)removeAllVoiceItems
{
    [self.playList removeAllObjects];
}

#pragma mark - setter & getter 方法
UIBackgroundTaskIdentifier _bgTaskId;
-(void)setPlayOnBackground:(BOOL)playOnBackground
{
    _playOnBackground = playOnBackground ;

    //开启后台处理多媒体事件
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    AVAudioSession * session=[AVAudioSession sharedInstance];
    [session setActive:playOnBackground error:nil];
    //后台播放
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    //这样做，可以在按home键进入后台后 ，播放一段时间，几分钟吧。但是不能持续播放网络歌曲，若需要持续播放网络歌曲，还需要申请后台任务id，具体做法是：
    _bgTaskId=[PMAVPlayer backgroundPlayerID:_bgTaskId];
    //其中的_bgTaskId是后台任务UIBackgroundTaskIdentifier _bgTaskId;在appdelegate.m中定义的全局变量
}
+(UIBackgroundTaskIdentifier)backgroundPlayerID:(UIBackgroundTaskIdentifier)backTaskId
{
    //设置并激活音频会话类别
    AVAudioSession *session=[AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
    //允许应用程序接收远程控制
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    //设置后台任务ID
    UIBackgroundTaskIdentifier newTaskId=UIBackgroundTaskInvalid;
    newTaskId=[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    if(newTaskId!=UIBackgroundTaskInvalid&&backTaskId!=UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:backTaskId];
    }
    return newTaskId;
}


-(void)setPlayerSpeed:(int32_t)playerSpeed
{
    if (_playerSpeed != playerSpeed) {
        _playerSpeed = playerSpeed ;
        [self seekToCurrentTime:[self timeWithProgressOnCurrentItem:self.currentProgress] speed:_playerSpeed];
    }
}
-(void)setCurrentProgress:(CGFloat)currentProgress
{
    if (currentProgress < 0.0) {
        currentProgress = 0.0 ;
    }
    else if(currentProgress > 1.0){
        currentProgress = 1.0 ;
    }
    
    if (_currentProgress != currentProgress) {
        _currentProgress = currentProgress ;
        [self seekToCurrentTime:self.currentPlayingTime speed:self.playerSpeed];
    }
}

-(NSMutableArray *)playList
{
    if (!_playList) {
        _playList = [NSMutableArray array];
    }
    return _playList ;
}

-(AVPlayerItem *)curItem
{
    if (_curItem) {
        [_curItem removeObserver:self forKeyPath:@"status"];
    }
    _curItem = [self playerItemWithIndex:self.currentPlayingIndex];
    
    return _curItem ;
}

-(NSTimeInterval)duration
{
    return CMTimeGetSeconds(self.currentItem.duration);
}

-(NSTimeInterval)currentPlayingTime
{
    return CMTimeGetSeconds(self.currentTime);
}

@end
