//
//  Enemies.m
//
//  Created by Robert Payne on 5/16/13.
//  Copyright (c) 2013 Robert Payne. All rights reserved.
//

#import "Enemies.h"
#import "GameScene.h"
#import "GameController.h"
#import "SoundManager.h"
#import "SpriteSheet.h"
#import "Animation.h"
#import "Player.h"
#import "Mouse.h"
#import "SockTrap.h"
#import "BitmapFont.h"
#import "PackedSpriteSheet.h"
#import "Spawn.h"
#import "PlayerAttack.h"
#import "EnemyAttack.h"

@implementation Enemies


@synthesize isReadyToThrow;
@synthesize index;

#define MOVEMENT_SPEED 1.0f

- (void)dealloc {
    [leftAnimation release];
    [rightAnimation release];
    [upAnimation release];
    [downAnimation release];
    [leftAttackAnimation release];
    [rightAttackAnimation release];
    [upAttackAnimation release];
    [downAttackAnimation release];
    [sleepAnimation release];
    [socksAnimation release];
    [currentAnimation release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Initialization

- (id)initWithTileLocation:(CGPoint)aLocation type:(int)aType spawnPointIndex:(int)anIndex {
    self = [super init];
	if (self != nil) {
        PackedSpriteSheet *pss = [PackedSpriteSheet packedSpriteSheetForImageNamed:@"spritePkg.png" controlFile:@"spritePkg" imageFilter:GL_NEAREST];
        
        leftAnimation = [[Animation alloc] init];
        rightAnimation = [[Animation alloc] init];
        downAnimation = [[Animation alloc] init];
		upAnimation = [[Animation alloc] init];
        leftAttackAnimation = [[Animation alloc] init];
        rightAttackAnimation = [[Animation alloc] init];
        downAttackAnimation = [[Animation alloc] init];
		upAttackAnimation = [[Animation alloc] init];
        sleepAnimation = [[Animation alloc]init];
        socksAnimation = [[Animation alloc]init];

        NSString *name = [NSString alloc];
        index = aType
        ;
        
        if((index >1 && index < 11) || (index > 33 && index < 42)){
            name = @"f";
            maxEnergy = 2;
            currentAnimation = downAnimation;
            [currentAnimation setState:kAnimationState_Stopped];
            [currentAnimation setCurrentFrame:4];
        }else if(index == 14){
            name = @"c";
            maxEnergy = 999999;
            currentAnimation = downAnimation;
            [currentAnimation setState:kAnimationState_Stopped];
            [currentAnimation setCurrentFrame:4];
        }else if(index == 13){
            isFacing = kEntityFacing_Left;
            name = @"m";
            maxEnergy = 25;
            currentAnimation = leftAnimation;
            [currentAnimation setState:kAnimationState_Stopped];
            [currentAnimation setCurrentFrame:4];
            retreatTimer = 6;
        }else if(index == 12){
            name = @"t";
            maxEnergy = 12;
            currentAnimation = downAnimation;
            [currentAnimation setState:kAnimationState_Stopped];
            [currentAnimation setCurrentFrame:4];
            retreatTimer = 4;
        }else if(index == 11){
            name = @"d";
            maxEnergy = 1000;
            currentAnimation = rightAnimation;
            [currentAnimation setState:kAnimationState_Stopped];
            [currentAnimation setCurrentFrame:4];
        }
        
        currentAnimation = [[Animation alloc] init];
		float animationDelay = 0.1f;
        // Left animation
		[leftAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"rl1.png"]] delay:animationDelay/4];
		[leftAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"rl2.png"]] delay:animationDelay];
		[leftAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"rl3.png"]] delay:animationDelay];
		[leftAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"rl1.png"]] delay:animationDelay];
		[leftAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"il.png"]] delay:animationDelay];
		leftAnimation.type = kAnimationType_Repeating;
		leftAnimation.state = kAnimationState_Running;
		leftAnimation.bounceFrame = 4;
        
        // Right animation  //start with mid run > run 1 > mid run > run 3 > standing
		[rightAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"rr1.png"]] delay:animationDelay/4];
		[rightAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"rr2.png"]] delay:animationDelay];
		[rightAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"rr3.png"]] delay:animationDelay];
		[rightAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"rr1.png"]] delay:animationDelay];
		[rightAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"ir.png"]] delay:animationDelay];
		rightAnimation.type = kAnimationType_Repeating;
		rightAnimation.state = kAnimationState_Running;
		rightAnimation.bounceFrame = 4;
        
        // Down animation
		[downAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"rd1.png"]] delay:animationDelay/4];
		[downAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"rd2.png"]] delay:animationDelay];
		[downAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"rd3.png"]] delay:animationDelay];
		[downAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"rd1.png"]] delay:animationDelay];
		[downAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"id.png"]] delay:animationDelay];
		downAnimation.type = kAnimationType_Repeating;
		downAnimation.state = kAnimationState_Running;
		downAnimation.bounceFrame = 4;
        
        // Up animation
		[upAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"ru1.png"]] delay:animationDelay/4];
		[upAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"ru2.png"]] delay:animationDelay];
		[upAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"ru3.png"]] delay:animationDelay];
		[upAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"ru1.png"]] delay:animationDelay];
		[upAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"iu.png"]] delay:animationDelay];
		upAnimation.type = kAnimationType_Repeating;
		upAnimation.state = kAnimationState_Running;
		upAnimation.bounceFrame = 4;           //not 9 9 0 2
        
        // Right attack animation
        [rightAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"ar1.png"]] delay:animationDelay];
		[rightAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"ar2.png"]] delay:animationDelay];
		[rightAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"ar1.png"]] delay:animationDelay];
		[rightAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"ar2.png"]] delay:animationDelay];
		rightAttackAnimation.type = kAnimationType_Once;
		rightAttackAnimation.state = kAnimationState_Running;
		rightAttackAnimation.bounceFrame = 4;
        
        // Left attack animation
        [leftAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"al1.png"]] delay:animationDelay];
		[leftAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"al2.png"]] delay:animationDelay];
		[leftAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"al1.png"]] delay:animationDelay];
		[leftAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"al2.png"]] delay:animationDelay];
		leftAttackAnimation.type = kAnimationType_Once;
		leftAttackAnimation.state = kAnimationState_Running;
		leftAttackAnimation.bounceFrame = 4;
        
        [upAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"au1.png"]] delay:animationDelay];
		[upAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"iu.png"]] delay:animationDelay];
		[upAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"au1.png"]] delay:animationDelay];
		[upAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"iu.png"]] delay:animationDelay];
		upAttackAnimation.type = kAnimationType_Once;
		upAttackAnimation.state = kAnimationState_Running;
		upAttackAnimation.bounceFrame = 4;
        
        // Down attack animation
        [downAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"ad1.png"]] delay:animationDelay];
		[downAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"ad2.png"]] delay:animationDelay];
		[downAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"ad1.png"]] delay:animationDelay];
		[downAttackAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"ad2.png"]] delay:animationDelay];
		downAttackAnimation.type = kAnimationType_Once;
		downAttackAnimation.state = kAnimationState_Running;
		downAttackAnimation.bounceFrame = 4;
        
        //Need to add sleeping animation
        [sleepAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"s1.png"]] delay:animationDelay];
		[sleepAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"s2.png"]] delay:animationDelay];
		[sleepAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"s3.png"]] delay:animationDelay];
		[sleepAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"s4.png"]] delay:animationDelay];
		sleepAnimation.type = kAnimationType_PingPong;
		sleepAnimation.state = kAnimationState_Running;
        
        //0 neutral, 1 front 2 back ---SOCKS ANIMATION----
        [socksAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"sock0.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"sock1.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"sock0.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"sock1.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"sock0.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"sock1.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"sock0.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"sock2.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"sock0.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"sock2.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"sock0.png"]] delay:animationDelay];
        [socksAnimation addFrameWithImage:[pss imageForKey:[name stringByAppendingString:@"sock2.png"]] delay:animationDelay];
        socksAnimation.type = kAnimationType_Repeating;
        socksAnimation.state = kAnimationState_Running;
        
        
        // Set the actors location to the CGPoint location which was passed in
        tileLocation = CGPointMake(aLocation.x + .5, aLocation.y + .6);
        pixelLocation = tileMapPositionToPixelPosition(tileLocation);
        spawnPointIndex = anIndex;
        speed = 0;
        
        energy = maxEnergy;
		state = kEntityState_Alive;
        attackCounter = 0;
		energyDrain = 1;
        isEnemy = YES;
        patrolDuration = 1.4;
        attackReadyDelta = 0;
        [self initializeAngle];
        socksDelta = 0;
        initLocation = pixelLocation;
        waterDelta = 0;
    }
    return self;

}


