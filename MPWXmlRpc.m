//
//  MPWXmlRpc.m
//  MPWXmlKit
//
//  Created by Marcel Weiher on 14.4.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWXmlRpc.h"
#import "MPWMAXParser.h"
#import "MPWXmlRpcGeneratorStream.h"
@implementation MPWXmlRpc

objectAccessor( MPWMAXParser , parser, setParser )
objectAccessor( MPWXmlRpcGeneratorStream , generator, setGenerator )


-init
{
	self=[super init];
	[self setParser:[MPWMAXParser parser]];
	[self setGenerator:[MPWXmlRpcGeneratorStream stream]];
	[[self parser] setHandler:self forElements:[NSArray arrayWithObjects:@"value",@"i4",@"double",@"data",@"member",@"struct",@"string",@"params",@"methodCall",@"html",@"HTML",nil] inNamespace:nil prefix:@"" map:nil];
	return self;
}

-htmlElement:(MPWXMLAttributes*)children attributes:(MPWXMLAttributes*)attrs parser:(MPWMAXParser*)parser
{
	NSLog(@"html Element, raise");
	[parser setParserError:[NSError errorWithDomain:@"XMLRPC" code:1 userInfo:nil]];
	[NSException raise:@"html" format:@"html in xmlrpc"];
	return nil;
}

-HTMLElement:(MPWXMLAttributes*)children attributes:(MPWXMLAttributes*)attrs parser:(MPWMAXParser*)parser
{
	NSLog(@"HTML Element, raise");
	[parser setParserError:[NSError errorWithDomain:@"XMLRPC" code:1 userInfo:nil]];
	[NSException raise:@"html" format:@"html in xmlrpc"];
	return nil;
}

-doubleElement:(MPWXMLAttributes*)children attributes:(MPWXMLAttributes*)attrs parser:(MPWMAXParser*)parser
{
	return [[NSNumber numberWithDouble:[[children lastObject] doubleValue]] retain];
}

-i4Element:(MPWXMLAttributes*)children attributes:(MPWXMLAttributes*)attrs parser:(MPWMAXParser*)parser
{
	return [[NSNumber numberWithInt:[[children lastObject] intValue]] retain];
}

-dataElement:(MPWXMLAttributes*)children attributes:(MPWXMLAttributes*)attrs parser:(MPWMAXParser*)parser
{
	return [[children allValues] retain];
}

-undeclaredElement:(MPWXMLAttributes*)children attributes:(MPWXMLAttributes*)attrs parser:(MPWMAXParser*)parser
{
	return [[children lastObject] retain];
}

-stringElement:(MPWXMLAttributes*)children attributes:(MPWXMLAttributes*)attrs parser:(MPWMAXParser*)parser
{
	return [[children combinedText] retain];
}

-valueElement:(MPWXMLAttributes*)children attributes:(MPWXMLAttributes*)attrs parser:(MPWMAXParser*)parser
{
//	NSLog(@"valueElement: %@",children);
	if ( [[children keyAtIndex:0] isEqual:MPWXMLPCDataKey] ) {
		return [[children combinedText] retain];
	} else {
		return [[children lastObject] retain];
	}
}



-defaultElement:(MPWXMLAttributes*)children attributes:(MPWXMLAttributes*)attrs parser:(MPWMAXParser*)parser
{
	return [children copy];
}

-structElement:(MPWXMLAttributes*)children attributes:(MPWXMLAttributes*)attrs parser:(MPWMAXParser*)parser
{
	NSMutableDictionary *structReturn=[[NSMutableDictionary alloc] init];
	for ( MPWXMLAttributes *member in [children allValues]) {
		NSString *name=[member objectForKey:@"name"];
		id value=[member objectForKey:@"value"];
		if ( name && value ) {
			[structReturn setObject:value forKey:name];
		}
	}
	return structReturn;
}


