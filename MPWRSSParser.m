//
//  MPWRSSParser.m
//  ObjectiveXML
//
//  Created by Marcel Weiher on 1/3/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import "MPWRSSParser.h"
#import "MPWMAXParser.h"
#import "MPWFeedItem.h"
#import "MPWFeed.h"
#import "AccessorMacros.h"
#import "MPWXmlAttributes.h"

@implementation MPWRSSParser

#define titleKey @"title"
#define linkKey @"link"
#define descriptionKey @"description"



objectAccessor( MPWMAXParser, xmlparser, setXmlparser )
objectAccessor( NSMutableArray, items, setItems )
objectAccessor( NSDictionary, headerItems, setHeaderItems )
scalarAccessor( Class, feedClass , setFeedClass )
scalarAccessor( Class, feedItemClass , setFeedItemClass )


-(void)createParser
{
	[self setXmlparser: [MPWMAXParser parser]];
	[[self xmlparser] setHandler:self forElements:[NSArray arrayWithObjects:@"rss",@"item",@"channel",@"title",@"enclosure",nil] inNamespace:nil
				prefix:@"" map:nil];
	[[self xmlparser] setUndefinedTagAction:MAX_ACTION_PLIST];
#if 0
	[[self xmlparser] handleElement:@"channel" withBlock:^(id elements, id attributes, id parser) {
			//	NSLog(@"got channel"); 
			[self setHeaderItems:[elements asDictionary]];
			return nil;
	}];
#endif	
}

-init
{
	self=[super init];
	return self;
}

-parsedData:(NSData*)data
{
	[self createParser];
	[self setItems:[NSMutableArray array]];
	[self setHeaderItems:[NSMutableDictionary dictionary]];
	id feed=[[self xmlparser] parsedData:data];
	return feed;
}

-defaultElement:(MPWXMLAttributes*)children attributes:(MPWXMLAttributes*)attributes parser:(MPWMAXParser*)parser
{
	return [parser buildPlistWithChildren:children attributes:attributes parser:parser];
}	

-channelElement:(MPWXMLAttributes*)children attributes:(MPWXMLAttributes*)attributes parser:parser
{
//	NSLog(@"got channel"); 
	[self setHeaderItems:[children asDictionary]];
	return nil;
}

-(NSArray*)getItemKeys
{
	return [NSArray arrayWithObjects:
			@"guid",@"title",@"category",@"link",
			@"pubDate",nil];
}

-(NSArray*)itemKeys
{
	static NSArray *keys=nil;
	if ( !keys ) {
		keys=[[self getItemKeys] retain];
	}
	return keys;
}

-(NSSet*)itemKeySet {
	static NSSet *keys=nil;
	if ( !keys ) {
		keys=[[NSSet setWithArray:[self itemKeys]] retain];
	}
	return keys;
}

// -(Class)feedItemClass { return [MPWFeedItem class]; }

-itemElement:children attributes:attributes parser:parser
{
	MPWFeedItem *item=[[[self feedItemClass] alloc] init];
	for ( NSString *key in [self itemKeys] ) {
		[item setValue:[children objectForKey:key] forKey:key];
	}
	[item setRemainder:[children asDictionaryExcludingKeys:[self itemKeySet]]];
	[items addObject:[item autorelease]];
//	NSLog(@"got an item");
	return nil;
}

-rssElement:children attributes:attributes parser:parser
{
//	NSLog(@"<rss>  feedClass: %@",[self feedClass]);
	id result=[[[self feedClass] alloc] initWithVersion:[attributes objectForKey:@"version"]
												  items:[self items]
												 header:[self headerItems]];
	return result;
}


@end
