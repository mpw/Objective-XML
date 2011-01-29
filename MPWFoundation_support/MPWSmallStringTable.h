//
//  MPWSmallStringTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 29/3/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPWObject.h"
#import "AccessorMacros.h"



@interface MPWSmallStringTable : NSDictionary {
	int _retainCount;
	int	tableLength;
	char *table;
	__strong id	*tableValues;
	id	defaultValue;
	BOOL caseInsensitive;
	@public
	IMP __stringTableLookupFun;
}

//extern IMP __stringTableLookupFun;

-initWithKeys:(NSArray*)keys values:(NSArray*)values;

-(NSUInteger)count;
-objectForKey:(NSString*)key;
-objectAtIndex:(NSUInteger)anIndex;
-objectForCString:(char*)cstr length:(int)len;
-objectForCString:(char*)cstr;
-(int)offsetForCString:(char*)cstr length:(int)len;
-(int)offsetForCString:(char*)cstr;

idAccessor_h( defaultValue, setDefaultValue )

#define OBJECTFORSTRINGLENGTH( table, str, stlen )  (table->__stringTableLookupFun( table, @selector(objectForCString:length:) , str, stlen ))
#define OBJECTFORCONSTANTSTRING( table, str )  OBJECTFORSTRINGLENGTH( table, str, (sizeof str) -1 )


@end
