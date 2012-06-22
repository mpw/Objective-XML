//
//  MPWAtomParser.m
//  ObjectiveXML
//
//  Created by Marcel Weiher on 12/14/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWAtomParser.h"
#import "MPWMAXParser.h"
#import "MPWFeedItem.h"
#import "MPWAtomLink.h"

@implementation MPWAtomParser

-(NSArray*)feedItemsForXml:(NSData*)xmlData
{
	id parser = [MPWMAXParser parser];
	[parser setHandler:self forElements:[NSArray arrayWithObjects:@"feed", @"entry",@"link",nil]];
	NSArray *entries = [parser parsedData:xmlData];
//	NSLog(@"did parse to: %@",entries);
	return entries;
}

-(id)entryElement:(MPWXMLAttributes*)elements attributes:(MPWXMLAttributes*)attributes parser:parser
{
//	NSLog(@"entry element with items: %@",elements);
	MPWFeedItem *item=[[MPWFeedItem alloc] init];
	[item setTitle:[elements objectForKey:@"title"]];
	[item setLinks:[elements objectsForKey:@"link"]];
	[item setGuid:[elements objectForKey:@"id"]];
	return item;
}

-(id)linkElement:(MPWXMLAttributes*)elements attributes:(MPWXMLAttributes*)attributes parser:parser
{
//	NSLog(@"link element with attributes: %@",attributes);
	MPWAtomLink *link=[[MPWAtomLink alloc] init];
	[link setRel:[attributes objectForKey:@"rel"]];
	NSString *relativeURL=[attributes objectForKey:@"href"];
	relativeURL = [[relativeURL componentsSeparatedByString:@"&amp;"] componentsJoinedByString:@"&"];

	[link setHref:relativeURL];
	[link setType:[attributes objectForKey:@"type"]];
//	[link setRel:[attributes objectForKey:@"rel"]];
	return link;
}

-(id)feedElement:(MPWXMLAttributes*)elements attributes:(MPWXMLAttributes*)attributes parser:parser
{
//	NSLog(@"feed element: elements: %@",elements);
	return [[elements objectsForKey:@"entry"] retain];
}

@end

#import "mpwfoundation_imports.h"

@implementation MPWAtomParser(testing)

+(NSArray*)parseTestFeed:(NSString*)feedName type:(NSString*)feedType
{
	NSString *path=[[NSBundle bundleForClass:self] pathForResource:feedName ofType:feedType ];
	NSData *xmlData = [NSData dataWithContentsOfMappedFile:path];
	EXPECTNOTNIL(xmlData,@"data");
	MPWAtomParser *parser = [[[self alloc] init] autorelease];
//	NSLog(@" === parser: %@",parser);
	 return [parser feedItemsForXml:xmlData];
}

+(void)testNumberOfEntries
{
	NSArray* items=[self parseTestFeed:@"atomfeed" type:@"xml"];
	INTEXPECT( [items count],20, @"number of items in feed");
}


+(void)testBasicEntries
{
	NSArray* items=[self parseTestFeed:@"atomfeed" type:@"xml"];
	MPWFeedItem *first=[items objectAtIndex:0];
	IDEXPECT( [first title], @"Thomas Jefferson", @"first president");
	IDEXPECT( [first guid], @"tag:livescribe.com,2008-04-22:/services/community/pencast/sZNlKwVxlsRM", @"first id");
	IDEXPECT( [first guid], @"tag:livescribe.com,2008-04-22:/services/community/pencast/sZNlKwVxlsRM", @"first id");
	IDEXPECT( [[items lastObject] title], @"Glee by Dela Ahmad", @"last item title");	
}

+(void)testLinks
{
	NSArray* items=[self parseTestFeed:@"atomfeed" type:@"xml"];
	MPWFeedItem *first=[items objectAtIndex:0];
	NSArray *links=[first links];
	INTEXPECT( [links count], 6, @"number of links in first feed item");
	MPWAtomLink *firstLink=[links objectAtIndex:0];
	IDEXPECT( [firstLink rel] , @"self", @"first rel");
	IDEXPECT( [firstLink href] , @"http://www.livescribe.com/cgi-bin/WebObjects/LDApp.woa/wa/flashXML?xml=0000C0A80116000009C610000000011977FE32EB174C4D4A", @"first href");
	IDEXPECT( [firstLink type] , @"application/pcc+xml", @"first link type");
	MPWAtomLink *lastLink=[links lastObject];
	IDEXPECT( [lastLink rel] , @"strokes", @"first rel");
	IDEXPECT( [lastLink href] , @"http://www.livescribe.com/cgi-bin/WebObjects/LDApp.woa/wa/flashXML?xml=0000C0A80116000009C610000000011977FE32EB174C4D4A&page=0", @"last href");
	IDEXPECT( [lastLink type] , @"application/pcc", @"first link type");
	
}

+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testNumberOfEntries",
			@"testBasicEntries",
			@"testLinks",
			nil];
}


@end