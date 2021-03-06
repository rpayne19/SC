//
//  SettingsViewController.m
//  SLQTSOR
//
//  Created by Mike Daley on 10/12/2009.
//  Copyright 2009 Michael Daley. All rights reserved.
//

#import "SettingsViewController.h"
#import "SoundManager.h"
#import "GameController.h"
#import "AbstractScene.h"

@interface SettingsViewController (Private)

// Moves the high score view into view when a showHighScore notification is received.
- (void)show;

// Update the controls on the view with the current values
- (void)updateControlValues;

@end

#pragma mark -
#pragma mark Public implementation

@implementation SettingsViewController

#pragma mark -
#pragma mark Deallocation

- (void)dealloc {
	// Remove observers that have been set up
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"showSettings" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"updateSettingsSliders" object:nil];
	
    [super dealloc];
}

#pragma mark -
#pragma mark Init view

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Set up the settings view
		sharedSoundManager = [SoundManager sharedSoundManager];
		sharedGameController = [GameController sharedGameController];
		
		// Set up a notification observers
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(show) name:@"showSettings" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateControlValues) name:@"updateSettingsSliders" object:nil];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Set the slider buttons to match our game theme
	[musicVolume setThumbImage:[UIImage imageNamed:@"ui_scrollbutton.png"] forState:UIControlStateNormal];
	[fxVolume setThumbImage:[UIImage imageNamed:@"ui_scrollbutton.png"] forState:UIControlStateNormal];

    // Set the slider tracks to also match the theme of the game. A single image with two 20 pixel wide caps
    // and a single stretchable pixel in the middle is used as the image.
    UIImage *slidercaps = [[UIImage imageNamed:@"sliderbg"] stretchableImageWithLeftCapWidth:20 topCapHeight:0];
    [musicVolume setMinimumTrackImage:slidercaps forState:UIControlStateNormal];
    [musicVolume setMaximumTrackImage:slidercaps forState:UIControlStateNormal];
    [fxVolume setMinimumTrackImage:slidercaps forState:UIControlStateNormal];
    [fxVolume setMaximumTrackImage:slidercaps forState:UIControlStateNormal];
    [slidercaps release];
}

- (void)viewWillAppear:(BOOL)animated {
	// Set the initial alpha of the view
	self.view.alpha = 0;

	// Make sure the controls on the view are updated with the current values
	[self updateControlValues];

	// If the orientation is in landscape then transform the view
	if (sharedGameController.interfaceOrientation == UIInterfaceOrientationLandscapeRight){
		[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
		self.view.transform = CGAffineTransformIdentity;
		self.view.transform = CGAffineTransformMakeRotation(M_PI_2);
		self.view.center = CGPointMake(160, 240);
	}
	if (sharedGameController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
		[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft];
		self.view.transform = CGAffineTransformIdentity;
		self.view.transform = CGAffineTransformMakeRotation(-M_PI_2);
		self.view.center = CGPointMake(160, 240);
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"pauseGame" object:self];
}

#pragma mark -
#pragma mark UI Actions

- (IBAction)musicValueChanged:(UISlider*)sender {
	
	// Change the music volume in the sound manager using the slider value
	sharedSoundManager.musicVolume = [sender value];
}

- (IBAction)fxValueChanged:(UISlider*)sender {
	
	// Change the music volume in the sound manager using the slider value
	sharedSoundManager.fxVolume = [sender value];
	
}

- (IBAction)joypadSideChanged:(UISegmentedControl*)sender {
	
	// Change the leftHanded property in the GameController
	sharedGameController.joypadPosition = sender.selectedSegmentIndex;
}

- (IBAction)fireDirctionChanged:(UISegmentedControl*)sender {
	sharedGameController.fireDirection = sender.selectedSegmentIndex;
}

#pragma mark -
#pragma mark Rotating and hiding

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (IBAction)hide:(id)sender {
	
	// Tell any interested parties that the settings view is being hidden.  This allows the gameScene
	// if running to check the values and switch the joypad as necessary
	[[NSNotificationCenter defaultCenter] postNotificationName:@"startGame" object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"hidingSettings" object:self];
	
	// Fade out the view using core animation.  We do not want to remove this view from EAGLView
	// until the fade has ended, so we use the animation delegate and AnimationDidStopSelector
	// to call the hideFinished method when the animation is done.  This then removes this
	// view from EAGLView
    
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(hideFinished)];
	self.view.alpha = 0.0f;
	[UIView commitAnimations];
}

- (void)hideFinished {
	// Remove this view from its superview i.e. EAGLView.  This allows the next view that is added
	// to be the topmost view and therefore react to orientation events
	[self.view removeFromSuperview];
}

- (IBAction)moveToMenu:(id)sender {

	// Set up the alert view that will check of the player really wants to return to the menu
	UIAlertView *alterView = [[UIAlertView alloc] initWithTitle:@"Return To Menu" message:@"Are you sure?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
	
	// Show the alert view
	[alterView show];
	
	// Now the view is visible we can release it
	[alterView release];
}

#pragma mark -
#pragma mark Alert View delegate

- (void)alertView:(UIAlertView*)alterView clickedButtonAtIndex:(NSInteger)buttonIndex {

	// Check to see which button has been pressed. Index 1 is the YES button and that is 
	// all we are interested in
	if (buttonIndex == 1) {
		// Hide the settings view
		[self hide:nil];
		
		// The user wants to finish so save the state of the game
		[sharedGameController.currentScene saveGameState];
		
		// The user wants to move to the menu so transition out of this scene.
		[(AbstractScene*)sharedGameController.currentScene setState:kSceneState_TransitionOut];
	}

}

@end

#pragma mark -
#pragma mark Private implementation

@implementation SettingsViewController (Private)

- (void)show {
	
	// Add this view as a subview of EAGLView
	[sharedGameController.eaglView addSubview:self.view];
	
	// If the current scene name is not name, then hide the menu button
	if (![sharedGameController.currentScene.name isEqualToString:@"game"]) {
		menuButton.hidden = YES;
	} else {
		menuButton.hidden = NO;
	}
	
	// ...then fade it in using core animation
	[UIView beginAnimations:nil context:NULL];
	self.view.alpha = 1.0f;
	[UIView commitAnimations];
}

- (void)updateControlValues {

	// Set the views control values based on the game controllers values
	musicVolume.value = sharedSoundManager.currentMusicVolume;
	fxVolume.value = sharedSoundManager.fxVolume;
	joypadPosition.selectedSegmentIndex = sharedGameController.joypadPosition;
	fireDirction.selectedSegmentIndex = sharedGameController.fireDirection;
}

@end
