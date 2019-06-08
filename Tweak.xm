#include <stdlib.h>
#import <AVFoundation/AVFoundation.h>


@interface VolumeControl
+(id)sharedVolumeControl;
-(void)setMediaVolume:(float)arg1;
-(float)getMediaVolume;
-(BOOL)headphonesPresent;
-(BOOL)_isMusicPlayingSomewhere;
-(void)toggleMute;
@end

@interface SpringBoard
+(id)sharedApplication;
-(void)_updateRingerState:(int)arg1 withVisuals:(BOOL)arg2 updatePreferenceRegister:(BOOL)arg3;
@end

@interface SBHUDController
-(void)hideHUDView;
@end

@interface Meow : NSObject <AVAudioPlayerDelegate>
@property(nonatomic, retain) AVAudioPlayer *player;
-(void)meow;
@end


static NSTimeInterval timeStamp = 0;
static Meow *meow;
static BOOL meowing = NO;

%hook SBUIController

-(void)updateBatteryState:(id)arg1 {
	%orig;

	// Meow
	if (timeStamp == 0) {
		int m = (arc4random_uniform(60) + 1) * 60;
		int h = (arc4random_uniform(60) + 1) * 60 * 60;
		int s = arc4random_uniform(60) + 1;

		timeStamp = [[NSDate date] timeIntervalSince1970] + h + m + s;
		
	} else if (timeStamp < [[NSDate date] timeIntervalSince1970]) {
		if (!meow)
        	meow = [[Meow alloc] init];
		[meow meow];
	}
}

%end

%hook SBHUDController

-(void)presentHUDView:(id)arg1 {
	if (meowing) {
		[self hideHUDView];
	} else {
		%orig;
	}
}

-(void)presentHUDView:(id)arg1 autoDismissWithDelay:(double)arg2 {
	if (meowing) {
		[self hideHUDView];
	} else {
		%orig;
	}
}

%end

@implementation Meow {
	AVAudioPlayer *player;
	NSNumber *cachedVol;
}
@synthesize player;

-(id)init {
	return self;
}

-(void)meow {
	if (![[%c(VolumeControl) sharedVolumeControl] headphonesPresent] && ![[%c(VolumeControl) sharedVolumeControl] _isMusicPlayingSomewhere]) {
		cachedVol = [NSNumber numberWithFloat: [[%c(VolumeControl) sharedVolumeControl] getMediaVolume]];
		if (cachedVol != nil) {
			NSError *error = nil;
			[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
			[[AVAudioSession sharedInstance] setActive:YES error:&error];
			if (error)
				NSLog(@"Meow");
			
			meowing = YES;
			[[%c(VolumeControl) sharedVolumeControl] setMediaVolume: 1.f];
			NSString * path = [NSString stringWithFormat:@"/Library/Application Support/Meow.bundle/m%d.mp3", arc4random_uniform(15) + 1];
			self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:NULL];
			self.player.delegate = self;
			self.player.volume = 1.f;
			[self.player play];
			timeStamp = 0;
		}
	}
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
	if (cachedVol != nil) 
		[[%c(VolumeControl) sharedVolumeControl] setMediaVolume: [cachedVol floatValue]];
	meowing = NO;
}

@end