-parseRequest:(NSData*)requestData
{
	id result=nil;
	if ( requestData ) {
		[[self parser] parse:requestData];
		result = [parser parseResult];
		if ( [[self parser] parserError] ) {
			NSLog(@"parseRequest had parseError");
			[NSException raise:@"parseError" format:@"error: %@",[[self parser] parserError]];
		}
	} 
	return result;
}

-parseResponse:(NSData*)responseData
{
	NSDictionary *response = [self parseRequest:responseData];
//	NSLog(@"response: %@",response);
	return [response objectForKey:@"param"];
}

-generateRequest:(NSString*)requestName withParams:params
{
	return [generator requestWithMethodName:requestName parameters:params];
}



-generateRequest:(NSString*)requestName withStringArg:(NSString*)arg
{
#if 0
	NSString *params=@"";
	if ( arg ) {
		params=[NSString stringWithFormat:@"<params><param><value>%@</value></param></params>",arg];
	}
#endif
	return [self generateRequest:requestName withParams:arg ? [NSArray arrayWithObject:arg]: arg];
}

-generateRequest:(NSString*)requestName 
{
	return [self generateRequest:requestName withParams:nil];
}

-(NSData*)generateResponse:param
{
	return [[self generator] response:param];
}


-resultOfSendingEncodedRequest:(NSData*)payload toEndpoint:(NSString*)urlString
{
	NSURL* url = [NSURL URLWithString:urlString];
	NSError *error=nil;
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	[request setValue: [[NSNumber numberWithInt:[payload length]] stringValue]  forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:payload];
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
	if ( error ) {
		NSLog(@"error: %@",error);
	}
	return responseData;
}

-parsedResultOfSendingEncodedRequest:(NSData*)payload toEndpoint:(NSString*)urlString
{
	return [self parseResponse:[self resultOfSendingEncodedRequest:payload toEndpoint:urlString]];
}


-(void)dealloc
{
	[parser release];
	[generator release];
	[super dealloc];
}

@end

//#import "DebugMacros.h"


@implementation MPWXmlRpc(testing)

+(void)testCanParseBasicIntegerRpcResponse
{
	id rpc=[[self new] autorelease];
	id response1 = [self frameworkResource:@"stringLengthResponse" category:@"xmlrpc"];
	EXPECTNOTNIL( response1, @"response1");
	id parsedResponse = [rpc parseResponse:response1];
	IDEXPECT( parsedResponse, [NSNumber numberWithInt:4], @"stringLength Response");
	id parsedResponse1 = [rpc parseResponse:[self frameworkResource:@"stringLengthResponse1" category:@"xmlrpc"]];
	IDEXPECT( parsedResponse1, [NSNumber numberWithInt:12], @"stringLength Response1");
}

+(void)testCanParseArrayRpcResponse
{
	id rpc=[[self new] autorelease];
	NSArray *expected=[NSArray arrayWithObjects:@"first string element",[NSNumber numberWithInt:42],@"20010110T12:59:08",nil];
	id response1 = [self frameworkResource:@"getListResponse" category:@"xmlrpc"];
	EXPECTNOTNIL( response1, @"response1");
	id parsedResponse = [rpc parseResponse:response1];
	IDEXPECT( parsedResponse, expected, @"array response");
}

+(void)testCanParseStructRpcResponse
{
	id rpc=[[self new] autorelease];
	NSDictionary *expected=[NSDictionary dictionaryWithObjectsAndKeys:
							@"20090414T19:12:45",@"Date",[NSNumber numberWithDouble:47.11],@"Some double",[NSNumber numberWithInt:42],@"Some integer",@"hello world",@"String",nil];
	id response1 = [self frameworkResource:@"getDictResponse" category:@"xmlrpc"];
	EXPECTNOTNIL( response1, @"response1");
	id parsedResponse = [rpc parseResponse:response1];
	IDEXPECT( parsedResponse, expected, @"struct response");
}

