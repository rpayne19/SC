//
//  Mouse.m
//  Neko Gaiden
//
//  Created by Robert Payne on 2/10/14.
//  Copyright (c) 2014 Robert Payne. All rights reserved.
//

#import "Mouse.h"
#import "GameScene.h"
#import "GameController.h"
#import "SoundManager.h"
#import "Image.h"
#import "Player.h"
#import "PackedSpriteSheet.h"
#import "Animation.h"


@implementation Mouse

@synthesize lifeSpanTimer;

- (void)dealloc {
    [upAnimation release];
    [rightAnimation release];
    [downAnimation release];
    [leftAnimation release];
    [super dealloc];
}

#pragma mark -
#pragma mark Initialization

- (id)initWithTileLocation:(CGPoint)aLocation {
    self = [super init];
	if (self != nil) {
        PackedSpriteSheet *test = [PackedSpriteSheet packedSpriteSheetForImageNamed:@"spritePkg.png" controlFile:@"spritePkg" imageFilter:GL_NEAREST];
        
        // Set up the animations for our player for different directions
        leftAnimation = [[Animation alloc] init];
        rightAnimation = [[Animation alloc] init];
        downAnimation = [[Animation alloc] init];
		upAnimation = [[Animation alloc] init];
        
        //Left Animation
		[leftAnimation addFrameWithImage:[test imageForKey:@"mousel1.png"] delay:0.25];
		[leftAnimation addFrameWithImage:[test imageForKey:@"mousel2.png"] delay:0.25];
		leftAnimation.type = kAnimationType_Repeating;
		leftAnimation.state = kAnimationState_Running;
        
        //Up Animation
		[upAnimation addFrameWithImage:[test imageForKey:@"mouseu1.png"] delay:0.25];
		[upAnimation addFrameWithImage:[test imageForKey:@"mouseu2.png"] delay:0.25];
		upAnimation.type = kAnimationType_Repeating;
		upAnimation.state = kAnimationState_Running;
        
        //Right Animation
		[rightAnimation addFrameWithImage:[test imageForKey:@"mouser1.png"] delay:0.25];
		[rightAnimation addFrameWithImage:[test imageForKey:@"mouser2.png"] delay:0.25];
		rightAnimation.type = kAnimationType_Repeating;
		rightAnimation.state = kAnimationState_Running;
        
        //Down Animation
		[downAnimation addFrameWithImage:[test imageForKey:@"moused1.png"] delay:0.25];
		[downAnimation addFrameWithImage:[test imageForKey:@"moused2.png"] delay:0.25];
		downAnimation.type = kAnimationType_Repeating;
		downAnimation.state = kAnimationState_Running;
        
        // Set the actors location to the vector location which was passed in
        tileLocation.x = aLocation.x;
        tileLocation.y = aLocation.y;
        
        lifeSpanTimer = 0;
        
        // Set the default direction of the player
        soundDelta = 0;
        // Set the entitu state to idle when it is created
        state = kEntityState_Idle;
    }
    return self;
}

#pragma mark -
#pragma mark Update

#define SWORD_LIFE_SPAN 30.0f

