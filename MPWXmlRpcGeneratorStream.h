//
//  MPWXmlRpcGeneratorStream.h
//  MPWXmlKit
//
//  Created by Marcel Weiher on 21.4.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWXmlGeneratorStream.h"


@interface MPWXmlRpcGeneratorStream : MPWFlattenStream {
}

-(NSData*)requestWithMethodName:(NSString*)requestName parameters:params;
-(NSData*)requestWithMethodName:(NSString*)requestName parameter:param;


@end