#pragma mark -
#pragma mark Updating

- (void)updateWithDelta:(GLfloat)aDelta scene:(AbstractScene*)aScene {
    if(attackReadyDelta > 0)
        attackReadyDelta -= aDelta;
    scene = (GameScene*)aScene;
	switch (state) {
        case kEntityState_Attack:{
            if(index == 13)
                retreatTimer += aDelta;
            if(index == 12)
                retreatTimer += 2;
            [self attackHandler:aDelta];
            break;}
		case kEntityState_Appearing:{
            [self appearingHandler:aDelta];
			break;}
        case kEntityState_Sleep:{
            [self sleepHandler:aDelta];
            break;}
        case kEntityState_Socks: {
            [self socksHandler:aDelta];
            break;}
        case kEntityState_Hit:{
            [self hitHandler:aDelta];
            if(energy <= 0)
                state = kEntityState_Dying;
            break;}
		case kEntityState_Alive: {
            if(index == 13 || index == 12){
                retreatTimer += aDelta;
                if(index == 12)
                    ;
                if(retreatTimer >= 8)
                    entityAIState = kEntityAIState_Retreating;
            }
			timeAlive += aDelta;
            if(waterDelta > 0.0) {
                waterDelta -= aDelta;
            }
            if([scene checkWaterDamage:tileLocation] && waterDelta <= 0.0){
                energy -= 350;
                waterDelta = .2;
                previousState = state;
                state = kEntityState_Hit;

            }
			// If there are any particles alive from appearing update them
			CGPoint oldPosition = tileLocation;
            distanceFromPlayer = (fabs(scene.player.tileLocation.x - tileLocation.x) + fabs(scene.player.tileLocation.y - tileLocation.y));
            distanceFromMouse = (fabs(scene.playerMouse.tileLocation.x - tileLocation.x) + fabs(scene.playerMouse.tileLocation.y - tileLocation.y));

			// If the player is within 5 tiles of the enemy then set its AI state to chasing
			if (distanceFromPlayer <=4 && entityAIState != kEntityAIState_Chasing && [self playerInLineOfSight] && scene.player.energy > 0 && !isChasingMouse && index != 14 && entityAIState != kEntityAIState_Retreating){//&& index != 13 && index != 12 && index != 11) {    //start chasing
				entityAIState = kEntityAIState_Chasing;
                if(scene.alertCounter == 0 && (index != 13 && index != 12 && index != 11)){
                    [sharedSoundManager playMusicWithKey:@"alert" timesToRepeat:-1];
                    [scene incrementAlertCounter];
                    [sharedSoundManager playSoundWithKey:@"alertsound" gain:1.0f pitch:1.0f location:CGPointMake(scene.player.tileLocation.x *kTile_Width, scene.player.tileLocation.y * kTile_Height) shouldLoop:NO];
                    [scene alertAnimation:pixelLocation];

                }
                
            }else if (distanceFromMouse <=4 && entityAIState != kEntityAIState_Chasing && [self mouseInLineOfSight] && index != 14 && index != 12) {    //start chasing
                
				entityAIState = kEntityAIState_Chasing;
                isChasingMouse = YES;
            }
			if (entityAIState == kEntityAIState_Chasing && index != 14) {
                [self chasingHandler:aDelta];
			}
            
            //end of chasing


			if(entityAIState == kEntityAIState_Retreating){
                [self retreatingHandler:aDelta];
            }
			if (entityAIState == kEntityAIState_Roaming) {
                [self enemyAIRoamingFunction:aDelta];
			}
            [self boundsHandler:oldPosition];
			
			// Now that the ninjas logic has been updated we can render the current animation
			// frame
            // Based on the players current direction angle in radians, decide
            // which is the best animation to be using
            [self angleHandler:aDelta];
 //angle handling

			break;}
			
		case kEntityState_Dying:
            [self deathHandler];
			break;
        case kEntityState_Idle:
            distanceFromPlayer = (fabs(scene.player.tileLocation.x - tileLocation.x) + fabs(scene.player.tileLocation.y - tileLocation.y));
            if(distanceFromPlayer < 8){
                [scene inBossFight:YES];
                state = kEntityState_Alive;
                [sharedSoundManager playMusicWithKey:@"boss" timesToRepeat:-1];
                [scene inBossFight:YES];
            }
		default:

			break;
	}
}

