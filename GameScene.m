//
//  GameScene.m
//


#import <QuartzCore/QuartzCore.h>
#import "Global.h"
#import "GameController.h"
#import "ImageRenderManager.h"
#import "GameScene.h"
#import "TextureManager.h"
#import "SoundManager.h"
#import "AbstractEntity.h"
#import "Image.h"
#import "SpriteSheet.h"
#import "Animation.h"
#import "TiledMap.h"
#import "BitmapFont.h"
#import "Player.h"
#import "Door.h"
#import "Spawn.h"
#import "Enemies.h"
#import "Portal.h"
#import "Primitives.h"
#import "PackedSpriteSheet.h"
#import "Layer.h"
#import "EnergyObject.h"
#import "KeyObject.h"
#import "MapObject.h"
#import "Textbox.h"
#import "TextEvent.h"
#import "Checkpoint.h"
#import "Primitives.h"
#import "DamageText.h"
#import "PlayerAttack.h"
#import "Mouse.h"
#import "SockTrap.h"
#import "EnemyAttack.h"
#import "Zone.h"
#import <GameController/GameController.h>

#pragma mark -
#pragma mark Private interface

@interface GameScene (Private)
// Initialize the sound needed for this scene
- (void)initSound;

// Initialize/reset the game
- (void)initScene;

// Sets up the game from the previously saved game.  If any of the data files are
// missing then the resume will not take place and the initial game state will be
// used instead
- (void)loadGameState;

// Initializes the games state
- (void)initNewGameState;

// Checks the game controller for the joypadPosition value. This is used to decide where the 
// joypad should be rendered i.e. for left or right handed players.
- (void)checkJoypadSettings;

// Initialize the game content e.g. tile map, collision array
- (void)initGameContent;

// Initializes portals defined in the tile map
- (void)initPortals;

// Initializes items defined in the tile map
- (void)initItems;

// Initiaize the doors used in the map
- (void)initCollisionMapAndDoors;

// Initializes the tile map
- (void)initTileMap;

- (void)initNewTileMap:(NSString*) aTilemap song:(NSString*)aSong;

// Initializes the localDoor array before the update loop starts.  This means that doors will be
// rendered correctly when the scene fades in
- (void)initLocalDoors;

// Calculate the players tile map location.  This inforamtion is used when rendering the tile map
// layers in the render method
- (void)calculatePlayersTileMapLocation;

// Make pixel blocks
//- (void)pixelBlockedAtTileX:(int)x TileY:(int)y Shape:(uint) shape;

// Deallocates resources this scene has created
- (void)deallocResources;

@end

#pragma mark -
#pragma mark Public implementation

@implementation GameScene

@synthesize sceneTileMap;
@synthesize player;
@synthesize playerMouse;
@synthesize gameEntities;
@synthesize gameObjects;
@synthesize doors;
@synthesize spawnPoints;
@synthesize gameStartTime;
@synthesize timeSinceGameStarted;
@synthesize score;
@synthesize gameTimeToDisplay;
@synthesize locationName;
@synthesize hasMouse;
@synthesize damageText;
@synthesize playerAttack;
@synthesize nextMap;
@synthesize nextMusic;
@synthesize alertCounter;

- (void)dealloc {
    
    // Remove observers that have been set up
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"hidingSettings" object:nil];

	// Dealloc resources this scene has created
	[self deallocResources];
	
    [super dealloc];
}

- (id)init {
    
    if(self = [super init]) {
        
		// Name of this scene
        self.name = @"game";
		nextMap = nil;
		nextMusic = nil;
        // Grab an instance of our singleton classes
        sharedImageRenderManager = [ImageRenderManager sharedImageRenderManager];
        sharedTextureManager = [TextureManager sharedTextureManager];
        sharedSoundManager = [SoundManager sharedSoundManager];
        sharedGameController = [GameController sharedGameController];
	
        // Grab the bounds of the screen
        screenBounds = [[UIScreen mainScreen] bounds];
#ifdef SCB
		NSLog(@"Screenbounds (%f, %f)", screenBounds.size.width, screenBounds.size.height);
#endif
        // Set the scenes fade speed which is used when fading the scene in and out and also set
        // the default alpha value for the scene
        fadeSpeed = .10f;
        alpha = 0.0f;
		musicVolume = 0.0f;
		isTextBoxTime = NO;
		isMenuScreenTime = NO;
		alertCounter = 0;
		alertStateDelta = 0.0f;

		// Add observations on notifications we are interested in.  When the settings view is hidden we
		// want to check to see if the joypad settings have changed.  For this reason we look for this
		// notification
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkJoypadSettings) name:@"hidingSettings" object:nil];
    }
	
    
    return self;
}
//ADDED 1/31
//GPAD
/////////////////////////////////////////

#pragma mark - Game Controllers
- (void)configureGameControllers {
	NSLog(@"Starting config for game controllers");
    // Receive notifications when a controller connects or disconnects.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameControllerDidConnect:) name:GCControllerDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameControllerDidDisconnect:) name:GCControllerDidDisconnectNotification object:nil];
    
    // Configure all the currently connected game controllers.
#ifdef SCB

    NSLog(@"Made it past the nsnotification calls in controllers");
#endif
    // And start looking for any wireless controllers.
    [GCController startWirelessControllerDiscoveryWithCompletionHandler:^{
#ifdef SCB

        NSLog(@"Finished finding controllers");
#endif
    }];
}

- (void)gameControllerDidConnect:(NSNotification *)notification {
    GCController *controller = notification.object;
#ifdef SCB

    NSLog(@"Connected game controller: %@", controller);
#endif
    gamepadConnected = YES;
    NSInteger playerIndex = controller.playerIndex;
    if (playerIndex == GCControllerPlayerIndexUnset) {
        [self assignUnknownController:controller];
    } else {
        [self assignPresetController:controller toIndex:playerIndex];
    }
}

- (void)gameControllerDidDisconnect:(NSNotification *)notification {
    GCController *controller = notification.object;
#ifdef SCB
	NSLog(@"-----------------------------");
	NSLog(@"-----------------------------");
	NSLog(@"-----------------------------");
	NSLog(@"---CONTROLLER DISCONNECTED---");
	NSLog(@"-----------------------------");
	NSLog(@"-----------------------------");
	NSLog(@"-----------------------------");
#endif
	gamepadConnected = NO;
	   
}

- (void)assignUnknownController:(GCController *)controller {
	NSInteger playerIndex = 0;
    
        // Found an unlinked player.
        controller.playerIndex = playerIndex;
        [self configureController:controller];
        return;
    
}
- (void)configureConnectedGameControllers {
    // First deal with the controllers previously set to a player.
    for (GCController *controller in [GCController controllers]) {
        NSInteger playerIndex = controller.playerIndex;
        if (playerIndex == GCControllerPlayerIndexUnset) {
            continue;
        }
        
        [self assignPresetController:controller toIndex:playerIndex];
    }
    
    // Now deal with the unset controllers.
    for (GCController *controller in [GCController controllers]) {
        NSInteger playerIndex = controller.playerIndex;
        if (playerIndex != GCControllerPlayerIndexUnset) {
            continue;
        }
        
        [self assignUnknownController:controller];
    }
}
- (void)assignPresetController:(GCController *)controller toIndex:(NSInteger)playerIndex {
    // Check whether this index is free.

        [self assignUnknownController:controller];
        return;
    
    
    [self configureController:controller];
}
- (void)configureController:(GCController *)controller {
#ifdef SCB
    NSLog(@"Assigning %@ to player", controller.vendorName);
#endif
    // Assign the controller to the player.
    
    GCControllerDirectionPadValueChangedHandler dpadMoveHandler = ^(GCControllerDirectionPad *dpad, float xValue, float yValue) {
        float length = hypotf(xValue, yValue);
        if (length > 0.0f && !isTextBoxTime) {

			joyPadAngle = atan2(-yValue, -xValue);
			[player setDirectionWithAngle:joyPadAngle speed:CLAMP(length * 16, 0, 8)];
				
        } else {
			player.speedOfMovement = 0;
		}
    };
	
    // Use either the dpad or the left thumbstick to move the character.
    controller.extendedGamepad.leftThumbstick.valueChangedHandler = dpadMoveHandler;
    controller.gamepad.dpad.valueChangedHandler = dpadMoveHandler;
	
    GCControllerButtonValueChangedHandler buttonAHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		[self aButtonFunc];

    };
	GCControllerButtonValueChangedHandler buttonBHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		[self bButtonFunc];

#ifdef SCB
		if(button.isPressed)
			NSLog(@"Button B");
#endif
    };
	GCControllerButtonValueChangedHandler buttonXHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		//Mouse button
		[self xButtonFunc];
    };
	GCControllerButtonValueChangedHandler buttonYHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
		//add player attack
		[self yButtonFunc];
#ifdef SCB
		if(button.isPressed)
			NSLog(@"Button Y");
#endif
    };
	GCControllerButtonValueChangedHandler buttonRHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {

#ifdef SCB
		if(button.isPressed)
			NSLog(@"Button R1");
#endif
    };
	GCControllerButtonValueChangedHandler buttonLHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
#ifdef SCB
		if(button.isPressed)
			NSLog(@"Button L1");
#endif
    };
	GCControllerButtonValueChangedHandler triggerRHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
#ifdef SCB
		if(button.isPressed)
			NSLog(@"Button R2");
#endif
    };
	GCControllerButtonValueChangedHandler triggerLHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
#ifdef SCB
		if(button.isPressed)
			NSLog(@"Button L2");
#endif
	};
	controller.controllerPausedHandler = ^(GCController *controller) {
#ifdef SCB
		NSLog(@"PAUSE BUTTON");
#endif
		if(state == kSceneState_Paused){
			state = kSceneState_Running;
		
		}else if(state == kSceneState_Running)
			player.speedOfMovement = 0;
		
			state = kSceneState_Paused;
			
    };
	
    controller.gamepad.buttonA.valueChangedHandler = buttonAHandler;
    controller.gamepad.buttonB.valueChangedHandler = buttonBHandler;
	controller.gamepad.buttonX.valueChangedHandler = buttonXHandler;
	controller.gamepad.buttonY.valueChangedHandler = buttonYHandler;
	controller.gamepad.rightShoulder.valueChangedHandler = buttonRHandler;
	controller.gamepad.leftShoulder.valueChangedHandler = buttonLHandler;
	controller.extendedGamepad.leftTrigger.valueChangedHandler = triggerLHandler;
	controller.extendedGamepad.rightTrigger.valueChangedHandler = triggerRHandler;

}

////
//END OF ADDITIONS
//GPAD
////
- (id)initWithMap:(NSString*)aMap music:(NSString*)aSong location:(CGPoint)aPosition {
    
    if(self = [super init]) {
        
		// Name of this scene
        self.name = @"game";
		nextMap = aMap;
		nextMusic = aSong;
		newPosition = aPosition;
        // Grab an instance of our singleton classes
        sharedImageRenderManager = [ImageRenderManager sharedImageRenderManager];
        sharedTextureManager = [TextureManager sharedTextureManager];
        sharedSoundManager = [SoundManager sharedSoundManager];
        sharedGameController = [GameController sharedGameController];
		[sharedSoundManager loadMusicWithKey:@"ingame" musicFile:aSong];
        // Grab the bounds of the screen
        screenBounds = [[UIScreen mainScreen] bounds];
		currentSystem = [[UIDevice currentDevice] systemVersion];

		NSLog(@"Screenbounds (%f, %f) OS version: %@", screenBounds.size.width, screenBounds.size.height, currentSystem);

		model = [[UIDevice currentDevice] model];
		local = [[UIDevice currentDevice] localizedModel];
		NSLog(@"Model: %@ Localized: %@", model, local);

        // Set the scenes fade speed which is used when fading the scene in and out and also set
        // the default alpha value for the scene
        fadeSpeed = 1.0f;
        alpha = 0.0f;
		musicVolume = 0.0f;
		isTextBoxTime = NO;
		isMenuScreenTime = NO;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkJoypadSettings) name:@"hidingSettings" object:nil];
    }
