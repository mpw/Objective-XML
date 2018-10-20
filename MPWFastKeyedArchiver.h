//
//  MPWFastKeyedArchiver.h
//  MPWXmlKit
//
//  Created by Marcel Weiher on 1/30/08.
//  Copyright 2008 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MPWFastKeyedArchiver : NSCoder {
	NSMutableData *data;
	id	stream;
	BOOL decoding;
}

-(instancetype)initForWritingWithMutableData:(NSData*)data;

@end
