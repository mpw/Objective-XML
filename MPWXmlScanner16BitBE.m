/* MPWXmlScanner16BitBE.m Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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

, created  on Sat 11-Sep-1999 */

#import "MPWXmlScanner16BitBE.h"
#import "MPWXmlParser.h"

#define	xmlchar	unichar
#define	XMLCHAR(x)	NSSwapHostShortToBig(x)
#define	NATIVECHAR(x)	NSSwapBigShortToHost(x)

static unichar cdata[]={ '<', '!' , '[','C','D','A','T','A','[' };
static unichar endcomment[]={ '-', '-' , '>'};
//static unichar empty[]={ 0, };

static int unicharncmp( const xmlchar *left, const xmlchar *right, int length )
{
    int res,i;
    for (i=0;i<length;i++) {
        if ( 0 != (res = right[i]-left[i]) ) {
            break;
        }
    }
    return res;
}

#define	CDATATAG	cdata
#define ENDCOMMENT	endcomment
#define	CHARCOMP	unicharncmp
#define	EMPTYSTRING	empty



#import "XmlScannerPseudoMacro.h"


@implementation NSXMLScanner(sixteenBitBE)

-(BOOL)makeTextBE:(const xmlchar*)start length:(int)len firstEntityOffset:(int)entityStart
{
    NSLog(@"%s: unicode string: %d",__FUNCTION__,len);
    NSLog(@"%s: unicode string: %@",__FUNCTION__,[NSString stringWithCharacters:start length:len]);
    return YES;
}

-(BOOL)makeCDataBE:(const xmlchar*)start length:(int)len
{
    NSLog(@"%s: unicode string: %d",__FUNCTION__,len);
    NSLog(@"%s: unicode string: %@",__FUNCTION__,[NSString stringWithCharacters:start length:len]);
    return YES;
}

-(BOOL)beginElementBE:(const xmlchar*)start length:(int)len nameLen:(int)nameEnd
{
    NSLog(@"%s: unicode string: %d",__FUNCTION__,len);
    NSLog(@"%s: unicode string: %@",__FUNCTION__,[NSString stringWithCharacters:start length:len]);
    return YES;
}

-(BOOL)endElementBE:(const xmlchar*)start length:(int)len
{
    NSLog(@"%s: unicode string: %d",__FUNCTION__,len);
    NSLog(@"%s: unicode string: %@",__FUNCTION__,[NSString stringWithCharacters:start length:len]);
    return YES;
}

-(BOOL)makeSgmlBE:(const xmlchar*)start length:(int)len nameLen:(int)nameEnd
{
    NSLog(@"%s: unicode string: %d",__FUNCTION__,len);
    NSLog(@"%s: unicode string: %@",__FUNCTION__,[NSString stringWithCharacters:start length:len]);
    return YES;
}

-(BOOL)makePIBE:(const xmlchar*)start length:(int)len nameLen:(int)nameEnd
{
    NSLog(@"%s: unicode string: %d",__FUNCTION__,len);
    NSLog(@"%s: unicode string: %@",__FUNCTION__,[NSString stringWithCharacters:start length:len]);
   return YES;
}

-(BOOL)makeEntityRefBE:(const xmlchar*)start length:(int)len
{
    NSLog(@"%s: unicode string: %d",__FUNCTION__,len);
    NSLog(@"%s: unicode string: %@",__FUNCTION__,[NSString stringWithCharacters:start length:len]);
    return YES;
}



-(void)scan16bit:(NSData*)aData
{
    ProcessFunc text16 = (ProcessFunc)[self methodForSelector:@selector(makeTextBE:length:firstEntityOffset:)];
    ProcessFunc space16 = (ProcessFunc)[self methodForSelector:@selector(makeTextBE:length:firstEntityOffset:)];
    ProcessFunc cdata16 = (ProcessFunc)[self methodForSelector:@selector(makeCDataBE:length:)];
    ProcessFunc sgml16 = (ProcessFunc)[self methodForSelector:@selector(makeSgmlBE:length:nameLen:)];
    ProcessFunc pi16 = (ProcessFunc)[self methodForSelector:@selector(makePIBE:length:nameLen:)];
    ProcessFunc openTag16 = (ProcessFunc)[self methodForSelector:@selector(beginElementBE:length:nameLen:)];
    ProcessFunc closeTag16 = (ProcessFunc)[self methodForSelector:@selector(endElementBE:length:)];
    ProcessFunc entityRef16 = (ProcessFunc)[self methodForSelector:@selector(makeEntityRefBE:length:)];
    data=[aData retain];
    scanXml( [data bytes], [data length] / sizeof(xmlchar),  openTag16, closeTag16, sgml16,pi16,entityRef16, text16,space16,cdata16, NULL, self );
    [data release];
    data=nil;
}

@end

