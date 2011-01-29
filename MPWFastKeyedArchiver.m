//
//  MPWFastKeyedArchiver.m
//  MPWXmlKit
//
//  Created by Marcel Weiher on 1/30/08.
//  Copyright 2008. All rights reserved.
//

#import "MPWFastKeyedArchiver.h"
#import "mpwfoundation_imports.h"

@interface NSString(fastCStringContents)

-(char*)_fastCStringContents:(BOOL)whatever;

@end


@implementation MPWFastKeyedArchiver

idAccessor( data ,setData )
idAccessor( stream ,setStream )

-initForWritingWithMutableData:(NSMutableData*)newData
{
	self=[super init];
	[self setData:newData];
	[self setStream:[MPWByteStream streamWithTarget:newData]];
//	[stream writeString:@"<xml>"];

	return self;
}

-(void)setOutputFormat:(int)newFormat 
{}


-(void)encodeInt:(int)anInt forKey:aKey
{
	char buf[200];
	int len;
#if 0
	if ( aKey ) {
		len = snprintf(buf,180, "<integer key='%.*s'>%d</integer>\n",[aKey length],[aKey _fastCStringContents:NO],anInt);
	} else { 
		len = snprintf(buf,180,"<integer>%d</integer>\n",anInt);
	}
	[stream appendBytes:buf length:len];
#else
	
	[stream appendBytes:"<integer" length:8];
	if ( aKey ) {
		[stream appendBytes:" key='" length:6];
		[stream appendBytes:[aKey _fastCStringContents:NO] length:[aKey length]];
		[stream appendBytes:"'" length:1];
	}
	len=snprintf( buf, 16, "%d",anInt);
	[stream appendBytes:">" length:1];
	[stream appendBytes:buf length:len];
	[stream appendBytes:"</integer>\n" length:11];
#endif	
}

-(void)encodeValueOfObjCType:(const char*)typestring at:(void const*)vptr
{
	void **ptr=(void**)vptr;
	if (typestring && ptr ) {
		switch ( *typestring ) {
			case 'i':
			case 'I':
				[self encodeInt:*(int*)ptr forKey:nil];
				break;
			case '@':
				[self encodeObject:*(id*)ptr forKey:nil];
				break;
			default:
				[NSException raise:@"unsupported" format:@"unsupported type: %s",typestring];
		}
	}
}


-(void)encodeObject:anObject forKey:aKey
{
	const char * classString = object_getClassName( anObject );
	[stream appendBytes:"<object class='" length:15];
	[stream appendBytes:classString length:strlen(classString)];
	if ( aKey ) {
		[stream writeString:@"' key='"];
		[stream writeString:aKey];
	}
	[stream  appendBytes:"'>\n" length:3];
	[anObject encodeWithCoder:self];
	[stream appendBytes:"</object>\n" length:10];
}

-(void)finishEncoding
{
//	[stream writeString:@"</xml>"];
	[stream close];
}

-(void)dealloc
{
	[data release];
	[stream release];
	[super dealloc];
}

@end
