//
//  Player.m
//  Tutorial1


#import "GameController.h"
#import "SoundManager.h"
#import "Player.h"
#import "Enemies.h"
#import "GameScene.h"
#import "Image.h"
#import "SpriteSheet.h"
#import "Animation.h"
#import "Primitives.h"
#import "BitmapFont.h"
#import "PackedSpriteSheet.h"
#import "AbstractObject.h"
#import "MapObject.h"
#import "EnergyObject.h"
#import "EnemyAttack.h"


#pragma mark -
#pragma mark Private implementation

@interface Player (Private)
// Updates the players location with the given delta
- (void)updateLocationWithDelta:(float)aDelta;

// Checks to see if the supplied object is part of the parchment
- (void)checkForParchment:(AbstractObject*)aObject pickup:(BOOL)aPickup;
@end

#pragma mark -
#pragma mark Public implementation

@implementation Player

@synthesize angleOfMovement;
@synthesize speedOfMovement;
@synthesize lives;
@synthesize beamLocation;
@synthesize checkPointLocation;
@synthesize attackDelta;




- (void)dealloc {
    [leftAnimation release];
    [rightAnimation release];
    [downAnimation release];
    [upAnimation release];
    [leftAttackAnimation release];
    [rightAttackAnimation release];
    [upAttackAnimation release];
    [downAttackAnimation release];
    [upLongCat release];
    [rightLongCat release];
    [leftLongCat release];
    [downLongCat release];
    [socksAnimation release];
    [sleepAnimation release];
    [super dealloc];
}

#pragma mark -
#pragma mark Init

