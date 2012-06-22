/* MPWXmlParser.m Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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

, created  on Sun 05-Sep-1999 */

#import "MPWXmlParser.h"
#import "MPWMAXParser_private.h"
#import "MPWXmlAttributes.h"
#import "SaxDocumentHandler.h"

#import "mpwfoundation_imports.h"

@implementation MPWSAXParser

-initWithData:aData
{
	self=[super initWithData:aData];
	[self setDelegate:nil];
	return self;
}

-(BOOL)endElement:(const char*)start length:(int)len namespaceLen:(int)namespaceLen
{
    id endName=nil;
	id prefix=nil;
	id fullyQualified=nil;
	id namespaceURI=nil;
    const char *namespaceLocation=NULL;
	const char *namespacePrefix=NULL;
//	const char *namespace;

	RECORDSCANPOSITION( start, len );
    start+=2;
    len-=3;
#if 1
    id openTag=CURRENTTAG;
    const char *b=[openTag bytes];
    for (int i=0;i<len;i++) {
        if ( start[i]!=b[i]) {
            endName=TAGFORCSTRING( start, len); //  MPWUniqueStringWithCString( start, len );
            break;
        }
    }
    if (!endName) {
        endName=openTag;
    }
#else
    endName=TAGFORCSTRING( start, len); //  MPWUniqueStringWithCString( start, len );
#endif
//   NSLog(@"end element </%@>, currentTag: %@ tagStackLen: %d",endName,CURRENTTAG,tagStackLen);
	if ( shouldProcessNamespaces &&  (namespaceLocation= memchr( start,':',len)) ) {
		fullyQualified=endName;
		namespacePrefix=start;
		namespaceLen=len-(namespaceLocation-start)-1; //   namespaceLocation-namespacePrefix-1;
		endName=TAGFORCSTRING( namespaceLocation+1, namespaceLen);
		prefix = TAGFORCSTRING( start, namespaceLocation-start );
		namespaceURI=[namespacePrefixToURIMap objectForKey:prefix];


//		NSLog(@"tag: %@ prefix: %@ fullyQualified: %@ uri: %@",endName,prefix,fullyQualified,namespaceURI);
	}
//	NSLog(@"end tag, tagStackLen: %d",tagStackLen);

    if (  CURRENTTAG == endName || [CURRENTTAG isEqual: endName] ) {
        POPTAG;
//		[documentHandler parser:(NSXMLParser*)self didEndElement:endName namespaceURI:namespaceURI qualifiedName:fullyQualified];
        ENDELEMENT( endName,namespaceURI, fullyQualified );
//		NSLog(@"end tag end, tagStackLen: %d",tagStackLen);
        return YES;
    } else {
		if ( enforceTagNesting ) {
			[self setParserError:[NSError errorWithDomain:@"XML" code:76 userInfo:nil]];
			[NSException raise:@"non-matching tags" format:@"non matching tags expecting: '%@' (at %d) actual end tag: '%@' tag stack:%@",[self currentTag],tagStackLen ,endName,[self _fullTagStackString]];
			return NO;
		} else {
			while ( ![CURRENTTAG isEqual: endName] && tagStackLen>0 ) {
	//			NSLog(@"stack[%d] non matching end-tags: %@",tagStackLen,CURRENTTAG);
				POPTAG;
			}
	//		NSLog(@"will call ENDELEMENT with target: %@ tag: %@ selector: %x %@",documentHandler,endName,ENDELEMENTSELECTOR,NSStringFromSelector(ENDELEMENTSELECTOR) );
	        ENDELEMENT( endName,  namespaceURI, fullyQualified  );

//			[documentHandler parser:(NSXMLParser*)self didEndElement:endName namespaceURI:namespaceURI qualifiedName:fullyQualified];
	//        ENDELEMENT( endName,namespaceURI, fullyQualified );
	//		NSLog(@"did call ENDELEMENT");
	//		NSLog(@"end tag end, tagStackLen: %d",tagStackLen);
			return YES;
		}
    }
}

-(BOOL)attributeName:(const char*)nameStart length:(int)nameLen value:(const char*)valueStart length:(int)valueLen namespaceLen:(int)namespaceLen
	/*"
	"*/
{
	id name = MAKEDATA( nameStart, nameLen );
	id value=nil;
	if ( autotranslateUTF8 ) {
		int i;
		for (i=0;i< valueLen;i++ ) {
			if ( valueStart[i] & 128 ) {
				value = [(id)CFStringCreateWithBytes(NULL, (const unsigned char*)valueStart, valueLen, kCFStringEncodingUTF8, NO) autorelease];
				break;
			}
		}
	}
	if (! value ) {
		value = MAKEDATA( valueStart, valueLen );
	}
	if ( shouldProcessNamespaces &&  nameLen >= 5  && !strncmp( nameStart, "xmlns", 5 ) ) {
		if ( nameLen > 6 ) {
			name=TAGFORCSTRING( nameStart+6, nameLen-6 );
		} else {
			name=@"";
		}
		[self handleNameSpaceAttribute:name withValue:value];
	} else {
		if ( !_attributes ) {
//			NSLog(@"getObject: %p  %p",attributeCache->getObject,[attributeCache getObjectIMP]);
			id att=GETOBJECT( (MPWObjectCache*)attributeCache);
			[self _setAttributes:att];
			[_attributes removeAllObjects];
		}
		[_attributes setValue:value forAttribute:name];
	}
	return YES;
}


