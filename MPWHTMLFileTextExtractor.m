//
//  NSHTMLFileTextExtractor.m
//  AKCmds
//
//  Created by  on 29/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MPWHTMLFileTextExtractor.h"
#import "MPWMAXParser_private.h"
//#import "MPWXmlParser.h"
#import "MPWXmlAttributes.h"
#import "mpwfoundation_imports.h"

@implementation MPWHTMLFileTextExtractor

//idAccessor( parser, setParser )
idAccessor( string, setString )
idAccessor( title, setTitle )
intAccessor( maxLen, setMaxLen )
idAccessor( metadata, setMetadata )


-(NSString*)convertDataToStringWithCurrentEncoding:rawData
{
	return [[[NSString alloc] initWithData:rawData encoding:[self dataEncoding]] autorelease];
}

-(NSString*)encodedStringOfDataSoFar
{
	return [self convertDataToStringWithCurrentEncoding:[self string]];
}


-(void)appendCString:(const char*)cstring
{
	[[self string] appendBytes:cstring length:strlen(cstring)];
}

-(void)appendNewline
{
	[self appendCString:"\n"];
}

-(void)appendSpace
{
	[self appendCString:" "];
}



-(BOOL)handleMetaTag
{
	id metaName;
	if ( [super handleMetaTag]) {
		return YES;
	} else if ( nil != (metaName = [self htmlAttributeLowerCaseNamed:@"name"] )) {
		metaName = [metaName lowercaseString];
		id metaValue = [self convertDataToStringWithCurrentEncoding: [self htmlAttributeLowerCaseNamed:@"content"]];
		[[self metadata] setObject:metaValue forKey:metaName];
		if ( [metaName isEqual:@"robots"] && [[metaValue lowercaseString] isEqual:@"noindex"] ) {
			[self setString:@""];
			[NSException raise:@"noindex" format:@"don't index this file"];
		}
		return YES;
	}
	return NO;
}

-(BOOL)beginElement:(const char*)start length:(int)len nameLen:(int)nameLen namespaceLen:(int)namespaceLen
{
	const char *tagBase=start+1;
//	NSLog(@"beginElement: %.*s",len,start);
	if ( !inBody && len >= 4 ) {
		if ( !strncasecmp(tagBase,"body", 4 ) )  {
			inBody=YES;
			[self pushTag:@"body"];
		} else if ( !strncasecmp(tagBase,"title", 4 ) ) {
			[self pushTag:@"title"];
			inTitle=YES;
//				NSLog(@"resetting string for title");
			[self setString:[NSMutableData dataWithCapacity:30000]];
		} else if ( !strncasecmp(tagBase,"meta", 4 ) ) {
			[self handleMetaTag];
		
		}
	} else if ( inBody && nameLen > 2 ) {
		if ( !strncasecmp(tagBase,"br",2) ||  !strncasecmp(tagBase,"dt",2)||!strncasecmp(tagBase,"dd",2)  || !strncasecmp(tagBase,"li",2) ) {
			[self appendNewline];
		} else if ( nameLen >= 6 && !strncasecmp(tagBase,"script", 6 ) ) {
//			NSLog(@"start ignoring javascript");
			inScript=YES;
		} else {
//			[string appendString:@" "];
		}
	} else if ( !strncasecmp(tagBase,"p", 1 ) ) {
			[self appendNewline];
	}
	if ( _attributes ) {
		[self clearAttributes];
	}
	return YES;
}

-(BOOL)endElement:(const  char*)start length:(int)len namespaceLen:(int)namespaceLen
{
	const  char *tagBase=start+2;
	len-=3;
//	NSLog(@"endElement: %.*s len:%d",len,tagBase,len);
	if ( len >= 2 ) { 
		if ( !inBody  ) {
			if ( len == 5 && !strncasecmp(tagBase,"title", 4 ) )  {
				[self setTitle:[self encodedStringOfDataSoFar]];
//				NSLog(@"resetting string for title");
				[self setString:[NSMutableData dataWithCapacity:30000]];
				[self popTag];
				inTitle=NO;
			}
		} else if ( inBody ) {
//			NSLog(@"inbody, len==%d",len);
			if (  len == 6 && !strncasecmp(tagBase,"script", 6 ) ) {
//			NSLog(@"stop ignoring javascript");
				inScript=NO;
			} else if (len == 2 && (!strncasecmp(tagBase,"dt", 2 ) ||  !strncasecmp(tagBase,"li", 2 ) || !strncasecmp(tagBase,"p", 1 )
					||  !strncasecmp(tagBase,"td",2)||  !strncasecmp(tagBase,"th",2)) ) {
//				NSLog(@"inbody, twp character space-insert");
				[self appendNewline];
			} else 	if ( len ==4 ) {
				if ( !strncasecmp(tagBase,"body", 4 ) )  {
//					inBody=NO;
				}
			} else if ( len ==2 && tolower( tagBase[0] ) == 'h' &&
					   ( 0 <= (tagBase[1]-'0') && (tagBase[1]-'0') <= 6)  ) {
				[self appendNewline];
			}
		} 
	} else if ( len ==1 && tolower( tagBase[0] ) == 'p' ) {
		[self appendNewline];
	}
	return YES;
} 

