/* MPWXmlStartTag.h Copyright (c) Marcel P. Weiher 1999, All Rights Reserver, created  on Mon 28-Sep-1998 */

#import <MPWXmlKit/MPWXmlTag.h>

@interface MPWXmlStartTag : MPWXmlTag
{
    id	attributes;
    BOOL single;
}

idAccessor_h( attributes, setAttributes)
boolAccessor_h( single, setSingle )
-attributeForKey:aKey;

@end
