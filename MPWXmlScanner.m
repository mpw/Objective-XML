/* MPWXmlScanner.m Copyright (c) Marcel P. Weiher 1998-2008, All Rights Reserved,
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

, created  on Sun 23-Aug-1998 */

#import "MPWXmlScanner.h"
#import "MPWXmlScanner16BitBE.h"
#import "mpwfoundation_imports.h"

#if 0

@interface NSData(swapBytes)

-(NSData*)swappedUnichars;
-(NSData*)initWithSwappedShortsOf:(short*)shorts length:(unsigned)shortLen;

@end
@implementation NSData(swapBytes)

-(NSData*)initWithSwappedShortsOf:(short*)shorts length:(unsigned)shortLen
{
    short *swapped=malloc(  sizeof *swapped * shortLen );
    int i;
    for (i=0;i<shortLen;i++) {
        swapped[i]=NSSwapShort( shorts[i] );
    }
    return [self initWithBytesNoCopy:(void*)swapped length:shortLen*2];
}

-(NSData*)swappedUnichars
{
    return [[[NSData alloc] initWithSwappedShortsOf:(short*)[self bytes] length:[self length]/2] autorelease];
}

@end

@implementation MPWSubData(swapBytes)

-(NSData*)swappedUnichars
{
    return [[[NSData alloc] initWithSwappedShortsOf:(short*)[self bytes] length:[self length]/2] autorelease];
}


@end
#endif 
@implementation NSXMLScanner
/*"
     An MPWXmlScanner segments 8 or 16 bit character data according to the XML specification.
     It provides pointers
     into the original data via call-backs and does not perform any further processing.  The intent
     is for MPWXmlScanner to serve as the lowest level of XML input-processing with minimal
     overhead and the ability to re-create the input file with 100% fidelity.  Any types of
     conversions, processing or policy decisions are left for higher levels to take care of.

     It can handle 8 bit ISO/ASCII and 16 bit Unicode encoded files.  UTF-8 files aren't treated
     specially but can be handled as-is due to the nature of the UTF-8 encoding (all XML-relevant
     syntactical entities have the same code positions as in ASCII).  Conversion of actual encoded
     content is left to clients/subclasses of MPWXmlScanner.  Sixteen bit data with non-native endianness
     is byte-swapped wholesale before reading as a stopgap measure.
     
"*/


scalarAccessor( id, delegate, _setDelegate )


-(void)_initDelegation
{
	if ( nil != delegate ) {
		text		= [delegate methodForSelector:@selector(makeText:length:firstEntityOffset:)];
		space		= [delegate methodForSelector:@selector(makeSpace:length:)];
		cdataTagCallback = [delegate methodForSelector:@selector(makeCData:length:)];
		sgml		= [delegate methodForSelector:@selector(makeSgml:length:nameLen:)];
		pi			= [delegate methodForSelector:@selector(makePI:length:nameLen:)];
		openTag		= [delegate methodForSelector:@selector(beginElement:length:nameLen:)];
		closeTag	= [delegate methodForSelector:@selector(endElement:length:)];
		attVal		= [delegate methodForSelector:@selector(attributeName:length:value:length:)];
		entityRef	= [delegate methodForSelector:@selector(makeEntityRef:length:)];
	}
}

-(void)setDelegate:aDelegate
{
	[self _setDelegate:aDelegate];
	[self _initDelegation];
}

+parser
{
	return [[[self alloc] init] autorelease];
}

+stream { return [self parser]; }

typedef char xmlchar;


#include "XmlScannerPseudoMacro.h"

idAccessor( data, setData )

 -(BOOL)scan8bit:(NSData*)aData
{
//    ProcessFunc entityRef = (ProcessFunc)[self methodForSelector:@selector(makeEntityRef:length:)];
	BOOL success=NO;
	id oldData=[[self data] retain];
	[self setData:aData];
    success=(scanXml( [data bytes], [data length] / sizeof(xmlchar),  openTag, closeTag, sgml,pi,entityRef, text,space,cdataTagCallback,attVal, delegate )==SCAN_OK);
	[self setData:oldData];
    [oldData release];
	return success;
}


-convert16BitUnicodeToUTF8:utf16data
{
	id string=[[NSString alloc] initWithData:utf16data encoding:NSUnicodeStringEncoding];
	id utf8data=[string dataUsingEncoding:NSUTF8StringEncoding];
	[string release];
	return utf8data;
}


-(BOOL)parse:(NSData*)aData
/*"
    Scan the data object, which can contain 8 bit ASCII compatible or 16 bit Unicode characters.
    Perform the call-backs described above for various XML syntactic structures found in the
    character data.  Does not perform validity or even well-formedness checking.
 
    Sixteen bit data is recognized by the header word 0xfffe, for data with non-native endianness,
    a byte-swapped copy is scanned.
"*/
{
    if ( [aData length] >= 2 ) {
        const unsigned short *chars=(unsigned short*)[aData bytes];
        if ( *chars == 0xfffe ||  *chars == 0xfeff  ) {
			NSLog(@"convert 16 bit to 8 bit!");
			aData=[self convert16BitUnicodeToUTF8:aData];
		}
    }
    return [self scan8bit:aData];
}


-(void)dealloc
{
    [data release];
//	[delegate release];
    [super dealloc];
}

@end