#ifdef SCB
    NSLog(@"Returning an init Map");
#endif
    return self;
}

#pragma mark -
#pragma mark Update scene logic

- (void)updateSceneWithDelta:(GLfloat)aDelta {
#ifdef SCB
	NSLog(@"updating gamescene with a delta");
#endif
	// Clear the screen before rendering
	glClear(GL_COLOR_BUFFER_BIT);

	switch (state) {
            
        #pragma mark kSceneState_Running
        case kSceneState_Running:
            // Update the game timer if the player is alive
            if (player.state == kEntityState_Alive || player.state == kEntityState_Appearing)
                timeSinceGameStarted += aDelta;

			// Calculate the minutes and seconds that have passed since the game started
            gameSeconds = (int)timeSinceGameStarted % 60;
            gameMinutes = (int)timeSinceGameStarted / 60;
			if(textbox != nil){
				if(textbox.state == kEntityState_Alive){
					isTextBoxTime = YES;
					[textbox updateWithDelta:aDelta scene:self];
#ifdef SCB
					NSLog(@"it is textbox time");
#endif
				}else{
				
					isTextBoxTime = NO;
				}
			}
			if(!isTextBoxTime){
				
			
            // Release the gameTime string before we create it and retain it.  We retain it to make sure 
            // that it is available even if this code is not run i.e. the game is paused.  The release
            // makes sure we release it and don't leak memory.
            NSString *timeSeconds = [NSString stringWithFormat:@"%02d", gameSeconds];
            NSString *timeMinutes = [NSString stringWithFormat:@"%03d", gameMinutes];
            self.gameTimeToDisplay = [NSString stringWithFormat:@"%@.%@", timeMinutes, timeSeconds] ;
            
            // Update player
            [player updateWithDelta:aDelta scene:self];
			sockDelta += aDelta;
            // Now we have updated the player we need to update their position relative to the tile map
            [self calculatePlayersTileMapLocation];
			
			[playerAttack updateWithDelta:aDelta scene:self];
		//	if(sock1.state == kEntityState_Alive)
		//		[sock1 updateWithDelta:aDelta scene:self];
		//	if(sock2.state == kEntityState_Alive)
		//		[sock2 updateWithDelta:aDelta scene:self];
		//	if(sock3.state == kEntityState_Alive)
		//		[sock3 updateWithDelta:aDelta scene:self];
			[playerMouse updateWithDelta:aDelta scene:self];
			}
			// Calculate the tile bounds around the player. We clamp the possbile values to between
			// 0 and the width/height of the tile map.  We remove 1 from the width and height
			// as the tile map is zero indexed in the game.  These values can then be used when
			// checking if objects, portals or doors should be updated
			int minScreenTile_x = CLAMP(player.tileLocation.x - 12, 0, kMax_Map_Width-1);
			int maxScreenTile_x = CLAMP(player.tileLocation.x + 12, 0, kMax_Map_Width-1);
			int minScreenTile_y = CLAMP(player.tileLocation.y - 8, 0, kMax_Map_Height-1);
			int maxScreenTile_y = CLAMP(player.tileLocation.y + 8, 0, kMax_Map_Height-1);
			
			if(!isTextBoxTime){
			// Update the game objects that are inside the bounds calculated above
			isPlayerOverObject = NO;
			
            for(AbstractObject *gameObject in gameObjects) {
              
                if (gameObject.tileLocation.x >= minScreenTile_x && gameObject.tileLocation.x <= maxScreenTile_x &&
                    gameObject.tileLocation.y >= minScreenTile_y && gameObject.tileLocation.y <= maxScreenTile_y) {

                    // Update the object
                    [gameObject updateWithDelta:aDelta scene:self];

                    if (gameObject.state == kObjectState_Active) {
						[player checkForCollisionWithObject:gameObject];
						[gameObject checkForCollisionWithEntity:player];
						if (gameObject.isCollectable) {
							isPlayerOverObject = YES;
						}

						
					
                    }
                }
            }
			for(TextEvent *event in eventTextboxes){
				if(CGRectIntersectsRect([player movementBounds], [event getCollisionBounds])){
					if(![event isEmpty]){
						isTextBoxTime = YES;
						textbox = [event getNextTextBox];
					}
				}
			}
			for(Checkpoint *checkpoint in checkpoints){
				if(CGRectIntersectsRect([player movementBounds], [checkpoint getCollisionBounds])){
					player.checkPointLocation = checkpoint.tileLocation;
#ifdef SCB
					NSLog(@"Checkpoint reached: (%f,%f)", checkpoint.tileLocation.x, checkpoint.tileLocation.y);
#endif
				}
			}
			

			if(playerAttack.state == kEntityState_Alive) {
				[playerAttack updateWithDelta:aDelta scene:self];
			
			}
			if(sock1.state == kEntityState_Alive){
				[sock1 updateWithDelta:aDelta scene:self];
			}
			if(sock2.state == kEntityState_Alive){
				[sock2 updateWithDelta:aDelta scene:self];
			}
			if(sock2.state == kEntityState_Alive){
				[sock2 updateWithDelta:aDelta scene:self];
			}
			if(playerMouse.state == kEntityState_Alive){
				[playerMouse updateWithDelta:aDelta scene:self];
			}
			for(AbstractEntity *attack in enemyProjectiles) {
				[attack updateWithDelta:aDelta scene:self];
				
				if(attack.state == kEntityState_Alive) {
					[player checkForCollisionWithEntity:attack];
				}
			}
			for(AbstractEntity *entity in damageText)
				[entity updateWithDelta:aDelta scene:self];
			
			float distanceFromPlayer;
			areChasing = NO;
            for(AbstractEntity *entity in gameEntities) {
				distanceFromPlayer = (fabs(player.tileLocation.x - entity.tileLocation.x) + fabs(player.tileLocation.y - entity.tileLocation.y));
				if(entity.entityAIState == kEntityAIState_Chasing)
					areChasing = YES;
				if(distanceFromPlayer < 24){
					[entity updateWithDelta:aDelta scene:self];
					if(playerAttack.state == kEntityState_Alive) {
						[entity checkForCollisionWithEntity:playerAttack];
					}
					if(sock1.state == kEntityState_Alive){
						[entity checkForCollisionWithEntity:sock1];
					}
					if(sock2.state == kEntityState_Alive){
						[entity checkForCollisionWithEntity:sock2];
					}
					if(sock3.state == kEntityState_Alive){
						[entity checkForCollisionWithEntity:sock3];
					}
				
					if(distanceFromPlayer <= 8 && alertCounter > 0 && entity.entityAIState != kEntityAIState_Chasing){
						entity.entityAIState = kEntityAIState_Chasing;
						[self incrementAlertCounter];


					}
				} else if(distanceFromPlayer >= 24){
					entity.pixelLocation = entity.initLocation;
					entity.tileLocation = pixelToTileMapPosition(entity.pixelLocation);
				}
				switch (entity.state) {
				
					case kEntityState_Alive:
						// Get the player to see if it has hit the entity and also ask the entity to see if it has
						// hit the player.  Each entity has its own way of resolving a collision so both checks are
						// necessary.
						[player checkForCollisionWithEntity:entity];
						[entity checkForCollisionWithEntity:player];
						if([entity isKindOfClass:[Enemies class]]&& entity.entityAIState == kEntityAIState_Chasing  && ((fabs(player.tileLocation.x - entity.tileLocation.x) + fabs(player.tileLocation.y - entity.tileLocation.y)) < 4 || (fabs(entity.target.tileLocation.x - entity.tileLocation.x) + fabs(entity.tileLocation.y - entity.tileLocation.y)))) {

							;
						}
						// Check to see if the axe has collided with the current entity


						break;
						
					// If the entity is dead then we can revive it somewhere new near the player

					default:
						break;
				}	//end of switch

				
			}
			if(areChasing){
				if(alertStateDelta > 0)
					alertStateDelta -= aDelta * 12;
				else
					[self decrementAlertCounter];
				
			}
			}
			
			// Update portals that are within the visible screen
            for(AbstractEntity *portal in portals) {
				if (portal.tileLocation.x >= minScreenTile_x && portal.tileLocation.x <= maxScreenTile_x &&
                    portal.tileLocation.y >= minScreenTile_y && portal.tileLocation.y <= maxScreenTile_y) {
					[portal updateWithDelta:aDelta scene:self];
					if(!inBossFight)
						[portal checkForCollisionWithEntity:player];
				}
			}
			for(Zone *zone in zones) {
				if (zone.tileLocation.x >= minScreenTile_x && zone.tileLocation.x <= maxScreenTile_x &&
                    zone.tileLocation.y >= minScreenTile_y && zone.tileLocation.y <= maxScreenTile_y) {
					[zone updateWithDelta:aDelta scene:self];
					if(sharedGameController.nextScene.nextMap != zone.tilemap){
						[sharedGameController setupNextScene:zone.tilemap music:zone.song location:zone.beamLocation];
					}
						[zone checkForCollisionWithEntity:player];
				}
			}
			
            // Populate the localDoors array with any doors that are found around the player.  This allows
            // us to reduce the number of doors we are rendering and updating in any single frame.  We only
			// perform this check if the player has moved from one tile to another on the tile map to save cycles
            if ((int)player.tileLocation.x != (int)playersLastLocation.x || (int)player.tileLocation.y != (int)playersLastLocation.y) {
                
				// Clear the localDoors array as we are about to populate it again based on the 
                // players new position
                [localDoors removeAllObjects];
                
                // Find doors that are close to the player and add them to the localDoors loop.  Layer 3 in the 
				// tile map holds the door information. Updating all doors in the map is a real performance hog
				// so only updating those near the player is necessary
                Layer *layer = [[sceneTileMap layers] objectAtIndex:2];
                for (int yy=minScreenTile_y; yy < maxScreenTile_y; yy++) {
                    for (int xx=minScreenTile_x; xx < maxScreenTile_x; xx++) {
						
                        // If the value property for this tile is not -1 then this must be a door and
                        // we should add it to the localDoors array
                        if ([layer valueAtTile:CGPointMake(xx, yy)] > -1) {
                            int index = [layer valueAtTile:CGPointMake(xx, yy)];
                            [localDoors addObject:[NSNumber numberWithInt:index]];
                        }
                    }
                }
            }
			
			if (CGRectIntersectsRect([player movementBounds], exitBounds)) {
#ifdef SCB
				NSLog(@"inside exit bounds");
#endif
				isMenuScreenTime = YES;
				fadeImage.color = Color4fMake(1,1,1, alpha);
				alpha = 1;
				player.state = kEntityState_Sleep;
				state = kSceneState_GameCompleted;
				[sharedSoundManager fadeMusicVolumeFrom:sharedSoundManager.musicVolume toVolume:0.0f duration:5.0f stop:YES];
				player.tileLocation = CGPointMake(312, 480);
				player.pixelLocation = tileMapPositionToPixelPosition(player.tileLocation);
				isMusicFading = YES;
				
			}

			for(int i = 0; i < [spawnPoints count]; i++) {
				Spawn *spawn = [spawnPoints objectAtIndex:i];
#ifdef SCB
			
			NSLog(@"Index of spawnPoints: (correct) %i, index actually stored in spawn: %i", i, spawn.arrayIndex);
#endif
				[spawn updateWithDelta:aDelta scene:self];
#ifdef SCB
				
				NSLog(@"Call made to update Spawn point index: %i", i);
#endif
			}
			
			// Record the players current position previous position so we can check if the player has
			// moved between updates
            playersLastLocation = player.tileLocation;
			//[textbox updateWithDelta:aDelta scene:self];
            
            break;

        #pragma mark kSceneState_TransportingOut
        case kSceneState_TransportingOut:
            alpha += fadeSpeed * aDelta;
            fadeImage.color = Color4fMake(1, 1, 1, alpha);
            if(alpha >= 1.0f) {
                alpha = 1.0f;
                state = kSceneState_TransportingIn;

				// Now we have faded out the scene, set the players new position i.e. the beam location
				// and make the scene transition in
				player.tileLocation = player.beamLocation;
				player.pixelLocation = tileMapPositionToPixelPosition(player.tileLocation);
				[self calculatePlayersTileMapLocation];
				// Init the doors local to the players new position
				[self initLocalDoors];
            }
            break;

			
        #pragma mark kSceneState_TransportingIn
        case kSceneState_TransportingIn:
            alpha -= fadeSpeed * aDelta;
            fadeImage.color = Color4fMake(1, 1, 1, alpha);

			// Once the scene has faded in, start the scene running and
			// also reset the joypad settings.  This removes any issues with
			// the state of the joypad before the transportation takes place
            if(alpha <= 0.0f) {
                alpha = 0.0f;
                state = kSceneState_Running;
				isJoypadTouchMoving = NO;
				joypadTouchHash = 0;
				player.angleOfMovement = 0;
				player.speedOfMovement = 0;
            }
			
            break;
	
		#pragma mark kSceneState_Loading
		case kSceneState_Loading:
			// If there is a game to resume and the game has not been initialized
            // then use the saved game state to init the game else use the default
            // game state
            if (!isGameInitialized) {
				isGameInitialized = YES;

				// Set the alpha to be used when fading
				alpha = 1.0f;
				
                if(sharedGameController.shouldResumeGame) {
                    [self loadGameState];
                } else {
					[self initNewGameState];
                }
				
				// Setup the joypad based on the current settings
				[self checkJoypadSettings];
            } else if(isZoning){		//not even doing this right now
#ifdef SCB
				NSLog(@"Made it to kSceneState_Loading - isZoning clause");
#endif
				isZoning = NO;
				state = kSceneState_TransitionIn;
				alpha = 1.0f;
			}
            
            // Update the alpha for this scene using the scenes fadeSpeed.  We are not actually
			// fading all the elements on the screen.  Instead we are changing the alpha value
			// of a fully black image that is drawn over the entire scene and faded out.  This
			// gives us a nice consistent fade across all objects, including those rendered ontop
			// of other graphics such as objects on the tilemap
            alpha -= fadeSpeed * aDelta;
            fadeImage.color = Color4fMake(1, 1, 1, alpha);
			
            // Once the scene has faded in start playing the background music and set the
			// scene to running
			if(alpha < 0.0f) {
				alpha = 0.0f;
				fadeImage.color = Color4fMake(1, 1, 1, alpha);
				isLoadingScreenVisible = NO;
                state = kSceneState_Running;
				
				// Now the game is running we check to see if it was a resumed game.  If not then we play the spooky
				// voice otherwise we just play the music
				if(sharedGameController.shouldResumeGame) {
					if (!sharedSoundManager.isMusicPlaying && !sharedSoundManager.isExternalAudioPlaying) {
						sharedSoundManager.currentMusicVolume = 0;	// Make sure the music volume is down before playing the music
						[sharedSoundManager playMusicWithKey:@"ingame" timesToRepeat:-1];
						[sharedSoundManager fadeMusicVolumeFrom:0 toVolume:sharedSoundManager.musicVolume duration:0.8f stop:NO];
					}
				} else {
					if (!sharedSoundManager.isMusicPlaying && !sharedSoundManager.isExternalAudioPlaying) {
						sharedSoundManager.loopLastPlaylistTrack = YES;
						sharedSoundManager.currentMusicVolume = sharedSoundManager.musicVolume;
						[sharedSoundManager playMusicWithKey:@"ingame" timesToRepeat:-1];
					}
				}
            }
			break;
			
        #pragma mark kSceneState_TransitionIn
        case kSceneState_TransitionIn:
#ifdef SCB
			NSLog(@"GameScene: Case = TransitionIn");
#endif
			if (!isSceneInitialized) {
				isSceneInitialized = YES;
				[self initScene];
				[self initSound];
			}
			
			if (isLoadingScreenVisible) {
				state = kSceneState_Loading;
			}
            break;
			
		#pragma mark kSceneState_TransitionOut
        case kSceneState_TransitionOut:

			if (!isMusicFading) {
				isMusicFading = YES;
				[sharedSoundManager fadeMusicVolumeFrom:sharedSoundManager.musicVolume toVolume:0 duration:1.8f stop:YES];
				alpha = 0;
			}
			
			alpha += fadeSpeed / 50;
			fadeImage.color = Color4fMake(1, 1, 1, alpha);
			
            if(alpha > 1.0f) {
                alpha = 1.0f;
                state = kSceneState_Idle;
				
				// Deallocate the resources this scene has created
				[self deallocResources];
				
				// Reset game flags
				isGameInitialized = NO;
				isZoning = NO;
				timeSinceGameStarted = 0;
				score = 0;
				isJoypadTouchMoving = NO;
				isSceneInitialized = NO;
				isLoadingScreenVisible = NO;
				isMusicFading = NO;
				
				// Transition to the menu scene
				[sharedGameController transitionToSceneWithKey:@"menu"];
            }
            break;
		#pragma mark kSceneState_GameCompleted
		case kSceneState_GameCompleted:{
			if(isMusicFading){
#ifdef SCB
				NSLog(@"Alpha: %f", alpha);
				NSLog(@"Current volume: %f Music Volume: %f", sharedSoundManager.currentMusicVolume, sharedSoundManager.musicVolume);
#endif
				fadeImage.color = Color4fMake(1,1,1, alpha);

				if(alpha >= 1){
#ifdef SCB
					NSLog(@"Inside alpha greater than 1");
#endif
					alpha = 0.99f;
					player.tileLocation = CGPointMake(209, 27.5);
					player.pixelLocation = tileMapPositionToPixelPosition(player.tileLocation);
					[sharedSoundManager stopMusic];
					[sharedSoundManager playMusicWithKey:@"ending" timesToRepeat:-1];
					[sharedSoundManager fadeMusicVolumeFrom:0.0f toVolume:sharedSoundManager.musicVolume duration:1.0f stop:NO];
				}else {
					alpha -= aDelta;
					fadeImage.color = Color4fMake(1,1,1, alpha);
					if(alpha <= 0)
						isMusicFading = NO;
				}
			} else {
				alpha -= fadeSpeed * aDelta;
				fadeImage.color = Color4fMake(1,1,1, alpha);
			}if(textbox != nil){
				if(textbox.state == kEntityState_Alive){
					isTextBoxTime = YES;
					[textbox updateWithDelta:aDelta scene:self];
#ifdef SCB
					NSLog(@"it is textbox time");
#endif
				}else{
					isTextBoxTime = NO;
				}
			}
			player.speedOfMovement = 0;
			player.angle = 0;
			player.state = kEntityState_Sleep;
			[player updateWithDelta:aDelta scene:self];
			if(!isTextBoxTime){
				for(TextEvent *event in eventTextboxes){
					if(CGRectIntersectsRect([player movementBounds], [event getCollisionBounds])){
						if(![event isEmpty]){
							isTextBoxTime = YES;
							textbox = [event getNextTextBox];
						}
					}
				}
			}

			if(alpha >= 1.0f){
				alpha = 1.0f;
				player.tileLocation = CGPointMake(209.0f, 27.5f);
				player.pixelLocation = tileMapPositionToPixelPosition(player.tileLocation);
				isZoning = YES;
				isGameInitialized = NO;
	//			[sharedGameController switchToNextScene];
				[self calculatePlayersTileMapLocation];
				[self initLocalDoors];
				
			}


			}
			break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark Tile map functions

- (BOOL)isBlocked:(float)x y:(float)y {
	// If we are asked for blocking information that is beyond the map border then by default
	// return yes.  When the player is moving near the edge of the map coordinates may be passed
	// that are beyond these bounds
	if (x < 0 || y < 0 || x > kMax_Map_Width || y > kMax_Map_Height) {
		return YES;
	}
	// Return the blocked status of the specified tile
    return blocked[(int)x][(int)y];
}


- (void)setBlocked:(float)aX y:(float)aY blocked:(BOOL)aState {
    blocked[(int)aX][(int)aY] = aState;
}
- (void)reduceNoOfAttacks{
	playerAttack.numOfAttacks -= 1;
}

-(void)incrementAlertCounter{
	if(alertCounter == 0){
		[sharedSoundManager playMusicWithKey:@"alert" timesToRepeat:-1];
		[self increaseAlertCounter];
	}
	alertCounter++;
	alertStateDelta = 100.0f;
}
-(void)decrementAlertCounter{
	
	if(alertCounter == 1){
		[sharedSoundManager playMusicWithKey:@"ingame" timesToRepeat:-1];
		alertStateDelta = 0.0f;
	}
	if(alertCounter > 0)
		alertCounter--;
}

- (BOOL)isPlayerOnTopOfEnemy {
	BOOL result = NO;
	for(AbstractEntity *entity in gameEntities) {
		if([entity isEnemy])
			if(CGRectIntersectsRect([player movementBounds], [entity movementBounds])){
				result = YES;
				break;
			}
		}
	return result;
}

- (BOOL)isPlayerOnTopOfMapObject {
	BOOL result = NO;
	for(AbstractObject *object in gameObjects){
		if(CGRectIntersectsRect([player movementBounds], [object collisionBounds])) {
#ifdef SCB
			NSLog(@"Object type: %i", [object subType]);
#endif
			result = YES;
			break;
		}
	}
	return result;
}

- (void) spawnEnemyAtTile:(CGPoint)aLocation Enemy:(uint)aType Index:(int) anIndex{

	Spawn *spawn = [spawnPoints objectAtIndex: anIndex];
	if(spawn.spawnState == kEntityState_Alive) {
#ifdef SCB
		NSLog(@"Invalid spawn call for index %i", anIndex);
#endif
		;
	}
	BOOL found = NO;
	
	 if((1 < aType && 15 > aType) || (33 < aType && 42 > aType)) {
		for(Enemies *enemy in gameEntities)
			if(enemy.spawnPointIndex == anIndex){
				enemy.state = kEntityState_Appearing;
				enemy.tileLocation = spawn.tileLocation;
				spawn.spawnState = kEntityState_Alive;
				found = YES;
				break;
				
			}
		 if(!found){
			 
			 Enemies *enemy = [[Enemies alloc] initWithTileLocation:aLocation type:aType spawnPointIndex:anIndex];
		
			 enemy.state = kEntityState_Appearing;
			 [gameEntities addObject:enemy];
			 spawn.spawnState = kEntityState_Alive;
		 }
	}
}

- (void)attackPlayerFromEntity:(Enemies*)anEnemy{
	EnemyAttack* newAttack;
	newAttack = [[EnemyAttack alloc] initWithTileLocation:anEnemy.tileLocation];
	[enemyProjectiles addObject:newAttack];
}



- (BOOL)isEntityInTileAtCoords:(CGPoint)aPoint {
    // By default nothing is at the point provided
    BOOL result = NO;

    // Check to see if any of the entities are in the tile provided
    for(AbstractEntity *entity in gameEntities) {
        if([entity isEntityInTileAtCoords:aPoint]) {
            result = YES;
            break;
        }
    }
    
    // Also check to see if the sword is in the tile provided
	if([playerAttack isEntityInTileAtCoords:aPoint])
		result = YES;
    
    return result;
}

#pragma mark -
#pragma mark Touch events

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event view:(UIView*)aView {
    
    for (UITouch *touch in touches) {
        // Get the point where the player has touched the screen
        CGPoint originalTouchLocation = [touch locationInView:nil];
     //   [sharedSoundManager playSoundWithKey:@"katana"];
        // As we have the game in landscape mode we need to switch the touches 
        // x and y coordinates
        CGPoint touchLocation = [sharedGameController adjustTouchOrientationForTouch:originalTouchLocation];
		      
		switch (state) {
			case kSceneState_Running:
				if (CGRectContainsPoint(joypadBounds, touchLocation) && !isJoypadTouchMoving && !isMenuScreenTime && !isTextBoxTime) {
					isJoypadTouchMoving = YES;
					joypadTouchHash = [touch hash];
					break;
				}
				
				// Check to see if the jump button was pressed

				// Check to see if the settings button has been pressed
				if (CGRectContainsPoint(settingsBounds, touchLocation)) {
					;
#ifdef SCB
					NSLog(@"settingBounds");
#endif
					//menu button
				}

				// Next check to see if the pause/play button has been pressed
				if (CGRectContainsPoint(AbuttonBounds, touchLocation)) {
					[self aButtonFunc];
								   
				}
				if(CGRectContainsPoint(XbuttonBounds, touchLocation)){
					[self xButtonFunc];
				}
				if(CGRectContainsPoint(BbuttonBounds, touchLocation)){
					[self bButtonFunc];
				}
				if(CGRectContainsPoint(YbuttonBounds, touchLocation)){
					[self yButtonFunc];
				}
				
				if(CGRectContainsPoint(pauseButtonBounds, touchLocation)){
					state = kSceneState_Paused;
					[sharedSoundManager stopMusic];
					pauseButton.color = Color4fMake(0.0f, 1.0f, 0.0f, 1.0f);
				}
				
				break;
				
			case kSceneState_GameCompleted:
				break;
			case kSceneState_Paused:
				// Check to see if the pause/play button has been pressed
				if(CGRectContainsPoint(pauseButtonBounds, touchLocation)){
					state = kSceneState_Running;
					[sharedSoundManager resumeMusic];
					pauseButton.color = Color4fMake(.5f, .5f, .5f, .3f);
				}
				break;
			
			default:
				break;
		}
    }
}


- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event view:(UIView*)aView {

    // Loop through all the touches
	for (UITouch *touch in touches) {
        
		// If the scene is running then check to see if we have a running joypad touch
        if (state == kSceneState_Running) {
            if ([touch hash] == joypadTouchHash && isJoypadTouchMoving) {
                
				// Get the point where the player has touched the screen
                CGPoint originalTouchLocation = [touch locationInView:nil];
                
                // As we have the game in landscape mode we need to switch the touches 
                // x and y coordinates
				CGPoint touchLocation = [sharedGameController adjustTouchOrientationForTouch:originalTouchLocation];
					                
                // Calculate the angle of the touch from the center of the joypad
                float dx = (float)joypadCenter.x - (float)touchLocation.x;
                float dy = (float)joypadCenter.y - (float)touchLocation.y;

				// Calculate the distance from the center of the joypad to the players touch using the manhatten
				// distance algorithm
				float distance = fabs(touchLocation.x - joypadCenter.x) + fabs(touchLocation.y - joypadCenter.y);
				
                // Set the players joypadAngle causing the player to move in that direction
				joyPadAngle = atan2(dy, dx);
                [player setDirectionWithAngle:joyPadAngle speed:CLAMP(distance/4, 0, 8)];
            }
        }
    }
}


- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event view:(UIView*)aView {
    
    switch (state) {
        case kSceneState_Running:
            // Loop through the touches checking to see if the joypad touch has finished
            for (UITouch *touch in touches) {
                // If the hash for the joypad has reported that its ended, then set the
                // state as necessary
                if ([touch hash] == joypadTouchHash) {
                    isJoypadTouchMoving = NO;
                    joypadTouchHash = 0;
                    player.angleOfMovement = 0;
					player.speedOfMovement = 0;
                    return;
                }
            }
            break;

        default:
            break;
    }
}

#pragma mark -
#pragma mark Alert View Delegates

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

	// First off grab a refernce to the textfield on the alert view.  This is done by hunting
	// for tag 99
	UITextField *nameField = (UITextField *)[alertView viewWithTag:99];

	// If the OK button is pressed then set the playersname
	if (buttonIndex == 1) {
		playersName = nameField.text;
		if ([playersName length] == 0)
			playersName = @"No Name Given";

		// Save the games info to the high scores table only if a players name has been entered
		if (playersName) {
			BOOL won = NO;
			if (state == kSceneState_GameCompleted)
				won = YES;
			[sharedGameController addToHighScores:score gameTime:gameTimeToDisplay playersName:playersName didWin:won];
		}
	}
	
	// We must remember to resign the textfield before this method finishes.  If we don't then an error
	// is reported e.g. "wait_fences: failed to receive reply:"
	[nameField resignFirstResponder];

	// Finally set the state to transition out of the scene
	state = kSceneState_TransitionOut;
}

#pragma mark -
#pragma mark Transition

- (void)transitionToSceneWithKey:(NSString*)theKey {
    state = kSceneState_TransitionOut;
}

- (void)transitionIn {
#ifdef SCB
	NSLog(@"Transitioning into gamescene");
#endif
    state = kSceneState_TransitionIn;
#ifdef SCB
	NSLog(@"Configuring game controller(s)");
#endif
	[self configureGameControllers];
#ifdef SCB
	NSLog(@"Configuring game controllers complete. Initializing sounds and music...");
#endif
	[self initSound];
#ifdef SCB
	NSLog(@"Sound/Music initialized");
#endif
	player.speedOfMovement = 0;
}

#pragma mark -
#pragma mark Render scene

- (void)renderScene {

	// If we are transitioning into the scene and we have initialized the scene then display the loading
	// screen.  This will be displayed until the rest of the game content has been loaded.
	if (state == kSceneState_TransitionIn && isSceneInitialized) {
		
		[sharedImageRenderManager renderImages];
		isLoadingScreenVisible = YES;
	}
	
	// Only render if the game has been initialized
	if (isGameInitialized) {
		switch (state) {
				
			case kSceneState_Loading:
			case kSceneState_TransitionOut:
			case kSceneState_TransportingOut:
			case kSceneState_TransportingIn:
			case kSceneState_Paused:
				
			case kSceneState_Running:
			{
				// Clear the screen before rendering
				glClear(GL_COLOR_BUFFER_BIT);
				// Save the current Matrix
				glPushMatrix();
			    
				// Translate the world coordinates so that the player is rendered in the middle of the screen
				//Vertical and Horizontal Scrolling needs to be modified here?
				glTranslatef(240 - player.pixelLocation.x, 180 - player.pixelLocation.y, 0);
				//blah blah blah
				// Render the Map tilemap layer
				[sceneTileMap renderLayer:0
									  mapx:playerTileX - leftOffsetInTiles - 1
									  mapy:playerTileY - bottomOffsetInTiles - 1 
									 width:screenTilesWide + 4
									height:screenTilesHeight + 2 
							   useBlending:NO];
				
				// Render the Objects tilemap layer
				[sceneTileMap renderLayer:1 
									  mapx:playerTileX - leftOffsetInTiles - 1 
									  mapy:playerTileY - bottomOffsetInTiles - 1 
									 width:screenTilesWide + 4
									height:screenTilesHeight + 2 
							   useBlending:NO];
								
				[sharedImageRenderManager renderImages];	//<--

				[playerAttack render];
				[playerMouse render];
				[sock1 render];
				[sock2 render];
				[sock3 render];
			
				for(int i = player.pixelLocation.y + 320; i >= player.pixelLocation.y - 320; i --){

				// Render the game objects
				for(AbstractObject *gameObject in gameObjects) {
					if (gameObject.state == kObjectState_Active && gameObject.pixelLocation.y == i) {
						[gameObject render];
					}
				}
				
				// Render the player
				if(player.pixelLocation.y ==i)
					[player render];

				
				// Render entities
					for(Enemies *entity in gameEntities) {

						if(entity.pixelLocation.y == i) {
							[entity render];

					
						}
					}
					
				}
				
				[sceneTileMap renderLayer:3
									  mapx:playerTileX - leftOffsetInTiles - 1
									  mapy:playerTileY - bottomOffsetInTiles - 1
									 width:screenTilesWide + 4
									height:screenTilesHeight + 2
							   useBlending:NO];
				if(player.state == kEntityState_Alive || player.state == kEntityState_Attack || player.state == kEntityState_Sleep)
					for(AbstractEntity *entity in damageText){
						[entity render];
					}
				 // Render what we have so far so that everything else rendered is drawn over it
				[sharedImageRenderManager renderImages];
				
				// Render the doors onto the map.  The localDoors array holds all doors
				// that have been found to be close to the player during the scenes update

				
				// Pop the old matrix off the stack ready for the next frame.  We need to make sure that the modelview
				// is using the origin 0, 0 again so that the images for the HUD below are rendered in view.
				glPopMatrix();
				
				// Render the torch mask over the scene.  This is done behind the hud and controls
				//[torchMask renderCenteredAtPoint:CGPointMake(240, 160)];
				
				// If we are transporting the player then the fade panel should be drawn under 
				// the HUD
	
				if (state == kSceneState_TransportingIn || state == kSceneState_TransportingOut) {
					[fadeImage renderAtPoint:CGPointMake(0, 0)];
					
					[fadeImage renderAtPoint:CGPointMake(0, 0)];

					// To make sure that this gets rendered UNDER the following images we need to get the
					// render manager to render what is currently in the queue.
					[sharedImageRenderManager renderImages];
				}
		// Render the hud background

				// Render the joypad

				//                             |||
				//put the number of lives here VVV
				//New UI
				[smallFont renderStringJustifiedInFrame:CGRectMake(50, 286, 21, 8) justification:BitmapFontJustification_MiddleRight text:[NSString stringWithFormat:@"LIFE:"]];
				[smallFont renderStringJustifiedInFrame:CGRectMake(50, 270, 21, 8) justification:BitmapFontJustification_MiddleRight text:[NSString stringWithFormat:@"ALERT:"]];
				if(inBossFight)
					[smallFont renderStringJustifiedInFrame:CGRectMake(80,273, 21, 8) justification: BitmapFontJustification_MiddleLeft text: [NSString stringWithFormat:@"%.2f",100.00f]];
				else
				[smallFont renderStringJustifiedInFrame:CGRectMake(80,273, 21, 8) justification: BitmapFontJustification_MiddleLeft text: [NSString stringWithFormat:@"%.2f",alertStateDelta]];
				for(float i = 1; i <= player.energy * 6; i+=6)
					[lifebar renderAtPoint:CGPointMake(i + 78, 288)];
				
				int xoffset = 10;
				int yoffset = 8;

				if (state == kSceneState_Running && !gamepadConnected) {
					[joypad renderCenteredAtPoint:CGPointMake(70,70)];

					[button setColor:Color4fMake(1.0f, 0.0f, 0.0f, .30f)];
					[button renderCenteredAtPoint:CGPointMake(385 + xoffset, 50 - yoffset)];
					[smallFont renderStringJustifiedInFrame:CGRectMake(370 + xoffset, 47 - yoffset, 21, 8) justification:BitmapFontJustification_MiddleRight text:[NSString stringWithFormat:@"A"]];
					if(hasMouse){
						[button setColor:Color4fMake(1.0f, 1.0f, 0.0f, .30f)];
						[button renderCenteredAtPoint:CGPointMake(370- 22, 85)];
						[smallFont renderStringJustifiedInFrame:CGRectMake(370-38, 80, 21, 8) justification:BitmapFontJustification_MiddleRight text:[NSString stringWithFormat:@"X"]];
					}
					if(hasSocktrap){
						[button setColor:Color4fMake(0.0f, 1.0f, 0.0f, .30f)];
						[button renderCenteredAtPoint:CGPointMake(420+ 20, 75 + 10)];
						[smallFont renderStringJustifiedInFrame:CGRectMake(405+20, 80, 21, 8) justification:BitmapFontJustification_MiddleRight text:[NSString stringWithFormat:@"B"]];
					}
					if(hasLongcat){
						[button setColor:Color4fMake(0.0f, 0.0f, 1.0f, .30f)];
						[button renderCenteredAtPoint:CGPointMake(385 + xoffset, 117 + yoffset)];
						[smallFont renderStringJustifiedInFrame:CGRectMake(370 + xoffset, 113 + yoffset, 21, 8) justification:BitmapFontJustification_MiddleRight text:[NSString stringWithFormat:@"Y"]];
					} //has longcat if
				}

				if (state == kSceneState_Paused) {
					fadeImage.color = Color4fMake(1, 1, 1, 0.55f);
					[fadeImage renderCenteredAtPoint:CGPointMake(240, 160)];

					fadeImage.color = Color4fMake(1, 1, 1, 1);
				}
				if(!gamepadConnected)
					[pauseButton renderCenteredAtPoint:CGPointMake(225, 42)];

				
				// We only draw the black overlay when we are fading into or out of this scene
				if (state == kSceneState_Loading || state == kSceneState_TransitionOut) {
					[fadeImage renderAtPoint:CGPointMake(0, 0)];
				}
				if(isTextBoxTime)
					[textbox render];	//render the text box
									
				// Render all queued images at this point
				[sharedImageRenderManager renderImages];

// Debug info
#ifdef SCB
				drawRect(joypadBounds);
				drawRect(AbuttonBounds);
				drawRect(BbuttonBounds);
				drawRect(XbuttonBounds);
				drawRect(YbuttonBounds);
				drawRect(pauseButtonBounds);
#endif
				break;
			}
				
			case kSceneState_GameCompleted:
			{
				// Render the game complete background
	//			[joypad renderCenteredAtPoint:CGPointMake(240, 160)];
				// Clear the screen before rendering
				glClear(GL_COLOR_BUFFER_BIT);
				// Save the current Matrix
				glPushMatrix();
			    [self calculatePlayersTileMapLocation];
				// Translate the world coordinates so that the player is rendered in the middle of the screen
				//Vertical and Horizontal Scrolling needs to be modified here?
				glTranslatef(240- player.pixelLocation.x, 160 - player.pixelLocation.y, 0);
				
				// Render the Map tilemap layer
				[sceneTileMap renderLayer:0
									 mapx:playerTileX - leftOffsetInTiles - 1
									 mapy:playerTileY - bottomOffsetInTiles - 1
									width:screenTilesWide + 4
								   height:screenTilesHeight + 2
							  useBlending:NO];
				
				// Render the Objects tilemap layer
				[sceneTileMap renderLayer:1
									 mapx:playerTileX - leftOffsetInTiles - 1
									 mapy:playerTileY - bottomOffsetInTiles - 1
									width:screenTilesWide + 4
								   height:screenTilesHeight + 2
							  useBlending:NO];
				
				[sharedImageRenderManager renderImages];
				[player render];
				[sceneTileMap renderLayer:3
									 mapx:playerTileX - leftOffsetInTiles - 1
									 mapy:playerTileY - bottomOffsetInTiles - 1
									width:screenTilesWide + 4
								   height:screenTilesHeight + 2
							  useBlending:NO];
				// Render what we have so far so that everything else rendered is drawn over it
				[sharedImageRenderManager renderImages];
				if(isTextBoxTime)
					[textbox render];	//render the text box
				else{
				
					CGRect textRectangle = CGRectMake(55, 20, 216, 80);
					NSString *spotted = [NSString stringWithFormat:@"Spotted: %i", alertCounts];
					NSString *cont = [NSString stringWithFormat:@"Continues: %i", continues];
					NSString *timeStat;
					if(gameSeconds < 10)
						timeStat = [NSString stringWithFormat:@"Final Time: %i:0%i", gameMinutes, gameSeconds];
					else
						timeStat = [NSString stringWithFormat:@"Final Time: %i:%i", gameMinutes, gameSeconds];
					[smallFont renderStringJustifiedInFrame:textRectangle justification:BitmapFontJustification_TopLeft text:cont];
					[smallFont renderStringJustifiedInFrame:textRectangle justification:BitmapFontJustification_MiddleLeft text:spotted];
					[smallFont renderStringJustifiedInFrame:textRectangle justification:BitmapFontJustification_BottomLeft text:timeStat];
				}
				glPopMatrix();
				// Render the game stats
				[fadeImage renderAtPoint:CGPointMake(0, 0)];

				[sharedImageRenderManager renderImages];
				break;
			}

			case kSceneState_GameOver:
			{
				// Render the game over background
	//			[joypad renderCenteredAtPoint:CGPointMake(240, 160)];
				
				// Render the game stats
				CGRect textRectangle = CGRectMake(55, 42, 216, 150);
				NSString *finalScore = [NSString stringWithFormat:@"%06d", score];
				NSString *scoreStat = [NSString stringWithFormat:@"Final Score: %@", finalScore];
				NSString *timeStat = [NSString stringWithFormat:@"Final Time: %@", gameTimeToDisplay];
				[smallFont renderStringJustifiedInFrame:textRectangle justification:BitmapFontJustification_TopLeft text:scoreStat];
				[smallFont renderStringJustifiedInFrame:textRectangle justification:BitmapFontJustification_MiddleLeft text:timeStat];
				[sharedImageRenderManager renderImages];
				break;
			}
			default:
				break;
		}
	}
}

#pragma mark -
#pragma mark Save game state

- (void)saveGameState {
	
	SLQLOG(@"INFO - GameScene: Saving game state.");
		
	// Set up the game state path to the data file that the game state will be saved too. 
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *gameStatePath = [documentsDirectory stringByAppendingPathComponent:@"gameState.dat"];
	
	// Set up the encoder and storage for the game state data
	NSMutableData *gameData;
	NSKeyedArchiver *encoder;
	gameData = [NSMutableData data];
	encoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:gameData];
	
	// Archive the entities
	[encoder encodeObject:gameEntities forKey:@"gameEntities"];
	
	// Archive the player
	[encoder encodeObject:player forKey:@"player"];
		
	// Archive the games doors
	[encoder encodeObject:doors forKey:@"doors"];
	
	// Archive the game objects
	[encoder encodeObject:gameObjects forKey:@"gameObjects"];
	
	// Archive the games timer settings
	NSNumber *savedGameStartTime = [NSNumber numberWithFloat:gameStartTime];
	NSNumber *savedTimeSinceGameStarted = [NSNumber numberWithFloat:timeSinceGameStarted];
	NSNumber *savedScore = [NSNumber numberWithFloat:score];
	[encoder encodeObject:savedGameStartTime forKey:@"gameStartTime"];
	[encoder encodeObject:savedTimeSinceGameStarted forKey:@"timeSinceGameStarted"];
	[encoder encodeObject:savedScore forKey:@"score"];
	[encoder encodeInt:locationName forKey:@"locationName"];
	
	// Finish encoding and write the contents of gameData to file
	[encoder finishEncoding];
	[gameData writeToFile:gameStatePath atomically:YES];
	[encoder release];
	
	// Tell the game controller that a resumed game is available
	sharedGameController.resumedGameAvailable = YES;
}

