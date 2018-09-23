//
//  MPWJSONWriter.h
//  ObjectiveXML
//
//  Created by Marcel Weiher on 12/30/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWNeXTPListWriter.h>


@interface MPWJSONWriter : MPWNeXTPListWriter {
}

-(void)writeNull;
-(void)writeInteger:(int)number;
-(void)writeFloat:(double)number;
-(void)writeInteger:(int)number forKey:(const char*)aKey;
-(void)writeString:(NSString*)string forKey:(const char*)aKey;

@end

@interface MPWJSONWriter(redeclare)

-(void)writeDictionaryLikeObject:anObject withContentBlock:(void (^)(MPWJSONWriter* writer))contentBlock;



@end

@interface NSObject(jsonWriting)

-(void)writeOnJSONStream:(MPWJSONWriter*)aStream;

@end
