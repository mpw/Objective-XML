/* MPWXmlTag.m Copyright (c) Marcel P. Weiher 1999, All Rights Reserver, created  on Sun 23-Aug-1998 */

#import "MPWXmlTag.h"

@implementation MPWXmlTag


+tagWithName:aName
{
    return [[[self alloc] initWithName:aName] autorelease];
}

-initWithName:aName
{
    self = [super init];
    name = [aName retain];
    return self;
}

-(void)dealloc
{
    [name release];
    [super dealloc];
}

-description
{
    return [NSString stringWithFormat:@"<%@>",name];
}

-name
{
    return name;
}

@end