- (id)initWithTileLocation:(CGPoint)aLocation {
    self = [super init];
	if (self != nil) {
		
		// The players position is held in terms of tiles on the map
        tileLocation = aLocation;
        checkPointLocation = CGPointMake(aLocation.x - 5, aLocation.y + 5);

		
		// Set up the initial pixel position based on the players tile position
		pixelLocation = tileMapPositionToPixelPosition(tileLocation);
		
       		PackedSpriteSheet *test = [PackedSpriteSheet packedSpriteSheetForImageNamed:@"spritePkg.png" controlFile:@"spritePkg" imageFilter:GL_NEAREST];
    
        // Set up the animations for our player for different directions
        leftAnimation = [[Animation alloc] init];
        rightAnimation = [[Animation alloc] init];
        downAnimation = [[Animation alloc] init];
		upAnimation = [[Animation alloc] init];
        leftAttackAnimation = [[Animation alloc] init];
        rightAttackAnimation = [[Animation alloc] init];
        upAttackAnimation = [[Animation alloc] init];
        downAttackAnimation = [[Animation alloc] init];
        upLongCat = [[Animation alloc] init];
        rightLongCat = [[Animation alloc] init];
        leftLongCat = [[Animation alloc] init];
        downLongCat = [[Animation alloc] init];
        socksAnimation = [[Animation alloc] init];
        sleepAnimation = [[Animation alloc]init];

        float animationDelay = 0.2f;
        
        NSString *name = [[NSString alloc]initWithString:@"s"];

        
        // Left animation
		[leftAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"rl1.png"]] delay:animationDelay/4];
		[leftAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"rl2.png"]] delay:animationDelay];
		[leftAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"rl3.png"]] delay:animationDelay]; //***
		[leftAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"rl1.png"]] delay:animationDelay];
		[leftAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"il.png"]] delay:animationDelay];
		leftAnimation.type = kAnimationType_Repeating;
		leftAnimation.state = kAnimationState_Running;
		leftAnimation.bounceFrame = 4;

        // Right animation  //start with mid run > run 1 > mid run > run 3 > standing
		[rightAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"rr1.png"]] delay:animationDelay/4];
		[rightAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"rr2.png"]] delay:animationDelay];
		[rightAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"rr3.png"]] delay:animationDelay];
		[rightAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"rr1.png"]] delay:animationDelay];
		[rightAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"ir.png"]] delay:animationDelay];
		rightAnimation.type = kAnimationType_Repeating;
		rightAnimation.state = kAnimationState_Running;
		rightAnimation.bounceFrame = 4;
      
        // Down animation
		[downAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"rd1.png"]] delay:animationDelay/4];
		[downAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"rd2.png"]] delay:animationDelay];
		[downAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"rd3.png"]] delay:animationDelay];
		[downAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"rd1.png"]] delay:animationDelay];
		[downAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"id.png"]] delay:animationDelay];
		downAnimation.type = kAnimationType_Repeating;
		downAnimation.state = kAnimationState_Running;
		downAnimation.bounceFrame = 4;
        
        // Up animation
		[upAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"ru1.png"]] delay:animationDelay/4];
		[upAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"ru2.png"]] delay:animationDelay];
		[upAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"ru3.png"]] delay:animationDelay];
		[upAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"ru1.png"]] delay:animationDelay];
		[upAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"iu.png"]] delay:animationDelay];
		upAnimation.type = kAnimationType_Repeating;
		upAnimation.state = kAnimationState_Running;
		upAnimation.bounceFrame = 4;           //not 9 9 0 2

        // Right attack animation
        [rightAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"ar1.png"]] delay:animationDelay];
		[rightAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"ar2.png"]] delay:animationDelay];
		[rightAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"ar1.png"]] delay:animationDelay];
		[rightAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"ar2.png"]] delay:animationDelay];
		rightAttackAnimation.type = kAnimationType_Once;
		rightAttackAnimation.state = kAnimationState_Running;
		rightAttackAnimation.bounceFrame = 4;
        
        // Left attack animation
        [leftAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"al1.png"]] delay:animationDelay];
		[leftAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"al2.png"]] delay:animationDelay];
		[leftAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"al1.png"]] delay:animationDelay];
		[leftAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"al2.png"]] delay:animationDelay];
		leftAttackAnimation.type = kAnimationType_Once;
		leftAttackAnimation.state = kAnimationState_Running;
		leftAttackAnimation.bounceFrame = 4;
     
        [upAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"au1.png"]] delay:animationDelay];
		[upAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"iu.png"]] delay:animationDelay];
		[upAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"au1.png"]] delay:animationDelay];
		[upAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"iu.png"]] delay:animationDelay];
		upAttackAnimation.type = kAnimationType_Once;
		upAttackAnimation.state = kAnimationState_Running;
		upAttackAnimation.bounceFrame = 4;
        
        // Down attack animation
        [downAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"ad1.png"]] delay:animationDelay];
		[downAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"ad2.png"]] delay:animationDelay];
		[downAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"ad1.png"]] delay:animationDelay];
		[downAttackAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"ad2.png"]] delay:animationDelay];
		downAttackAnimation.type = kAnimationType_Once;
		downAttackAnimation.state = kAnimationState_Running;
		downAttackAnimation.bounceFrame = 4;
        
        //Need to add sleeping animation
        [sleepAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"s1.png"]] delay:animationDelay];
		[sleepAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"s2.png"]] delay:animationDelay];
		[sleepAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"s3.png"]] delay:animationDelay];
		[sleepAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"s4.png"]] delay:animationDelay];
		sleepAnimation.type = kAnimationType_PingPong;
        sleepAnimation.bounceFrame = 3;
		sleepAnimation.state = kAnimationState_Running;
        
        //0 neutral, 1 front 2 back ---SOCKS ANIMATION----
        [socksAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"sock0.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"sock1.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"sock0.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"sock1.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"sock0.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"sock1.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"sock0.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"sock2.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"sock0.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"sock2.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"sock0.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[test imageForKey:[name stringByAppendingString:@"sock2.png"]] delay:animationDelay];
        socksAnimation.type = kAnimationType_Repeating;
        socksAnimation.state = kAnimationState_Running;
        
        //Up Long Cat Animation
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong00.png"] delay:animationDelay/9];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong01.png"] delay:animationDelay/9];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong02.png"] delay:animationDelay/8];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong03.png"] delay:animationDelay/7];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong04.png"] delay:animationDelay/6];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong05.png"] delay:animationDelay/4.5];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong06.png"] delay:animationDelay/3.25];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong07.png"] delay:animationDelay/2.25];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong08.png"] delay:animationDelay];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong09.png"] delay:animationDelay/2.25];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong10.png"] delay:animationDelay/3.25];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong11.png"] delay:animationDelay/4.5];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong12.png"] delay:animationDelay/6];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong13.png"] delay:animationDelay/7];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong14.png"] delay:animationDelay/8];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong15.png"] delay:animationDelay/9];
        [upLongCat addFrameWithImage:[test imageForKey:@"ulong16.png"] delay:animationDelay*9];
        upLongCat.type = kAnimationType_Once;
        upLongCat.state = kAnimationState_Running;
		
        //Down Long Cat Animation
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong00.png"] delay:animationDelay/9];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong01.png"] delay:animationDelay/9];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong02.png"] delay:animationDelay/8];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong03.png"] delay:animationDelay/7];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong04.png"] delay:animationDelay/6];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong05.png"] delay:animationDelay/4.5];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong06.png"] delay:animationDelay/3.25];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong07.png"] delay:animationDelay/2.25];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong08.png"] delay:animationDelay];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong09.png"] delay:animationDelay/2.25];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong10.png"] delay:animationDelay/3.25];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong11.png"] delay:animationDelay/4.5];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong12.png"] delay:animationDelay/6];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong13.png"] delay:animationDelay/7];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong14.png"] delay:animationDelay/8];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong15.png"] delay:animationDelay/9];
        [downLongCat addFrameWithImage:[test imageForKey:@"dlong16.png"] delay:animationDelay*9];
        downLongCat.type = kAnimationType_Once;
        downLongCat.state = kAnimationState_Running;
        
        //Right Long Cat Animation
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong00.png"] delay:animationDelay/9];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong01.png"] delay:animationDelay/9];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong02.png"] delay:animationDelay/8];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong03.png"] delay:animationDelay/7];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong04.png"] delay:animationDelay/6];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong05.png"] delay:animationDelay/4.5];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong06.png"] delay:animationDelay/3.25];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong07.png"] delay:animationDelay/2.25];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong08.png"] delay:animationDelay];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong09.png"] delay:animationDelay/2.25];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong10.png"] delay:animationDelay/3.25];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong11.png"] delay:animationDelay/4.5];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong12.png"] delay:animationDelay/6];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong13.png"] delay:animationDelay/7];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong14.png"] delay:animationDelay/8];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong15.png"] delay:animationDelay/9];
        [rightLongCat addFrameWithImage:[test imageForKey:@"rlong16.png"] delay:animationDelay*9];
        rightLongCat.type = kAnimationType_Once;
        rightLongCat.state = kAnimationState_Running;
        
        //Left Long Cat Animation
        //Up Long Cat Animation
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong00.png"] delay:animationDelay/9];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong01.png"] delay:animationDelay/9];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong02.png"] delay:animationDelay/8];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong03.png"] delay:animationDelay/7];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong04.png"] delay:animationDelay/6];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong05.png"] delay:animationDelay/4.5];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong06.png"] delay:animationDelay/3.25];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong07.png"] delay:animationDelay/2.25];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong08.png"] delay:animationDelay];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong09.png"] delay:animationDelay/2.25];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong10.png"] delay:animationDelay/3.25];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong11.png"] delay:animationDelay/4.5];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong12.png"] delay:animationDelay/5];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong13.png"] delay:animationDelay/9];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong14.png"] delay:animationDelay/9];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong15.png"] delay:animationDelay/9];
        [leftLongCat addFrameWithImage:[test imageForKey:@"llong16.png"] delay:animationDelay*9];
        leftLongCat.type = kAnimationType_Once;
        leftLongCat.state = kAnimationState_Running;
        
        // End of Animation definitions//
        

        // Set the default animation to be facing the right with the selected frame
        // showing the player standing
        currentAnimation = downAnimation;
        [currentAnimation setCurrentFrame:4];
        // Set the players state to alive
        state = kEntityState_Alive;
        // Speed at which the player moves
        playerSpeed = 0.6f;
        maxEnergy = 10;
		// Default player values
        energy = maxEnergy;
        isFacing = kEntityFacing_Down;
        target = nil;

        
 
        
        self.isEnemy = NO;
        self.isDying = YES;
        // Number of seconds the player stays dead before reappearing
		stayDeadTime = 4;
		deathTimer = 0;
		appearingTimer = 0;
        sleepTimer = 0;
        energyDrain = 1;
        attackTimer = 0;
        controlDelta = 0;
        animationDelta = 0;
        timeAlive = 0;
        attackDelta = 0;
        regenDelta = 0;
        longCatDelta = 0;
    }
    return self;
    
}

