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
    [self appendBytes:":" length:1];
}

#define INTBUFLEN 64

typedef struct {
    char buf[INTBUFLEN];
} intbuf;

static inline char *itoa( int value, intbuf *buf )
{
    char *buffer=buf->buf;
    int offset=INTBUFLEN/2;
    buffer[offset]=0;
    do {
        int next=value/10;
        int digit=value - (next*10)+'0';
        buffer[--offset]=digit;
        value=next;
    } while (value);
    return buffer+offset;
}

static inline long writeKey( char *buffer, const char *aKey, BOOL *firstPtr)
{
    char *ptr=buffer;
    long  keylen=strlen(aKey);
    if ( !*firstPtr ) {
        *firstPtr=NO;
    } else {
        *ptr++ = ',';
    }
    *ptr++ = '"';
    memcpy( ptr, aKey, keylen);
    ptr+=keylen;
    *ptr++ ='"';
    *ptr++ =':';
    return ptr-buffer;
}

-(void)writeString:aString forKey:(const char*)aKey
{
    char buffer[1000];
    long len=writeKey(buffer, aKey, firstElementOfDict + currentFirstElement);
    [self appendBytes:buffer length:len];
//    [self appendBytes:"\":" length:2];
    [self writeObject:aString];
}

-(void)writeObject:(id)anObject forKey:(id)aKey
{
    [self writeKey:aKey];
    [self writeObject:anObject];
}

-(void)writeInteger:(int)number forKey:(const char*)aKey
{
    char buffer[1000];
    long len=writeKey(buffer, aKey, firstElementOfDict + currentFirstElement);
    char *ptr=buffer+len;
    intbuf ibuf;
    char *s=itoa(number, &ibuf);
    long ilen=strlen(s);
    memcpy( ptr, s, ilen);
    ptr+=ilen;
    TARGET_APPEND(buffer, ptr-buffer);
//    [self appendBytes:buffer length:ptr-buffer];
}

-(void)beginArray
{
    TARGET_APPEND("[", 1);
}

-(void)endArray
{
    TARGET_APPEND("]", 1);
}

-(void)beginDictionary
{
    TARGET_APPEND("{", 1);
}

-(void)endDictionary
{
    TARGET_APPEND("}", 1);
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
    const char *buffer=NULL;
    char curchar;
    NSUInteger len=[anObject length];
//	NSLog(@"==== JSONriter writeString: %@",anObject);
    TARGET_APPEND("\"", 1);
    buffer=CFStringGetCStringPtr((CFStringRef)anObject, kCFStringEncodingUTF8);
    if ( buffer ) {
//        NSLog(@"got buffer: %p",buffer);
    } else {
        long maxLen= [anObject maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        buffer=alloca(maxLen+1);
//        NSLog(@"alloca buffer: %p",buffer);
//        NSAssert(buffer, @"buffer");
        BOOL success=[anObject getBytes:buffer maxLength:maxLen usedLength:&len encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, len) remainingRange:NULL];
//        NSLog(@"got bytes: %d",success);
//        NSAssert(success,@"got bytes");
//        [anObject getCString:buffer maxLength:maxLen encoding:NSUTF8StringEncoding];
    }
    const char *endptr=buffer+len;
    const char *rest=buffer;
    char *cur=rest;
//	NSLog(@"length of UTF8: %d",strlen(buffer));
	while ( (curchar = *cur) && cur < endptr ) {
        
        while (  cur < endptr && (curchar > '0')  && (curchar != '\\')) {
            cur++;
            curchar=*cur;
        }
        if (curchar==' ') {
            cur++;
            continue;
        }
        if (curchar==0) {
            break;
        }
        
		char *escapeSequence=NULL;
		char unicodeEscapeBuf[16];
		switch (curchar) {
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
				
				if ( curchar < 32 ) {
					snprintf( unicodeEscapeBuf, 8,"\\u00%02x",*cur);
					escapeSequence=unicodeEscapeBuf;
				}
				break;
		}
		if ( escapeSequence ) {
            TARGET_APPEND((char*)rest, cur-rest);
            TARGET_APPEND(escapeSequence, strlen(escapeSequence));
			cur++;
			rest=cur;
			
		} else {
			cur++;
		}
	}
    TARGET_APPEND((char*)rest,endptr-rest);
    TARGET_APPEND("\"", 1);
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

-(void)writeOnJSONStream:(MPWJSONWriter*)aStream
{
	[self writeOnPropertyList:aStream];
}


@end

#import <MPWFoundation/DebugMacros.h>

@implementation MPWJSONWriter(testing)

+(void)testWriteArray
{
	IDEXPECT( ([self _encode:[NSArray arrayWithObjects:@"hello",@"world",nil]]), 
			 @"[\"hello\",\"world\"]", @"array encode" );
}

+(void)testWriteDict
{
	NSString *expectedEncoding= @"{\"key\":\"value\", \"key1\":\"value1\"}";
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
    IDEXPECT( [self _encode:@"hello world\\\n"], @"\"hello world\\\\\\n\"", @"combined escapes");
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
