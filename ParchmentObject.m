//
//  GeneralParchmentTop.m
//  SLQTSOR
//
//  Created by Mike Daley on 25/11/2009.
//  Copyright 2009 Michael Daley. All rights reserved.
//

#import "ParchmentObject.h"
#import "PackedSpriteSheet.h"
#import "Image.h"
#import "Animation.h"
#import "SpriteSheet.h"

@implementation ParchmentObject


- (void)dealloc {
    [image release];
	[particles release];
    [super dealloc];
}


- (id) initWithTileLocation:(CGPoint)aTileLocaiton type:(int)aType subType:(int)aSubType {
    self = [super init];
    if (self != nil) {
		
		// Add 0.5 to the tile location so that the object is in the middle of the square
		// as defined in the tile map editor
		tileLocation.x = aTileLocaiton.x + 0.5f;
		tileLocation.y = aTileLocaiton.y + 0.5f;
        pixelLocation = tileMapPositionToPixelPosition(tileLocation);
        type = aType;
		subType = aSubType;
		
		// Set up the particle emitter
		particles = [[ParticleEmitter alloc] initParticleEmitterWithFile:@"parchmentEmitter.pex"];
		particles.sourcePosition = Vector2fMake(pixelLocation.x, pixelLocation.y);
		
		// Set up the parchment images
        PackedSpriteSheet *pss = [PackedSpriteSheet packedSpriteSheetForImageNamed:@"atlas.png" controlFile:@"coordinates" imageFilter:GL_LINEAR];

        switch (subType) {
			case kObjectSubType_ParchmentTop:
				image = [[[pss imageForKey:@"item_parchment1.png"] imageDuplicate] retain];
				break;
				
			case kObjectSubType_ParchmentMiddle:
				image = [[[pss imageForKey:@"item_parchment2.png"] imageDuplicate] retain];
				break;

			case kObjectSubType_ParchmentBottom:
				image = [[[pss imageForKey:@"item_parchment3.png"] imageDuplicate] retain];
				break;
				
			default:
				break;
		}
		scaleUp = YES;
    }
    return self;
}

- (void)updateWithDelta:(float)aDelta scene:(AbstractScene *)aScene {

	// If the parchment is active then update the particle emiter located with the parchment and also scale
	// the parchment up and down to make it pulse.
	if (state == kObjectState_Active) {
		particles.sourcePosition = Vector2fMake(pixelLocation.x, pixelLocation.y);
		[particles updateWithDelta:aDelta];
		
		Scale2f scale = image.scale;
		if (scaleUp) {
			scale.x += 0.5 * aDelta;
			scale.y += 0.5 * aDelta;
		} else {
			scale.x -= 0.5 * aDelta;
			scale.y -= 0.5 * aDelta;
		}
		
		image.scale = scale;
		if (scale.x > 1.2) {
			scaleUp = NO;
		}
		
		if (scale.x < 1) {
			scaleUp = YES;
		}
	}
}

- (void)render {
    [image renderCenteredAtPoint:CGPointMake(pixelLocation.x, pixelLocation.y)];

	// Only render the particles of the obejct if its not in inventory.
	if (state == kObjectState_Active)
		[particles renderParticles];
	[super render];
}

- (CGRect)collisionBounds { 
    return CGRectMake(pixelLocation.x - 10, pixelLocation.y - 10, 20, 20);
}

- (void)checkForCollisionWithEntity:(AbstractEntity *)aEntity {
	
	if ([aEntity isKindOfClass:[Player class]] && state == kObjectState_Active) {
		if (CGRectIntersectsRect([self collisionBounds], [aEntity collisionBounds])) {
			isCollectable = YES;
		} else {
			isCollectable = NO;
		}
	}
}

@end
