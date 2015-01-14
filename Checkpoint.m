//
//  Checkpoint.m
//  Silicon Cog
//
//  Created by Robert Payne on 2/18/14.
//  Copyright (c) 2014 Robert Payne. All rights reserved.
//

#import "Checkpoint.h"

@implementation Checkpoint
- (void)dealloc {
    [super dealloc];
}

#pragma mark -
#pragma mark Initialization
- (id)init{
    self = [super init];
    return self;
}
- (id)initWithTileLocation:(CGPoint)aLocation withWidth:(CGFloat) aWidth withHeight:(CGFloat)aHeight{
    [self init];
    CGPoint topLeft, topRight, bottomLeft, bottomRight;
    tileLocation = aLocation;
    topLeft = tileMapPositionToPixelPosition(CGPointMake(aLocation.x,aLocation.y));
    topRight = tileMapPositionToPixelPosition(CGPointMake(aLocation.x, aLocation.y));
    topRight.x += aWidth;
    bottomLeft = tileMapPositionToPixelPosition(CGPointMake(aLocation.x, aLocation.y));
    bottomLeft.y += aHeight;
    bottomRight = tileMapPositionToPixelPosition(CGPointMake(aLocation.x ,aLocation.y));
    bottomRight.y += aHeight;
    bottomRight.x +=aWidth;
    bounds = CGRectMake(topLeft.x, topLeft.y,topRight.x-topLeft.x, topLeft.y-bottomLeft.y);
    return self;
}

- (CGRect)getCollisionBounds{
    return bounds;
}
@end
