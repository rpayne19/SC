//
//  EnergyCake.h


#import "Global.h"
#import "AbstractObject.h"

@class GameScene;
@class Image;

@interface EnergyObject : AbstractObject {
    GameScene *scene;
	Image *image;		// Image to be displayed for this object
	BOOL scaleUp;    	// Identifies if the image is scaling up or down
    
}

// Designated initializer
- (id) initWithTileLocation:(CGPoint)aTileLocaiton type:(int)aType subType:(int)aSubType fromScene:(GameScene*)scene;

@end
