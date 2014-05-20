//
//  SEENetworkConnectionRepresentation.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 26.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEENetworkConnectionDocumentListItem.h"
#import "SEEConnectionManager.h"
#import "SEEConnection.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMMMBEEPSessionManager.h"
#import "TCMMMPresenceManager.h"

void * const SEENetworkConnectionRepresentationConnectionObservingContext = (void *)&SEENetworkConnectionRepresentationConnectionObservingContext;
void * const SEENetworkConnectionRepresentationUserObservingContext = (void *)&SEENetworkConnectionRepresentationUserObservingContext;
void * const SEEConnectionClearableObservingContext = (void *)&SEEConnectionClearableObservingContext;

@interface SEENetworkConnectionDocumentListItem ()
@property (nonatomic, copy) NSString *cachedUID;
@end

@implementation SEENetworkConnectionDocumentListItem

@dynamic uid;
@synthesize name = _name;
@synthesize image = _image;

- (id)init
{
    self = [super init];
    if (self) {
		[self installKVO];
		self.subline = nil;
    }
    return self;
}

- (void)dealloc
{
	[self removeKVO];
}

- (void)installKVO {
	[self addObserver:self forKeyPath:@"connection" options:0 context:SEENetworkConnectionRepresentationConnectionObservingContext];
	[self addObserver:self forKeyPath:@"user" options:NSKeyValueObservingOptionInitial context:SEENetworkConnectionRepresentationUserObservingContext];
}

- (void)removeKVO {
	[self removeObserver:self forKeyPath:@"connection" context:SEENetworkConnectionRepresentationConnectionObservingContext];
	[self removeObserver:self forKeyPath:@"user" context:SEENetworkConnectionRepresentationUserObservingContext];
}

- (void)updateSubline {
	NSMutableArray *parts = [NSMutableArray new];
	
	NSString *result = @"";
	NSString *URLString = [[TCMMMPresenceManager sharedInstance] reachabilityURLStringOfUserID:self.user.userID];
	if (URLString.length > 0) {
		[parts addObject:URLString];
	}

	if (URLString.length == 0 && self.user.isMe) {
		if (![[TCMMMPresenceManager sharedInstance] isCurrentlyReallyInvisible]  &&
			![[TCMMMBEEPSessionManager sharedInstance] isNetworkingDisabled]) {
				[parts addObject:@"Bonjour"];
		}
	}
	SEEConnection *connection = self.connection;
	if (connection.isBonjour) {
		[parts addObject:@"Bonjour"];
	} else if ([[connection.BEEPSession userInfo] objectForKey:@"isAutoConnect"]) {
		[parts addObject:@"Friendcast"];
	} else {
		NSURL *connectToURL = self.connection.URL;
		if (connectToURL && ![connectToURL.absoluteString isEqual:parts.lastObject]) {
			[parts addObject:connectToURL.absoluteString];
		}
	}
	
	result = [parts componentsJoinedByString:@" – "];
	self.subline = result;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SEENetworkConnectionRepresentationConnectionObservingContext) {
		SEEConnection *connection = self.connection;
		self.user = connection.user;
	} else if (context == SEENetworkConnectionRepresentationUserObservingContext) {
		TCMMMUser *user = self.user;
		SEEConnection *connection = self.connection;

		[self updateSubline];
		
		if (user) {
			self.name = user.name;
			self.image = user.image;
			self.cachedUID = user.userIDIncludingChangeCount;
		} else if (connection) {
			self.name = connection.URL.description;
			self.image = [NSImage imageNamed:NSImageNameNetwork];
		} else {
			self.name = NSLocalizedString(@"Unknown Person", @"");
			self.image = [NSImage imageNamed:NSImageNameUserGuest];
		}
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

+ (NSSet *)keyPathsForValuesAffectingShowsDisconnect;
{
    return [NSSet setWithObjects:@"connection", @"connection.isBonjour", nil];
}

- (BOOL)showsDisconnect
{
	if (self.connection) {
		return ! self.connection.isBonjour;
	}
	return NO;
}

- (IBAction)disconnect:(id)sender {
	SEEConnection *connection = self.connection;
	if(connection) {
		DEBUGLOG(@"InternetLogDomain", DetailedLogLevel, @"cancel");
		BOOL abort = NO;
				if ([[[connection BEEPSession] valueForKeyPath:@"channels.@unionOfObjects.profileURI"] containsObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"]) {
					abort = YES;
				}

		if (abort) {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert setMessageText:NSLocalizedString(@"OpenChannels", @"Sheet message text when user has open document connections")];
			[alert setInformativeText:NSLocalizedString(@"AbortChannels", @"Sheet informative text when user has open document connections")];
			[alert addButtonWithTitle:NSLocalizedString(@"Abort", @"Button title")];
			[alert addButtonWithTitle:NSLocalizedString(@"Keep Connection", @"Button title")];
			[[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];

			[alert beginSheetModalForWindow:[NSApp keyWindow] completionHandler:^(NSModalResponse returnCode) {
				if (returnCode == NSAlertFirstButtonReturn) {
					[connection cancel];
					[[SEEConnectionManager sharedInstance] clear];
				}
			}];
		} else {
			[connection cancel];
			[[SEEConnectionManager sharedInstance] clear];
		}
	}
}

- (NSString *)uid {
	if (self.connection) {
		return self.connection.BEEPSession.sessionID;
	}
	return self.cachedUID;
}

- (IBAction)itemAction:(id)sender {

}

@end
