/* MPWSaxProtocol.h Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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

, created  on Tue 09-Feb-1999 */

#import <Foundation/Foundation.h>

@protocol MPWSaxDocumentLocator

-(int)getLineNumber;
-(int)getColumnNumber;
-(NSString*)getSystemId;
-(NSString*)getPublicId;

@end


@protocol MPWSaxDocumentHandler

-(void)startDocument;
-(void)endDocument;
-(void)startElement:elementName attributes:attributes;
-(void)endElement:elementName;
#if EMULATE_JAVA_SAX
-(void)characters:(char*)base from:(unsigned)start length:(unsigned)length;
-(void)ignorableWhitespace:(char*)base from:(unsigned)start length:(unsigned)length;
-(void)processingInstruction:target data:data;
#else
-(void)characters:characterData;
-(void)cdata:cdataData;
#endif
-(void)setDocumentLocator:locator;

@end
