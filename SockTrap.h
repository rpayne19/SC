//
//  SockTrap.h
//  Silicon Cog
//
//  Created by Robert Payne on 2/15/14.
//  Copyright (c) 2014 Robert Payne. All rights reserved.
//

#import "AbstractEntity.h"

@class GameScene;
@class GameController;

@interface SockTrap : AbstractEntity
{
    Image *sockImage;
    float lifeSpanTimer;	// Accumulates the time the axe is alive.  Used as a timer
}
@property (nonatomic, assign) float lifeSpanTimer;
@end
