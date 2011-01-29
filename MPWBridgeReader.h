//
//  MPWBridgeReader.h
//  MPWXmlKit
//
//  Created by Marcel Weiher on 6/4/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPWBridgeReader : NSObject {
	id	context;
	id	loadedSet;
	int count;
	
}

-(void)parseFrameworkAtPath:(NSString*)frameworkPath;


@end
