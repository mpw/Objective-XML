//
//  MPWMASONParser.h
//  ObjectiveXML
//
//  Created by Marcel Weiher on 12/29/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWXmlAppleProplistReader.h"

@class MPWPListBuilder,MPWSmallStringTable;

@interface MPWMASONParser : MPWXmlAppleProplistReader {
	MPWPListBuilder *builder;
	BOOL inDict;
	BOOL inArray;
	MPWSmallStringTable *commonStrings;
}

@end
