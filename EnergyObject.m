//
//  EnergyCake.m

#import "GameScene.h"
#import "EnergyObject.h"
#import "PackedSpriteSheet.h"
#import "Image.h"
#import "AbstractEntity.h"
#import "SoundManager.h"
#import "Player.h"

@implementation EnergyObject

- (void)dealloc {
	[image release];
	[super dealloc];
}

- (id) initWithTileLocation:(CGPoint)aTileLocaiton type:(int)aType subType:(int)aSubType fromScene:(GameScene*)aScene{
	self = [super init];
	if (self != nil) {
		type = aType;
		subType = aSubType;
        scene = aScene;
        
		// Add 0.5 to the tile location so that the object is in the middle of the square
		// as defined in the tile map editor
		tileLocation.x = aTileLocaiton.x + 0.5f;
		tileLocation.y = aTileLocaiton.y + 0.5f;
		pixelLocation = tileMapPositionToPixelPosition(tileLocation);
        PackedSpriteSheet *test = [PackedSpriteSheet packedSpriteSheetForImageNamed:@"spritePkg.png" controlFile:@"spritePkg" imageFilter:GL_NEAREST];
        
		switch (subType) {
			case kObjectSubType_Cake:
				image = [[Image alloc] initWithImageNamed:@"wetfood.png" filter:GL_NEAREST];
				energy = 14;
				break;
				
            case kObjectSubType_RFID:
                image = [[test imageForKey:@"RFID.png"] retain];
                energy = 0;
                NSMutableArray *temp2 = [[NSMutableArray alloc]init];
                [temp2 addObject:[NSString stringWithFormat:@"You got an RFID Chip!"]];
                [temp2 addObject:[NSString stringWithFormat:@"---"]];
                [temp2 addObject:[NSString stringWithFormat:@"Used to open certain doors."]];
                [temp2 addObject:[NSString stringWithFormat:@"---"]];
                [scene createTextEventAtPoint:tileLocation WithTextInArray:temp2];
                [temp2 release];
                break;
            case kObjectSubType_SockTrap:
                image = [[test imageForKey:@"sock.png"] retain];
                energy = 0;
                NSMutableArray *temp1 = [[NSMutableArray alloc]init];
                [temp1 addObject:[NSString stringWithFormat:@"You got the Sock Trap!"]];
                [temp1 addObject:[NSString stringWithFormat:@"---"]];
                [temp1 addObject:[NSString stringWithFormat:@"Cats don't like stepping on this!"]];
                [temp1 addObject:[NSString stringWithFormat:@"Press 'B' to set."]];
                [temp1 addObject:[NSString stringWithFormat:@"---"]];
                [scene createTextEventAtPoint:tileLocation WithTextInArray:temp1];
                [temp1 release];
			default:
				break;
		}
	}
	return self;
}

- (void)updateWithDelta:(float)aDelta scene:(AbstractScene *)aScene {
	
    ;
}

- (void)render {
	// Only render the object if its state is active
	if (state == kObjectState_Active) {
		[image renderCenteredAtPoint:pixelLocation];
	}
	[super render];
}

- (void)checkForCollisionWithEntity:(AbstractEntity*)aEntity {

	// Only bother to check for collisions if the entity passed in is the player
	if ([aEntity isKindOfClass:[Player class]]) {

		if (CGRectIntersectsRect([self collisionBounds], [aEntity collisionBounds])) {
			// If we have collided with the player then set the state of the object to inactive
			// and plat the eatfood sound
			state = kObjectState_Inactive;
            if(subType == kObjectSubType_SockTrap)
                [scene aquireSocktrap];
            if(subType == kObjectSubType_RFID)
                [scene aquireRFID];
			// Play the sound to signify that the player has gained energy
            [sharedSoundManager playSoundWithKey:@"powerup" location:pixelLocation];

		}
	}
}

- (CGRect)collisionBounds {
    if(subType == kObjectSubType_SockTrap || subType == kObjectSubType_RFID)
        return CGRectMake(pixelLocation.x - 16, pixelLocation.y - 16, 32, 32);
    else
        return CGRectMake(pixelLocation.x - 10, pixelLocation.y - 10, 20, 20);
}

@end
