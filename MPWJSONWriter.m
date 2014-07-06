//
//  MPWJSONWriter.m
//  ObjectiveXML
//
//  Created by Marcel Weiher on 12/30/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWJSONWriter.h"


@implementation MPWJSONWriter

-(void)writeKey:(NSString*)aKey
{
    [self writeString:aKey];
    [self appendBytes:": " length:2];
}

-(void)writeObject:anObject forKey:aKey
{
    [self writeIndent];
	[self writeKey:aKey];
    [self writeObject:anObject];

} 

-(void)beginArray
{
    [self appendBytes:"[ " length:2];
}

-(void)endArray
{
    [self appendBytes:"] " length:2];
}

-(void)beginDictionary
{
    [self appendBytes:"{ " length:2];
}

-(void)endDictionary
{
    [self appendBytes:"} " length:2];
}

-(void)writeArray:(NSArray*)anArray
{
//	NSLog(@"==== JSONriter writeArray: %@",anArray);
    [self beginArray];
//	[self indent];
    [self writeArrayContent:anArray];
//	[self outdent];
	[self endArray];
}

-(void)writeDictionary:(NSDictionary *)dict
{
	BOOL first=YES;
	[self beginDictionary];
	for ( NSString *key in [dict allKeys] ) {
		if ( first ) {
			first=NO;
		} else {
			[self appendBytes:", " length:2];	
		}
		[self writeObject:[dict objectForKey:key] forKey:key];
	}
	[self endDictionary];
}

-(void)writeString:(NSString*)anObject
{
	int maxLen= [anObject maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	char buffer[ maxLen ];
	char *rest=buffer;
	char *cur=rest;
//	NSLog(@"==== JSONriter writeString: %@",anObject);
    [self appendBytes:"\"" length:1];
	[anObject getCString:buffer maxLength:maxLen encoding:NSUTF8StringEncoding];

//	NSLog(@"length of UTF8: %d",strlen(buffer));
	while ( *cur ) {
		char *escapeSequence=NULL;
		char unicodeEscapeBuf[16];
		switch (*cur) {
			case '\\':
				escapeSequence="\\\\";
				break;
			case '"':
				escapeSequence="\\\"";
				break;
			case '\n':
				escapeSequence="\\n";
				break;
			case '\t':
				escapeSequence="\\t";
				break;
			case '\r':
				escapeSequence="\\r";
				break;
			default:
				
				if ( *cur < 32 ) {
					snprintf( unicodeEscapeBuf, 8,"\\u00%02x",*cur);
					escapeSequence=unicodeEscapeBuf;
				}
				break;
		}
		if ( escapeSequence ) {
			[self appendBytes:rest length:cur-rest ];
			[self appendBytes:escapeSequence length:strlen(escapeSequence)];
			cur++;
			rest=cur;
			
		} else {
			cur++;
		}
	}
	[self appendBytes:rest length:strlen(rest) ];
    [self appendBytes:"\"" length:1];
}

-(SEL)streamWriterMessage
{
	return @selector(writeOnJSONStream:);
}

-(void)writeNull
{
	[self appendBytes:"null" length:4];
}

-(void)writeInteger:(int)number
{
	[self printf:@"%d",number];
}


-(void)writeFloat:(double)number
{
	[self printf:@"%g",number];
}


//------------



@end


@implementation NSObject(jsonWriting)

-(void)writeOnJSONStream:aStream
{
	[self writeOnPropertyList:aStream];
}


@end

#import <MPWFoundation/DebugMacros.h>

@implementation MPWJSONWriter(testing)

+(void)testWriteArray
{
	IDEXPECT( ([self _encode:[NSArray arrayWithObjects:@"hello",@"world",nil]]), 
			 @"[ \"hello\",\"world\"] ", @"array encode" );
}

+(void)testWriteDict
{
	NSString *expectedEncoding= @"{ \"key\": \"value\", \"key1\": \"value1\"} ";
	NSString *actualEncoding=[self _encode:[NSDictionary dictionaryWithObjectsAndKeys:@"value",@"key",
											@"value1",@"key1",nil ]];
//	INTEXPECT( [actualEncoding length], [expectedEncoding length], @"lengths");
	
	IDEXPECT( actualEncoding, expectedEncoding, @"dict encode");
}

+(void)testWriteLiterals
{
    NSLog(@"bool %@ / %@",[NSNumber numberWithBool:YES],[[NSNumber numberWithBool:YES] class]);
	IDEXPECT( [self _encode:[NSNumber numberWithBool:YES]], @"true", @"true");
	IDEXPECT( [self _encode:[NSNumber numberWithBool:NO]], @"false", @"false");
	IDEXPECT( [self _encode:[NSNull null]], @"null", @"null");
}


+(void)testEscapeStrings
{
	IDEXPECT( [self _encode:@"\""], @"\"\\\"\"", @"quote is escaped");
	IDEXPECT( [self _encode:@"\n"], @"\"\\n\"", @"newline is escaped");
	IDEXPECT( [self _encode:@"\r"], @"\"\\r\"", @"return is escaped");
	IDEXPECT( [self _encode:@"\t"], @"\"\\t\"", @"tab is escaped");
	IDEXPECT( [self _encode:@"\\"], @"\"\\\\\"", @"backslash is escaped");
}


+(void)testUnicodeEscapes
{
	unichar thechar=1;
	IDEXPECT( [self _encode:[NSString stringWithCharacters:&thechar length:1]], @"\"\\u0001\"", @"ASCII 1 is Unicode escaped");
	thechar=2;
	IDEXPECT( [self _encode:[NSString stringWithCharacters:&thechar length:1]], @"\"\\u0002\"", @"ASCII 2 is Unicode escaped");
	thechar=27;
	IDEXPECT( [self _encode:[NSString stringWithCharacters:&thechar length:1]], @"\"\\u001b\"", @"ASCII 27 is Unicode escaped");
}

+(NSArray*)testSelectors {
	return [NSArray arrayWithObjects:
			@"testWriteString",
			@"testWriteArray",
			@"testWriteLiterals",
			@"testWriteIntegers",
			@"testWriteDict",
			@"testEscapeStrings",
			@"testUnicodeEscapes",
			nil];
}

@end