#pragma mark -
#pragma mark Rendering

- (void)render {

	switch (state) {
        case kEntityState_Idle:
		case kEntityState_Alive:
        case kEntityState_Socks:
        case kEntityState_Sleep:
            if(index != 13){
                [super render];
                [currentAnimation renderAtPointWithFilter: CGPointMake(pixelLocation.x, pixelLocation.y) filter:Color4fMake(1,1,1,1)];
            }else if(state == kEntityState_Socks || isChasingMouse || state == kEntityState_Idle){
                [super render];
                [currentAnimation renderAtPointWithFilter: CGPointMake(pixelLocation.x, pixelLocation.y) filter:Color4fMake(0.1,0.1,0.1,0.5)];
            }else if(entityAIState == kEntityAIState_Chasing && !isChasingMouse){
                [super render];
                [currentAnimation renderAtPointWithFilter: CGPointMake(scene.player.pixelLocation.x, scene.player.pixelLocation.y+distanceFromPlayer * 25) filter:Color4fMake(0.1,0.1,0.1,0.5)];
                [currentAnimation renderAtPointWithFilter: CGPointMake(scene.player.pixelLocation.x, scene.player.pixelLocation.y-distanceFromPlayer * 25) filter:Color4fMake(0.1,0.1,0.1,0.5)];
                [currentAnimation renderAtPointWithFilter: CGPointMake(scene.player.pixelLocation.x+distanceFromPlayer * 25, scene.player.pixelLocation.y) filter:Color4fMake(0.1,0.1,0.1,0.5)];
                [currentAnimation renderAtPointWithFilter: CGPointMake(scene.player.pixelLocation.x-distanceFromPlayer * 25, scene.player.pixelLocation.y) filter:Color4fMake(0.1,0.1,0.1,0.5)];
            }else if(speed == 0){
                [currentAnimation renderAtPointWithFilter: CGPointMake(pixelLocation.x, pixelLocation.y) filter:Color4fMake(1,1,1,1)];
            }
			break;
		case kEntityState_Dying:
            [currentAnimation renderAtPointWithFilter: CGPointMake(pixelLocation.x, pixelLocation.y) filter:Color4fMake(1,1,1,1)];
			break;
        case kEntityState_Attack:
            [super render];
            [currentAnimation renderAtPointWithFilter: CGPointMake(pixelLocation.x, pixelLocation.y) filter:Color4fMake(1,1,1,1)];
            break;
        case kEntityState_Hit:
            [super render];
            [currentAnimation renderAtPointWithFilter: CGPointMake(pixelLocation.x, pixelLocation.y + 5) filter:Color4fMake(1,0.5,0.5,1)];
            break;
            
		default:
			break;
	}
}

#pragma mark -
#pragma mark Bounds & collision