@end

#pragma mark -
#pragma mark Private implementation

@implementation GameScene (Private)

#pragma mark -
#pragma mark Initialize new game state

- (void)initNewGameState {

	[self initGameContent];
	continues = 0;
	
	// Set up the players initial locaiton
	player = [[Player alloc] initWithTileLocation:CGPointMake(13.0f, 506.0f)];	//13, 506 starting point
																				//202, 488 next to bldg enterance
																				//152, 431 next to the second dialog event
																				//430, 42 first east-west door (blue area)
																				//470, 70 room before scientist
																				//404, 42 near the first boss (not super close)
																				//313, 231			water room before server
				
																				//360,139 sand room eastwest door problem grey level
																				//491, 69		scientist
																				//346, 26		locked door(mouse)
																				//301, 31		first boss
																				//417, 125		blocked door(2nd boss)
																				//471, 128		socktrap
																				//495, 118		second boss
																				//317, 250		final boss
																				//498, 237		door before ending
																				//209, 27.5		ending
																				/////////ENEMY BEHAVIOR TESTS
																				//477, 14		directional standers
				
	   
	// Now we have loaded the player we need to set up their position in the tilemap
	[self calculatePlayersTileMapLocation];
    
	playerAttack = [[PlayerAttack alloc] initWithTileLocation:CGPointMake(0,0)];
	playerMouse = [[Mouse alloc] initWithTileLocation:CGPointMake(0,0)];
	sock1 = [[SockTrap alloc]initWithTileLocation:CGPointMake(0,0)];
	sock2 = [[SockTrap alloc]initWithTileLocation:CGPointMake(0,0)];
	sock3 = [[SockTrap alloc]initWithTileLocation:CGPointMake(0,0)];
	// Initialize the game items.  This is only done when initializing a new game as
	// this information is loaded when a resumed game is started.
	[self initItems];

	// Init the localDoors array
	[self initLocalDoors];
}

                                    
- (void)loadGameState {
	
	[self initGameContent];

    // Set up the file manager and documents path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSMutableData *gameData;
    NSKeyedUnarchiver *decoder;
    
    // Check to see if the ghosts.dat file exists and if so load the contents into the
    // entities array
    NSString *documentPath = [documentsDirectory stringByAppendingPathComponent:@"gameState.dat"];
    gameData = [NSData dataWithContentsOfFile:documentPath];

    decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:gameData];

    SLQLOG(@"INFO - GameScene: Loading saved player data.");
    player = [[decoder decodeObjectForKey:@"player"] retain];
	[self calculatePlayersTileMapLocation];


	SLQLOG(@"INFO - GameScene: Loading saved entity data.");
	if (gameEntities)
		[gameEntities release];
    gameEntities = [[decoder decodeObjectForKey:@"gameEntities"] retain];

	SLQLOG(@"INFO - GameScene: Loading saved game object data.");
	if (gameObjects)
		[gameObjects release];
	gameObjects = [[decoder decodeObjectForKey:@"gameObjects"] retain];

	SLQLOG(@"INFO - GameScene: Loading saved door data.");
	if (doors)
		[doors release];
    doors = [[decoder decodeObjectForKey:@"doors"] retain];
    
	SLQLOG(@"INFO - GameScene: Loading saved game duration.");
    timeSinceGameStarted = [[decoder decodeObjectForKey:@"timeSinceGameStarted"] floatValue];
	
	SLQLOG(@"INFO - GameScene: Loading saved game score.");
	score = [[decoder decodeObjectForKey:@"score"] floatValue];
	
	SLQLOG(@"INFO - GameScene: Loading location name.");
	locationName = [decoder decodeIntForKey:@"locationName"];
    
    SLQLOG(@"INFO - GameScene: Loading game time data.");

	// We have finishd decoding the objects and retained them so we can now release the
	// decoder object
	[decoder release];

	// Init the localDoors array
	[self initLocalDoors];
}

