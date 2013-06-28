//
//  opentester.m
//  MPWXmlKit
//
//  Created by Marcel Weiher on 4/7/08.
//  Copyright 2008 Marcel Weiher. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "MPWOpenDocumentParser.h"
#import <malloc/malloc.h>

int main( int argc, char *argv[] ) {
	id pool=[NSAutoreleasePool new];
	id name = [NSString stringWithCString:argv[1]];
	id data = [NSData dataWithContentsOfFile:name];
	id reader;
	id richString;
	int highWater,afterPool;
	struct mstats after,before=mstats();
	int i;
	NSTimeInterval timeUsed;
	pool=[NSAutoreleasePool new];
	timeUsed=[NSDate timeIntervalSinceReferenceDate];
	for (i=0;i<10;i++) {
		reader = [[[NSClassFromString( @"NSOpenDocumentReader") alloc] initWithData:data options:nil] autorelease];
		richString = [[reader attributedString] retain];
	}
	after=mstats();
	highWater=after.bytes_used - before.bytes_used;
	[pool release];
	timeUsed=[NSDate timeIntervalSinceReferenceDate] - timeUsed;
	after=mstats();
	afterPool=after.bytes_used - before.bytes_used;
	printf("%s %s %d bytes max %d bytes after pool %d ms real %d chars\n",rindex(argv[0],'/')+1,rindex(argv[1],'/')+1,highWater,afterPool,(int)(timeUsed*1000.0),[richString length]);
	exit(0);
	return 0;
}
