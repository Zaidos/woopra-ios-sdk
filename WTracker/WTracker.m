//
//  WTracker.m
//  WTracker
//
//  Created by Woopra on 1/23/13.
//
//

#import "WTracker.h"
#import "WPinger.h"

static NSString* const WEventEndpoint = @"http://www.woopra.com/track/ce/";

@implementation WTracker

@synthesize domain, idleTimeout, pingEnabled, visitor, referer;

static WTracker* gSingleton = nil;
static WPinger* gPinger = nil;

+ (WTracker*)sharedInstance
{
	if (nil == gSingleton)
	{
		gSingleton = [[WTracker alloc] init];
		gPinger = [[WPinger alloc] initWithTracker:gSingleton];

		// create dummy visitor object to track 'anonimous' events
		gSingleton.visitor = [WVisitor anonymousVisitor];
	}
	
	return gSingleton;
}

- (id)init
{
	self = [super init];
	if (!self) return nil;
	
	// default timeout value for Woopra service
	self.idleTimeout = 30.0;
	
	return self;
}


- (BOOL)trackEvent: (WEvent*)event
{
	// check parameters
	if (nil == self.domain)
	{
		NSLog(@"WTracker.domain property must be set before [WTracker trackEvent:] invocation. Ex.: tracker.domain = mywebsite.com");
		return FALSE;
	}
	
	if (nil == self.visitor)
	{
		NSLog(@"WTracker.visitor property must be set before [WTracker trackEvent:] invocation");
		return FALSE;
	}
	
	NSMutableString* parameters = [NSMutableString stringWithFormat:@"?host=%@&cookie=%@&response=xml&timeout=%d",
								   self.domain, self.visitor.cookie, (int)(self.idleTimeout * 1000)];
	if (self.referer)
		[parameters appendFormat:@"&referer=%@", self.referer];
	
	// Add visitors properties
	NSDictionary* prop = self.visitor.properties;
	for (NSString* k in prop)
		[parameters appendFormat:@"&cv_%@=%@", k, prop[k]];
	
	// Add Event Properties
	prop = event.properties;
	for (NSString* k in prop)
		[parameters appendFormat:@"&ce_%@=%@", k, prop[k]];
	
	// submit asynchronous track request
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:
									[NSURL URLWithString: [[WEventEndpoint stringByAppendingString:parameters] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	[NSURLConnection connectionWithRequest:request delegate:self];
	
	return TRUE;
}

- (BOOL)trackEventNamed:(NSString*)eventName
{
	return [self trackEvent: [WEvent eventWithName:eventName]];
}

@end
