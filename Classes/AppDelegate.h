//
//  AppDelegate.h
//  SLQTSOR
//
//  Created by Michael Daley on 18/08/2009.
//  Copyright Michael Daley 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EAGLView;
@class SoundManager;
@class GameController;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    UIWindow *window;
    EAGLView *glView;
	
	// Sound manager reference
	SoundManager *sharedSoundManager;
	GameController *sharedGameController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet EAGLView *glView;

@end