- (void)initScene {

	// Game objects
	doors = [[NSMutableArray alloc] init];
	spawnPoints = [[NSMutableArray alloc] initWithCapacity:128];
	gameEntities = [[NSMutableArray alloc] initWithCapacity:128];
	portals = [[NSMutableArray alloc] init];
	zones = [[NSMutableArray alloc] init];
	gameObjects = [[NSMutableArray alloc] init];
	localDoors = [[NSMutableArray alloc] init];
	enemyProjectiles = [[NSMutableArray alloc] initWithCapacity:8];
	damageText = [[NSMutableArray alloc] init];
	eventTextboxes = [[NSMutableArray alloc] init];
	checkpoints = [[NSMutableArray alloc] init];

    // Initialize the fonts needed for the game
    smallFont = [[BitmapFont alloc] initWithFontImageNamed:@"zafont.png" controlFile:@"zafont" scale:Scale2fMake(1.2f, 1.2f) filter:GL_LINEAR];
	digitFont = [[BitmapFont alloc] initWithFontImageNamed:@"smallDigits.png" controlFile:@"smallDigit" scale:Scale2fMake(1.0f, 1.0f) filter:GL_LINEAR];
    
	exitBounds = CGRectMake(501 * kTile_Width, 232 * kTile_Height, 64, 80);
	menuScreen = [[Image alloc] initWithImageNamed:@"menuScreenWithPortraits.png" filter:GL_NEAREST];


	// Pause button
	pauseButton = [[Image alloc] initWithImageNamed:@"pauseButton.png" filter:GL_NEAREST];
	pauseButton.color = Color4fMake(.5f, .5f, .5f, .3f);
	pauseButton.scale = Scale2fMake(.5f, .5f);
	button = [[Image alloc] initWithImageNamed:@"button.png" filter:GL_NEAREST];
	button.color = Color4fMake(1, 1, 1, 0.35f);
	button.scale = Scale2fMake(.5f,.5f);
	int x;
	int y;
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		if ([[UIScreen mainScreen] bounds].size.height == 568) {
			NSLog(@"iphone 5");
			x = 0;
			y = 0;
		}else{
			NSLog(@"not iphone 5");

			x = 50;
			y = 0;
		}
	}else{
		NSLog(@"ipad");

		x = 50;
		y = 0;
	}

	pauseButtonBounds = CGRectMake(250 - x, 20, 50, 50);
	XbuttonBounds = CGRectMake(370 - x, 80- y, 50, 50);	//middle left
	AbuttonBounds = CGRectMake(425 - x, 20, 50, 50);	//bottom middle
	YbuttonBounds = CGRectMake(425 - x, 110, 50, 50);	//top middle
	BbuttonBounds = CGRectMake(485 - x, 80- y, 50, 50);	//middle right

	// Settings button
	button = [[Image alloc] initWithImageNamed:@"button.png" filter:GL_NEAREST];
	button.scale = Scale2fMake(.5f, .5f);
	settingsBounds = CGRectMake(290, 27, 50, 50);
  
    // Overlay used to fade the game scene
    fadeImage = [[Image alloc] initWithImageNamed:@"allBlack.png" filter:GL_NEAREST];
	fadeImage.scale = Scale2fMake(screenBounds.size.width, screenBounds.size
								  .height);
	
    // Joypad setup
	joypadCenter = CGPointMake(120 - x, 70);

	joypadRectangleSize = CGSizeMake(40, 40);
	
    lifebar = [[[Image alloc]initWithImageNamed:@"lifetick.png" filter:GL_NEAREST] retain];
    joypad = [[Image alloc] initWithImageNamed: @"gamepad.png" filter: GL_NEAREST];
	joypad.color = Color4fMake(1.0f, 1.0f, 1.0f, 0.25f);
  
	// Set up the game score and timers
	score = 0;
	timeSinceGameStarted = 0;
    gameStartTime = CACurrentMediaTime();
	gameTimeToDisplay = @"000.00";
	
	// Set up flags
	isWinMusicPlaying = NO;
	isLoseMusicPlaying = NO;
	hasMouse = NO;
	hasLongcat = NO;
	hasSocktrap = NO;
	blocked[415][125] = YES;
	blocked[415][124] = YES;
	if(!hasSocktrap){
		blocked[482][104] = YES;
		blocked[482][103] = YES;
	}
	if(!hasMouse){
		blocked[343][25] = YES;
		blocked[343][24] = YES;
	}
	playersLastLocation = CGPointMake(0,0);
}

