#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>

@interface GrowlReeder : NSObject<GrowlApplicationBridgeDelegate> {
}
+ (void)load;
+ (GrowlReeder *)sharedInstance;
- (void)growlReaderItem:(NSDictionary *)item;
@end