/* MPWXmlStartTag.m Copyright (c) Marcel P. Weiher 1999, All Rights Reserver, created  on Mon 28-Sep-1998 */

#import "MPWXmlStartTag.h"
#import "MPWXmlGeneratorStream.h"

@implementation MPWXmlStartTag

idAccessor( attributes, setAttributes)
boolAccessor( single, setSingle )

-(void)dealloc
{
    [attributes release];
    [super dealloc];
}

-description
{
    return attributes ?
    [NSString stringWithFormat:@"<%@ %@%s>",name,attributes,single?"/":""] :
    [super description];
}


-attributeForKey:aKey
{
    return [attributes objectForKey:aKey];
}

-(void)generateXmlOnto:aStream
{
    [aStream writeStartTag:name attributes:attributes single:single];
}

@end