- (void)initGameContent {	//hannabarbera
	// Initialize the scenes tile map
	[self initTileMap];
    [self initCollisionMapAndDoors];
    [self initPortals];	
}




- (void)initSound {
    
    // Set the listener to the middle of the screen by default.  This will be changed as the player moves around the map
#ifdef SCB
	NSLog(@"Begin init Sound");
#endif    
	[sharedSoundManager setListenerPosition:CGPointMake(player.tileLocation.x*kTile_Width, player.tileLocation.y*kTile_Height)];
    // Initialize the sound effects																						//
	[sharedSoundManager loadSoundWithKey:@"alertsound" soundFile:@"alert.caf"];
	[sharedSoundManager loadSoundWithKey:@"dying" soundFile:@"dying.caf"];
	[sharedSoundManager loadSoundWithKey:@"throw" soundFile:@"throw.caf"];

	[sharedSoundManager loadSoundWithKey:@"swoosh" soundFile:@"Swoosh.caf"];
	[sharedSoundManager loadSoundWithKey:@"voice1" soundFile:@"Man voice.caf"];
	[sharedSoundManager loadSoundWithKey:@"voice2" soundFile:@"Man voice B.caf"];

	[sharedSoundManager loadSoundWithKey:@"voice3" soundFile:@"Man voice C.caf"];
	[sharedSoundManager loadSoundWithKey:@"katana" soundFile:@"fightsound.caf"];
	[sharedSoundManager loadSoundWithKey:@"hit" soundFile:@"punch1.caf"];

	[sharedSoundManager loadSoundWithKey:@"powerup" soundFile:@"powup8.caf"];
	[sharedSoundManager loadSoundWithKey:@"longcat" soundFile:@"longcatOmega.caf"];
	[sharedSoundManager loadSoundWithKey:@"katanaSwing" soundFile:@"katana.caf"];

	[sharedSoundManager loadSoundWithKey:@"snoring" soundFile:@"snoring.caf"];
	[sharedSoundManager loadSoundWithKey:@"mouse" soundFile:@"windupmouse.caf"];
	[sharedSoundManager loadSoundWithKey:@"gun" soundFile:@"punch1.caf"];

	[sharedSoundManager loadSoundWithKey:@"fireGun" soundFile:@"LAZER.caf"];
	[sharedSoundManager loadMusicWithKey:@"alert" musicFile:@"panic.mp3"];
	[sharedSoundManager loadMusicWithKey:@"boss" musicFile:@"boss.mp3"];

	[sharedSoundManager loadMusicWithKey:@"ending" musicFile:@"ending.mp3"];

	if(nextMusic != nil){
		[sharedSoundManager stopMusic];
		[sharedSoundManager loadMusicWithKey:@"ingame" musicFile:nextMusic];
	}
	sharedSoundManager.loopLastPlaylistTrack = NO;

}