+(void)testCanGenerateSimpleStringArgRequest
{
	id rpc=[[self new] autorelease];
	id request1 = [self frameworkResource:@"stringLengthRequest" category:@"xmlrpc"];
	EXPECTNOTNIL( request1, @"response1");
	id generatedRequest = [rpc generateRequest:@"lengthOfString" withStringArg:@"hello world"];
	IDEXPECT( [generatedRequest stringValue], [request1 stringValue], @"simple string request");
}

+(void)testCanGenerateSimpleNoArgRequest
{
	id rpc=[[self new] autorelease];
	id request1 = [self frameworkResource:@"getDictRequest" category:@"xmlrpc"];
	EXPECTNOTNIL( request1, @"response1");
	id generatedRequest = [rpc generateRequest:@"getADict" withStringArg:nil];
	IDEXPECT( [generatedRequest stringValue], [request1 stringValue], @"simple string request");
	generatedRequest = [rpc generateRequest:@"getADict" ];
	IDEXPECT( generatedRequest, request1, @"simple string request");
}

+(void)testCanParseResponseWithAmpersands
{
	id rpc=[[self new] autorelease];
	id response1 = [self frameworkResource:@"responseWithAmpersands" category:@"xmlrpc"];
	EXPECTNOTNIL( response1, @"response1");
	id parsedResponse = [rpc parseResponse:response1];
	IDEXPECT( [parsedResponse objectForKey:@"someLink"], @"http://www.example.com/cgi-bin/mySuperCGI/pageName?source=asdfasdeiasdgkvMpz10f&data_one=OPOT&data_two=Testing One Two Three", @"should have whole response, not just last piece" );
}	

+(void)testCanParseRequest
{
	id rpc=[[self new] autorelease];
	NSData *cannedRequest = [self frameworkResource:@"loginRequest" category:@"xmlrpc"];
	NSDictionary* parsedRequest = [rpc parseRequest:cannedRequest];
	EXPECTNOTNIL( [parsedRequest objectForKey:@"methodName"], @"should have a method name");
	IDEXPECT( [parsedRequest objectForKey:@"methodName"], @"login", @"method name");
//	NSLog(@"parsedRequest: %@",parsedRequest);
	NSArray *allParams=[[parsedRequest objectForKey:@"params"] allValues];
	NSString *method = [allParams objectAtIndex:0];
	NSArray *restParams = [allParams subarrayWithRange:NSMakeRange(1, [allParams count]-1)];
//	NSLog(@"allParams: %@",allParams);
	EXPECTNOTNIL( allParams, @"params");
	NSString *password=[[restParams lastObject] objectForKey:@"password"];
	IDEXPECT( password, @"passwordBla",@"password");
}

+(void)testHtmlRaisesException
{
	id rpc=[[self new] autorelease];
	NS_DURING
		NSLog(@"will try to parse");
		id result =[rpc parseResponse:[@"<html><body>some response</body></html>" dataUsingEncoding:NSUTF8StringEncoding]];
		NSLog(@"did try to parse result: %@",result);
		EXPECTTRUE( NO, @"didn't raise");
	NS_HANDLER
//		NSLog(@"did raise properly");
	NS_ENDHANDLER
	NS_DURING
		NSLog(@"will try to parse");
		id result =[rpc parseResponse:[@"<HTML><body>some response</body></HTML>" dataUsingEncoding:NSUTF8StringEncoding]];
		NSLog(@"did try to parse result: %@",result);
		EXPECTTRUE( NO, @"didn't raise");
	NS_HANDLER
//		NSLog(@"did raise properly");
	NS_ENDHANDLER
	//	EXPECTTRUE( NO, @"implemented");
}

+testSelectors {
	return [NSArray arrayWithObjects:
			@"testCanParseBasicIntegerRpcResponse",
			@"testCanParseArrayRpcResponse",
			@"testCanParseStructRpcResponse",
			@"testCanGenerateSimpleStringArgRequest",
			@"testCanGenerateSimpleNoArgRequest",
			@"testCanParseResponseWithAmpersands",
			@"testCanParseRequest",
			@"testHtmlRaisesException",
			nil];
}

@end


