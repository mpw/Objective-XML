//
//  MPWXmlFastInfosetParser.h
//  MPWXmlKit
//
//  Created by Marcel Weiher on 10/4/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import "MPWXmlParser.h"


@interface MPWXmlFastInfosetParser : MPWSAXParser {
	NSData* fiData;
	unsigned const char *bytestart;
	unsigned const char *byteend;
	unsigned const char *curpos;
	int	header;
	int fiVersion;
	unsigned char optionalComponentsMask;
}

-(void)parseElement:(unsigned char)startByte;
@end