#pragma mark -
#pragma mark Update

- (void)updateWithDelta:(GLfloat)aDelta scene:(GameScene*)aScene {

    

    if(attackDelta > 0)
        attackDelta -= aDelta;
    timeAlive += aDelta;
    longCatDelta -= aDelta;


    // Check the state of the player and update them accordingly
    switch (state) {
        case kEntityState_DLong:
        case kEntityState_RLong:
        case kEntityState_LLong:
        case kEntityState_ULong:
            [self updateLocationWithDelta:aDelta];
            if(longCatDelta <= 0){
                if(state == kEntityState_LLong)
                    currentAnimation = leftAnimation;
                else if(state == kEntityState_RLong)
                    currentAnimation = rightAnimation;
                else if(state == kEntityState_DLong)
                    currentAnimation = downAnimation;
                else if(state == kEntityState_ULong)
                    currentAnimation = upAnimation;
            [sharedSoundManager setListenerPosition:CGPointMake(tileLocation.x*kTile_Width, tileLocation.y*kTile_Height)];
            state = kEntityState_Alive;
            [currentAnimation setCurrentFrame:4];
            }
            break;
        case kEntityState_Attack:
            if(attackDelta <= 0) {
                state = kEntityState_Alive;
            }
            speedOfMovement *= .0;

            [self updateLocationWithDelta:aDelta];
            break;
                
        case kEntityState_Defend:
        case kEntityState_Evade:
        
            appearingTimer += aDelta;
            
            if(appearingTimer >= .2) {
                renderSprite = YES;
            }
            if(state == kEntityState_Evade) {
                
                state = kEntityState_Alive;
                break;
            }
            break;
        case kEntityState_Sleep:
            if(currentAnimation != sleepAnimation)
                currentAnimation = sleepAnimation;              ///PUT SLEEP BACK HERE AFTER FINISHED TESTING!!!

        case kEntityState_Appearing:
		case kEntityState_Alive:
        case kEntityState_Hit:
        case kEntityState_Socks:

            if(state == kEntityState_Alive){
                if(waterDelta > 0.0)
                    waterDelta -= aDelta;
                if([scene checkWaterDamage:tileLocation] && waterDelta <= 0.0){
                    energy -= 100;
                    waterDelta = .5;
                    previousState = state;
                    state = kEntityState_Hit;
                    appearingTimer = 0;
                    
                }
            }
            
			// If the player is appearing then update the timers
			if (state == kEntityState_Appearing || state == kEntityState_Hit) {
				appearingTimer += aDelta;

				// If the player has been appearing for more than 2 seconds then set their
				// state to alive
				if (appearingTimer >= .1) {
					state = previousState;
					appearingTimer = 0;
				}

				//  The player sprite will only be rendered if the renderSprite flag is YES. This
				// allows us to make the player blink when appearing
				blinkTimer += aDelta;
				if (blinkTimer >= 0.9) {
					renderSprite = (renderSprite == YES) ? NO : YES;
					blinkTimer = 0;
				}
                state = kEntityState_Alive;
			}

            // Update the players position
        
            [self updateLocationWithDelta:aDelta];
			
			// If the players energy reaches 0 then set their state to
			// dead
			if (energy <= 0) {
				state = kEntityState_Dead;
                [scene increaseContinueCounter];
                [sharedSoundManager playSoundWithKey:@"dying" gain:0.55f pitch:0.70f location:CGPointMake(tileLocation.x*kTile_Width, tileLocation.y*kTile_Height) shouldLoop:NO];

				// Set the energy to 0 else a small amount of energy could be left
				// showing even though the player is dead
				energy = 0;
				
				// Reduce the number of lives the player has.  If the player is then below the minimum number of lives
				// they are dead, for good, so we set the game scene state to game over.
				lives -= 1;
				if (lives < 1) {
                    
                 //   currentAnimation = sleepAnimation;
               //     currentAnimation.state = kAnimationState_Stopped;
             //       [currentAnimation setFrames:1];
				//	[sharedGameController transitionToSceneWithKey:@"menu"];
				}

                
				// The player has died so play a suitable scream
				//[sharedSoundManager playSoundWithKey:@"scream" location:pixelLocation];
			}
            break;
	
		case kEntityState_Dead:
            timeAlive = 0;
            if(deathTimer == 0){
                [sharedSoundManager pauseMusic];
            }
			// The player should stay dead for the time defined in stayDeadTime.  After this time has passed
			// the players state is set back to alive and their energy is reset
			deathTimer += aDelta;
            currentAnimation = sleepAnimation;              ///PUT SLEEP BACK HERE AFTER FINISHED TESTING!!!
            [currentAnimation setCurrentFrame:1];
            [currentAnimation setState: kAnimationState_Running];
            if (deathTimer >= stayDeadTime) {
                for(Enemies *enemy in scene.gameEntities){
                    if(enemy.energy > 0 && (enemy.index == 13 || enemy.index == 12 || enemy.index == 11)){
                        [enemy setState: kEntityState_Idle];
                        [enemy setEnergy: enemy.maxEnergy];
                        enemy.pixelLocation = enemy.initLocation;
                        enemy.tileLocation = pixelToTileMapPosition( enemy.pixelLocation);
                    }
                }
				deathTimer = 0;
                tileLocation = CGPointMake(checkPointLocation.x + 5, checkPointLocation.y - 5) ;
                scene.state = kSceneState_TransportingIn;
                [sharedSoundManager resumeMusic];
                //[sharedSoundManager fadeMusicVolumeFrom:0.0f toVolume:0.8f duration:0.8f stop:NO];
                //[sharedGameController transitionToSceneWithKey:@"menu"];
                //uncomment if checkpoints get implemented; otherwise death is a gameover
                isFacing = kEntityFacing_Down;
                currentAnimation = downAnimation;
                [currentAnimation setCurrentFrame:4];
				state = kEntityState_Alive;
				energy = maxEnergy;
			}
			break;
        default:
            break;
    }

}

