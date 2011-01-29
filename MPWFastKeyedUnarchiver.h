//
//  MPWFastKeyedUnarchiver.h
//  MPWXmlKit
//
//  Created by Marcel Weiher on 1/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MPWFastKeyedUnarchiver : NSCoder {
	id data;
	BOOL isDecoding;
	const void *allocator;
	id	intKeyCache;
	id	objectKeyCache;
	
	id	*decodeBase;
	int	decodeCount;
	int	decodeCurrent;
}

@end
