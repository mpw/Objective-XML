//
//  MPWFeedItem.h
//  ObjectiveXML
//
//  Created by Marcel Weiher on 1/3/11.
//  Copyright 2011 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MPWFeedItem : NSObject
{
	NSString		*guid;
	NSString		*title;
	NSString		*category;
	NSString		*link;
	NSString		*imageLink;
	NSString		*pubDate;
	NSDictionary	*remainder;
}

-(NSString*)guid;
-(NSString*)title;
-(NSString*)category;
-(NSString*)link;
-(NSString*)pubDate;
-(NSDictionary*)remainder;


@end