-(NSData*)parser:aParser resolveExternalEntityName:entity systemID:systemId
{
//	NSLog(@"entity: %@",entity);
	if ( [entity isEqual:@"nbsp"] ) {
		[self appendSpace];
	} else if ( [entity isEqual:@"#39"] ) {
		[self appendSpace];
	} else if ( [entity isEqual:@"amp"] ) {
		[self appendCString:"&"];
	} else if ( [entity isEqual:@"copy"] ) {
		[self appendCString:"\251"];
	} else if ( [entity isEqual:@"eacute"] ) {
		// --- only correct for default ISOLatin1 encoding...
		[self appendCString:"\351"];
	} else if ( [entity isEqual:@"#40"] ) {
		[self appendSpace];
	} else if ( [entity hasPrefix:@"#"] ) {
		char entityValue[2]={[[entity substringFromIndex:1] intValue],0};
		[self appendCString:entityValue];

//		[string appendString:[NSString stringWithCharacters:&entityValue length:1]];
	} else {
//		NSLog(@"resolve entity: %@",entity);
	}
	return nil;
}

-(BOOL)characterDataAllowed:parser
{
	BOOL wouldSuperAllow=inFragment || [super characterDataAllowed:parser];
	return  !inScript && (inBody || inTitle || inFragment) && wouldSuperAllow;
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)characterString
{
	[string appendData:(NSData*)characterString];
}


-init
{
	self=[super init];
//	[self setParser:[MPWXmlScanner parser]];
//	[[self parser] setDelegate:self];
	[self setAutotranslateUTF8:NO];
	[self setEnforceTagNesting:NO];
	[self setIgnoreCase:YES];
	return self;
}

// [NSArray arrayWithObjects:NSTitleDocumentAttribute, NSSubjectDocumentAttribute, NSCommentDocumentAttribute, NSAuthorDocumentAttribute, NSCompanyDocumentAttribute, NSCopyrightDocumentAttribute, NSCreationTimeDocumentAttribute, NSModificationTimeDocumentAttribute, NSKeywordsDocumentAttribute, nil]


#define TITLE_KEY	@"title"

-(void)checkForHtmlFragment:someData
{
	if ( ((char*)[someData bytes])[0] != '<' ) {
		inFragment=YES;
		inBody=YES;
	}
}

-extractTextFromData:xmlHtmlData attributes:dict
{
	id result=nil;
	[self setMaxLen:10 * 1024 * 1024];
	inFragment=NO;
	inBody=NO;
	inScript=NO;
	inTitle=NO;
//	NSLog(@"will extract: %@",path);
//	NSLog(@"maxLen: %d",maxLen);
	[self setMetadata:[NSMutableDictionary dictionary]];
	[self setString:[NSMutableData dataWithCapacity:30000]];
	[self setDataEncoding:NSISOLatin1StringEncoding];
//	[self setString:nil];
	[self setDelegate:self];
	[self checkForHtmlFragment:xmlHtmlData];
	@try { 
		[self parse:xmlHtmlData];
	} @catch ( id ex ) { if ( ![[ex name] isEqual:@"noindex"] ) { NSLog(@"exception during parsing %@",ex);} }

	result=[self encodedStringOfDataSoFar];
	[self setString:nil];
	if ( [self title]) {
		[dict setObject:[self title] forKey:TITLE_KEY];
	}
	[dict addEntriesFromDictionary:[self metadata]];

	return result;
}

-extractTextFromPath:path maxLength:(int)newMaxLen attributes:dict
{
	id pool=[NSAutoreleasePool new];
	id result;
	NSData *contents = [[[NSData alloc] initWithContentsOfMappedFile:path] autorelease];
	result = [[self extractTextFromData:contents attributes:dict] retain];
	[pool release];
	return [result autorelease];
}

static id extractor=nil;

+extractTextFromPath:path maxLength:(int)maxLen attributes:dict
{
	if ( !extractor ) {
		extractor=[[self alloc] init];
	}
	return [extractor extractTextFromPath:path maxLength:maxLen attributes:dict];
}

-(void)dealloc
{
	[string release];
	[metadata release];
	[super dealloc];
}

@end


@interface NSObject(doTest)

+(void)doTest:testName withTest:testObject;

@end

#ifndef MPWXmlCoreOnly

@implementation MPWHTMLFileTextExtractor(testing)


+(void)verifyThatResultOfExtracting:data  equals:expectedResult title:expectedTitle testName:testName
{
	id extractor = [[[self alloc] init] autorelease];
	NSMutableDictionary *dict=[NSMutableDictionary dictionary];
	id actualResult=[extractor extractTextFromData:data attributes:dict];
	id errorString = [NSString stringWithFormat:@"test: '%@' extracting from '%@'",testName,[data stringValue]];
	IDEXPECT( actualResult, expectedResult,errorString );
	if ( expectedTitle ) {
		IDEXPECT( [dict objectForKey:TITLE_KEY], expectedTitle, errorString );
	}
}

