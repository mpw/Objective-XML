//
//  MPWXmlFastInfosetParser.m
//  MPWXmlKit
//
//  Created by Marcel Weiher on 10/4/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//
//
//	Note to self:  this is currently a subclass of MPWXmlParser, but
//	that won't work in the long run because of subclassing going on
//	in other dimensions, so one (or both) have to be changed to 
//	composition and/or categories.
//

#import "MPWXmlFastInfosetParser.h"
#import "MPWXmlParserTesting.h"
#import "SaxDocumentHandler.h"

#import "mpwfoundation_imports.h"

@implementation MPWXmlFastInfosetParser

#define	SKIP(n)		(curpos+=(n))

#define PARSERSELF	((NSXMLParser*)self)

-(void)skip:(int)n
{
	SKIP(n);
}

-(int)read2ByteInt
{
	int value =(curpos[0]<<8 ) + curpos[1];
	SKIP(2);
	return value;
}

-(unsigned char)readByte
{
	return *curpos++;
}

-(int)scanVersion
{
	return fiVersion=[self read2ByteInt];
}

-(int)verifyFastInfosetDocumentAndReturnHeaderLength
{
	if (  bytestart[0]==0xe0 && bytestart[1]==0 ) {
		return 2;
	}
	return 0;
}

-(BOOL)verifyFastInfosetDocument
{
	return [self verifyFastInfosetDocumentAndReturnHeaderLength]>0;
}

-(BOOL)verifyFastInfosetAndSkip
{
	int headerLen=[self verifyFastInfosetDocumentAndReturnHeaderLength];
	SKIP(headerLen);
	return headerLen > 0;
}

-stringFromBytes:(int)numBytes
{
	id result=[[[NSString alloc] initWithBytes:curpos length:numBytes encoding:NSUTF8StringEncoding] autorelease];
	SKIP(numBytes);
	return result;
}

objectAccessor( NSData*, fiData , _setFiData )

-(void)setFiData:(NSData*)xmldata
{
	[self _setFiData:xmldata];
	bytestart=[xmldata bytes];
	byteend=bytestart+[xmldata length];
	curpos=bytestart;
}

-(BOOL)hasAddtionalData		{ return optionalComponentsMask & 0x40; }
-(BOOL)hasInitialVocabulary	{ return optionalComponentsMask & 0x20; }
-(BOOL)hasNotations			{ return optionalComponentsMask & 0x10; }
-(BOOL)hasUnparsedEntities	{ return optionalComponentsMask & 0x08; }
-(BOOL)hasCharacterEncodingScheme	{ return optionalComponentsMask & 0x04; }
-(BOOL)hasStandalone		{ return optionalComponentsMask & 0x02; }
-(BOOL)hasVersion			{ return optionalComponentsMask & 0x01; }

-parseNamespace
{
	[NSException raise:@"notsupported" format:@"method %s not implemented",_cmd];
	return self;
}

-parsePrefix
{
	[NSException raise:@"notsupported" format:@"method %s not implemented",_cmd];
	return self;
}


-(int)read32BitInt
{
	[NSException raise:@"unimplemented" format:@"read32BitInt not implemented yet"];
	return 0;
}

-parseBytesStartingOnSeventhBit:(unsigned char)startByte
{
	switch ( startByte & 0x3 )  {
		case 0:
		case 1:
				return [self stringFromBytes:(startByte&0x1)+1];
				break;
		case 2:
				return [self stringFromBytes:[self readByte]+3];
				break;
		case 3:
				return [self stringFromBytes:[self read32BitInt]+265];
				break;
	}
	return nil;
}

-parseEncodedCharacterStringOnFifthBit:(unsigned char)startByte	//	C.20
{
	if ( (startByte & 0xc) == 0 ) {
		return [self parseBytesStartingOnSeventhBit:startByte];
	} else {
		[NSException raise:@"encoding-not-supperted" format:@"unsupported non-UTF-8 encoding"];
		return nil;
	}
}

-(void)parseCharacterContent:(unsigned char)startByte			//  starting on the third bit (C.15)
{
	BOOL literalCharacter=(startByte & 0x020) == 0;
	if ( literalCharacter ) {
//		BOOL addToTable=(startByte & 0x010) != 0;
		id name=[self parseEncodedCharacterStringOnFifthBit:startByte];
		[documentHandler parser:PARSERSELF foundCharacters:name];
	} else {
		[NSException raise:@"unsupported" format:@"string index not supported"];
	}
}

