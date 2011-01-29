/* MPWXmlDOM.h Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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

, created  on Mon 12-Oct-1998 */

@protocol Node

const unsigned short      ELEMENT_NODE       = 1;
const unsigned short      ATTRIBUTE_NODE     = 2;
const unsigned short      TEXT_NODE          = 3;
const unsigned short      CDATA_SECTION_NODE = 4;
const unsigned short      ENTITY_REFERENCE_NODE = 5;
const unsigned short      ENTITY_NODE        = 6;
const unsigned short      PROCESSING_INSTRUCTION_NODE = 7;
const unsigned short      COMMENT_NODE       = 8;
const unsigned short      DOCUMENT_NODE      = 9;
const unsigned short      DOCUMENT_TYPE_NODE = 10;
const unsigned short      DOCUMENT_FRAGMENT_NODE = 11;
const unsigned short      NOTATION_NODE      = 12;

-(NSString*)nodeName;
-(NSString*)nodeValue;
-(unsigned short)nodeType;
-(id <Node>)parentNode;
-(id <NodeList>)childNodes;
-(id <Node>)firstChild;
-(id <Node>)lastChild;
-(id <Node>)previousSibling;
-(id <Node>)nextSibling;
-(id <NameNodeMap>) attributes;
-(id <Document>)ownerDocument;

-(id <Node>)insert:(in id <Node>)newChild before:(in id <Node>)refChild;
-(id <Node>)replaceChild:(in id <Node>)oldChild with:(in id <Node>)newChild
-(id <Node>)removeChild(in Node oldChild)
-(id <Node>)appendChild:(in id <Node>)oldChild;
-(BOOL)hasChildNodes;
-(id <Node>)cloneNode:(in BOOL)deep;


@end