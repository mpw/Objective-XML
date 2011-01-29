/* MPWXmlTag2ElementProcessor.m Copyright (c) Marcel P. Weiher 1999, All Rights Reserver, created  on Mon 12-Oct-1998 */

#import "MPWXmlTag2ElementProcessor.h"
#import "MPWXmlElement.h"
#import "MPWXmlScanner.h"
#import <MPWFoundation/MPWScanner.h>

@implementation MPWXmlTag2ElementProcessor

-initWithTarget:aTarget
{
    self = [super initWithTarget:aTarget];
    entityStack = [[NSMutableArray alloc] init];
    return self;
}

-(void)dealloc
{
    [entityStack release];
    [super dealloc];
}

-(void)writeXmlStartTag:aTag
{
    id element = [[MPWXmlElement alloc] initWithTag:aTag];
    [self pushTarget:element];
    [element release];
}

-(void)writeXmlCloseTag:aTag
{
    id lastTarget=[target retain];
    [self popTarget];
    [self writeObject:lastTarget];
    [lastTarget release];
}

@end

@implementation MPWXmlTag2ElementProcessor(testing)

+(NSString*)frameworkPath:(NSString*)aPath
{
    return [[[NSBundle bundleForClass:self] resourcePath] stringByAppendingPathComponent:aPath];
}


+testSelectors
{
    return [NSArray arrayWithObject:@"testParserWithDefaultFile"];
}

+(NSString*)defaultTestFileName
{
    return [self frameworkPath:@"test1.xml"];
}

+(void)testParserWithDefaultFile
{
    id scanner = [MPWXmlScanner scannerWithData:[NSData dataWithContentsOfMappedFile:[self defaultTestFileName]]];
    id result = [self process:scanner];
    NSLog(@"result = %@",result);
}



@end

