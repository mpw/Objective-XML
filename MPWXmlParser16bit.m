/* MPWXmlParser16bit.m Copyright (c) 1999 by Marcel P. Weiher, All Rights Reserved */

#import "MPWXmlParser16bit.h"

@implementation MPWXmlParser(sixtenBit)

typedef unichar xmlchar;

#import "delimitAttrValues.h"


-(BOOL)endElementBE:(const xmlchar*)start length:(int)len
{
    id endName;
    start+=2;
    len-=3;
    endName = MPWUniqueStringWithUnichars(start,len);
    if ( [[self currentTag] isEqual: endName] ) {
        POPTAG;
        ENDELEMENT( endName );
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
    BEGINELEMENT( tag, attrs );
    if ( isEmpty ) {
        POPTAG;
        ENDELEMENT(tag);
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
        CHARACTERS([NSString stringWithCharacters:start length:len]);
    }
    return YES;
}

-(BOOL)makeCDataBE:(const xmlchar*)start length:(int)len
{
    int cdlen = 9;
    start+=cdlen;
    len-=cdlen+2;
    if ( [self characterDataAllowed] ) {
        CDATA([NSString stringWithCharacters:start length:len]);
        //--- also have to check for non '@' valueType
    }
    return YES;
}



@end

