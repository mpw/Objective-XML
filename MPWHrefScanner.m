//
//  MPWHrefScanner.m
//  MPWXmlKit
//
//  Created by Marcel Weiher on 06/07/2006.
/*  Copyright 2006 Marcel Weiher.  All Rights Reserved.
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

#import "MPWHrefScanner.h"
#import "MPWXmlAttributes.h"
#import "MPWTagHandler.h"
#import "mpwfoundation_imports.h"

@implementation MPWHrefScanner

idAccessor( base, setBase )
idAccessor( hrefs, setHrefs )

-init
{
	self=[super init];
	[self setHrefs:[NSMutableArray array]];
	//---	prepare the parser for HTML parsing
	[self setIgnoreCase:YES];
	[self setEnforceTagNesting:NO];
	//---	these are the tags we're interested in
	[self setHandler:self forTags:[NSArray arrayWithObjects:@"a",@"area",@"base",nil] inNamespace:nil prefix:@"" map:nil ];
	return self;
}

//---	this is a utility method

-handleHref:attributes
{
	id href=[attributes objectForCaseInsensitiveKey:@"href"];
	[hrefs addObject:href];
	return nil;
}

//---	tag handlers that are invoked by the parser

-aTag:attributes parser:parser
{
	return [self handleHref:attributes];
}

-areaTag:attributes parser:parser
{
	return [self handleHref:attributes];
}

-baseTag:attributes parser:parser
{
	[self setBase:[attributes objectForCaseInsensitiveKey:@"href"]];
	return nil;
}

//---	ensure we don't build up spurious tree

-defaultElement:(MPWXMLAttributes*)children attributes:(MPWXMLAttributes*)attributes parser:(MPWMAXParser*)parser
{
	return nil;
}

-(void)dealloc
{
	[base release];
	[hrefs release];
	[super dealloc];
}

@end

@implementation MPWHrefScanner(testing)

+(void)testBasicHrefs
{
	id data=[self frameworkResource:@"hreftest" category:@"html"];
	id parser=[self parser];
	id hrefs;
	[parser parse:data];
	hrefs=[parser hrefs];
	INTEXPECT( [hrefs count], 4, @"number of hrefs");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testBasicHrefs",
		nil];
}

@end