- (void)checkJoypadSettings {

    // If the joypad is marked as being on the left the set the joypads center left, otherwise,
	// you guessed it, set the joypad center to the right.  This also adjusts the location of
	// the settings button which needs to also be moved
	// Calculate the rectangle that we check for touches to know someone has touched the joypad
	joypadBounds = CGRectMake(joypadCenter.x - joypadRectangleSize.width, 
						joypadCenter.y - joypadRectangleSize.height, 
						joypadRectangleSize.width * 2, 
						joypadRectangleSize.height * 2);
}

- (void) readControlInputs
{
#ifdef SCB

    if (myGamepad.buttonA.isPressed)
        NSLog(@"RIGHT TRIGGER PRESSED");
    if (myGamepad.buttonB.isPressed)
        NSLog(@"LEFT TRIGGER PRESSED");
#endif
}

- (void)initPortals {
    
    // Get the object groups that were found in the tilemap
    NSMutableDictionary *portalObjects = sceneTileMap.objectGroups;

    // Calculate the height of the tilemap in pixels.  We also add an extra tile to the height
    // so that objects pixel location is correct.  This is needed as the tile map has a zero
    // index which means we actually loose a tile when calculating a pixel position within the
    // map
    float tileMapPixelHeight = (kTile_Height * (sceneTileMap.mapHeight -1   ));
    
    // Loop through all objects in the object group called Portals
    NSMutableDictionary *objects = [[portalObjects objectForKey:@"Portals"] objectForKey:@"Objects"];
    for (NSString *objectKey in objects) {
        
        // Get the location of the portal
        float portal_x = [[[[objects objectForKey:objectKey] 
                            objectForKey:@"Attributes"] 
                           objectForKey:@"x"] floatValue] / kTile_Width;
        
        // As the tilemap coordinates have been reversed on the y-axis, we need to also reverse
        // y-axis pixel locaiton for objects.  This is done by subtracting the objects current
        // y value from the full pixel height of the tilemap
        float portal_y = (tileMapPixelHeight - [[[[objects objectForKey:objectKey] 
                                                  objectForKey:@"Attributes"] 
                                                 objectForKey:@"y"] floatValue]) / kTile_Height;
        
        // Get the location to where the portal will transport the player
        float dest_x = [[[[objects objectForKey:objectKey]
                          objectForKey:@"Properties"] 
                         objectForKey:@"dest_x"] floatValue];
        
        float dest_y = [[[[objects objectForKey:objectKey]
                          objectForKey:@"Properties"]
                         objectForKey:@"dest_y"] floatValue];
        
		// Get the name of the destination this portal takes you too
		uint destinationName = [[[[objects objectForKey:objectKey]
								  objectForKey:@"Properties"]
								 objectForKey:@"locationName"] intValue];
		
        // Create a portal instance and add it to the portals array
#ifdef SCB
		NSLog(@"Successfully parsed x: %f y: %f destx: %f desty: %f", portal_x, portal_y, dest_x, dest_y);
#endif
        Portal *portal = [[Portal alloc] initWithTileLocation:CGPointMake(portal_x, portal_y) beamLocation:CGPointMake(dest_x, dest_y)];
        portal.state = kEntityState_Alive;
		portal.locationName = destinationName;
       [portals addObject:portal];	//hannabarbara uncomment to add portal support
        [portal release];
        portal = nil;
    }
	NSMutableDictionary *zoneObjects = [[portalObjects objectForKey:@"Zones"] objectForKey:@"Objects"];
	for(NSString *objectKey in zoneObjects) {
		float zone_x = [[[[zoneObjects objectForKey:objectKey]
						  objectForKey:@"Attributes"]
						 objectForKey:@"x"] floatValue] / kTile_Width;
		float zone_y = (tileMapPixelHeight -[[[[zoneObjects objectForKey:objectKey]
						  objectForKey:@"Attributes"]
						 objectForKey:@"y"] floatValue]) / kTile_Height;
		float dest_x = [[[[zoneObjects objectForKey:objectKey]
                          objectForKey:@"Properties"]
                         objectForKey:@"dest_x"] floatValue];
		float dest_y = [[[[zoneObjects objectForKey:objectKey]
						  objectForKey: @"Properties"]
						  objectForKey:@"dest_y"] floatValue];
						
		uint destinationName = [[[[zoneObjects objectForKey:objectKey]
								   objectForKey:@"Properties"]
								   objectForKey:@"locationName"] intValue];
		NSString *tileMapName = [[[zoneObjects objectForKey:objectKey]
								   objectForKey:@"Properties"]
								  objectForKey:@"tilemap"];
		NSString *music = [[[zoneObjects objectForKey:objectKey]
							objectForKey:@"Properties"]
						   objectForKey:@"music"];
#ifdef SCB
		NSLog(@"Successfully parsed x: %f y: %f destx: %f desty: %f tilemap: %@ music: %@", zone_x, zone_y, dest_x, dest_y, tileMapName, music);
#endif
		Zone *zone = [[Zone alloc] initWithTileLocation:CGPointMake(zone_x, zone_y) beamLocation:CGPointMake(dest_x, dest_y) tileMap:tileMapName music:music];
		zone.state = kEntityState_Alive;
		zone.locationName = destinationName;
#ifdef SCB
		for(zone in zones)
			NSLog(@"zone name in zones: %@", [zone tilemap]);
#endif
		[zone release];
		zone = nil;
	}
}

