/* MPWNSXMLDocumentParser.m Copyright (c) 2007 by Marcel P. Weiher.  All Rights Reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

        Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.

        Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in
        the documentation and/or other materials provided with the distribution.

        Neither the name Marcel Weiher nor the names of contributors may
        be used to endorse or promote products derived from this software
        without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.


*/

#import "MPWNSXMLDocumentParser.h"
//#import "MPWXmlElement.h"
//#import "MPWXmlAttributes.h"

#import "mpwfoundation_imports.h"
#import "MPWMAXParser_private.h"



@implementation MPWNSXMLDocumentParser




+domForData:(NSData*)data
{
	id pool=[NSAutoreleasePool new];
	id parser=[self parser];
	id result;
	[parser parse:data];
	result=[parser parseResult];
	result = [[NSXMLDocument alloc] initWithRootElement:result];
	[pool release];
	return [result autorelease];
}

-init
{
    self = [super init];
	[self setHandler:self forElements:[NSArray array] inNamespace:nil prefix:@"" map:nil];
 	allocator = (void*)kCFAllocatorSystemDefault; // CFAllocatorGetDefault();
//	[[self class] makeUniqueNameTable];
   return self;
}


-(BOOL)makeText:(const char*)start length:(int)len firstEntityOffset:(int)entityOffset
{
//	NSLog(@"%d characters:  '%@' entityOffset: %d tagStackLen: %d self: %x",len,MAKEDATA(start,len),entityOffset,tagStackLen,self);
	if ( entityOffset > 0 ) {
		
	}
    if (  tagStackLen > 0   ) {
		PUSHOBJECT([[NSXMLNode textWithStringValue:(id)CFStringCreateWithBytes( allocator, (const unsigned char*)start, len, 0 , NO)] retain],nil,nil);
//        CHARACTERS(MAKEDATA( start, len ));
    } else {
//		NSLog(@"suppressing characters, tagStackLen: %d",tagStackLen);
	}
    return YES;
}


-(BOOL)makeSpace:(const char*)start length:(int)len 
{
	if ( tagStackLen > 0 && lastTagWasOpen ) {
		numSpacesOnStack++;
       PUSHOBJECT([[NSXMLNode textWithStringValue:(id)CFStringCreateWithBytes( allocator, (const unsigned char*)start, len, 0 , NO)] retain],nil,nil);
    } else {
//		NSLog(@"suppressing characters, tagStackLen: %d",tagStackLen);
	}
    return YES;
}


-getTagForCString:(const char*)start length:(int)len
{
	// should try uniquing
	return (id)CFStringCreateWithBytes( allocator, (const unsigned char*)start, len, 0 , NO);
}

-undeclaredElement:children attributes:attributes parser:parser
{
    id element=nil;
	int i,max=[attributes count];
//	sub=[NSArray arrayWithObjects:objs count:count];
	element = [[NSXMLElement alloc] initWithName:CURRENTTAG];
	if ( [children count] ) {
		NSArray* childArray=nil;
		childArray = [[NSArray alloc] initWithObjects:[children _pointerToObjects] count:[children count]];
		[element setChildren:childArray];
		[childArray release];
	}
	if ( max ) {
		id attrArray[ [attributes count] ];
		id convertedAttributes;
		for ( i=0; i < max; i++) {
			id key=[attributes keyAtIndex:i];
			id value=[attributes objectAtIndex:i];
			attrArray[i] = [NSXMLNode attributeWithName:key stringValue:value];
//		[convertedAttributes addObject:node];
		}
		convertedAttributes = [[NSArray alloc] initWithObjects:attrArray count:max];
		[element setAttributes:convertedAttributes];
		[convertedAttributes release];
	}
//	element = [[NSXMLNode elementWithName:CURRENTTAG children: attributes:convertedAttributes] retain];
//	element = [[NSXMLNode elementWithName:name children:[NSArray array] attributes:nil] retain];
    return element;
}



-(void)dealloc
{
//	NSLog(@"-[%p:%@ dealloc] stack depth: %d",self,[self class],objectStackLen );
//    [elementCache release];
    [super dealloc];
}


@end

@implementation MPWNSXMLDocumentParser(testing)

