//
//  MPWFastKeyedArchiver.h
//  MPWXmlKit
//
//  Created by Marcel Weiher on 1/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MPWFastKeyedArchiver : NSCoder {
	NSMutableData *data;
	id	stream;
	BOOL decoding;
}



@end
