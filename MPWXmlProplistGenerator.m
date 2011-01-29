/* MPWXmlProplistGenerator.m Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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

, created  on Tue 13-Jul-1999 */

#import "MPWXmlProplistGenerator.h"

@implementation MPWXmlProplistGenerator

static const char *array="array";
static const char *dict="dict";
static const char *string="string";

-(SEL)streamWriterMessage
{
    return @selector(generateXmlProplistOnto:);
}

-(void)writeProplistArray:(NSArray*)anArray
{
    [self writeElementName:array attributes:nil contents:anArray];
}

-(void)writeObject:anObject forKey:aKey
{
    [self writeStartTag:[aKey cString] attributes:nil single:NO];
    [self writeObject:anObject];
    [self closeTag];
}

-(void)writeProplistDictionary:(NSDictionary*)aDict
{
    [self writeElementName:dict attributes:nil contents:aDict];
}

-(void)writeProplistString:(NSString*)aString
{
    [self writeElementName:string attributes:nil contents:aString];
}

@end

@implementation NSObject(xmlProplist)

-(void)generateXmlProplistOnto:aStream
{
    [self generateXmlOnto:aStream];
}

@end
@implementation NSArray(xmlProplist)

-(void)generateXmlProplistOnto:aStream
{
    [aStream writeProplistArray:self];
}

@end
@implementation NSDictionary(xmlProplist)

-(void)generateXmlProplistOnto:aStream
{
    [aStream writeProplistDictionary:self];
}

@end
@implementation NSString(xmlProplist)

-(void)generateXmlProplistOnto:aStream
{
    [aStream writeProplistString:self];
}

@end



