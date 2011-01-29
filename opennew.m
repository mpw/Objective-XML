//
//  opentester.m
//  MPWXmlKit
//
//  Created by Marcel Weiher on 4/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "MPWOpenDocumentParser.h"
#import <malloc/malloc.h>

@class NSOpenDocumentParser;

int main( int argc, char *argv[] ) {
	id pool=[NSAutoreleasePool new];
	id name = [NSString stringWithCString:argv[1]];
	id data = [NSData dataWithContentsOfFile:name];

	id reader;
	id richString;
	struct mstats after,before=mstats();
	int highWater,afterPool;
	int i;
	NSTimeInterval timeUsed;
	pool=[NSAutoreleasePool new];
	timeUsed=[NSDate timeIntervalSinceReferenceDate];
	for (i=0;i<10;i++) {
		reader = [[[NSOpenDocumentParser alloc] init] autorelease];
		richString = [[reader parseZip:data documentAttributes:nil] retain];
	}
	after=mstats();
	highWater=after.bytes_used - before.bytes_used;
	[pool release];
	timeUsed=[NSDate timeIntervalSinceReferenceDate] - timeUsed;
	after=mstats();
	afterPool=after.bytes_used - before.bytes_used;
	printf("%s %s %d bytes max %d bytes after pool %d ms real %d chars\n",rindex(argv[0],'/')+1,rindex(argv[1],'/')+1,highWater,afterPool,(int)(timeUsed*1000.0),[richString length]);
	exit(0);
	[pool release];
	return 0;
}
