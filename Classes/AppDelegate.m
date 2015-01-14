//
//  AppDelegate.m
//  SLQTSOR
//
//  Created by Michael Daley on 18/08/2009.
//  Copyright Michael Daley 2009. All rights reserved.
//

#import "AppDelegate.h"
#import "Global.h"
#import "EAGLView.h"
#import "SoundManager.h"
#import "GameController.h"
#import "GameScene.h"

#pragma mark -
#pragma mark Private interface

@interface AppDelegate (Private)

// Loads the settings from the settings plist file into the 
// sound manager
- (void)loadSettings;

@end

#pragma mark -
#pragma mark Public implementation

@implementation AppDelegate

@synthesize window;
@synthesize glView;

- (void) dealloc
{
	[window release];
	[glView release];
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	// Grab a reference to the sound manager
	sharedGameController = [GameController sharedGameController];
	sharedSoundManager = [SoundManager sharedSoundManager];


	// Start getting device orientation notifications
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];

	[glView setMultipleTouchEnabled:YES];
    
	[glView setBounds:screenBounds];
	// Load the settings from the plist file
	[sharedGameController loadSettings];
	
	// Start the game
	[glView startAnimation];
}
- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self applicationDidFinishLaunching:application];
    return YES;
}
- (void) applicationWillResignActive:(UIApplication *)application
{
	// The game is resigning its active status i.e. a phone call, alarm or lock has occured.
	// We don't want the game to continue in this case so we stop the animation
	[glView stopAnimation];
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
	// If the game was paused when it resigned active then we don't want to 
	// start the game again when the app becomes active
	if (!sharedGameController.gamePaused)
		[glView startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Stop the game loop
	[glView stopAnimation];
	
	// If the current scenes state is game over or completed then don't save the game state
	if (sharedGameController.currentScene.state != kSceneState_GameOver && 
		sharedGameController.currentScene.state != kSceneState_GameCompleted) {
		[sharedGameController.currentScene saveGameState];
	}

	[sharedGameController saveSettings];
	
	// Enable the idle timer before we leave
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

@end

