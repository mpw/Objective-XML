//
//  MPWTagHandler.m
//  MPWXmlKit
//
//  Created by Marcel Weiher on 2/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MPWTagHandler.h"
#import "mpwfoundation_imports.h"
#import <objc/objc.h>

@implementation MPWTagHandler

objectAccessor( NSDictionary , exceptionMap, setExceptionMap )
idAccessor( attributeMap, setAttributeMap )
idAccessor( namespaceString, setNamespaceString )
idAccessor( tagMap, setTagMap )
idAccessor( tag2actionMap, setTag2actionMap )
idAccessor( element2actionMap, setElement2actionMap )

-(SEL)defaultElementSelector
{
	return @selector(defaultElement:attributes:parser:);
}

-_actionInvocationForAlreadyMappedTag:(NSString*)tag suffix:(NSString*)suffix defaultSelector:(SEL)defaultSelector target:actionTarget
{
	int tagLen=[tag length],suffixLen=[suffix length];
	char selName[ tagLen + suffixLen + 2];
	SEL selector;
	id invocation;
	int encoding=NSUTF8StringEncoding;
#if WINDOWS
	encoding=NSISOLatin1StringEncoding;
#endif
//	NSLog(@"_actionInvocationForAlreadyMappedTag");
	[tag getCString:selName maxLength:tagLen+1 encoding:encoding];
	[suffix getCString:selName+tagLen maxLength:suffixLen+1 encoding:encoding];
	selName[tagLen+suffixLen]=0;
//	NSLog(@"selName: '%s'",selName);
//	selector=sel_getUid( selName );
	selector=NSSelectorFromString( [NSString stringWithCString:selName encoding:encoding] );
//	NSLog(@"selector '%p'",selector);
	if ( !selector || ![actionTarget respondsToSelector:selector] ) {
		selector=defaultSelector;
	}
//	NSLog(@"will create invocation");
	invocation = [[MPWFastInvocation new] autorelease];
//	NSLog(@"did create invocation");
	[invocation setSelector:selector];
//	NSLog(@"tag: %@ actionTarget: %x/%@, %s",tag,actionTarget,actionTarget,selName);
	[invocation setTarget:actionTarget];
	[invocation setUseCaching:YES];
//	NSLog(@"return the invocation");
	return invocation;
}

-actionInvocationForTag:(NSString*)tag suffix:(NSString*)suffix defaultSelector:(SEL)defaultSelector target:actionTarget 
{
	id mappedTag=[exceptionMap objectForKey:tag];
	if ( mappedTag ) {
		tag=mappedTag;
	}
	return [self _actionInvocationForAlreadyMappedTag:tag suffix:suffix defaultSelector:defaultSelector target:actionTarget];
}


-actionInvocationForElement:(NSString*)tag target:actionTarget suffix:suffix
{
	return [self actionInvocationForTag:tag suffix:suffix defaultSelector:[self defaultElementSelector] target:actionTarget];
}

-actionMapWithTags:(NSArray*)keys caseInsensitive:(BOOL)caseInsensitive target:actionTarget suffix:(NSString*)suffix
{
	id map;
	Class tableClass = (caseInsensitive ? [MPWCaseInsensitiveSmallStringTable class] : [MPWSmallStringTable class]);
	id invocations=[NSMutableArray array];
//	NSLog(@"-[MPWTagHandler actionMapWithTags:%@ caseInsensitive:%d target:%@ suffix:%@]",keys,caseInsensitive,actionTarget,suffix);
//	NSLog(@"will do keys (pointer): %p",keys);
//	NSLog(@"will do keys: %@",keys);
	for ( id key in keys ) {
//		NSLog(@"key: %@",key);
		[invocations addObject:[self actionInvocationForElement:key target:actionTarget suffix:suffix]];
	}
//	NSLog(@"did do keys wil do table");
//	NSLog(@"did do keys wil do table with keys: %@ invocations: %@",keys,invocations);
	map=[[[tableClass alloc] initWithKeys:keys values:invocations] autorelease];
//	NSLog(@"got table");
//	[map setDefaultValue:[self actionInvocationForElement:@"undeclared" target:actionTarget suffix:suffix]];
	return map;
//	[tagMap setDefaultValue:@"default"];
}

