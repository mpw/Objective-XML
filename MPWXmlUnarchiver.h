/* MPWXmlUnarchiver.h Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

        Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.

        Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in
        the documentation and/or other materials provided with the distribution.

        Neither the name Marcel Weiher nor the names of contributors may
        be used to endorse or promote products derived from this software
        without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

, created  on Sun 25-Jul-1999 */

#import "MPWXmlParser.h"


@interface MPWXmlUnarchiver : MPWSAXParser
{
	id target;
    NSMutableArray	*objects;
    id	holderCache,valueCache;
    char valueType;
    id	currentValue;
    id	decoder;
    id	objectTable;
    int dataLen;
}


+unarchiveObjectWithData:(NSData*)archivedData;
-unarchiveObjectWithData:(NSData*)archivedData;
-initWithTarget:aTarget;

-(void)setCurrentValue:someValue;

-(void)makeValue:endName;

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)endName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;

@end

@class ValueHolder,ObjectHolder;


@interface XmlDecoder : NSCoder
{
    ObjectHolder*	currentObjectHolder;
    int	currentValue;
    id	currentObject;
    id	classVersionTable;
}
-(unsigned)versionForClassName:(NSString*)className;
-(void)decodeValueOfObjCType:(const char *)itemType at:(void*)address withName:(const char*)name;
-(void)decodeArrayOfObjCType:(const char *)itemType count:(unsigned)count at:(void*)address withName:(const char*)name;
-(void)decodeValueOfObjCType:(const char *)itemType at:(void*)address;
-(void)decodeArrayOfObjCType:(const char *)itemType count:(unsigned)count at:(void*)address;
-decodeDataObject;
+ (void)setDefaultVersion:(int)version forClass:(Class)aClass;

@end

@interface NSObject(xmlUnarchiving)

-initWithXmlCoder:(NSCoder*)coder;
+(BOOL)canHaveRecursiveReferences;
+(void)setDefaultXmlVersion:(int)version;

@end