- (void)setState:(uint)aState {
	state = aState;
}

#pragma mark -
#pragma mark Render

- (void)render {

	switch (state) {
		case kEntityState_Alive:
        case kEntityState_Attack:
        case kEntityState_Socks:
        case kEntityState_Sleep:
        case kEntityState_Dead:

            [super render];
            [currentAnimation renderAtPointWithFilter:CGPointMake((int)pixelLocation.x, (int)pixelLocation.y) filter:Color4fMake(1, 1, 1, 1)];
            break;
        case kEntityState_LLong:
            [super render];
            [currentAnimation renderAtPointWithFilter:CGPointMake((int)pixelLocation.x+64, (int)pixelLocation.y) filter:Color4fMake(1, 1, 1, 1)];
            break;
        case kEntityState_DLong:
            [super render];
            [currentAnimation renderAtPointWithFilter:CGPointMake((int)pixelLocation.x, (int)pixelLocation.y+64) filter:Color4fMake(1, 1, 1, 1)];
            break;
        case kEntityState_RLong:
            [super render];
            [currentAnimation renderAtPointWithFilter:CGPointMake((int)pixelLocation.x-64, (int)pixelLocation.y) filter:Color4fMake(1, 1, 1, 1)];
            break;
        case kEntityState_ULong:
            [super render];
            [currentAnimation renderAtPointWithFilter:CGPointMake((int)pixelLocation.x, (int)pixelLocation.y-64) filter:Color4fMake(1, 1, 1, 1)];
            break;
        case kEntityState_Defend:
        case kEntityState_Idle:
        case kEntityState_Lattack:
            [super render];
            [currentAnimation renderAtPointWithFilter: CGPointMake(pixelLocation.x, pixelLocation.y) filter:Color4fMake(1,1,1,1)];
			break;
        		
		case kEntityState_Appearing:
			[super render];
			if (renderSprite)
                [currentAnimation renderAtPointWithFilter: CGPointMake(pixelLocation.x, pixelLocation.y) filter:Color4fMake(1,1,1,1)];
            break;
        case kEntityState_Evade:
        case kEntityState_Hit:

           [super render];
            
            if (renderSprite)
                [currentAnimation renderAtPointWithFilter: CGPointMake(pixelLocation.x, pixelLocation.y + 5) filter:Color4fMake(1,0.5,0.5,1)];
			break;
		default:
			break;
	}

}