- (CGRect)movementBounds {
	// Calculate the pixel position and return a CGRect that defines the bounds
	if(state == kEntityState_Alive|| state == kEntityState_Attack){
        pixelLocation = tileMapPositionToPixelPosition(tileLocation);
        return CGRectMake(pixelLocation.x-8, pixelLocation.y-22, 16, 16); //(x-8, y-28, 14, 10)
    }
    return CGRectMake(0,0,0,0);
}

- (CGRect)collisionBounds {
	// Calculate the pixel position and return a CGRect that defines the bounds
	if(state == kEntityState_Alive|| state == kEntityState_Attack || state == kEntityState_Sleep || state == kEntityState_Socks){
        pixelLocation = tileMapPositionToPixelPosition(tileLocation);
        return CGRectMake(pixelLocation.x - 10, pixelLocation.y - 20, 20, 35);
    }
    return CGRectMake(0,0,0,0);
}

- (void)checkForCollisionWithEntity:(AbstractEntity *)aEntity {
	if(([aEntity isKindOfClass:[PlayerAttack class]] || [aEntity isKindOfClass:[SockTrap class]])
       && aEntity.state == kEntityState_Alive && timeAlive > 1) {
		if (CGRectIntersectsRect([self collisionBounds], [aEntity collisionBounds])) {
	//		[sharedSoundManager playSoundWithKey:@"pop" location:CGPointMake(tileLocation.x*kTile_Width, tileLocation.y*kTile_Height)];
            if([aEntity isKindOfClass:[SockTrap class]]){
                previousState = state;
                socksDelta = 0;
                state = kEntityState_Socks;
                currentAnimation = socksAnimation;
                currentAnimation.state = kAnimationState_Running;
                aEntity.state = kEntityState_Dead;
            }else
            
            if([aEntity isKindOfClass:[PlayerAttack class]] && index != 14){
                int damage = aEntity.energyDrain;
                energy -= damage;
                [scene reduceNoOfAttacks];
                [sharedSoundManager playSoundWithKey:@"hit" location:CGPointMake(tileLocation.x*kTile_Width, tileLocation.y*kTile_Height)];
                if(state!= kEntityState_Hit)
                    previousState = state;
                state = kEntityState_Hit;
                hitDelta = .15;
            } else if([aEntity isKindOfClass:[PlayerAttack class]] && index == 14){
                [scene reduceNoOfAttacks];
                [scene reduceNoOfAttacks];

                if(scene.hasMouse){
                    NSMutableArray *temp = [[NSMutableArray alloc]init];
                    [temp addObject:[NSString stringWithFormat:@"Dr. Charteux: You must hurry!"]];
                    [temp addObject:[NSString stringWithFormat:@"---"]];
                    [scene createTextEventAtPoint:scene.player.tileLocation WithTextInArray:temp];
                    [temp release];
                }else{
                    NSMutableArray *temp = [[NSMutableArray alloc]init];
                    [temp addObject:[NSString stringWithFormat:@"Dr. Charteux: You must hurry!"]];
                    [temp addObject:[NSString stringWithFormat:@"---"]];
                    [temp addObject:[NSString stringWithFormat:@"Dr. Charteux: ..."]];
                    [temp addObject:[NSString stringWithFormat:@"..."]];
                    [temp addObject:[NSString stringWithFormat:@"..."]];
                    [temp addObject:[NSString stringWithFormat:@"---"]];
                    [temp addObject:[NSString stringWithFormat:@"Dr. Charteux: It might actually"]];
                    [temp addObject:[NSString stringWithFormat:@"be helpful if I GIVE you the mouse!"]];
                    [temp addObject:[NSString stringWithFormat:@"---"]];
                    [scene aquireMouse];

                    [scene createTextEventAtPoint:scene.player.tileLocation WithTextInArray:temp];
                    [temp release];
                }
            }


            if(energy <= 0) {
                if(entityAIState == kEntityAIState_Chasing){
                    [scene decrementAlertCounter];
                }
                entityAIState = kEntityAIState_Roaming;
                state = kEntityState_Dying;
                scene.score += 150;

            }
		}
	}
}