-(void)setUndeclaredElementHandler:handler backup:backup
{
	id realTarget=nil;
	id invocation=nil;
	if ( [handler respondsToSelector:@selector(undeclaredElement:attributes:parser:)] ) {
		realTarget=handler;
	} else {
		realTarget=backup;
	}
	invocation = [self actionInvocationForElement:@"undeclared" target:realTarget suffix:@"Element:attributes:parser:"];
	[element2actionMap setDefaultValue:invocation];
}

-(void)initializeActionMapWithTags:(NSArray*)keys caseInsensitive:(BOOL)caseInsensitive target:actionTarget
{
	Class tableClass = (caseInsensitive ? [MPWCaseInsensitiveSmallStringTable class] : [MPWSmallStringTable class]);
	[self setElement2actionMap:[self actionMapWithTags:keys caseInsensitive:caseInsensitive target:actionTarget suffix:@"Element:attributes:parser:"]];
	[self setTagMap:[[[tableClass alloc] initWithKeys:keys values:keys] autorelease]];
}

-(void)initializeActionMapWithTags:(NSArray*)keys target:actionTarget prefix:prefix
{
	Class tableClass = (NO ? [MPWCaseInsensitiveSmallStringTable class] : [MPWSmallStringTable class]);
//	NSLog(@"tableClass: %@",tableClass);
	[self setElement2actionMap:[self actionMapWithTags:keys caseInsensitive:NO target:actionTarget suffix:[prefix stringByAppendingString:@"Element:attributes:parser:"]] ];
	[self setTagMap:[[[tableClass alloc] initWithKeys:keys values:keys] autorelease]];
}

-(void)initializeTagActionMapWithTags:(NSArray*)keys caseInsensitive:(BOOL)caseInsensitive target:actionTarget prefix:prefix
{
	[self setTag2actionMap:[self actionMapWithTags:keys caseInsensitive:caseInsensitive target:actionTarget suffix:[prefix stringByAppendingString:@"Tag:parser:"]]];
}

-(void)setInvocation:anInvocation forElement:(NSString*)tagName
{
	[element2actionMap setObject:anInvocation forKey:tagName];
}


-(void)initializeTagActionMapWithTags:(NSArray*)keys caseInsensitive:(BOOL)caseInsensitive target:actionTarget
{
	[self initializeTagActionMapWithTags:keys caseInsensitive:caseInsensitive target:actionTarget prefix:@""];
}

-(void)initializeActionMapWithTags:(NSArray*)keys target:actionTarget
{
//	NSLog(@"-[MWPTagHandler initializeActionMapWithTags:%@ target:%@]",keys,actionTarget);
	[self initializeActionMapWithTags:keys caseInsensitive:0 target:actionTarget];

}


-getTagForCString:(const char*)cstr length:(int)len
{
	id tag = [tagMap objectForCString:(char*)cstr length:len];
	return tag;
}

-elementHandlerInvocationForCString:(const char*)cstr length:(int)len
{
	return [element2actionMap objectForCString:(char*)cstr length:len];
}

-tagHandlerInvocationForCString:(const char*)cstr length:(int)len
{
	return [tag2actionMap objectForCString:(char*)cstr length:len];
}

-(void)declareAttributes:(NSArray*)attributes 
{
	[self setAttributeMap:[[[MPWSmallStringTable alloc] initWithKeys:attributes values:attributes] autorelease]];
}


-description
{
	return [NSString stringWithFormat:@"<%@/%x:  %@>",[self class],self,namespaceString];
}

-(void)dealloc
{
	[element2actionMap release];
	[tag2actionMap release];
	[tagMap release];
	[exceptionMap release];
	[attributeMap release];
	[super dealloc];
}

@end
#ifndef RELEASE

@interface MPWTagHandlerTesting : NSObject {}

@end 


@implementation MPWTagHandlerTesting

+dummyElement:children attributes:attrs parser:paser
{
	return @"42";
}

+(void)testElementHandlerForCString
{
	id handler=[[[MPWTagHandler alloc] init] autorelease];
	id invocation;
	[handler initializeActionMapWithTags:[NSArray arrayWithObjects:@"dummy",nil] target:self prefix:@""];
	invocation = [handler elementHandlerInvocationForCString:"dummy" length:5];
	NSLog(@"invocation: %x",invocation);
	NSAssert1( invocation != nil , @"invocation %x should not ben nil",invocation);
	IDEXPECT( [invocation resultOfInvoking], @"42", @"result of invoking");

}

+(NSArray*)testSelectors
{
	return [NSArray arrayWithObjects:
				@"testElementHandlerForCString",
				nil];
}	


@end

#endif
