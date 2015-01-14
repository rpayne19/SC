//
//  Checkpoint.h
//  Silicon Cog
//
//  Created by Robert Payne on 2/18/14.
//  Copyright (c) 2014 Robert Payne. All rights reserved.
//

#import "AbstractEntity.h"

@interface Checkpoint : AbstractEntity{
    CGRect bounds;
}
//Public interface
- (id)initWithTileLocation:(CGPoint)aLocation withWidth:(CGFloat) aWidth withHeight:(CGFloat)aHeight;
- (CGRect)getCollisionBounds;


@end
