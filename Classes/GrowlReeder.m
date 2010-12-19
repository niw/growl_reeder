#import "GrowlReeder.h"
#import <objc/runtime.h>

#define NEW_ARTICLE_NOTIFICATION_NAME @"New Article"
#define MAX_NOTIFICATIONS_AT_ONCE 5

@implementation GrowlReeder
+ (void)load {
	{
		Class class = objc_getClass("ReaderFetchItems");
		Method originalMethod = class_getInstanceMethod(class, @selector(item:));
		Method hookMethod = class_getInstanceMethod(class, @selector(growl_reeder_item:));
		method_exchangeImplementations(originalMethod, hookMethod);
	}
	{
		Class class = objc_getClass("ReederMacAppDelegate");
		Method originalMethod = class_getInstanceMethod(class, @selector(readerDidSync:));
		Method hookMethod = class_getInstanceMethod(class, @selector(growl_reeder_readerDidSync:));
		method_exchangeImplementations(originalMethod, hookMethod);
	}

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

- (id)init {
	self = [super init];
	if(self) {
		items = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[items release];
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

- (void)growlItems {
	int i, count = [items count];
	for(i = 0; i < count && i < MAX_NOTIFICATIONS_AT_ONCE; i++) {
		NSDictionary *item = [items objectAtIndex:i];

		NSDictionary *origin = [item valueForKey:@"origin"];
		NSData *iconData = nil;
		NSImage *icon = [self displayIconForFeedId:[origin valueForKey:@"streamId"]];
		if(icon) {
			iconData = [NSData dataWithData:[icon TIFFRepresentation]];
		}

		[self growl:[item valueForKey:@"title"] withTitle:[origin valueForKey:@"title"] withIconData:iconData];
	}

	int remains = count - i;
	if(remains > 0) {
		[self growl:[NSString stringWithFormat:@"And %d articles", remains] withTitle:@"Reeder" withIconData:nil];
	}

	[items removeAllObjects];
}

- (void)addReederItem:(NSDictionary *)item {
	[items addObject:item];
}

- (void)fetchedReederItem:(NSDictionary *)item {
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
		[self addReederItem:item];
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

	[[GrowlReeder sharedInstance] fetchedReederItem:item];
	[self growl_reeder_item:item];
}

- (void)growl_reeder_readerDidSync:(NSNotification *)notification {
#ifdef DEBUG
	NSLog(@"GrowlReeder: -growl_reeder_readerDidSync:%@", notification);
#endif
	if([[notification name] isEqualToString:@"ReaderDidSync"]) {
		[[GrowlReeder sharedInstance] growlItems];
	}
	[self growl_reeder_readerDidSync:notification];
}
@end