-(BOOL)beginElement:(const char*)start length:(int)len nameLen:(int)nameLen namespaceLen:(int)namespaceLen
{
	id namespaceURI=nil;
	id fullyQualifiedTag=nil;
	id namespacePrefixTag=nil;
	const char *namespace;
   id tag=nil;
    BOOL isEmpty=NO;
	RECORDSCANPOSITION( start, len );
//    NSLog(@"start[len-2]=='%c'",start[len-2]);
    if ( start[len-2]=='/' ) {
        isEmpty=YES;
        if ( start[nameLen-1]=='/' ) {
            nameLen--;
        }
    }
    start++;
    nameLen--;
    len-=2;
//	NSLog(@"begin tag, tagStackLen: %d",tagStackLen);

    if ( nameLen > 0 ) {
		id attrs=_attributes;
//		id prefixTag=nil;
		
		//---  interpret HTML meta-tags to figure out content encoding if it's likely we are parsing HTML
		
		if ( nameLen == 4 && ignoreCase && !enforceTagNesting && !strncasecmp(start, "meta", 4) ) {
			[self handleMetaTag];
		}
		
		tag=TAGFORCSTRING( start, nameLen);
		if ( shouldProcessNamespaces && (namespace = memchr( start, ':', nameLen )) ) {
			fullyQualifiedTag=tag;
			namespaceLen=nameLen-(namespace-start)-1;
			tag=TAGFORCSTRING( namespace+1, namespaceLen );
			namespacePrefixTag=TAGFORCSTRING( start, namespace-start );
			namespaceURI=[namespacePrefixToURIMap objectForKey:namespacePrefixTag];
//			NSLog(@"namespaceprefix: %@ tag: %@ uri: %@ fully qualified: %@",namespacePrefixTag,tag,namespaceURI, fullyQualifiedTag);
		} else {
//			NSLog(@"no namespace");
		}	
        PUSHTAG(tag);
//		NSLog(@"begin element: <%@ %@%s> tagdepth=%d",tag,_attributes,isEmpty?"/":"",tagStackLen);
//		NSLog(@"beginelement: %@/%x",documentHandler,beginElement);
		if ( !attrs ) {
			if ( !emptyDict ) {
				emptyDict=[[MPWXMLAttributes alloc] init];
			}
			attrs=emptyDict;
		}
//		fprintf(stderr,"BEGINELEMENT: self=%p beginElement: %p documentHandler: %p\n",self,beginElement,documentHandler);
        BEGINELEMENT( tag,  namespaceURI, fullyQualifiedTag	,attrs );
		if ( _attributes ) {
			[self clearAttributes];
		}
        if ( isEmpty ) {
            [tag retain];
            POPTAG;
//			[documentHandler parser:self didEndElement:tag namespaceURI:namespaceURI qualifiedName:fullyQualifiedTag];
            ENDELEMENT(tag,namespaceURI,fullyQualifiedTag);
           [tag release];
        }
    } else {
        NSLog(@"nameLen <= 0!");
    }
//	NSLog(@"begin tag (end), tagStackLen: %d",tagStackLen);
    return YES;
}    

-(BOOL)makeSpace:(const char*)start length:(int)len 
/*"
    Call-back for spaces.  Create text data.
"*/
{
	RECORDSCANPOSITION( start, len );
    return [self makeText:start length:len firstEntityOffset:-1];
}

-(BOOL)characterDataAllowed:parser
{
    return tagStackLen > 0 ? 1 : 0;
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {}
-(void)cdata:chars{}
-(void)characters:chars{}
-(void)ignorableWhiteSpace:chars{}
-(void)processingInstructionTarget:piTarget data:piData{}
-(void)parserDidStartDocument:(NSXMLParser*)parser {}
-(void)parserDidEndDocument:(NSXMLParser*)parser {}

-(void)handleNameSpaceAttribute:name withValue:value
{
	if ( [documentHandler respondsToSelector:@selector(parser:didStartMappingPrefix:toURI:)] ) {
//		NSLog(@"map name: '%@' toURI: '%@'",name,value);
		if ( !namespacePrefixToURIMap ) {
			namespacePrefixToURIMap=[[NSMutableDictionary alloc] init];
		}
		[namespacePrefixToURIMap setObject:[value stringValue] forKey:[name stringValue]];
//		[super handleNameSpaceAttribute:name withValue:value];
//			NSLog(@"prefix2uri map: %@",namespacePrefixToURIMap);
		if ( shouldReportNamespacePrefixes && [documentHandler respondsToSelector:@selector(parser:didStartMappingPrefix:toURI:)] ) {
			[ documentHandler parser:(NSXMLParser*)self didStartMappingPrefix:name toURI:value];
		}
	}
}

-(void)setCharacterHandlerWithDocumentHandler:newCharHandler
{
	characterHandler=newCharHandler;
}
+testSelectors
{
	return [NSArray array];
}

@end

