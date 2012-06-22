//
//  MPWFastKeyedUnarchiver.m
//  MPWXmlKit
//
//  Created by Marcel Weiher on 1/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MPWFastKeyedUnarchiver.h"
#import "mpwfoundation_imports.h"
#import "MPWMAXParser.h"
#import "MPWXmlAttributes.h"
#import <objc/runtime.h>

@interface MPWKeyStore : MPWObject {
	id	key;
}

idAccessor_h( key, setKey )
@end

@interface MPWKeyedInteger : MPWKeyStore {
	int	intValue;
}

intAccessor_h( intValue, setIntValue )
@end

@interface MPWKeyedObject : MPWKeyStore {
	id	objectValue;
}
idAccessor_h( objectValue, setObjectValue )
@end

@implementation MPWKeyStore 
idAccessor( key,setKey )
-(void)dealloc{ [key release]; [super dealloc]; }
@end

@implementation MPWKeyedObject 

idAccessor( objectValue, setObjectValue )
-(void)dealloc{ [objectValue release]; [super dealloc]; }
@end
@implementation MPWKeyedInteger 

intAccessor( intValue, setIntValue )
@end



@implementation MPWFastKeyedUnarchiver

idAccessor( data ,setData )
idAccessor( intKeyCache, setIntKeyCache )
idAccessor( objectKeyCache, setObjectKeyCache )

-initForReadingWithData:newData
{
	self=[super init];
	[self setData:newData];
	intKeyCache = [[MPWObjectCache alloc] initWithCapacity:10 class:[MPWKeyedInteger class]];
    [intKeyCache setUnsafeFastAlloc:YES];
	objectKeyCache = [[MPWObjectCache alloc] initWithCapacity:10 class:[MPWKeyedObject class]];
    [objectKeyCache setUnsafeFastAlloc:YES];

	allocator = kCFAllocatorDefault;
	return self;
}

typedef enum {
	NSFKAttributeKey,
	NSFKAttributeClass,
	NSFKAttributeId
} NSFKAttributeTag;


typedef enum {
	NSFKElementInteger,
	NSFKElementObject
} NSFKElementTag;



-startDecoding
{
	MPWMAXParser* parser;
	isDecoding=YES;
	id parseResult;
	parser=[MPWMAXParser parser];
	[parser setHandler:self forElements:[NSArray arrayWithObjects:@"integer",@"object",nil]
				];
	[parser declareAttributes:[NSArray arrayWithObjects:@"key",@"class",@"id",nil]
				 inNamespace:nil];


	[parser parse:[self data]];
//	NSLog(@"after scan, currentObject: %@",[parser currentObject]);
//	NSLog(@"after scan, parser toplevel: %@",[parser parseResult]);
	parseResult = [[parser parseResult] objectValue];
	return parseResult;
}


-integerElement:children attributes:attrs parser:parser
{
	id *subdataPtr=[children _pointerToObjects];
	int val = [subdataPtr[0] intValue];
	id store = [intKeyCache getObject];
//	NSLog(@"integer: %d, key %@ children: %@",val,[attrs objectForTag:NSFKAttributeKey],children);
	[store setIntValue:val];
	[store setKey:[attrs objectForKey:@"key"]];
	return [store retain];
}

-defaultElement:children attributes:attrs parser:parser
{
	NSLog(@"defaultElement in fast keyed unarchiver");
	return nil;
}
// extern Class objc_lookUpClass( char *className );

-objectElement:children attributes:attrs parser:parser
{
	NSString *className=[attrs objectForKey:@"class"];
	char buffer[200];
	char *cstrClass=buffer;
	Class class;
	id obj;
	id key=nil;
	[className getCString:buffer maxLength:190 encoding:NSASCIIStringEncoding];
	buffer[[className length]]=0;
	if ( !strcmp( "NSCFArray", cstrClass )) {
		cstrClass="NSArray";
	}
//	NSLog(@"classname: %s",cstrClass);
	class=objc_lookUpClass( cstrClass );
	class = [class classForKeyedUnarchiver];
	decodeBase = [children _pointerToObjects];
	decodeCurrent = 0;
	decodeCount = [children count];
	obj = [[class alloc] initWithCoder:self];
	decodeCount = 0;
//	NSLog(@"obj when decoding: %@",obj);
	if ( nil != (key=[attrs objectForKey:@"key"]) ) {
		id store;
		store = [objectKeyCache getObject];
		[store setKey:key];
		[store setObjectValue:obj];
		obj = store;
	}
//	NSLog(@"object class: %@ key: %@ ivars: %d",[attrs objectForKey:@"class"],[attrs objectForKey:@"key"],[children count]);
	return [obj retain];
//	return nil;
}

