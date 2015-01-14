//
//  GeneralParchmentTop.h
//  SLQTSOR
//
//  Created by Mike Daley on 25/11/2009.
//  Copyright 2009 Michael Daley. All rights reserved.
//

#import "Global.h"
#import "AbstractObject.h"
#import "ParticleEmitter.h"

@class Image;

@interface ParchmentObject : AbstractObject {

	// Image to be displayed for this object
	Image *image;
	// Is the image scaling up
	BOOL scaleUp;
	// Particle emitter
	ParticleEmitter *particles;
}

// Designated initializer
- (id) initWithTileLocation:(CGPoint)aTileLocaiton type:(int)aType subType:(int)aSubType;


@end