- (void)initItems {
    // Get the object groups that were found in the tilemap
    NSMutableDictionary *objectGroups = sceneTileMap.objectGroups;
    int numberOfTextboxes;
    // Calculate the height of the tilemap in pixels.  All tile locations are zero indexed
	// so we need to reduce the mapHeight by 1 to calculate the pixels correctly.
    // so that objects pixel location is correct.
    float tileMapPixelHeight = (kTile_Height * (sceneTileMap.mapHeight - 1));
    
    // Loop through all objects in the object group called Game Objects
    NSMutableDictionary *objects = [[objectGroups objectForKey:@"Game Objects"] objectForKey:@"Objects"];
    
    for (NSString *objectKey in objects) {
        
        // Get the x location of the object
        float object_x = [[[[objects objectForKey:objectKey] 
                            objectForKey:@"Attributes"] 
                           objectForKey:@"x"] floatValue] / kTile_Width;
        
        // As the tilemap coordinates have been reversed on the y-axis, we need to also reverse
        // y-axis pixel location for objects.  This is done by subtracting the objects current
        // y value from the full pixel height of the tilemap
        
		float object_y = (tileMapPixelHeight - [[[[objects objectForKey:objectKey]
                                                  objectForKey:@"Attributes"] 
                                                 objectForKey:@"y"] floatValue]) / kTile_Height;
		float objectWidth = [[[[objects objectForKey:objectKey] objectForKey:@"Attributes"] objectForKey:@"width"] floatValue];
		float objectHeight = [[[[objects objectForKey:objectKey] objectForKey:@"Attributes"] objectForKey:@"height"] floatValue];
		
        // Get the type of the object
        uint type = [[[[objects objectForKey:objectKey]
                          objectForKey:@"Attributes"] 
                         objectForKey:@"type"] intValue];

        // Get the subtype of the object
        uint subType = [[[[objects objectForKey:objectKey]
                       objectForKey:@"Properties"] 
                      objectForKey:@"subtype"] intValue];
        
        // Based on the type and subtype of the object in the map create the correct object instance
        // and add it to the game objects array
        switch (type) {
            case kObjectType_Energy:
            {
				EnergyObject *object = [[EnergyObject alloc] initWithTileLocation:CGPointMake(object_x, object_y) type:type subType:subType fromScene: self];
				[gameObjects addObject:object];
				[object release];
				break;
            }
                
            case kObjectType_Key:
			{
				KeyObject *key = [[KeyObject alloc] initWithTileLocation:CGPointMake(object_x, object_y) type:type subType:subType width:objectWidth height:objectHeight];
				[gameObjects addObject:key];
				[key release];
                break;
			}
			case kObjectType_TextEvent:
			{
				TextEvent *event = [[TextEvent alloc] initWithTileLocation:CGPointMake(object_x, object_y) withWidth:objectWidth withHeight:objectHeight];
				NSMutableDictionary *textObjects = [[objects objectForKey:objectKey] objectForKey:@"Properties"];
				NSArray *myArray;
				
				myArray = [textObjects keysSortedByValueUsingComparator: ^(id obj1, id obj2) {
					
					if ([obj1 integerValue] > [obj2 integerValue]) {
						
						return (NSComparisonResult)NSOrderedDescending;
					}
					if ([obj1 integerValue] < [obj2 integerValue]) {
						
						return (NSComparisonResult)NSOrderedAscending;
					}
					
					return (NSComparisonResult)NSOrderedSame;
				}];

				myArray = [myArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

				for(NSString *key in myArray) {
#ifdef SCB
					NSLog(key);
#endif
					if([key isEqualToString:@"subtype"]){
						;
#ifdef SCB
						NSLog(@"found subtype");
#endif
					}else
						[event addString:[textObjects objectForKey:key]];
				}
				[event turnIntoTextBoxes];
				[eventTextboxes addObject:event];
				[event release];
				break;
			}
			case kObjectType_Checkpoint:{
#ifdef SCB
				NSLog(@"Found checkpoint");
#endif
				Checkpoint *tempCheckpoint = [[Checkpoint alloc]initWithTileLocation:CGPointMake(object_x, object_y) withWidth:objectWidth withHeight:objectHeight];
				[checkpoints addObject:tempCheckpoint];
				[tempCheckpoint release];
				break;
			}
            case kObjectType_General:
			{
				switch (subType) {


					case kObjectSubType_Wall:
					{
						MapObject *object = [[MapObject alloc] initWithTileLocation:CGPointMake(object_x, object_y) type:type subType:subType width:objectWidth height:objectHeight];
						[gameObjects addObject:object];
						[object release];
						break;
					}
					
					default:
						break;
				}
             }
						
            default:
                break;
        }
    }
}

- (void)initTileMap {
    
    // Create a new instance of TiledMap
	if(nextMap != nil){
		sceneTileMap = [[TiledMap alloc] initWithFileName:nextMap fileExtension:@"tmx"];
	}
	else{
		sceneTileMap = [[TiledMap alloc] initWithFileName:@"Level1" fileExtension:@"tmx"]; //Level1
    }
    // Grab the map width and height in tiles
    tileMapWidth = [sceneTileMap mapWidth];
    tileMapHeight = [sceneTileMap mapHeight];
    
    // Calculate how many tiles it takes to fill the screen for width and height
    screenTilesWide = screenBounds.size.height / kTile_Width + 6;
    screenTilesHeight = screenBounds.size.width / kTile_Height;
    
    bottomOffsetInTiles = screenTilesHeight / 2;
    leftOffsetInTiles = screenTilesWide / 1.5;
}

- (void)initNewTileMap:(NSString*) aTilemap song:(NSString*) aSong{
	[sceneTileMap release];
	
	sceneTileMap = [[TiledMap alloc] initWithFileName:aTilemap fileExtension:@"tmx"];
    // Grab the map width and height in tiles
    tileMapWidth = [sceneTileMap mapWidth];
    tileMapHeight = [sceneTileMap mapHeight];
    
    // Calculate how many tiles it takes to fill the screen for width and height
    screenTilesWide = screenBounds.size.height / kTile_Width;
    screenTilesHeight = screenBounds.size.width / kTile_Height;
    [sharedSoundManager stopMusic];
	[sharedSoundManager loadMusicWithKey:@"ingame" musicFile:aSong];
	[sharedSoundManager playMusicWithKey:@"ingame" timesToRepeat:-1];
	
    bottomOffsetInTiles = screenTilesHeight / 2;
    leftOffsetInTiles = screenTilesWide / 2;
	[self initCollisionMapAndDoors];
    [self initPortals];
}

- (void)initCollisionMapAndDoors {
    
    // Build a map of blocked locations within the tilemap.  This information is held on a layer called Collision
    // within the tilemap
    SLQLOG(@"INFO - GameScene: Creating tilemap collision array and doors.");

    // Grab the layer index for the layer in the tile map called Collision
    int collisionLayerIndex = [sceneTileMap layerIndexWithName:@"Collision"];
    Door *door = nil;
    Spawn *spawn;
    // Loop through the map tile by tile
    Layer *collisionLayer = [[sceneTileMap layers] objectAtIndex:collisionLayerIndex];
	Layer *objectLayer = [[sceneTileMap layers] objectAtIndex:[sceneTileMap layerIndexWithName:@"Objects"]];
    for(int yy=0; yy < sceneTileMap.mapHeight; yy++) {
        for(int xx=0; xx < sceneTileMap.mapWidth; xx++) {
            
            // Grab the global tile id from the tile map for the current location
            int globalTileID = [collisionLayer globalTileIDAtTile:CGPointMake(xx, yy)];
			int objectsTileID = [objectLayer globalTileIDAtTile:CGPointMake(xx,yy)];
			if(objectsTileID == 449 || objectsTileID == 450 ||objectsTileID == 451 ||
			   objectsTileID == 481 || objectsTileID == 482 ||objectsTileID == 483 ||
			   objectsTileID == 513 || objectsTileID == 514 ||objectsTileID == 515){
				waterDamage[xx][yy] = YES;
			}
			
            if((globalTileID < 15 && globalTileID > 1 )|| (globalTileID > 33 && globalTileID < 42)) {
#ifdef SCB
				NSLog(@"Found enemy tile on collision layer and added to spawnpoints array");
#endif
				spawn = [[Spawn alloc] initWithTileLocation:CGPointMake(xx,yy) type:globalTileID arrayIndex: [spawnPoints count]];
				[spawnPoints addObject: spawn];
#ifdef SCB
				NSLog(@"Current spawn tile count: %i", [spawnPoints count]);
#endif
				[spawn release];
			}
				
            // If the global tile ID is the blocking tile image then this location is blocked.  If it is a door object
            // then a door is created and placed in the doors array.  The value below is the tileid from the tileset used in the 
			// tile map.  If this tile is present in the collision layer then we mark that tile as blocked.
			
            else if(globalTileID == kBlockedTileGlobalID) {
                blocked[xx][yy] = YES;
            } else  {
                
                // If the game is being resumed, then we do not need to load the doors array
                if (!sharedGameController.shouldResumeGame) {
                    // Check to see if the tileid for the current tile is a door tile.  If not then move on else check the type
					// of the door and create a door instance.  If the tile map sprite sheet changes then these numbers need to be
					// checked.  Also this assumes that the door tile are contiguous in the sprite sheet
					if (globalTileID >= kFirstDoorTileGlobalID && globalTileID <= kLastDoorTileGlobalID) {
						int doorType = [[sceneTileMap tilePropertyForGlobalTileID:globalTileID key:@"type" defaultValue:@"-1"] intValue];
						if (doorType != -1) {
							// Create a new door instance of the correct type.  As we create the door we set the doors array
							// index to be its index in the doors array.  At this point we have not actually added the door to 
							// the array so we can use the current array count which will give us the correct number
							door = [[Door alloc] initWithTileLocation:CGPointMake(xx, yy) type:doorType arrayIndex:[doors count]];
							[doors addObject:door];
							[door release];
						}
					}
                }
            }
        }
		
    }
//	SLQLOG(@"INFO - GameScene: Finished constructing collision array and doors.");
}

- (void)calculatePlayersTileMapLocation {
	// Round the players tile location
	playerTileX = (int) player.tileLocation.x;
    playerTileY = (int) player.tileLocation.y;

    // Calculate the players tile x and y offset.  This allows us to keep the player in the middle of
	// the screen and have the map render correctly under the player.  This information is used when
	// rendering the tile map layers in the render method
	playerTileOffsetX = (int) ((playerTileX - player.tileLocation.x) * kTile_Width);
    playerTileOffsetY = (int) ((playerTileY - player.tileLocation.y) * kTile_Height);
}

- (void)initLocalDoors {
	// Calculate the tile bounds around the player. We clamp the possbile values to between
	// 0 and the width/height of the tile map.  We remove 1 from the width and height
	// as the tile map is zero indexed in the game.  These values can then be used when
	// checking if objects, portals or doors should be updated
	int minScreenTile_x = CLAMP(player.tileLocation.x - 8, 0, kMax_Map_Width-1);
	int maxScreenTile_x = CLAMP(player.tileLocation.x + 8, 0, kMax_Map_Width-1);
	int minScreenTile_y = CLAMP(player.tileLocation.y - 6, 0, kMax_Map_Height-1);
	int maxScreenTile_y = CLAMP(player.tileLocation.y + 6, 0, kMax_Map_Height-1);
	
	// Populate the localDoors array with any doors that are found around the player.  This allows
	// us to reduce the number of doors we are rendering and updating in any single frame.  We only
	// perform this check if the player has moved from one tile to another on the tile map to save cycles
	if ((int)player.tileLocation.x != (int)playersLastLocation.x || (int)player.tileLocation.y != (int)playersLastLocation.y) {
		
		// Clear the localDoors array as we are about to populate it again based on the 
		// players new position
		[localDoors removeAllObjects];
		
		// Find doors that are close to the player and add them to the localDoors loop.  Layer 3 in the 
		// tile map holds the door information
		Layer *layer = [[sceneTileMap layers] objectAtIndex:2];
		for (int yy=minScreenTile_y; yy < maxScreenTile_y; yy++) {
			for (int xx=minScreenTile_x; xx < maxScreenTile_x; xx++) {
				
				// If the value property for this tile is not -1 then this must be a door and
				// we should add it to the localDoors array
				if ([layer valueAtTile:CGPointMake(xx, yy)] > -1) {
					int index = [layer valueAtTile:CGPointMake(xx, yy)];
					[localDoors addObject:[NSNumber numberWithInt:index]];
				}
			}
		}
	}
}


- (NSMutableArray *) getSpawnPoints {
	return spawnPoints;
}

- (void)createDamageTextbox:(NSString *)aText aLocation:(CGPoint)aPoint{
	DamageText *dtext = [[DamageText alloc] initWithText:aText aLocation:aPoint];
	[damageText addObject:dtext];
}
- (void)alertAnimation:(CGPoint) aPoint{
	DamageText *dtext = [[DamageText alloc]initWithText:@"<!>" aLocation:aPoint];
	[damageText addObject:dtext];
}


- (BOOL)checkWaterDamage:(CGPoint) aPoint{
	return waterDamage[(int)aPoint.x][(int)aPoint.y];
}

- (void)deallocResources {

	// Release the images
	[fadeImage release];
	[button release];
	[pauseButton release];
	[openMainDoor release];
	[closedMainDoor release];
	[joypad release];
	[lifebar release];
	[pauseButton release];
	[menuScreen release];
	// Release fonts
	[smallFont release];
	[digitFont release];

	// Release game entities
	[doors release];
	[spawnPoints release];
	[gameEntities release];
	[enemyProjectiles release];

	[playerAttack release];
	[playerMouse release];
	[sock1 release];
	[sock2 release];
	[sock3 release];
	[localDoors release];
	[gameObjects release];
	[portals release];
	[zones release];
	[sceneTileMap release];
	[damageText release];
	[eventTextboxes release];
	[player release];
	
	// Release sounds
	[sharedSoundManager removeSoundWithKey:@"dying"];
	[sharedSoundManager removeSoundWithKey:@"encounter"];
	[sharedSoundManager removeSoundWithKey:@"alertsound"];
	[sharedSoundManager removeSoundWithKey:@"casting"];
	[sharedSoundManager removeSoundWithKey:@"castingDown"];
	[sharedSoundManager removeSoundWithKey:@"throw"];
	[sharedSoundManager removeSoundWithKey:@"blowup"];
	[sharedSoundManager removeSoundWithKey:@"scream"];
	[sharedSoundManager removeSoundWithKey:@"swoosh"];
	[sharedSoundManager removeSoundWithKey:@"hurt"];
	[sharedSoundManager removeMusicWithKey:@"ingame"];
	[sharedSoundManager removeMusicWithKey:@"alert"];
	[sharedSoundManager removeMusicWithKey:@"boss"];
	[sharedSoundManager removeMusicWithKey:@"ending"];
	[sharedSoundManager removeSoundWithKey:@"voice1"];
	[sharedSoundManager removeSoundWithKey:@"voice2"];
	[sharedSoundManager removeSoundWithKey:@"voice3"];
	[sharedSoundManager removeSoundWithKey:@"voice4"];
	[sharedSoundManager removeSoundWithKey:@"voice5"];
	[sharedSoundManager removeSoundWithKey:@"katana"];
	[sharedSoundManager removeSoundWithKey:@"katanaSwing"];
	[sharedSoundManager removeSoundWithKey:@"snoring"];
	[sharedSoundManager removeSoundWithKey:@"mouse"];
	[sharedSoundManager removeSoundWithKey:@"skiddGun"];
	[sharedSoundManager removeSoundWithKey:@"fireGun"];
	[sharedSoundManager removeMusicWithKey:@"longcat"];


}

- (void)createTextEventAtPoint:(CGPoint) aPoint WithTextInArray:(NSMutableArray*)anArray{
	TextEvent *temp = [[TextEvent alloc]initWithTileLocation:CGPointMake(aPoint.x, aPoint.y) withWidth:32 withHeight:32];
	for(NSString *str in anArray){
		[temp addString:str];
	}
	[temp turnIntoTextBoxes];
	[eventTextboxes addObject:temp];
	[temp release];
}

- (void)aquireMouse{
	hasMouse = YES;
	blocked[343][25] = NO;
	blocked[343][24] = NO;
}
- (void)aquireLongcat{
	hasLongcat = YES;
}
- (void)aquireSocktrap{
	hasSocktrap = YES;
	blocked[482][104] = NO;
	blocked[482][103] = NO;
}
- (void)aquireRFID{
	hasRFID = YES;
}

- (void)xButtonFunc{
	if(hasMouse){
		[player resetSleepTimer];
		if(!isMenuScreenTime && !isTextBoxTime){
			if(playerMouse.state != kEntityState_Alive){
				[playerMouse initWithTileLocation:CGPointMake(0, 0)];
				playerMouse.state = kEntityState_Alive;
				playerMouse.lifeSpanTimer = .02;
				playerMouse.pixelLocation = CGPointMake(player.pixelLocation.x, player.pixelLocation.y - 14);
				[sharedSoundManager playSoundWithKey:@"mouse" gain:.3f pitch:.75f location:CGPointMake(player.tileLocation.x*kTile_Width, player.tileLocation.y*kTile_Height) shouldLoop:YES];
				if(player.isFacing == kEntityFacing_Down)
					playerMouse.angle = 270;
				else if(player.isFacing == kEntityFacing_Left)
					playerMouse.angle = 180;
				else if(player.isFacing == kEntityFacing_Right)
					playerMouse.angle = 0;
				else
					playerMouse.angle = 90;
			} else{
				[playerMouse turnRight];
			}
		}
	}
}
- (void)yButtonFunc{
	if(hasLongcat){
		if(!isMenuScreenTime && !isTextBoxTime){
			[player longCatTime];
		}
	}
}

- (void)aButtonFunc{
	if(!isMenuScreenTime && !isTextBoxTime){
		[player resetSleepTimer];
		if(playerAttack.state != kEntityState_Alive && player.attackDelta <= 0 && player.state == kEntityState_Alive){
			
			[playerAttack initWithTileLocation:CGPointMake(0,0)];
			playerAttack.numOfAttacks = 2;
			player.state = kEntityState_Attack;
			player.attackDelta = .8f;
			playerAttack.state = kEntityState_Alive;
			playerAttack.pixelLocation = player.pixelLocation;
			
		}
	}
}

- (void)bButtonFunc{
	if(hasSocktrap){
		[player resetSleepTimer];
		if(!isMenuScreenTime && !isTextBoxTime){
			if(sockDelta >= .2){
				if(sock1.state != kEntityState_Alive){
					sock1.state = kEntityState_Alive;
					sock1.tileLocation = player.tileLocation;
					sock1.pixelLocation = player.tileLocation;
				} else if(sock2.state != kEntityState_Alive){
					sock2.state = kEntityState_Alive;
					sock2.tileLocation = player.tileLocation;
					sock2.pixelLocation = player.tileLocation;
				
				} else if(sock3.state != kEntityState_Alive){
					sock3.state = kEntityState_Alive;
					sock3.tileLocation = player.tileLocation;
					sock3.pixelLocation = player.tileLocation;
				
				}
				sockDelta = 0;
			}
		}
	}
}
- (void)inBossFight:(BOOL)isInBossFight{
	inBossFight = isInBossFight;
	if(inBossFight){
		//block tiles
		blocked[291][31] = YES;
		blocked[291][30] = YES;
		blocked[494][130] = YES;
		blocked[495][130] = YES;
		blocked[354][245] = YES;
		blocked[354][244] = YES;
	}else{
		//unblock tiles
		blocked[291][31] = NO;
		blocked[291][30] = NO;
		blocked[494][130] = NO;
		blocked[495][130] = NO;
		blocked[354][245] = NO;
		blocked[354][244] = NO;
	}
}
- (void)increaseContinueCounter{
	continues += 1;
}

- (void)increaseAlertCounter{
	alertCounts += 1;
}
- (void)increaseWaterDeaths{
	waterDeaths += 1;
}

@end

