//
//  SockTrap.m
//  Silicon Cog
//
//  Created by Robert Payne on 2/15/14.
//  Copyright (c) 2014 Robert Payne. All rights reserved.
//

#import "SockTrap.h"
#import "GameScene.h"
#import "GameController.h"
#import "SoundManager.h"
#import "Image.h"
#import "Player.h"
#import "PackedSpriteSheet.h"
#import "Animation.h"

@implementation SockTrap



- (void)dealloc {
    [sockImage release];
    [super dealloc];
}

#pragma mark -
#pragma mark Initialization

- (id)initWithTileLocation:(CGPoint)aLocation {
    self = [super init];
	if (self != nil) {
    
        PackedSpriteSheet *test = [PackedSpriteSheet packedSpriteSheetForImageNamed:@"spritePkg.png" controlFile:@"spritePkg" imageFilter:GL_NEAREST];
        sockImage = [[test imageForKey:@"sock.png"] retain];

        // Set the actors location to the vector location which was passed in
        tileLocation.x = aLocation.x;
        tileLocation.y = aLocation.y;
        
        lifeSpanTimer = 0;
        
        // Set the entitu state to idle when it is created
        state = kEntityState_Dead;
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
            
			// Take a copy of the current location so that we can move the axe back to this
			// location if there is a collision
            ///
            // Grab the scene that has been passed in
            scene = (GameScene*)aScene;
            pixelLocation = tileMapPositionToPixelPosition(tileLocation);
            // If the timer exceeds the defined time then set the entity state
            // to idle
            if(lifeSpanTimer > SWORD_LIFE_SPAN) {
                state = kEntityState_Dead;
                tileLocation = CGPointMake(0, 0);
                lifeSpanTimer = 0;
            }
            break;
        default:
            tileLocation = scene.player.tileLocation;
            break;
    }
}

#pragma mark -
#pragma mark Rendering

- (void)render {
    if(state == kEntityState_Alive) {
		[super render];
        [sockImage renderCenteredAtPoint:pixelLocation];
	}
    
}

#pragma mark -
#pragma mark Collision & Bounding

- (CGRect)collisionBounds {
#ifdef SCB
    NSLog(@"call made to sock trap collision bounds***");
#endif
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

@end
