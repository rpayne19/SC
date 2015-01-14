//
//  Mouse.h
//  Neko Gaiden
//
//  Created by Robert Payne on 2/10/14.
//  Copyright (c) 2014 Robert Payne. All rights reserved.
//

#import "AbstractEntity.h"

@class GameScene;
@class GameController;

@interface Mouse : AbstractEntity
{
    Animation *upAnimation;
    Animation *rightAnimation;
    Animation *downAnimation;
    Animation *leftAnimation;
    Animation *currentAnimation;
    float turnDelta;
    float lifeSpanTimer;	// Accumulates the time the axe is alive.  Used as a timer
    float soundDelta;
}
@property (nonatomic, assign) float lifeSpanTimer;
-(void)turnRight;
@end
