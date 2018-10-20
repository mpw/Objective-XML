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


-(void)setLink:(NSString*)aLink
{
	MPWAtomLink* link=[[[MPWAtomLink alloc] init] autorelease];
	[link setHref:aLink];
	[self setLinks:[NSMutableArray arrayWithObject:link]];
}

-(NSString*)link
{
	return [[[self links] objectAtIndex:0] href];
}

-(void)dealloc
{
	[_guid release];
	[_title release];
	[_category release];
	[_links release];
	[_imageLink release];
	[_pubDate release];
	[super dealloc];
}

-description {
	return [NSString stringWithFormat:@"<%@:%p: title: %@ guid: %@ category: %@ link: %@ date: %@ remainder: %@>",
			[self class],self,[self title],[self guid],[self category],[self link],[self pubDate],[self remainder]];
}

@end