+(NSDictionary*)attributesDictionaryForData:data
{
	id extractor = [[[self alloc] init] autorelease];
	NSMutableDictionary *dict=[NSMutableDictionary dictionary];
	[extractor extractTextFromData:data attributes:dict];
	return dict;
}

+(void)verifyThatResultOfExtractingString:(NSString*)sourceString  equals:expectedResult title:expectedTitle testName:testName
{
	id data=[sourceString dataUsingEncoding:NSISOLatin1StringEncoding];
	[self verifyThatResultOfExtracting:data  equals:expectedResult title:expectedTitle testName:testName];
}

+(void)testExtractXMLorHTMLwithPlainTextTestResult:testName
{
	id original,expectedExtracted;
	original = [self frameworkResource:testName category:@"html"];
	expectedExtracted=[NSString stringWithContentsOfFile:[self frameworkPath:[testName stringByAppendingString:@".txt"]] encoding:NSUTF8StringEncoding error:nil];
	if ( !original ) {
		original = [self frameworkResource:testName category:@"xml"];
	}
	[self verifyThatResultOfExtracting:original equals:expectedExtracted title:nil testName:testName];
}

+(void)testVeryBasicHtmlExtract
{
	[self verifyThatResultOfExtractingString:@"<html><body>Some text</body></html>" equals:@"Some text" title:nil testName:@"testVeryBasicHtmlExtract"];
}

+(void)testGetTitle
{
	[self verifyThatResultOfExtractingString:@"<html><head><title>Whattatitle</title></head><body>Bodytext</body></html>" equals:@"Bodytext" title:@"Whattatitle" testName:@"testGetTitle"];
}

+(void)testGetMetaAttributes
{
	NSDictionary* dict = [self attributesDictionaryForData:[self frameworkResource:@"meta_attributes" category:@"html"]];
	IDEXPECT( [dict objectForKey:TITLE_KEY], @"Test of HTML metadata", @"Title");
	IDEXPECT( [dict objectForKey:@"author"], @"Douglas R. Davidson", @"author");
	IDEXPECT( [dict objectForKey:@"copyright"], @"2006 Apple Computer, Inc.", @"copyright");
	IDEXPECT( [dict objectForKey:@"subject"], @"HTML metadata", @"subject");
	IDEXPECT( [dict objectForKey:@"company"], @"Apple", @"company");
	IDEXPECT( [dict objectForKey:@"keywords"], @"this, that, the other", @"company");
	IDEXPECT( [dict objectForKey:@"cocoaversion"], @"824.41", @"company");
	INTEXPECT( [dict count], 9,  @"meta dict size");
}


+(void)testUnicodeMetaAttributes
{
	NSDictionary* dict = [self attributesDictionaryForData:[self frameworkResource:@"metadata_unicode" category:@"html"]];
	NSString* title = [dict objectForKey:TITLE_KEY];
	NSString* author = [dict objectForKey:@"author"];

	//--- where to get 'magic' unichar values:
	//---
	//--- load source file into TextEdit as plain text
	//--- save as UTF16, then check actual hex values 
	//--- using, for example, hexdump -C (beware of
	//--- big-endian vs. little endian
	
	INTEXPECT( [title characterAtIndex:0], 0x648, @"first unichar of title");
	INTEXPECT( [title characterAtIndex:1], 0x062b , @"second unichar of title");
	INTEXPECT( [title length], 8 , @"length of title" );
	INTEXPECT( [author characterAtIndex:0], 0x5f35 , @"first unichar of author");
	INTEXPECT( [author characterAtIndex:1], 0x6df5 , @"second unichar of author");
	INTEXPECT( [author length], 2 , @"length of author" );

}

+(void)doTest:(NSString*)testName withTest:aTestCase
{
    if ( [self respondsToSelector:NSSelectorFromString(testName)] ) {
        [super doTest:testName withTest:aTestCase];
    } else {
        [self testExtractXMLorHTMLwithPlainTextTestResult:testName];
    }
}


+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testVeryBasicHtmlExtract",
			@"testGetTitle",
			@"textwith_br",
			@"textwith_td",
			@"html_with_javascript",
			@"naked_html_fragment",
			@"html_text_through_tag",
			@"jap-pto",
			@"jap-pto_upcase_meta",
			@"jap-pto_all_upcase_meta",
			@"c1qt12",
			@"entity_runon",
			@"close_tag_not_closed",
			@"jap-pto-other-meta",		//	tests for bug where other meta-tag overrides encoding
			@"textwith_th",
			@"textwith_p",
			@"textwith_multiple_body",
			@"textwith_headings",
			@"no_space_between_attributes",
			@"attributes_with_double_closing_quotes",
			@"space_before_tag_close",
			@"html_comment_with_dash",
			@"testGetMetaAttributes",
			@"testUnicodeMetaAttributes",
			@"decor",
			nil];
}

@end

#endif

