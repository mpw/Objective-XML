/* MPWXmlCloseTag.m Copyright (c) Marcel P. Weiher 1999, All Rights Reserver, created  on Mon 28-Sep-1998 */

#import "MPWXmlCloseTag.h"
#import "MPWXmlGeneratorStream.h"

@implementation MPWXmlCloseTag

-description
{
    return [NSString stringWithFormat:@"</%@>",name];
}

-(void)generateXmlOnto:aStream
{
    [aStream writeCloseTag:name];
}

@end

