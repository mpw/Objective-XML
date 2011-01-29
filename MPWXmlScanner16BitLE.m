/* MPWXmlScanner16BitLE.m Copyright (c) 1999 by Marcel P. Weiher, All Rights Reserved */

#import "MPWXmlScanner16BitLE.h"

#import "MPWXmlScanner16BitBE.h"
#import "MPWXmlParser.h"

#define	xmlchar	unichar
#define	XMLCHAR(x)	NSSwapHostShortToLittle(x)
#define	NATIVECHAR(x)	NSSwapLittleShortToHost(x)

static unichar cdata[]={ XMLCHAR('<'), XMLCHAR('!') , XMLCHAR('['),XMLCHAR('C'),XMLCHAR('D'),XMLCHAR('A'),XMLCHAR('T'),XMLCHAR('A'),XMLCHAR('[') };
static unichar endcomment[]={ XMLCHAR('-'),XMLCHAR('-') , XMLCHAR('>')};
static unichar empty[]={ 0, };

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

#define	CDATA		cdata
#define ENDCOMMENT	endcomment
#define	CHARCOMP	unicharncmp
#define	EMPTYSTRING	empty



#import "XmlScannerPseudoMacro.h"


@implementation MPWXmlScanner(sixteenBitBE)

-(BOOL)makeTextBE:(const xmlchar*)start length:(int)len firstEntityOffset:(int)entityStart
{
    NSLog(@"%s: unicode string: %@",__FUNCTION__,[NSString stringWithCharacters:start length:len]);
    return YES;
}

-(BOOL)makeCDataBE:(const xmlchar*)start length:(int)len
{
    NSLog(@"%s: unicode string: %@",__FUNCTION__,[NSString stringWithCharacters:start length:len]);
    return YES;
}

-(BOOL)beginElementBE:(const xmlchar*)start length:(int)len nameLen:(int)nameEnd
{
    NSLog(@"%s: unicode string: %@",__FUNCTION__,[NSString stringWithCharacters:start length:len]);
    return YES;
}

-(BOOL)endElementBE:(const xmlchar*)start length:(int)len
{
    NSLog(@"%s: unicode string: %@",__FUNCTION__,[NSString stringWithCharacters:start length:len]);
    return YES;
}

-(BOOL)makeSgmlBE:(const xmlchar*)start length:(int)len nameLen:(int)nameEnd
{
    NSLog(@"%s: unicode string: %@",__FUNCTION__,[NSString stringWithCharacters:start length:len]);
    return YES;
}

-(BOOL)makePIBE:(const xmlchar*)start length:(int)len nameLen:(int)nameEnd
{
    NSLog(@"%s: unicode string: %@",__FUNCTION__,[NSString stringWithCharacters:start length:len]);
   return YES;
}

-(BOOL)makeEntityRefBE:(const xmlchar*)start length:(int)len
{
    NSLog(@"%s: unicode string: %@",__FUNCTION__,[NSString stringWithCharacters:start length:len]);
    return YES;
}



-(void)scan16bitBE:(NSData*)aData
{
    ProcessFunc text = (ProcessFunc)[self methodForSelector:@selector(makeTextBE:length:firstEntityOffset:)];
    ProcessFunc space = (ProcessFunc)[self methodForSelector:@selector(makeTextBE:length:firstEntityOffset:)];
    ProcessFunc cdata = (ProcessFunc)[self methodForSelector:@selector(makeCDataBE:length:)];
    ProcessFunc sgml = (ProcessFunc)[self methodForSelector:@selector(makeSgmlBE:length:nameLen:)];
    ProcessFunc pi = (ProcessFunc)[self methodForSelector:@selector(makePIBE:length:nameLen:)];
    ProcessFunc openTag = (ProcessFunc)[self methodForSelector:@selector(beginElementBE:length:nameLen:)];
    ProcessFunc closeTag = (ProcessFunc)[self methodForSelector:@selector(endElementBE:length:)];
//    ProcessFunc entityRef = (ProcessFunc)[self methodForSelector:@selector(makeEntityRef:length:)];
    data=[aData retain];
    scanXml( [data bytes], [data length] / sizeof(xmlchar),  openTag, closeTag, sgml,pi, text,space,cdata, self );
    [data release];
    data=nil;
}

@end

@implementation MPWXmlParser(sixtenBit)

-(BOOL)endElementBE:(const xmlchar*)start length:(int)len
{
    id endName;
    int i;
    start+=2;
    len-=3;
    endName = MPWUniqueStringWithUnichars(start,len);
    if ( [[self currentTag] isEqual: endName] ) {
        [self popTag];
        [self endElement:endName];
        return YES;
    } else {
        [NSException raise:@"non-matching tags" format:@"non matching tags start '%@' end '%@'",[self currentTag],endName];
        return NO;
    }
}

-(BOOL)beginElementBE:(const xmlchar*)start length:(int)len nameLen:(int)nameLen
{
    id tag;
    BOOL isEmpty=NO;
    const xmlchar *attrStart;
    int attrLen;
    id attrs;


    start++;
    nameLen--;
    len-=2;
    attrStart=start+nameLen+1;
    attrLen=len-nameLen-1;

    if ( start[len-1]=='/' ) {
        isEmpty=YES;
        len--;
    } else {

    }
    tag = MPWUniqueStringWithUnichars(start,nameLen);
    [self pushTag:tag];
    attrs = GETOBJECT(attributeCache);
//    [self scanAttributesFromData:[NSString stringWithCharacters:start length:nameLen] into:attrs];
    [self beginElement:tag attributes:attrs];
    if ( isEmpty ) {
        [self popTag];
        [self endElement:tag];
    }
    return YES;
}

-(BOOL)characterDataAllowed
{
    return NO;
}

-(BOOL)makeTextBE:(const xmlchar*)start length:(int)len firstEntityOffset:(int)entityOffset
{
    if ([self characterDataAllowed] ) {
        [self characters:[NSString stringWithCharacters:start length:len]];
    }
    return YES;
}

-(BOOL)makeCDataBE:(const xmlchar*)start length:(int)len
{
    int cdlen = 9;
    start+=cdlen;
    len-=cdlen+2;
    if ( [self characterDataAllowed] ) {
        [self cdata:[NSString stringWithCharacters:start length:len]];
        //--- also have to check for non '@' valueType
    }
    return YES;
}