-(BOOL)playerInLineOfSight{
    if(isFacing == kEntityFacing_Up){
        if(scene.player.tileLocation.x+1 >= tileLocation.x && scene.player.tileLocation.x-1 <= tileLocation.x&& scene.player.tileLocation.y >= tileLocation.y)
           return YES;
    } else if(isFacing == kEntityFacing_Down){
        if(scene.player.tileLocation.x+1 >= tileLocation.x && scene.player.tileLocation.x-1 <= tileLocation.x&& scene.player.tileLocation.y <= tileLocation.y)
            return YES;
    } else if(isFacing == kEntityFacing_Right){
        if(scene.player.tileLocation.y+1 >= tileLocation.y && scene.player.tileLocation.y-1 <= tileLocation.y && scene.player.tileLocation.x >= tileLocation.x)
            return YES;
    } else if(isFacing == kEntityFacing_Left){
        if(scene.player.tileLocation.y+1 >= tileLocation.y && scene.player.tileLocation.y-1 <= tileLocation.y && scene.player.tileLocation.x <= tileLocation.x)
            return YES;
    }
    return NO;
}
-(BOOL)mouseInLineOfSight{
    if(isFacing == kEntityFacing_Up){
        if(scene.playerMouse.tileLocation.x+1 >= tileLocation.x && scene.playerMouse.tileLocation.x-1 <= tileLocation.x&& scene.playerMouse.tileLocation.y >= tileLocation.y)
            return YES;
    } else if(isFacing == kEntityFacing_Down){
        
        if(scene.playerMouse.tileLocation.x+1 >= tileLocation.x && scene.playerMouse.tileLocation.x-1 <= tileLocation.x&& scene.playerMouse.tileLocation.y <= tileLocation.y)
            return YES;
    } else if(isFacing == kEntityFacing_Right){
        if(scene.playerMouse.tileLocation.y+1 >= tileLocation.y && scene.playerMouse.tileLocation.y-1 <= tileLocation.y && scene.playerMouse.tileLocation.x >= tileLocation.x)
            return YES;
    } else if(isFacing == kEntityFacing_Left){
        if(scene.playerMouse.tileLocation.y+1 >= tileLocation.y && scene.playerMouse.tileLocation.y-1 <= tileLocation.y && scene.playerMouse.tileLocation.x <= tileLocation.x)
            return YES;
    }
    return NO;
}
-(void)initializeAngle{
    isStandingStill = YES;
    patrolDelta =2;
    switch(index){
        case 2:
        case 4:
        case 38:
        case 41:
            angle = 0;
            break;
        case 34:
        case 37:
        case 7:
        case 9:
            angle = 180;
            break;
        case 3:
        case 5:
        case 6:
        case 40:
            angle = 270;
            break;
        case 35:
        case 36:
        case 39:
        case 8:
            angle = 90;
            break;
        default:
            angle = 270;
            break;
    }
}

-(void)nextAngle{
    switch (index) {
        case 2:                  //Starts left, goes right then left again
        case 34:                //Starts right, goes left, then right again
            if(angle == 0){
                angle = 180;
                isFacing = kEntityFacing_Left;

            }else if(angle == 180){
                angle = 0;
                isFacing = kEntityFacing_Right;
            }
            break;
        case 3:                 //Starts down then goes up and then down again
        case 35:                //Starts up then goes down then up again
            if(angle == 90){
                angle = 270;
                isFacing = kEntityFacing_Down;
            }else if(angle == 270){
                angle = 90;
                isFacing = kEntityFacing_Up;
            }
            break;
        case 4:                 //Starts NW and goes clockwise
        case 36:                //Starts SW and goes clockwise
        case 5:                 //Starts NE and goes clockwise
        case 37:                //Starts SE and goes clockwise
            if(angle == 90){
                angle = 0;
                isFacing = kEntityFacing_Right;
            }else if(angle == 0){
                angle = 270;
                isFacing = kEntityFacing_Down;
            }else if(angle == 270){
                angle = 180;
                isFacing = kEntityFacing_Left;
            }else if(angle == 180){
                angle = 90;
                isFacing = kEntityFacing_Up;
            }
            break;
        case 6:                 //Starts NW and goes counter clockwise
        case 38:                //Starts SW and goes counter clockwise
        case 7:                 //Starts NE and goes counter clockwise
        case 39:                //Starts SE and goes counter clockwise
            if(angle == 90){
                angle = 180;
                isFacing = kEntityFacing_Left;
            }else if(angle == 180){
                angle = 270;
                isFacing = kEntityFacing_Down;
            }else if(angle == 270){
                angle = 0;
                isFacing = kEntityFacing_Right;
            }else if(angle == 0){
                angle = 90;
                isFacing = kEntityFacing_Up;
            }
            break;
        case 8:                 //Facing up
            angle = 90;
            isFacing = kEntityFacing_Up;
            break;
        case 40:                //Facing down
            angle = 270;
            isFacing = kEntityFacing_Down;
            break;
        case 9:                 //Facing left
            angle = 180;
            isFacing = kEntityFacing_Left;
            break;
        case 41:                //Facing right
            angle = 0;
            isFacing = kEntityFacing_Right;
            break;
        case 42:                //Sleeping
            break;
            
        //-------------------ADD MORE FOR NON-NORMAL ENEMIES----------------//
        default:
            angle = 270;
            isFacing = kEntityFacing_Down;
            break;
    }
}

- (void)enemyAIRoamingFunction:(float)aDelta{
    if((index >= 2 && index <= 7) || (index >= 34 && index <= 39)){
        if(isStandingStill && patrolDelta > 0){ //index 2
            patrolDelta -= aDelta/2;
        } else if(isStandingStill){
            isStandingStill = NO;
            patrolDelta += aDelta;
            [self nextAngle];
            speed = 3 * MOVEMENT_SPEED;

        } else if(patrolDelta > patrolDuration){
            isStandingStill = YES;
            speed = 0;
        }else{
            patrolDelta += aDelta;
            speed = 3 * MOVEMENT_SPEED;

        }
        //end of index 2-9 and 34-41
        
        tileLocation.x += (speed * aDelta) * cos(DEGREES_TO_RADIANS(angle));
        tileLocation.y += (speed * aDelta) * sin(DEGREES_TO_RADIANS(angle));
    } else if(index == 10){ //10 zzz, 11 B1, 12 B2, 13 B3 Bosses and sleeping left to do
        if(isStandingStill && patrolDelta > 0){
            patrolDelta -= aDelta/2;
        } else if(isStandingStill){
            isStandingStill = NO;
            patrolDelta += aDelta;
            
        } else if(patrolDelta > patrolDuration){
            isStandingStill = YES;
            speed = 0;
        }else{
            patrolDelta += aDelta;
        }
    }
    if(index >= 11 && index <= 13){
        if(isStandingStill && patrolDelta > 0){ //index 2
            patrolDelta -= aDelta*8;
        } else if(isStandingStill){
            isStandingStill = NO;
            patrolDelta += aDelta;
            speed = 2 * MOVEMENT_SPEED;
        } else if(patrolDelta > patrolDuration) {
            isStandingStill = YES;
            speed = 0;
        }else{
    //        patrolDelta += aDelta;
            speed = 2 * MOVEMENT_SPEED;
            [self moveTowardsPlayer];

        }
        tileLocation.x += (speed * aDelta) * cos(DEGREES_TO_RADIANS(angle));
        tileLocation.y += (speed * aDelta) * sin(DEGREES_TO_RADIANS(angle));
    }
}