+domForResource:(NSString*)resourceName category:(NSString*)resourceType
{
	return [[self domForData:[self frameworkResource:resourceName category:resourceType]] rootElement];
}

+(void)testEmptyXmlParse
{
	id dom = [self domForResource:@"test1" category:@"xml"];
//	NSLog(@"%@ %@",self,NSStringFromSelector(_cmd));
//	NSLog(@"dom %@",[dom class]);
	IDEXPECT( [dom name], @"xml" , @"name" );
	INTEXPECT( [dom childCount], 0 , @"number of children" );
}


+(void)testNestedXmlParse
{
	id dom = [self domForResource:@"test3" category:@"xml"];
	id child1,child2;
//	NSLog(@"dom result: %@",dom);
	IDEXPECT( [dom name], @"xml" , @"name" );
	INTEXPECT( [dom childCount], 2 , @"number of children" );
	child1=[dom childAtIndex:0];
	child2=[dom childAtIndex:1];
	IDEXPECT( [child1 name], @"nested1" , @"child1" );
	IDEXPECT( [child2 name], @"nested2" , @"child2" );
	INTEXPECT( [[dom childAtIndex:0] childCount], 1 , @"number of children" );
	IDEXPECT( [[dom childAtIndex:1] name], @"nested2" , @"child2" );
	INTEXPECT( [[dom childAtIndex:1] childCount], 1 , @"number of children" );
	IDEXPECT( [[[dom childAtIndex:1] childAtIndex:0] objectValue], @"content1" , @"/nested2/" );
}

+(void)testXmlParseWithSpaceContent
{
	id dom = [self domForResource:@"test4" category:@"xml"];
	id child1,child2;
	IDEXPECT( [dom name], @"xml" , @"name" );
	INTEXPECT( [dom childCount], 2 , @"number of children" );
	child1=[dom childAtIndex:0];
	child2=[dom childAtIndex:1];
	IDEXPECT( [child1 name], @"nested1" , @"child1" );
	IDEXPECT( [child2 name], @"space" , @"child2" );
	INTEXPECT( [[dom childAtIndex:0] childCount], 1 , @"number of children" );
	IDEXPECT( [[dom childAtIndex:1] name], @"space" , @"child2" );
	INTEXPECT( [[dom childAtIndex:1] childCount], 1 , @"number of children" );
	IDEXPECT( [[[dom childAtIndex:1] childAtIndex:0] objectValue], @" " , @"/nested2/" );
}

+(void)testXmlWithAttributes
{
	NSXMLDocument* dom = [self domForResource:@"archiversample" category:@"xml"];
	NSXMLElement *child0,*child1;
//	NSLog(@"dom=%@",dom);
	IDEXPECT( [dom name] , @"MPWSubData", @"top level");
//	NSLog(@"[[dom childAtIndex:0] name]=%@",[[dom childAtIndex:0] name]);
//	NSLog(@"[[dom childAtIndex:1] name]=%@",[[dom childAtIndex:1] name]);
	IDEXPECT( [[dom childAtIndex:0] name], @"myData" , @"child 1" );
	child0=(NSXMLElement*)[dom childAtIndex:0];
	INTEXPECT( [[child0 attributes] count], 1 , @"1 attribute" );
//	NSLog(@"attributes of element[0]=%@",[[dom childAtIndex:0] attributes]);

	IDEXPECT( [[[child0 attributes] objectAtIndex:0] objectValue], @"4" , @"idref value" );
	IDEXPECT( [[[child0 attributes] objectAtIndex:0] name], @"idref" , @"idref value" );
	child1=(NSXMLElement*)[dom childAtIndex:1];
	IDEXPECT( [[[child1 attributes] objectAtIndex:0] name], @"valuetype" , @"valuetype" );
	IDEXPECT( [[[child1 attributes] objectAtIndex:0] objectValue], @"i" , @"valuetype" );

}


+testSelectors
{
#if WINDOWS
	return [NSArray array];
#else	
	return [NSArray arrayWithObjects:
				@"testEmptyXmlParse",
				@"testNestedXmlParse",
				@"testXmlWithAttributes",
				@"testXmlParseWithSpaceContent",
				nil];
#endif	
}

@end

