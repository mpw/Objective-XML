//
//  MPWFeedItem.m
//  ObjectiveXML
//
//  Created by Marcel Weiher on 1/3/11.
//  Copyright 2011 Marcel Weiher. All rights reserved.
//

#import "MPWFeedItem.h"
#import "mpwfoundation_imports.h"


@implementation MPWFeedItem

objectAccessor( NSString*, guid, setGuid )
objectAccessor( NSString*, title, setTitle )
objectAccessor( NSString*, category, setCategory )
objectAccessor( NSString*, link, setLink )
objectAccessor( NSString*, imageLink, setImageLink )
objectAccessor( NSString*, pubDate, setPubDate )
objectAccessor( NSDictionary*, remainder, setRemainder )

-(void)dealloc
{
	[guid release];
	[title release];
	[category release];
	[link release];
	[imageLink release];
	[pubDate release];
	[super dealloc];
}

-description {
	return [NSString stringWithFormat:@"<%@:%p: title: %@ guid: %@ category: %@ link: %@ date: %@ remainder: %@>",
			[self class],self,[self title],[self guid],[self category],[self link],[self pubDate],[self remainder]];
}

@end


