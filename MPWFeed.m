/*
	RSS.m
	A class for reading RSS feeds.

	Created by Brent Simmons on Wed Apr 17 2002.
	Copyright (c) 2002 Brent Simmons. All rights reserved.
	Extensively rewritten (almost from scratch) to use MPWXmlKit 
		by Marcel Weiher
*/


#import "MPWFeed.h"
#import "NSString+extras.h"
#import "mpwfoundation_imports.h"
#import "MPWMAXParser.h"
#import "MPWXmlAttributes.h"
#import "MPWFeedItem.h"
#import "MPWRSSParser.h"

@implementation MPWFeed


objectAccessor( NSDictionary, headerItems, setHeaderItems )
objectAccessor( NSArray, newsItems, setNewsItems )
objectAccessor( NSString, version, setVersion )
//  MAX XML parsing callbacks  


-initWithVersion:(NSString*)newVersion items:(NSArray*)newItems header:(NSDictionary*)newHeaderItems
{
	self=[super init];
	[self setVersion:newVersion];
	[self setNewsItems:newItems];
	[self setHeaderItems:newHeaderItems];
	return self;
}

-(Class)feedItemClass { return [MPWFeedItem class]; }

- (MPWFeed *) initWithData: (NSData *) rssData normalize: (BOOL) fl {
	
	id parser =[[[MPWRSSParser alloc] init] autorelease];
	[parser setFeedClass:[self class]];
	[parser setFeedItemClass:[self feedItemClass]];
	[self release];
//	NSLog(@"parser feedClass: %@",[parser feedClass]);
	self = [[parser parsedData:rssData] retain];

//	[self setNewsItems:[NSMutableArray array]];
//	[parser parse:rssData];

	return (self);
	} /*initWithData*/


- (MPWFeed *) initWithURL: (NSURL *) url normalize: (BOOL) fl {
	
	NSData *rssData=[NSData dataWithContentsOfURL:url];
	NSAssert1( rssData , @"couldn't load RSS feed '%@'",url);
	
	return [self initWithData: rssData normalize: fl];	
} 



- (void) dealloc 
{
	[headerItems release];
	[newsItems release];
	[version release];
	[super dealloc];
} 

@end


@interface NSObject(testing)

+frameworkResource:filename category:category;

@end

@implementation MPWFeed(testing)

+_parseTestFeedFile:(NSString*)filename
{
	id rssData = [self frameworkResource:filename category:@"rss"];
	return [[[self alloc] initWithData:rssData normalize: NO] autorelease];
}


+(void)testMetaobjectHeader
{
	NSDictionary *header = [[self _parseTestFeedFile:@"metaobject"] headerItems];
	IDEXPECT( [header objectForKey:@"title"], @"metablog" , @"title" );
	IDEXPECT( [header objectForKey:@"lastBuildDate"], @"Sun, 20 Apr 2008 21:13:50 +0000" , @"lastBuildDate" );
}


+(void)testMetaobjectNewsItems
{
	NSArray *newsItems = [[self _parseTestFeedFile:@"metaobject"] newsItems];
	INTEXPECT( [newsItems count], 10 , @"number of news items");
	id item1=[newsItems objectAtIndex:0];
	IDEXPECT( [item1 title], @"Higher Order Messaging backgrounded" , @"number of news items");
}

+(void)testRevision3Header
{
	NSDictionary *header = [[self _parseTestFeedFile:@"revision3-diggnation-quicktime"] headerItems];
	NSDictionary *image = [header objectForKey:@"image"];
	IDEXPECT( [header objectForKey:@"title"], @"Diggnation (Small Quicktime)" , @"title" );
//	NSLog(@"image: %@",image);
	IDEXPECT( [image objectForKey:@"url"], @"http://revision3.com/static/images/shows/diggnation/diggnation.jpg", @"image ur");
	IDEXPECT( [header objectForKey:@"itunes:explicit"], @"yes", @"itunes:explcit element");
}

+(void)testRevision3NewsItems
{
	NSArray *newsItems = [[self _parseTestFeedFile:@"revision3-diggnation-quicktime"] newsItems];
	INTEXPECT( [newsItems count], 25 , @"number of news items");
	id item1=[newsItems objectAtIndex:0];
	IDEXPECT( [item1 title], @"Diggnation - The Crazy Episode Taped Live in New York City" , @"number of news items");
//    NSLog(@"item1 remainder: %@",[item1 remainder]);
	IDEXPECT( [[[item1 remainder] objectForKey:@"enclosure"] objectForKey:@"url"], @"http://www.podtrac.com/pts/redirect.m4v/bitcast-a.bitgravity.com/revision3/web/diggnation/0154/diggnation--0154--2008-06-12studbeez--small.m4v" , @"enclosure url");
//	NSLog(@"newsItems: %@",newsItems);
}

+(void)testVersion
{
	IDEXPECT( [[self _parseTestFeedFile:@"metaobject"]  version], @"2.0" , @"verison" );
}


+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testMetaobjectHeader",
		@"testMetaobjectNewsItems",
		@"testVersion",
		@"testRevision3Header",
		@"testRevision3NewsItems",
		nil];
		
}


@end
