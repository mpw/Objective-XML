//
//  MPWAtomLink.m
//  ObjectiveXML
//
//  Created by Marcel Weiher on 1/3/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import "MPWAtomLink.h"

@implementation MPWAtomLink

objectAccessor( NSString, href, setHref )
objectAccessor( NSString, rel, setRel )
objectAccessor( NSString, type , setType )


-(void)dealloc
{
	[href release];
	[rel release];
	[type release];
	[super dealloc];
}

@end
