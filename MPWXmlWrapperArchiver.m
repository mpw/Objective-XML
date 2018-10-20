//
//  MPWXmlWrapperArchiver.m
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

#import "MPWXmlWrapperArchiver.h"
#import "mpwfoundation_imports.h"
#import "MPWXmlGeneratorStream.h"


@implementation MPWXmlWrapperArchiver

idAccessor( datas, setDatas )

-initWithTarget:newTarget
{
	self = [super initWithTarget:newTarget];
	[self setDatas:[NSMutableArray array]];
	return self;
}


-(void)encodeDataObject:(NSData*)theObject
{
    [target writeElementName:"datareference" attributes:[NSString stringWithFormat:@"length='%d'",(int)[theObject length]] contents:nil];
	[datas addObject:theObject];
}

-resultOfEncodingRootObject:root
{
	id dict=[NSMutableDictionary dictionary];
	int i;
	id base = [super resultOfEncodingRootObject:root];
	[dict setObject:base forKey:@"document.xml"];
	for (i=0;i<[datas count];i++) {
		[dict setObject:[datas objectAtIndex:i]
			forKey:[NSString stringWithFormat:@"data_%d.data",i]];
	}
	return dict;
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
