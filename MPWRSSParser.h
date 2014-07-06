//
//  MPWRSSParser.h
//  ObjectiveXML
//
//  Created by Marcel Weiher on 1/3/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWMAXParser;

@interface MPWRSSParser : NSObject {
	Class feedClass,feedItemClass;
	MPWMAXParser *xmlparser;
	NSMutableArray *items;
	NSDictionary	*headerItems;
}

scalarAccessor_h( Class, feedClass , setFeedClass )
scalarAccessor_h( Class, feedItemClass , setFeedItemClass )

@end