-parseNameStartingOnFirstBit    //  
{
	id name=nil;
	unsigned char nameDefByte=[self readByte];
	BOOL isLiteral=(nameDefByte & 0x80) == 0;
	if ( isLiteral ) {
		if ( (nameDefByte & 0x40) == 0) {
			int length=(nameDefByte&63)+1;
			name=[self stringFromBytes:length];
		} else {
			[NSException raise:@"lengthtype" format:@"length type not supported"];
		}
	} else {
		[NSException raise:@"lengthtype" format:@"non-literal names not supported"];
	}
	
	return name;
}

-(void)parseElementContent
{
	do {
		unsigned char nextByte=[self readByte];
		if ( (nextByte & 0xf0) == 0xf0 ) {
			return;
		} else if ( (nextByte & 0xc0) == 0x80 ) {
			[self parseCharacterContent:nextByte];
		} else if ( (nextByte & 0x80) == 0 ) {
			[self parseElement:nextByte];
		}
	} while ( YES );
}


-(void)parseElement:(unsigned char)startByte
{
	BOOL hasAttributes = (startByte & 0x40 ) != 0;
	if ( !hasAttributes ) {
		BOOL isLiteralQualifiedName=(startByte & 0x3c)==0x3c;
		if ( isLiteralQualifiedName ) {
#if 1
			BOOL hasPrefix = (startByte & 0x2) != 0;
			BOOL hasNamespace = (startByte & 0x1) != 0;
			id prefix,namespace,name;
			if ( hasPrefix ) {
				prefix = [self parsePrefix];
			}
			if ( hasNamespace ) {
				namespace = [self parseNamespace];
			}
			name=[self parseNameStartingOnFirstBit];
			[documentHandler parser:PARSERSELF didStartElement:name namespaceURI:nil qualifiedName:nil attributes:nil];
			[self parseElementContent];
			[documentHandler parser:PARSERSELF didEndElement:name namespaceURI:nil qualifiedName:nil ];

#endif	
		}
	}
}

-(void)scanDocument
{
	unsigned char startByte=[self readByte];
	BOOL isElement = (startByte & 0x80) == 0;
	[documentHandler parserDidStartDocument:PARSERSELF];
	if ( isElement ) {
		[self parseElement:startByte];
	
	}
	[documentHandler parserDidEndDocument:PARSERSELF];
}

-(BOOL)parse:xmldata
{
	int headerskip=0;
	[self setFiData:xmldata];
	headerskip = [self verifyFastInfosetDocumentAndReturnHeaderLength];
	if ( headerskip > 0 ) {
		SKIP(headerskip);
		fiVersion=[self scanVersion];
		optionalComponentsMask=[self readByte];
		if ( optionalComponentsMask == 0 ) {
			[self scanDocument];
		}
	} else {
		
	}
	return YES;
}

+testSelectors { return [NSArray array]; }

@end

@interface MPWFastInfoSetParserTesting : MPWXmlParserTesting
@end

@implementation MPWFastInfoSetParserTesting

+xmlResourceWithName:(NSString*)name
{
	return [self resourceWithName:name type:@"fi"];
}

+parser
{
	return [[[MPWXmlFastInfosetParser alloc] init] autorelease];
}

+(void)testVerifyFI
{
	MPWXmlFastInfosetParser* parser=[self parser];
	[parser setFiData:[self xmlResourceWithName:@"test1"]];
	NSAssert( [parser verifyFastInfosetDocument], @"test1.fi should be a fast infoset document");
	[parser skip:2];
	INTEXPECT( [parser scanVersion], 1 , @"version encoded in document");
	INTEXPECT( [parser readByte], 0 , @"optional components");
	[parser setFiData:[self resourceWithName:@"test1" type:@"xml"]];
	NSAssert( ![parser verifyFastInfosetDocument], @"test1.xml should not be a fast infoset document");
}


+(NSArray*)testSelectors
{
    return [NSArray arrayWithObjects:
 #if 0 
		@"testVerifyFI",
		@"testBasicSaxParse",
		@"testBasicSaxParseWithCharacterContent",
		@"testBasicSaxParseWithElementAndCharacterContent",

        @"testBasicSaxParseOfEmptyElement",
        @"testEmptyElementWithAttribute",
        @"testNamespaceParsingMPWXML",
#endif		
        nil];
}


@end