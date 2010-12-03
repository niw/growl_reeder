#import "GrowlReeder.h"
#import <objc/runtime.h>

#define NEW_ARTICLE_NOTIFICATION_NAME @"New Article"

@implementation GrowlReeder
+ (void)load {
	Class class = objc_getClass("ReaderFetchItems");
	Method originalMethod = class_getInstanceMethod(class, @selector(item:));
	Method hookMethod = class_getInstanceMethod(class, @selector(growl_reeder_item:));
	method_exchangeImplementations(originalMethod, hookMethod);

	[GrowlApplicationBridge setGrowlDelegate:[self sharedInstance]];

	NSLog(@"GrowlReeder loaded");
}

#pragma mark -
#pragma mark Instantiations

+ (GrowlReeder *)sharedInstance {
	static id sharedInstance = nil;
	if(! sharedInstance) {
		sharedInstance = [[self alloc] init];
	}
	return sharedInstance;
}

- (void)dealloc {
	[super dealloc];
}

#pragma mark -
#pragma mark Utilities

- (NSImage *)displayIconForFeedId:(NSString *)feedId {
	Class readerUserMetaClass = objc_getClass("ReaderUser");
	id user = objc_msgSend(readerUserMetaClass, @selector(defaultUser));
	if(user) {
		id store = objc_msgSend(user, @selector(store));
		id feed = objc_msgSend(store, @selector(feedWithId:), feedId);
		if(feed) {
			NSImage *icon = objc_msgSend(feed, @selector(displayIcon));
			return icon;
		}
	}
	return nil;
}

- (void)growl:(NSString *)message withTitle:(NSString *)title withIconData:(NSData *)iconData {
	[GrowlApplicationBridge notifyWithTitle:title
								description:message
						   notificationName:NEW_ARTICLE_NOTIFICATION_NAME
								   iconData:iconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

- (void)growlReaderItem:(NSDictionary *)item {
	NSArray *categories = [item valueForKey:@"categories"];
	BOOL read = NO;
	for(id obj in categories) {
		if([obj isKindOfClass:[NSString class]]) {
			NSString *category = (NSString *)obj;
			if([category hasSuffix:@"/read"]) {
				read = YES;
				break;
			}
		}
	}

	if(! read) {
		NSDictionary *origin = [item valueForKey:@"origin"];
		NSData *iconData = nil;
		NSImage *icon = [self displayIconForFeedId:[origin valueForKey:@"streamId"]];
		if(icon) {
			iconData = [NSData dataWithData:[icon TIFFRepresentation]];
		}

		[self growl:[item valueForKey:@"title"] withTitle:[origin valueForKey:@"title"] withIconData:iconData];
	}
}

#pragma mark -
#pragma mark GrowlApplicationBridgeDelegate

- (NSDictionary *)registrationDictionaryForGrowl {
	NSArray *allNotifications = [NSArray arrayWithObjects:NEW_ARTICLE_NOTIFICATION_NAME, nil];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			allNotifications, GROWL_NOTIFICATIONS_ALL,
			allNotifications, GROWL_NOTIFICATIONS_DEFAULT,
			nil];
}
@end

@implementation NSObject (GrowlReeder)

#pragma mark -
#pragma mark ReaderFetchItems

- (void)growl_reeder_item:(id)item {
#ifdef DEBUG
	NSLog(@"GrowlReeder: -growl_reeder_item:%@", item);
#endif

	[[GrowlReeder sharedInstance] growlReaderItem:item];
	[self growl_reeder_item:item];
}
@end