- (void)angleHandler:(float)aDelta{
    if(angle > 359 || angle < 0){
        if(angle < 0)
            angle *= -1;
        if(sin(angle) != 0)
            angle -= M_2_PI / 2;
        angle = RADIANS_TO_DEGREES(angle);
        angle = (int)angle % 360;
        
    }
    
    if (angle >= 225 && angle <= 315) {
        if(entityAIState == kEntityAIState_Chasing){
            currentAnimation = upAnimation;
            isFacing = kEntityFacing_Up;
        }
        else{
            currentAnimation = downAnimation;
            isFacing = kEntityFacing_Down;
        }
    } else if (angle >= 45 && angle <= 135) {
        if(entityAIState == kEntityAIState_Chasing){
            currentAnimation = downAnimation;
            isFacing = kEntityFacing_Down;
        }
        else{
            currentAnimation = upAnimation;
            isFacing = kEntityFacing_Up;
        }
    } else if (angle < 225 && angle > 135) {
        currentAnimation = leftAnimation;
        isFacing = kEntityFacing_Left;
        
    } else  {
        currentAnimation = rightAnimation;
        isFacing = kEntityFacing_Right;
        
    }
    
    if(speed != 0) {
        [currentAnimation setState:kAnimationState_Running];
        [currentAnimation updateWithDelta:aDelta];
    }else{
        if(state != kEntityState_Sleep && state != kEntityState_Socks){
            [currentAnimation setState:kAnimationState_Stopped];
            [currentAnimation setCurrentFrame:4];
        }
        else{
            [currentAnimation setState:kAnimationState_Running];
            [currentAnimation updateWithDelta:aDelta];
        }
    }
}

- (void)deathHandler{
    Spawn *spawn;
    [currentAnimation setState: kAnimationState_Stopped];
    [currentAnimation setCurrentFrame:4];
    state = kEntityState_Dead;
    pixelLocation = initLocation;
    if(index == 11){
        [sharedSoundManager stopMusic];
        [sharedSoundManager removeMusicWithKey:@"ingame"];
        [sharedSoundManager loadMusicWithKey:@"ingame" musicFile:@"sneak2.mp3"];
        [sharedSoundManager playMusicWithKey:@"ingame" timesToRepeat:-1];
        NSMutableArray *temp = [[NSMutableArray alloc]init];
        [temp addObject:[NSString stringWithFormat:@"You get the Longcat ability!"]];
        [temp addObject:[NSString stringWithFormat:@"---"]];
        [temp addObject:[NSString stringWithFormat:@"Press the 'Y' button to extend."]];
        [temp addObject:[NSString stringWithFormat:@"Might come in handy passing certain"]];
        [temp addObject:[NSString stringWithFormat:@"obsticles..."]];
        [temp addObject:[NSString stringWithFormat:@"---"]];
        [sharedSoundManager playSoundWithKey:@"powerup" location:scene.player.pixelLocation];
        
        scene.player.maxEnergy += 5;
        scene.player.energy = scene.player.maxEnergy;
        [temp addObject:[NSString stringWithFormat:@"Your life increased!"]];
        [temp addObject:[NSString stringWithFormat:@"---"]];
        [sharedSoundManager playSoundWithKey:@"powerup" location:scene.player.pixelLocation];
        [scene aquireLongcat];
        [scene createTextEventAtPoint:scene.player.tileLocation WithTextInArray:temp];
        [temp release];
        [scene inBossFight:NO];
    } else if(index == 12){
        NSMutableArray *temp = [[NSMutableArray alloc]init];
        [sharedSoundManager stopMusic];
        [sharedSoundManager removeMusicWithKey:@"ingame"];
        [sharedSoundManager loadMusicWithKey:@"ingame" musicFile:@"run.mp3"];
        [sharedSoundManager playMusicWithKey:@"ingame" timesToRepeat:-1];
        [sharedSoundManager removeMusicWithKey:@"boss"];
        [sharedSoundManager loadMusicWithKey:@"boss" musicFile:@"finalboss.mp3"];
        
        scene.player.maxEnergy += 5;
        scene.player.energy = scene.player.maxEnergy;
        [temp addObject:[NSString stringWithFormat:@"Your life increased!"]];
        [temp addObject:[NSString stringWithFormat:@"---"]];
        [sharedSoundManager playSoundWithKey:@"powerup" location:scene.player.pixelLocation];
        [scene createTextEventAtPoint:scene.player.tileLocation WithTextInArray:temp];
        [scene inBossFight:NO];
        [temp release];
        [scene setBlocked:415 y:125 blocked:NO];
        [scene setBlocked:415 y:124 blocked:NO];
        
    } else if(index == 13){
        NSMutableArray *temp = [[NSMutableArray alloc]init];
        [sharedSoundManager removeMusicWithKey:@"ingame"];
        [sharedSoundManager loadMusicWithKey:@"ingame" musicFile:@"finalboss.mp3"];
        [temp addObject:[NSString stringWithFormat:@"Main Coon: SHADOW!!!!"]];
        [temp addObject:[NSString stringWithFormat:@"---"]];
        [temp addObject:[NSString stringWithFormat:@"It's not over yet!"]];
        [temp addObject:[NSString stringWithFormat:@"Ha ha ha ha..."]];
        [temp addObject:[NSString stringWithFormat:@"---"]];
        [scene createTextEventAtPoint:scene.player.tileLocation WithTextInArray:temp];

        [scene inBossFight:NO];
        [temp release];
    }else{
        spawn = [[scene getSpawnPoints] objectAtIndex:spawnPointIndex];
        spawn.spawnState = kEntityState_Dead;
    }
    [self initializeAngle];
}
- (void)socksHandler:(float)aDelta{
    socksDelta += aDelta;
    retreatTimer = 10;
    if(index == 13 || index == 12)
        socksDelta += aDelta *2;
    speed = 0;
    if(socksDelta > 3){
        state = kEntityState_Alive;
        socksDelta = 0;
    }
    [currentAnimation updateWithDelta:aDelta];
}