#pragma mark -
#pragma mark Bounds & Collision

- (CGRect)movementBounds { 
	// Calculate the pixel position and return a CGRect that defines the bounds
	pixelLocation = tileMapPositionToPixelPosition(tileLocation);
	return CGRectMake(pixelLocation.x-8, pixelLocation.y-22, 16, 16); //(x-8, y-28, 14, 10)
    
}

- (CGRect)collisionBounds {
	// Calculate the pixel position and return a CGRect that defines the bounds
	pixelLocation = tileMapPositionToPixelPosition(tileLocation);
	return CGRectMake(pixelLocation.x - 10, pixelLocation.y - 20, 20, 35);
}

- (void)checkForCollisionWithEntity:(AbstractEntity*)aEntity {
	
	if (CGRectIntersectsRect([self collisionBounds], [aEntity collisionBounds])) {
		if ([aEntity isKindOfClass:[EnemyAttack class]]) {
            energy -= 1;
		}
	}
} 

- (void)checkForCollisionWithObject:(AbstractObject*)aObject {
		
	if (CGRectIntersectsRect([self collisionBounds], [aObject collisionBounds])) {
		if ([aObject isKindOfClass:[EnergyObject class]]) {
					energy += aObject.energy;
					if (energy > maxEnergy) {
						energy = maxEnergy;
					}
		}
	}
}


#pragma mark -
#pragma mark Inventory

- (void)placeInInventoryObject:(AbstractObject*)aObject {
    ;
}

- (void)dropInventoryFromSlot:(int)aInventorySlot {

	AbstractObject *invObject = nil;
	

	// Change the properties of invObject so that the object is placed
	// back into the map
	if (invObject) {
		invObject.pixelLocation = pixelLocation;
		invObject.tileLocation = tileLocation;
		invObject.state = kObjectState_Active;
	}

}

