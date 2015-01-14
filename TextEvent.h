//
//  TextEvent.h
//  Silicon Cog
//
//  Created by Robert Payne on 2/15/14.
//  Copyright (c) 2014 Robert Payne. All rights reserved.
//

#import "AbstractEntity.h"
@class GameScene;
@interface TextEvent : AbstractEntity{
    NSMutableArray *textboxes;
    NSMutableArray *linesOfText;
    CGRect bounds;
    
}
//Public interface
- (id)initWithTileLocation:(CGPoint)aLocation withWidth:(CGFloat) aWidth withHeight:(CGFloat)aHeight;
- (void)addString:(NSString*)textLine;
- (void)turnIntoTextBoxes;
- (BOOL)isEmpty;
- (id)getNextTextBox;
- (CGRect)getCollisionBounds; 

@end