- (void)updateWithDelta:(GLfloat)aDelta scene:(AbstractScene*)aScene {
    
	// Record the current position of the axe
    
    if(lifeSpanTimer > SWORD_LIFE_SPAN) {
        state = kEntityState_Dead;

    }

    switch (state) {
        case kEntityState_Alive:
            lifeSpanTimer += aDelta;
            soundDelta -= aDelta;
            turnDelta -= aDelta;

			// Take a copy of the current location so that we can move the axe back to this
			// location if there is a collision
///
            // Grab the scene that has been passed in
            scene = (GameScene*)aScene;
            tileLocation = pixelToTileMapPosition(pixelLocation);

            // Update the x position of the sword
			pixelLocation.x += (85 * cosf(DEGREES_TO_RADIANS( angle))) * aDelta;
			// Convert the tile position to the pixel position ready for the collision checks
			CGRect bRect = [self movementBounds];
			BoundingBoxTileQuad bbtq = getTileCoordsForBoundingRect(bRect, CGSizeMake(kTile_Width, kTile_Height));
			
			// Check to see if moving the axe in along the a-axis causes it to collide with a blocked tile
            if([scene isBlocked:bbtq.x1 y:bbtq.y1] ||
               [scene isBlocked:bbtq.x2 y:bbtq.y2] ||
               [scene isBlocked:bbtq.x3 y:bbtq.y3] ||
               [scene isBlocked:bbtq.x4 y:bbtq.y4]) {
				// Check to see if the axe is moving up or down the screen and reflect the
				// angle as necessary in the x-axis.  The values below are radians
                
                state = kEntityState_Dead;
                [sharedSoundManager stopSoundWithKey:@"mouse"];

            } else {
				// Moving along the x-axis did not cause a collision so now do the same along the y-axis
				pixelLocation.y += (85 * sinf(DEGREES_TO_RADIANS( angle))) * aDelta;
				CGRect bRect = [self movementBounds];
				BoundingBoxTileQuad bbtq = getTileCoordsForBoundingRect(bRect, CGSizeMake(kTile_Width, kTile_Height));
				if([scene isBlocked:bbtq.x1 y:bbtq.y1] ||
				   [scene isBlocked:bbtq.x2 y:bbtq.y2] ||
				   [scene isBlocked:bbtq.x3 y:bbtq.y3] ||
				   [scene isBlocked:bbtq.x4 y:bbtq.y4]) {
					state = kEntityState_Dead;
                    [sharedSoundManager stopSoundWithKey:@"mouse"];
				}
			}
///
            if(angle == 0)
                currentAnimation = rightAnimation;
            else if(angle == 90)
                currentAnimation = upAnimation;
            else if(angle == 180)
                currentAnimation = leftAnimation;
            else
                currentAnimation = downAnimation;
            [currentAnimation updateWithDelta:aDelta];
            // Grab the scene that has been passed in
            scene = (GameScene*)aScene;
            energyDrain = 1;
			
            // Update the timer and rotate the axe image
            
            
            // If the timer exceeds the defined time then set the entity state
            // to idle
            if(lifeSpanTimer > SWORD_LIFE_SPAN) {
                state = kEntityState_Idle;
                tileLocation = CGPointMake(0, 0);
                lifeSpanTimer = 0;
            }
           // tileLocation.x += (4.5 * aDelta) * cos(DEGREES_TO_RADIANS(angle));  //a little faster than normal enemies
           // tileLocation.y += (4.5 * aDelta) * sin(DEGREES_TO_RADIANS(angle));
			
            break;
        default:
            tileLocation = scene.player.tileLocation;
            turnDelta = .5;
            break;
    }
}

#pragma mark -
#pragma mark Rendering

- (void)render {
    if(state == kEntityState_Alive) {
		[super render];
        [currentAnimation renderCenteredAtPoint:CGPointMake(pixelLocation.x, pixelLocation.y)];
	}
    
}

#pragma mark -
#pragma mark Collision & Bounding

- (CGRect)collisionBounds {
	return CGRectMake(pixelLocation.x - 8, pixelLocation.y - 8, 16, 16);
}

- (CGRect)movementBounds {
	return CGRectMake(pixelLocation.x - 8, pixelLocation.y - 8, 16, 16);
}

#pragma mark -
#pragma mark Encoding

- (id)initWithCoder:(NSCoder *)aDecoder {
	[self initWithTileLocation:CGPointMake(0, 0)];
	tileLocation = [aDecoder decodeCGPointForKey:@"position"];
	lifeSpanTimer = [aDecoder decodeFloatForKey:@"lifeSpanTimer"];
	state = [aDecoder decodeIntForKey:@"state"];
    
	// Calculate the pixel position of the weapon
	pixelLocation.x = tileLocation.x * kTile_Width;
	pixelLocation.y = tileLocation.y * kTile_Height;
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeCGPoint:tileLocation forKey:@"position"];
	[aCoder encodeFloat:lifeSpanTimer forKey:@"lifeSpanTimer"];
	[aCoder encodeInt:state forKey:@"state"];
	[aCoder encodeFloat:image.rotation forKey:@"imageRotation"];
}

#pragma mark -
#pragma mark turnRight

-(void)turnRight{
    if(turnDelta <= 0){
        switch((int)angle){
            case 90:
            case 180:
            case 270:
                angle -= 90.0;
                break;
            case 0:
                angle = 270;
            default:
                angle = 270;
                break;
        
        }
        turnDelta = 0.5;
    }
}

@end
