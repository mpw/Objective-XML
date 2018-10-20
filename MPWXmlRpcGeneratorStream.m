//
//  MPWXmlRpcGeneratorStream.m
//  MPWXmlKit
//
//  Created by Marcel Weiher on 21.4.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWXmlRpcGeneratorStream.h"

#define  TARGET _target

@interface NSObject(generateXmlRPCOnStream)

-(void)generateXmlRPCOnStream:aStream;

@end

@implementation MPWXmlRpcGeneratorStream

-(SEL)streamWriterMessage
{
    return @selector(generateXmlRPCOnStream:);
}


+defaultTarget
{
	return [MPWXmlGeneratorStream stream];
}

-(void)writeString:(NSString*)param
{
	[TARGET writeElementName:"value" contents:param];
}

-(void)writeNumber:(NSNumber*)param
{
	const char *objcType=[param objCType];
	[TARGET startTag:"value"];
	if ( *objcType == * @encode(double) || *objcType ==  *@encode(float) ) {
		[TARGET writeElementName:"double" contents:param];
	} else {
		[TARGET writeElementName:"i4" contents:param];
	}
	[TARGET closeTag];
}

-(void)writeArray:(NSArray*)param
{
	[[[TARGET startTag:"value"] startTag:"array"] startTag:"data"];
	for (id obj in param ) {
//		[TARGET startTag:"value"];
		[self writeObject:obj];
//		[TARGET closeTag];
	}
	[[[TARGET closeTag] closeTag] closeTag];
}


-(void)writeDictionary:(NSDictionary*)aDict
{
	id keys=[[aDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
	[[TARGET startTag:"value"] startTag:"struct"];
	for (id key in keys ) {
		[[TARGET startTag:"member"] writeElementName:"name" contents:key];
		[self writeObject:[aDict objectForKey:key]];
		[TARGET closeTag];
	}
	[[TARGET closeTag] closeTag];
}

-(NSData*)_requestOrResponse:(const char*)requestOrResponse withMethodName:(NSString*)requestName parameters:paramsArray
{
	[self setTarget:[[self class] defaultTarget]];
	[TARGET writeStandardXmlHeader];
	[TARGET startTag:requestOrResponse];
	if ( requestName ) {
		[TARGET writeElementName:"methodName" contents:requestName];
	}
	if ( paramsArray && [paramsArray count] ) {
		[TARGET startTag:"params"];
		for ( id param in paramsArray ) {
			[TARGET startTag:"param"];
			[self writeObject:param];
			[TARGET closeTag];
		}
		[TARGET closeTag];
	}
	[TARGET closeTag];
	
	return [[(id)[self target] target] target];
}

-(NSData*)requestWithMethodName:(NSString*)requestName parameters:params
{
	return [self _requestOrResponse:"methodCall" withMethodName:requestName parameters:params];
}


-(NSData*)requestWithMethodName:(NSString*)requestName parameter:param
{
	return [self requestWithMethodName:requestName parameters:param ? [NSArray arrayWithObject:param] : param];
}


-(NSData*)response:param
{
	return [self _requestOrResponse:"methodResponse" withMethodName:nil parameters:param ? [NSArray arrayWithObject:param] : param];
}

@end

@implementation NSObject(generateXmlRPCOnStream)

-(void)generateXmlRPCOnStream:aStream
{
	[self flattenOntoStream:aStream];
}

@end

@implementation NSString(generateXmlRPCOnStream)

-(void)generateXmlRPCOnStream:aStream
{
	[aStream writeString:self];
}

@end
@implementation NSNumber(generateXmlRPCOnStream)

-(void)generateXmlRPCOnStream:aStream
{
	[aStream writeNumber:self];
}

@end

//#import "DebugMacros.h"

@implementation MPWXmlRpcGeneratorStream(testing)

+(void)testSingleStringParamRequest
{
	MPWXmlRpcGeneratorStream *generator = [self stream];
	NSData *result=[generator requestWithMethodName:@"lengthOfString" parameter:@"hello world"];
	IDEXPECT( [result stringValue], [[self frameworkResource:@"stringLengthRequest" category:@"xmlrpc"] stringValue], @"encoding simple string request");
}

+(void)testDictParamResponse
{
	MPWXmlRpcGeneratorStream *generator = [self stream];
	NSDictionary *responseDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:123],@"Number (int)",
								  [NSNumber numberWithDouble:512.45],@"Number (double)",
								  @"hello world",@"String",nil];
	NSData *result=[generator response:responseDict];
	IDEXPECT( [result stringValue], [[self frameworkResource:@"getSimpleDictResponse" category:@"xmlrpc"] stringValue], @"encoding simple dict response");
}

+(void)testLoginRequest
{
	MPWXmlRpcGeneratorStream *generator = [self stream];
	NSDictionary *loginParamDict = [NSDictionary dictionaryWithObjectsAndKeys:
								  @"passwordBla",@"password",nil];
	NSArray *parameters=[NSArray arrayWithObjects:@"userName",loginParamDict,nil];
	NSData *result=[generator requestWithMethodName:@"login" parameters:parameters];
	IDEXPECT( [result stringValue], [[self frameworkResource:@"loginRequest" category:@"xmlrpc"] stringValue], @"encoding simple dict response");
}

+(void)testUTF8Request
{
	MPWXmlRpcGeneratorStream *generator = [self stream];
	NSString *arg=@"Ähh";
	NSString *expected=@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<methodCall><methodName>lengthOfString</methodName><params><param><value>Ähh</value></param></params></methodCall>";
	NSData *result=[generator requestWithMethodName:@"lengthOfString" parameter:arg];
	NSString *resultString=[[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease];
	EXPECTNOTNIL( resultString, @"able to decode the request");
	IDEXPECT( resultString, expected , @"encoded request" );
}

+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testSingleStringParamRequest",
//			@"testDictParamResponse",
//			@"testLoginRequest",
			@"testUTF8Request",
			nil];
}

@end
