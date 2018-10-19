//
//  MPWXmlWrapperUnarchiver.m
//  MPWXmlKit
//
//  Created by marcel on Wed Aug 15 2001.
/*  Copyright (c) 2001 Marcel Weiher.  All Rights Reserved.
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

#import "MPWXmlWrapperUnarchiver.h"
#import "mpwfoundation_imports.h"

@implementation XmlWrapperDecoder


@end



@implementation MPWXmlWrapperUnarchiver

+_xmldecoder1
{
	return [[XmlWrapperDecoder alloc] init];
}

idAccessor( datas, setDatas )

-unarchiveObjectWithData:archivedDataArray
{
	id mainData;
	if ( [archivedDataArray count] >1 ) {
		[self setDatas:[archivedDataArray subarrayWithRange:NSMakeRange(1,[archivedDataArray count]-1)]];
	}
//	NSLog(@"archivedDatatArray has %d elements",[archivedDataArray count]);
	mainData = [archivedDataArray objectAtIndex:0];
//	NSLog(@"got mainData");
	return [super unarchiveObjectWithData:mainData];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)endName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
//    NSLog(@"endElement:%@",endName);
	if ( [endName isEqual:@"datareference"] ) {
  //      NSLog(@"got data reference");
		[self setCurrentValue:[datas objectAtIndex:currentData++]];
		[self makeValue:endName];
		dataLen=0;
	} else {
		[super parser:parser didEndElement:endName namespaceURI:namespaceURI qualifiedName:qName];
	}
}


-(void)dealloc
{
	[datas release];
	[super dealloc];
}
+testSelectors
{
    return @[
             ];
}




@end