- (void)attackHandler:(float)aDelta{
    if(attackReadyDelta > 0){
        if (currentAnimation == downAttackAnimation) {
            currentAnimation = downAnimation;
        } else if (currentAnimation == upAttackAnimation) {
            currentAnimation = upAnimation;
        } else if (currentAnimation == rightAttackAnimation) {
            currentAnimation = rightAnimation;
        } else  if(currentAnimation == leftAttackAnimation){
            currentAnimation = leftAnimation;
        }
        [currentAnimation setState:kAnimationState_Running];
        [currentAnimation updateWithDelta:aDelta];
        speed = 0;
    } else{
        state = kEntityState_Alive;
    }
    
    if (currentAnimation == downAnimation) {
        currentAnimation = downAttackAnimation;
        [currentAnimation setCurrentFrame:0];
        [currentAnimation setState: kAnimationState_Running];
    } else if (currentAnimation == upAnimation) {
        currentAnimation = upAttackAnimation;
        [currentAnimation setCurrentFrame:0];
        [currentAnimation setState: kAnimationState_Running];
    } else if (currentAnimation == rightAnimation) {
        
        currentAnimation = rightAttackAnimation;
        [currentAnimation setCurrentFrame:0];
        [currentAnimation setState: kAnimationState_Running];
    } else  if(currentAnimation == leftAnimation){
        currentAnimation = leftAttackAnimation;
        [currentAnimation setCurrentFrame:0];
        [currentAnimation setState: kAnimationState_Running];
    }
    [currentAnimation setState: kAnimationState_Running];
    [currentAnimation updateWithDelta:aDelta];
}
- (void)hitHandler:(float)aDelta{
    if(index == 11 && energy == 980 && !warningText){
        NSMutableArray *temp = [[NSMutableArray alloc]init];
        [temp addObject:[NSString stringWithFormat:@"Main Coon: Shadow!"]];
        [temp addObject:[NSString stringWithFormat:@"At this rate you'll never win!"]];
        [temp addObject:[NSString stringWithFormat:@"---"]];
        [temp addObject:[NSString stringWithFormat:@"Use a different strategy!"]];
        [temp addObject:[NSString stringWithFormat:@"---"]];
        [scene createTextEventAtPoint:scene.player.tileLocation WithTextInArray:temp];
        [temp release];
        warningText = YES;
    }
    hitDelta -= aDelta;
    if(hitDelta < 0)
        state = previousState;
    if(energy <=0)
        state = kEntityState_Dying;
}

- (void)boundsHandler:(CGPoint)oldPosition{
    // We have just moved the ninja, so we need to make sure that none of the vertices for its
    // bounding box are in a blocked tile.  First get the bounds for the ninja
    CGRect bRect = [self movementBounds];
    
    // ...and then convert them into tile map coordinates
    BoundingBoxTileQuad bbtq = getTileCoordsForBoundingRect(bRect, CGSizeMake(kTile_Width, kTile_Height));
    
    // ...and then check to see of any of the vertices are in a blocked tile.  If they are then we
    // reverse the ninja by reversing
    if([scene isBlocked:bbtq.x1 y:bbtq.y1] ||
       [scene isBlocked:bbtq.x2 y:bbtq.y2] ||
       [scene isBlocked:bbtq.x3 y:bbtq.y3] ||
       [scene isBlocked:bbtq.x4 y:bbtq.y4] ||
       [scene isPlayerOnTopOfEnemy]) {
        
        // The way is blocked so restore the old position and change the ninjas angle
        // to something in the oposite direction
        tileLocation = oldPosition;
    }
}

- (void)sleepHandler:(float)aDelta{
    speed = 0;
    currentAnimation = sleepAnimation;
    [currentAnimation setState:kAnimationState_Running];
    [currentAnimation updateWithDelta:aDelta];
}

