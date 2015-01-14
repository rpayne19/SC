//
//  TextEvent.m
//  Silicon Cog
//
//  Created by Robert Payne on 2/15/14.
//  Copyright (c) 2014 Robert Payne. All rights reserved.
//

#import "TextEvent.h"
#import "Textbox.h"

@implementation TextEvent
- (void)dealloc {
	[textboxes release];
    [super dealloc];
}

#pragma mark -
#pragma mark Initialization
- (id)init{
    self = [super init];
    textboxes = [[NSMutableArray alloc] init];
    linesOfText = [[NSMutableArray alloc]init];
    return self;
}
- (id)initWithTileLocation:(CGPoint)aLocation withWidth:(CGFloat) aWidth withHeight:(CGFloat)aHeight{
    [self init];
    CGPoint topLeft, topRight, bottomLeft, bottomRight;
    
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
- (void)addString:(NSString*)textLine{
    [linesOfText addObject:textLine];
}
- (void)turnIntoTextBoxes{
    NSMutableArray *temp = [[NSMutableArray alloc]init];
    for(NSString *line in linesOfText){
        if([line isEqualToString:@"---"]){
            switch([temp count]){
                case 1:
                    [textboxes addObject:[[Textbox alloc]initWithText:[temp objectAtIndex:0]]];
                    [temp removeAllObjects];
                    break;
                case 2:
                    [textboxes addObject:[[Textbox alloc]initWIthText:[temp objectAtIndex:0] text2:[temp objectAtIndex:1]]];
                    [temp removeAllObjects];

                    break;
                case 3:
                    [textboxes addObject:[[Textbox alloc]initWithText:[temp objectAtIndex:0]text2:[temp objectAtIndex:1]text3:[temp objectAtIndex:2]]];
                    [temp removeAllObjects];
                    break;
                default:
                    NSLog(@"INCORRECT FORMATTING FOR TEXTBOX!!!");
                    [temp removeAllObjects];
            }
            
        }else{
            [temp addObject:line];
            if([temp count] == 4){
                NSLog(@"INCORRECT FORMATTING FOR TEXTBOX!!!!");
                [temp removeAllObjects];
            }
        }
    }
    [temp release];
}
- (BOOL)isEmpty{
    return [textboxes count] == 0;
}
- (id)getNextTextBox{
    Textbox *next = [textboxes objectAtIndex:0];
    [textboxes removeObjectAtIndex:0];
    return next;
}
- (CGRect)getCollisionBounds{
    return bounds;
}

@end
