/* MPWXmlArchiver.h Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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

, created  on Sat 24-Jul-1999 */

#import <Foundation/Foundation.h>

@interface MPWXmlArchiver : NSCoder
{
    id	target;
    id	currentObject;
    id	todo;
    int	ivarIndex;
    NSMapTable*	objectTable;
    id	classVersionTable;
}

//--- public API

-initWithTarget:target;

+archivedDataWithRootObject:root;
-resultOfEncodingRootObject:root;
-(void)encodeValueOfObjCType:(const char *)itemType at:(const void*)address withName:(const char*)name;
-(void)encodeArrayOfObjCType:(const char *)itemType count:(unsigned)count at:(const void*)address withName:(const char*)name;
-(void)encodeValueOfObjCType:(const char *)itemType at:(const void*)address;
-(void)encodeArrayOfObjCType:(const char *)itemType count:(unsigned)count at:(const void*)address;
-(void)encodeString:(NSString*)value name:(const char*)name;
-(void)encodeRootObject:someObject;
-(void)encodeDataObject:(NSData*)theObject;

//--- private API

-(void)writeClass:(Class)aClass;

@end

@interface NSObject(xmlArchiving)

-(void)encodeXmlOn:aCoder withName:(const char*)name;
-(void)encodeWithXmlCoder:(NSCoder*)aCoder;

@end