- (void)appearingHandler:(float)aDelta{
    // If the particle count for the appearing emitter is 0 then it has not been started and
    // we can start it now
    energy = maxEnergy;
    appearingTimer+=.05;
    Spawn *temp = [[scene getSpawnPoints] objectAtIndex:spawnPointIndex];
    temp.spawnState = kEntityState_Alive;
    
    // Check to see if we have exceeded the appearing timer.  If so then set it to inactive,
    // mark the ninja as alive and reset the appearing timer to 0
    if (appearingTimer >= 0.01f) {
        if(index >13 || index < 11)
            state = kEntityState_Alive;
        else
            state = kEntityState_Idle;
        appearingTimer = 0;
    }
}

- (void)chasingHandler:(float)aDelta{

    speed = 4.25 * MOVEMENT_SPEED;
    float dy = 0;
    float dx = 0;
    if(isChasingMouse){ //Mouse chasing

        if(scene.playerMouse.state == kEntityState_Alive) {
            dx = tileLocation.x - scene.playerMouse.tileLocation.x;
            dy = tileLocation.y - scene.playerMouse.tileLocation.y;
            target = scene.playerMouse;
        } else{
            isChasingMouse = NO;
            entityAIState = kEntityAIState_Roaming;
            isStandingStill = YES;
        }
        angle = atan2(dy, dx) - DEGREES_TO_RADIANS(180);
        tileLocation.x += (speed * aDelta) * cos(angle);
        tileLocation.y += (speed * aDelta) * sin(angle);
        if(index != 11 && index != 13 && distanceFromMouse <= 1){
            attackReadyDelta = 0.5;
            state = kEntityState_Attack;
            scene.playerMouse.state = kEntityState_Dead;
            [sharedSoundManager playSoundWithKey:@"hit" location:pixelLocation];
            [sharedSoundManager stopSoundWithKey:@"mouse"];
            isStandingStill = YES;
            entityAIState = kEntityAIState_Roaming;
            [self initializeAngle];
            
        } else if(distanceFromMouse >14){           //stop chasing
            entityAIState = kEntityAIState_Roaming;
            [self initializeAngle];
            isStandingStill = YES;
            patrolDelta = 2;
        }
        
    }//end of Mouse chasing
    else{

        if(scene.player.energy > 0) {
            dx = tileLocation.x - scene.player.tileLocation.x;
            dy = tileLocation.y - scene.player.tileLocation.y;
            target = scene.player;
        }
        if(index == 12)
            speed *= 2;
        angle = atan2(dy, dx) - DEGREES_TO_RADIANS(180);
        tileLocation.x += (speed * aDelta) * cos(angle);
        tileLocation.y += (speed * aDelta) * sin(angle);
        if(distanceFromPlayer <= 1 && scene.player.energy > 0){
            attackReadyDelta = 0.5;
            previousState = state;
            state = kEntityState_Attack;
            [scene.player resetSleepTimer];
            scene.player.state = kEntityState_Hit;
            scene.player.energy -= 1;
            [sharedSoundManager playSoundWithKey:@"hit" location:pixelLocation];
            
            
        } else if(distanceFromPlayer > 14 || scene.player.energy <= 0 || ((index == 11 || index == 12 || index == 13) && distanceFromPlayer > 4)){           //stop chasing
            entityAIState = kEntityAIState_Roaming;
            isStandingStill = YES;
            [scene decrementAlertCounter];
            [self initializeAngle];
            patrolDelta = .2;
            
            
        }
        
    }
}

- (void) retreatingHandler:(float)aDelta{
    speed = 4.5 * MOVEMENT_SPEED;
    if(index == 12)
        speed *= 2;
    float dx = tileLocation.x - scene.player.tileLocation.x;
    float dy = tileLocation.y - scene.player.tileLocation.y;
    angle = atan2(dy, dx);
    tileLocation.x += (speed * aDelta) * cos(angle);
    tileLocation.y += (speed * aDelta) * sin(angle);
    retreatTimer -= aDelta * 12;
    if(retreatTimer <= 0) {
        entityAIState = kEntityAIState_Chasing;
    } else if(distanceFromPlayer >14) {
        entityAIState = kEntityAIState_Roaming;
    }
}
    
- (void)moveTowardsPlayer{
    if((int)scene.player.tileLocation.x > (int)tileLocation.x){
        if(![scene isBlocked: tileLocation.x + 1 y:tileLocation.y])
            angle = 0;
        else if((int)scene.player.tileLocation.y < (int)tileLocation.y)
            angle = 270;
        else
            angle = 90;
    }//else if((int)scene.player.tileLocation.y > (int)tileLocation.y && ![scene isBlocked:tileLocation.x y:tileLocation.y +1])
    
    else if((int)scene.player.tileLocation.x < (int)tileLocation.x){
        if(![scene isBlocked:tileLocation.x -1 y:tileLocation.y])
            angle = 180;
        else if((int)scene.player.tileLocation.y < (int)tileLocation.y)
            angle = 270;
        else
            angle = 90;
    }
    else {
    
     if((int)scene.player.tileLocation.y < (int)tileLocation.y && ![scene isBlocked:tileLocation.x y:tileLocation.y -1])
        angle = 270;
    else
        angle = 90;
    }
    
}
@end






















