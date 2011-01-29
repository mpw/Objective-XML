//
//  MPWTagHandler.h
//  MPWXmlKit
//
//  Created by Marcel Weiher on 2/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MPWTagHandler : NSObject {
	id	element2actionMap;
	id	tag2actionMap;
	id  tagMap;
	id	exceptionMap;
	id	attributeMap;
	id	namespaceString;
}

-(void)setExceptionMap:(NSDictionary*)map;
-(void)declareAttributes:(NSArray*)attributes;

-(void)initializeActionMapWithTags:(NSArray*)keys target:actionTarget prefix:prefix;
-(void)initializeTagActionMapWithTags:(NSArray*)keys caseInsensitive:(BOOL)caseInsensitive target:actionTarget prefix:prefix;
-(void)setUndeclaredElementHandler:handler backup:backup;
-(void)setInvocation:anInvocation forElement:(NSString*)tagName;



//---	getting FastInvocations for names

-elementHandlerInvocationForCString:(const char*)cstr length:(int)len;
-tagHandlerInvocationForCString:(const char*)cstr length:(int)len;
-namespaceString;
-(void)setNamespaceString:(id)newNamespaceString;


@end