-(int)decodeIntForKey:aKey
{
	if ( decodeCurrent < decodeCount ) {
//		NSLog(@"decode key: %@ matches current: %@ intValue: %d at %d of %d",aKey,[decodeBase[decodeCurrent] key],[decodeBase[decodeCurrent] intValue],decodeCurrent,decodeCount);
		return [decodeBase[decodeCurrent++] intValue];
	} else {
		[NSException raise:@"out of bounds" format:@"tried to decode int %d beyond end %d key %@",decodeCurrent,decodeCount,aKey];
		return 0;
	}
}

-(void)decodeValueOfObjCType:(const char*)type at:(void*)vptr
{
	void **ptr=(void**)vptr;
	if ( type ) {
		switch ( *type ) {
			case '@':
				*(id*)ptr = [self decodeObjectForKey:nil];
				break;
			case 'i':
				*(int*)ptr = [self decodeIntForKey:nil];
				break;
			default:
				NSLog(@"wanted to decode %s at %x",type,ptr);
		}
	}
}

-decodeObjectForKey:aKey
{
	BOOL isTopLevel=NO;
//	NSLog(@"will decode object for key %@",aKey);
	if (!isDecoding) {
		isTopLevel=YES;
		isDecoding=YES;
//		NSLog(@"will decode object for key %@",aKey);
		return [self startDecoding];
	} else  {
		if ( decodeCurrent < decodeCount ) {
	//		NSLog(@"decode key: %@ matches current: %@ objectValue: %@ at %d of %d",aKey,[decodeBase[decodeCurrent] key],[[decodeBase[decodeCurrent] objectValue] class],decodeCurrent,decodeCount);
			if ( aKey ) {
				return [decodeBase[decodeCurrent++] objectValue];
			} else {
				return decodeBase[decodeCurrent++];
			}
			
		} else {
			[NSException raise:@"out of bounds" format:@"tried to object %d beyond end %d key %@",decodeCurrent,decodeCount,aKey];
			return nil;
		}
	}
}

-(void)finishDecoding
{}

-(void)dealloc
{
	[data release];
	[super dealloc];
}

@end

#import "MPWFastKeyedArchiver.h"


@interface _MPWFastKeyedArchiverTestClass : MPWObject
{
        int number1,number2;
}

-initWithNumber:(int)aNumber secondNumber:(int)secondNumber;
-(int)number1;
-(int)number2;
-(void)setNumber1:(int)newNum1;
-(void)setNumber2:(int)newNum1;

@end

@implementation _MPWFastKeyedArchiverTestClass

-(int)number1 { return number1; }
-(int)number2 { return number2; }
-(void)setNumber1:(int)newNum1
{
        number1=newNum1;
}
-(void)setNumber2:(int)newNum2
{
        number2=newNum2;
}
-initWithNumber:(int)aNumber secondNumber:(int)secondNumber
{
        if ( (self=[super init]) ) {
                [self setNumber1:aNumber];
                [self setNumber2:secondNumber];
        }
        return self;
}

-(NSUInteger)hash
{
        return number1 + number2;
}

-(BOOL)isEqual:other
{
        return other==self ||
                (([other number1] == [self number1]) && ([other number2] == [self number2]));
}

-initWithCoder:(NSCoder*)keyedCoder
{
        [super init];
        [self setNumber1:[keyedCoder decodeIntForKey:@"number1"]];
        [self setNumber2:[keyedCoder decodeIntForKey:@"number2"]];
        return self;
}

-(void)encodeWithCoder:(NSCoder*)keyedCoder
{
        [keyedCoder encodeInt:number1 forKey:@"number1"];
    [keyedCoder encodeInt:number2 forKey:@"number2"];
}

@end

@implementation MPWFastKeyedUnarchiver(testing)

+(void)testTrivalArchive
{
	id testArray=[NSMutableArray array];
	NSMutableData *data=[NSMutableData data];
	id archiver=[[[MPWFastKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease];
	id unarchiver,decoded;
	[testArray addObject:[[[_MPWFastKeyedArchiverTestClass alloc] initWithNumber:42 secondNumber:24] autorelease]];
	[archiver encodeObject:testArray forKey:@"array"];
	[archiver finishEncoding];
//	NSLog(@"data: %@",data);
	unarchiver = [[[self alloc] initForReadingWithData:data] autorelease];
	decoded = [unarchiver decodeObjectForKey:@"array"];
    [unarchiver finishDecoding];

	IDEXPECT( decoded, testArray,  @"after unarchiving");
}

#if !WINDOWS
+testSelectors
{
	return [NSArray arrayWithObjects:
			 @"testTrivalArchive",
			nil];
}
#endif

@end
