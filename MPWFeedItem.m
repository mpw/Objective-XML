//
//  MPWFeedItem.m
//  ObjectiveXML
//
//  Created by Marcel Weiher on 1/3/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import "MPWFeedItem.h"
#import "mpwfoundation_imports.h"
#import "MPWAtomLink.h"

@implementation MPWFeedItem

objectAccessor( NSString, guid, setGuid )
objectAccessor( NSString, title, setTitle )
objectAccessor( NSString, category, setCategory )
objectAccessor( NSArray, links, setLinks )
objectAccessor( NSString, imageLink, setImageLink )
objectAccessor( NSString, pubDate, setPubDate )
objectAccessor( NSDictionary, remainder, setRemainder )

-(void)setLink:(NSString*)aLink
{
	MPWAtomLink* link=[[[MPWAtomLink alloc] init] autorelease];
	[link setHref:aLink];
	[self setLinks:[NSArray arrayWithObject:link]];
}

-(NSString*)link
{
	return [[[self links] objectAtIndex:0] href];
}

-(void)dealloc
{
	[guid release];
	[title release];
	[category release];
	[links release];
	[imageLink release];
	[pubDate release];
	[super dealloc];
}

-description {
	return [NSString stringWithFormat:@"<%@:%p: title: %@ guid: %@ category: %@ link: %@ date: %@ remainder: %@>",
			[self class],self,[self title],[self guid],[self category],[self link],[self pubDate],[self remainder]];
}

@end


