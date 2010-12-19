#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>

@interface GrowlReeder : NSObject<GrowlApplicationBridgeDelegate> {
	NSMutableArray *items;
}
+ (void)load;
+ (GrowlReeder *)sharedInstance;
- (void)fetchedReederItem:(NSDictionary *)item;
- (void)growlItems;
@end