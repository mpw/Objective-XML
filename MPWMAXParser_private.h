//
//  MPWMAXParser_private.h
//  MPWXmlKit
//
//  Created by Marcel Weiher on 22/04/2008.
//  Copyright 2008 Marcel Weiher. All rights reserved.
//

#import "MPWMAXParser.h"
#import "MPWXmlAttributes.h"
#import "AccessorMacros.h"

@interface MPWXMLAttributes(privateProtocol)

//---	append values with keys and tags

-(void)setValue:(id)anObject forAttribute:(id)aKey ;
-(void)setValueAndRelease:(id)anObject forAttribute:(id)aKey namespace:aNamespace;

//--- private?

-(id*)_pointerToObjects;

@end

typedef struct _NSXMLElementInfo {
	id			elementName;
	id			attributes;
	id			children;
	const char	*start;
	const char  *end;
	BOOL		isIncomplete;
	int			integerTag;
} NSXMLElementInfo;

#define	INITIALTAGSTACKDEPTH 20
#define MAKEDATA( start, length )   initDataBytesLength( getData( dataCache, @selector(getObject)),@selector(reInitWithData:bytes:length:), data, start , length )
//#define MAKEDATA( start, len )		[self makeData:start length:len]

/*  cached IMPs fro SAX document handler methods */

#define	BEGINELEMENTSELECTOR		@selector(parser:didStartElement:namespaceURI:qualifiedName:attributes:)
#define	ENDELEMENTSELECTOR		    @selector(parser:didEndElement:namespaceURI:qualifiedName:)
#define	CHARACTERSSELECTOR		    @selector(parser:foundCharacters:)
#define	CDATASELECTOR				@selector(parser:foundCDATA:)


#define BEGINELEMENT(tag,namespaceURI,fullyQualified,attr)		beginElement(documentHandler, BEGINELEMENTSELECTOR ,self, tag,namespaceURI,fullyQualified,attr)
#define ENDELEMENT(tag,namespaceURI,fullyQualified)				endElement(documentHandler, ENDELEMENTSELECTOR , self,tag,namespaceURI,fullyQualified )

#define RECORDSCANPOSITION( start, length )			lastGoodPosition=start+length
#define TAGFORCSTRING( cstr, len )  uniqueTagForCString(self, @selector(getTagForCString:length:) , cstr, len )
#define	CHARACTERDATAALLOWED		characterDataAllowed( self, @selector(characterDataAllowed:), self )
#define	CHARACTERS( c )				characters( characterHandler , CHARACTERSSELECTOR,self, c )
#define	CDATA( c )					cdata( characterHandler ,CDATASELECTOR,self, c )


#define POPTAG						( [((NSXMLElementInfo*)_elementStack)[--tagStackLen].elementName release])
#define PUSHTAG(aTag) {\
    if ( tagStackLen > tagStackCapacity ) {\
        [self _growTagStack:tagStackCapacity * 2];\
    }\
    ((NSXMLElementInfo*)_elementStack)[tagStackLen++].elementName=[aTag retain];\
}

#define CURRENTOBJECT  				[self currentObject]
#define PUSHOBJECT(anObject, key, aNamespace) {\
    [self pushObject:anObject forKey:key withNamespace:aNamespace];\
}
#define CURRENTELEMENT  			(((NSXMLElementInfo*)_elementStack)[tagStackLen-1] )
#define CURRENTTAG  				((tagStackLen > 0) ? CURRENTELEMENT.elementName : nil)
#define CURRENTINTEGERTAG 			((tagStackLen > 0) ? CURRENTELEMENT.integerTag : -3)



@interface MPWMAXParser(private)

objectAccessor_h( NSError*, parserError, setParserError )

-(void)_growTagStack:(unsigned)newCapacity;
-currentTag;
-(void)pushTag:aTag;
-(void)popTag;
-getTagForCString:(const char*)cstr length:(int)len;
-currentObject;
-(void)handleNameSpaceAttribute:name withValue:value;

-(void)setScanner:newScanner;
-(void)setAutotranslateUTF8:(BOOL)shouldTranslate;

-(void)flushPureSpace;
-(void)clearAttributes;
-(void)_setAttributes:newAttributes;

-(void)setDelegate:newDelegate;

-(void)rebuildPrefixHandlerMap;
-(id)_attributes;
-_fullTagStackString;

-(void)setData:newData;

-(BOOL)makeText:(const char*)start length:(int)len firstEntityOffset:(int)entityOffset;
-(void)pushObject:anObject forKey:aKey withNamespace:aNamespace;
-(int)dataEncoding;
-(void)setDataEncoding:(int)newEncoding;
-(BOOL)parseSource:(NSEnumerator*)source;
-htmlAttributeLowerCaseNamed:(NSString*)lowerCaseAttributeName;
-(BOOL)handleMetaTag;

@end
