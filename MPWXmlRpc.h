//
//  MPWXmlRpc.h
//  MPWXmlKit
//
//  Created by Marcel Weiher on 14.4.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPWMAXParser;
@class MPWXmlRpcGeneratorStream;

@interface MPWXmlRpc : NSObject {
	MPWMAXParser*					parser;
	MPWXmlRpcGeneratorStream*		generator;
}

-generateRequest:(NSString*)requestName withParams:params;
-resultOfSendingEncodedRequest:(NSData*)payload toEndpoint:(NSString*)urlString;
-parseResponse:(NSData*)responseData;

@end