#pragma mark -
#pragma mark Encoding

- (id)initWithCoder:(NSCoder *)aDecoder {
	// Initialize the player
	[self initWithTileLocation:CGPointMake(0, 0)];
	
	// Load in the important variables from the decoder
	self.tileLocation = [aDecoder decodeCGPointForKey:@"position"];
	self.angleOfMovement = [aDecoder decodeFloatForKey:@"directionAngle"];
	self.energy = [aDecoder decodeFloatForKey:@"energy"];
	self.lives = [aDecoder decodeFloatForKey:@"lives"];
	
	// Set up the initial pixel position based on the players tile position
	pixelLocation = tileMapPositionToPixelPosition(tileLocation);
	
	// Make sure that the inventory items are rotated correctly.

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	// Encode the important variables to save the players state
	[aCoder encodeCGPoint:tileLocation forKey:@"position"];
	[aCoder encodeFloat:angleOfMovement forKey:@"directionAngle"];
	[aCoder encodeFloat:energy forKey:@"energy"];
	[aCoder encodeFloat:lives forKey:@"lives"];
}

#pragma mark -
#pragma mark Setters

- (void)setDirectionWithAngle:(float)aAngle speed:(float)aSpeed {
	self.angleOfMovement = aAngle;
	self.speedOfMovement = aSpeed;
}

@end

#pragma mark -
#pragma mark Private implementation

@implementation Player (Private)

- (void)updateLocationWithDelta:(float)aDelta {
  
    controlDelta += aDelta;
    if(controlDelta > (1.0/30.0)) {
	
    // Holds the bounding box verticies in tile map coordinates
	BoundingBoxTileQuad bbtq;
	CGPoint oldPosition = tileLocation;
        if(state == kEntityState_DLong || state == kEntityState_ULong || state == kEntityState_RLong || state == kEntityState_LLong){
            speedOfMovement = 0;
            [currentAnimation setState:kAnimationState_Running];
            [currentAnimation updateWithDelta:controlDelta];
        }
    else if (speedOfMovement != 0) {
        if(state == kEntityState_Sleep){
            [sharedSoundManager stopSoundWithKey:@"snoring"];
            state = kEntityState_Alive;
        }
        sleepTimer = 0;

		// Move the player in the x-axis based on the angle of the joypad
		tileLocation.x -= (aDelta * (playerSpeed * speedOfMovement)) * cosf(angleOfMovement);
		// Check to see if any of the players bounds are in a blocked tile.  If they are
		// then set the x location back to its original location
		CGRect bRect = [self movementBounds];
		bbtq = getTileCoordsForBoundingRect(bRect, CGSizeMake(kTile_Width, kTile_Height));
		if ([scene isBlocked:bbtq.x1 y:bbtq.y1] ||
			[scene isBlocked:bbtq.x2 y:bbtq.y2] ||
			[scene isBlocked:bbtq.x3 y:bbtq.y3] ||
			[scene isBlocked:bbtq.x4 y:bbtq.y4] ||
            [scene isPlayerOnTopOfEnemy]

             ){
            
             tileLocation.x = oldPosition.x;
		}
		
		// Move the player in the y-axis based on the angle of the joypad
		tileLocation.y -= (aDelta * (playerSpeed * speedOfMovement)) * sinf(angleOfMovement);
		
		// Check to see if any of the players bounds are in a blocked tile.  If they are
		// then set the x location back to its original location
		bRect = [self movementBounds];
		bbtq = getTileCoordsForBoundingRect(bRect, CGSizeMake(kTile_Width, kTile_Height));
		if ([scene isBlocked:bbtq.x1 y:bbtq.y1] ||
			[scene isBlocked:bbtq.x2 y:bbtq.y2] ||
			[scene isBlocked:bbtq.x3 y:bbtq.y3] ||
			[scene isBlocked:bbtq.x4 y:bbtq.y4] ||
            [scene isPlayerOnTopOfEnemy]) {
    
            tileLocation.y = oldPosition.y;
		}
		
		// Based on the players current direction angle in radians, decide
		// which is the best animation to be using
        if(state== kEntityState_Alive){
		if (angleOfMovement > 0.785 && angleOfMovement < 2.355) {
			currentAnimation = downAnimation;
            isFacing = kEntityFacing_Down;
		} else if (angleOfMovement < -0.785 && angleOfMovement > -2.355) {
			currentAnimation = upAnimation;
            isFacing = kEntityFacing_Up;
		} else if (angleOfMovement < -2.355 || angleOfMovement > 2.355) {
			currentAnimation = rightAnimation;
            isFacing = kEntityFacing_Right;
		} else  {
			currentAnimation = leftAnimation;
            isFacing = kEntityFacing_Left;
		}

		[currentAnimation setState:kAnimationState_Running];
        [currentAnimation updateWithDelta:controlDelta];
		
		// Set the OpenAL listener position within the sound manager to the location of the player
		[sharedSoundManager setListenerPosition:CGPointMake(pixelLocation.x, pixelLocation.y)];
        }
    }
    else if(state == kEntityState_Alive){
        if (currentAnimation== downAttackAnimation) {
			currentAnimation = downAnimation;
            isFacing = kEntityFacing_Down;
            
		} else if (currentAnimation == upAttackAnimation) {
			currentAnimation = upAnimation;
            isFacing = kEntityFacing_Up;
        } else if (currentAnimation == rightAttackAnimation) {
			currentAnimation = rightAnimation;
            isFacing = kEntityFacing_Right;
		} else  if(currentAnimation == leftAttackAnimation){
			currentAnimation = leftAnimation;
            isFacing = kEntityFacing_Left;
		}
        sleepTimer += controlDelta;
        if(sleepTimer >= 10 && state != kEntityState_Sleep){
            state = kEntityState_Sleep;
            [sharedSoundManager playSoundWithKey:@"snoring" gain:0.15f pitch:0.70f location:CGPointMake(tileLocation.x*kTile_Width, tileLocation.y*kTile_Height) shouldLoop:YES];
            
            currentAnimation = sleepAnimation;              ///PUT SLEEP BACK HERE AFTER FINISHED TESTING!!!
            [currentAnimation setCurrentFrame:1];
            [currentAnimation setState: kAnimationState_Running];
        } else{
            [currentAnimation setState:kAnimationState_Stopped];
            [currentAnimation setCurrentFrame:4];
        }
    }
    else if(state == kEntityState_Attack){
        sleepTimer = 0;
        if (currentAnimation == downAnimation) {
            
			currentAnimation = downAttackAnimation;
            isFacing = kEntityFacing_Down;
            [currentAnimation setCurrentFrame:0];
		} else if (currentAnimation == upAnimation) {
			currentAnimation = upAttackAnimation;
            isFacing = kEntityFacing_Up;
            [currentAnimation setCurrentFrame:0];
		} else if (currentAnimation == rightAnimation) {
			currentAnimation = rightAttackAnimation;
            isFacing = kEntityFacing_Right;
            [currentAnimation setCurrentFrame:0];
		} else  if(currentAnimation == leftAnimation){
			currentAnimation = leftAttackAnimation;
            isFacing = kEntityFacing_Left;
            [currentAnimation setCurrentFrame:0];
		}
            [currentAnimation setState: kAnimationState_Running];
            [currentAnimation setCurrentFrame:0];
            [currentAnimation updateWithDelta:controlDelta];

    
    }
    else if(state == kEntityState_Sleep || state == kEntityState_Socks){
        [currentAnimation setState:kAnimationState_Running];
        [currentAnimation updateWithDelta:controlDelta];
    }

        controlDelta = 0;
    }
}

