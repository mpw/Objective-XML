//
//  MPWAtomLink.h
//  ObjectiveXML
//
//  Created by Marcel Weiher on 1/3/11.
//  Copyright 2011 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "mpwfoundation_imports.h"


@interface MPWAtomLink : NSObject {
	NSString *href;
	NSString *rel;
	NSString *type;
}

objectAccessor_h( NSString*, href, setHref )
objectAccessor_h( NSString*, rel, setRel )
objectAccessor_h( NSString*, type , setType )

@end
