//
//  MPWBridgeReader.m
//  MPWXmlKit
//
//  Created by Marcel Weiher on 6/4/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import "MPWBridgeReader.h"
#import "MPWMAXParser.h"
#import "mpwfoundation_imports.h"
#ifndef WINDOWS
#include <dlfcn.h>
#endif

@interface NSObject(valueBinding)

-(void)bindValue:value toVariableNamed:name;

@end

@implementation MPWBridgeReader

idAccessor( context ,setContext )
idAccessor( loadedSet, setLoadedSet )

-(NSUInteger)count { return count; }

-initWithContext:aContext
{
	self=[super init];
	[self setContext:aContext];
	[self setLoadedSet:[NSMutableSet new]];
	return self;
}

+(void)parseBridgeDict:aDict forContext:aContext
{
	id pool=[NSAutoreleasePool new];
	id reader = [[[self alloc] initWithContext:aContext] autorelease];
	[reader parse:aDict];
	NSLog(@"%d total elements",[reader count]);
	[pool release];
}

-enumTag:attrs parser:parser
{
	[context bindValue:[NSNumber numberWithInt:[[attrs objectForKey:@"value"] intValue]] toVariableNamed:[[attrs objectForKey:@"name"] stringValue]];
	return nil;
}

-defaultElement:children attributes:a parser:p {  count++; /* NSLog(@"<%@ > ",[p currentTag]); */ return nil; }

-depends_onElement:children attributes:attributes parser:parser
{
	id path = [[[attributes objectForKey:@"path"] copy] autorelease];
//	NSLog(@"dependency: %@",path);
	if ( path ) {
		if ( ![[self loadedSet] containsObject:path] ) {
			[[self loadedSet] addObject:path];
			[self parseFrameworkAtPath:path];
		} else {
//			NSLog(@"skipping %@, already seen",path);
		}
	}
	return nil;
}

-constantTag:attrs parser:parser
{
	if ( [[attrs objectForKey:@"type"] isEqual:@"@"] ) {
		char symbol[255]="";
		id name = [attrs objectForKey:@"name"];
		[name getCString:symbol maxLength:250];
		symbol[ [name length] ] =0;
		
#ifndef WINDOWS
		id* ptr=dlsym( RTLD_DEFAULT, symbol );
		if ( ptr && *ptr )  {
			[context bindValue:*ptr toVariableNamed:[name stringValue]];
		}
#endif		
	}
	return nil;
}


-(BOOL)parse:xmlData
{
	id pool=[NSAutoreleasePool new];
	if ( xmlData ) {
		id parser=[MPWMAXParser parser];

		[parser setHandler:self forTags:[NSArray arrayWithObjects:@"enum",@"constant",@"depends_on",nil] inNamespace:nil 
						       prefix:@"" map:nil];


		[parser parse:xmlData];
	
		[pool release];
	}
	return YES;
}

-(void)parseFrameworkAtPath:(NSString*)frameworkPath
{
	id frameworkName=[[frameworkPath lastPathComponent] stringByDeletingPathExtension];
	id bridgeSupportFilePath = [NSString stringWithFormat:@"%@/Resources/BridgeSupport/%@.bridgesupport",
									frameworkPath,frameworkName];
	[self parse:[NSData dataWithContentsOfFile:bridgeSupportFilePath]];
}

-(void)dealloc
{
	[context release];
	[super dealloc];
}

@end