- (void)checkForParchment:(AbstractObject*)aObject pickup:(BOOL)aPickup {

	// Check to see if the object just picked up was part of the parchment needed to escape from the
	// castle.  If pickup was YES then and the object was a parchment piece, then we set the approprite
	// parchment variable to YES.  If we were putting it down, then we set the appropriate variable to NO
	if (aPickup) {
		if (aObject.subType == kObjectSubType_ParchmentTop) {
			hasParchmentTop = YES;
		} else if (aObject.subType == kObjectSubType_ParchmentMiddle) {
			hasParchmentMiddle = YES;
		} else if (aObject.subType == kObjectSubType_ParchmentBottom) {
			hasParchmentBottom = YES;
		}
	} else {
		if (aObject.subType == kObjectSubType_ParchmentTop) {
			hasParchmentTop = NO;
		} else if (aObject.subType == kObjectSubType_ParchmentMiddle) {
			hasParchmentMiddle = NO;
		} else if (aObject.subType == kObjectSubType_ParchmentBottom) {
			hasParchmentBottom = NO;
		}
	}
	

}
-(void)longCatTime{
    if(longCatDelta <= 0 && state != kEntityState_Dead){
        longCatDelta = .2;  //longcat jumps vertically through the level if this line isn't here
//        [sharedSoundManager stopSoundWithKey:@"longcat"];
        sleepTimer = 0;
        CGRect longcatBounds;
        CGPoint oldPosition = tileLocation;
        BoundingBoxTileQuad bbtq;

        switch(isFacing){
            case kEntityFacing_Down:
                pixelLocation.y -= 128;
                longcatBounds= CGRectMake(pixelLocation.x - 10, pixelLocation.y - 20 - 64, 20, 160);
                break;
            case kEntityFacing_Right:
                pixelLocation.x += 128;
                longcatBounds = CGRectMake(pixelLocation.x - 10 + 64, pixelLocation.y - 20, 160, 35);
                break;
            case kEntityFacing_Up:
                pixelLocation.y += 128;
                longcatBounds = CGRectMake(pixelLocation.x - 10, pixelLocation.y - 20 + 64, 20, 160);
                break;
            case kEntityFacing_Left:
                pixelLocation.x -= 128;
                longcatBounds = CGRectMake(pixelLocation.x - 10 - 64, pixelLocation.y - 20, 160, 35);
                break;
        }
        tileLocation = pixelToTileMapPosition(pixelLocation);
        
        CGRect bRect = [self movementBounds];
		bbtq = getTileCoordsForBoundingRect(bRect, CGSizeMake(kTile_Width, kTile_Height));
		if ([scene isBlocked:bbtq.x1 y:bbtq.y1] ||
			[scene isBlocked:bbtq.x2 y:bbtq.y2] ||
			[scene isBlocked:bbtq.x3 y:bbtq.y3] ||
			[scene isBlocked:bbtq.x4 y:bbtq.y4] ||
            [scene isPlayerOnTopOfEnemy]
            
            ){
            
            tileLocation = oldPosition;
            state = kEntityState_Alive;
		
        } else{
            BOOL isBlocked = NO;
            float v1,v2,v3,v4;
            switch(isFacing){
                case kEntityFacing_Down:
                    v1 = tileLocation.y + 1;
                    v2 = tileLocation.y + 2;
                    v3 = tileLocation.y + 3;
                    v4 = tileLocation.y + 4;

                    if([scene isBlocked:tileLocation.x y:v1]||
                       [scene isBlocked:tileLocation.x y:v2]||
                       [scene isBlocked:tileLocation.x y:v3]||
                       [scene isBlocked:tileLocation.x y:v4])
                        isBlocked = YES;
                    break;
                case kEntityFacing_Left:
                    v1 = tileLocation.x + 1;
                    v2 = tileLocation.x + 2;
                    v3 = tileLocation.x + 3;
                    v4 = tileLocation.x + 4;

                    if([scene isBlocked:v1 y:tileLocation.y]||
                       [scene isBlocked:v2 y:tileLocation.y]||
                       [scene isBlocked:v3 y:tileLocation.y]||
                       [scene isBlocked:v4 y:tileLocation.y])
                        isBlocked = YES;
                    break;
                    
                case kEntityFacing_Right:
                    v1 = tileLocation.x - 1;
                    v2 = tileLocation.x - 2;
                    v3 = tileLocation.x - 3;
                    v4 = tileLocation.x - 4;

                    if([scene isBlocked:v1 y:tileLocation.y]||
                       [scene isBlocked:v2 y:tileLocation.y]||
                       [scene isBlocked:v3 y:tileLocation.y]||
                       [scene isBlocked:v4 y:tileLocation.y])
                        isBlocked = YES;
                    break;
                case kEntityFacing_Up:
                    v1 = tileLocation.y - 1;
                    v2 = tileLocation.y - 2;
                    v3 = tileLocation.y - 3;
                    v4 = tileLocation.y - 4;
                    if([scene isBlocked:tileLocation.x y:v1]||
                       [scene isBlocked:tileLocation.x y:v2]||
                       [scene isBlocked:tileLocation.x y:v3]||
                       [scene isBlocked:tileLocation.x y:v4])
                        isBlocked = YES;
                    break;
            }
            if(isBlocked){
                tileLocation = oldPosition;
                state = kEntityState_Alive;
            }
            else{
                switch(isFacing){
                    case kEntityFacing_Down:
                        state = kEntityState_DLong;
                        currentAnimation = downLongCat;
                        break;
                    case kEntityFacing_Right:
                        state = kEntityState_RLong;
                        currentAnimation = rightLongCat;
                    
                        break;
                    case kEntityFacing_Up:
                        state = kEntityState_ULong;
                        currentAnimation = upLongCat;
                        break;
                    case kEntityFacing_Left:
                        state = kEntityState_LLong;
                        currentAnimation = leftLongCat;
                        break;
                }
                [currentAnimation setCurrentFrame:1];
                [sharedSoundManager playSoundWithKey:@"longcat" location:pixelLocation];

                currentAnimation.state = kAnimationState_Running;
                longCatDelta = 0.8;
            }
        }
    }
    
}
- (void) resetSleepTimer{
    sleepTimer = 0;
}

@end

