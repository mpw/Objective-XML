/* MPWXmlArchiver.m Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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

#import "MPWXmlArchiver.h"
#import "MPWXmlGeneratorStream.h"

#import "MPWXmlUnarchiver.h"
#import <objc/objc.h>
#import "mpwfoundation_imports.h"
#import <objc/runtime.h>

@implementation MPWXmlArchiver

idAccessor( target, setTarget )
idAccessor( todo, setTodo )
idAccessor( classVersionTable, setClassVersionTable )
scalarAccessor( NSMapTable* , objectTable, setObjectTable )

static void retainObject(NSMapTable *table, const void *obj)
{
    [(id)obj retain];
}

static void releaseObject(NSMapTable *table, void *obj)
{
    [(id)obj release];
}

static NSString* describeObject(NSMapTable *table, const void *obj)
{
    return [(id)obj description];
}

static NSString* describeInteger(NSMapTable *table, const void *obj)
{
    return [NSString stringWithFormat:@"%ld",(long)obj];
}

-initWithTarget:newTarget
{
    static NSMapTableKeyCallBacks keyCallBacks = {
        NULL,NULL,retainObject,releaseObject,describeObject
    };
    static NSMapTableValueCallBacks valueCallBacks = {
        NULL,NULL,describeInteger,
    };
    self = [super init];
    [self setTarget:newTarget];
	[target setShouldIndent:YES];
    [self setTodo:[NSMutableArray array]];
    [self setObjectTable:NSCreateMapTable(keyCallBacks, valueCallBacks, 50) ];
    [self setClassVersionTable:[NSMutableDictionary dictionary]];
    return self;
}

+archivedDataWithRootObject:root
{
    id archiver;
    id data;
    archiver = [[self alloc] initWithTarget:[MPWXmlGeneratorStream streamWithTarget:[MPWXMLByteStream stream]]];
//    NSLog(@"did encode");
    data = [[archiver resultOfEncodingRootObject:root] retain];
//    NSLog(@"value is %@, %x, will release archiver",[data class],data);
    [archiver release];
//    NSLog(@"did release archiver");
    return [data autorelease];
}

-resultOfEncodingRootObject:root
{
	[self encodeRootObject:root];
	return [[[self target] target] target];
}

-init
{
    return [self initWithTarget:[MPWXmlGeneratorStream streamWithTarget:[MPWXMLByteStream Stdout]]];
}

-(void)dealloc
{
    [target release];
    NSFreeMapTable( objectTable );
    [classVersionTable release];
    [super dealloc];
}

-(void)writeClass:(Class)aClass
{
    id className;
    className = NSStringFromClass(aClass);
//    NSLog(@"writeClass: %@, found version: %@",aClass,[classVersionTable objectForKey:className]);
    if ( ![classVersionTable objectForKey:className] ) {
        long version=[aClass version];
//        NSLog(@"version = %d",version);
        if ( version != 0 ) {
            [target writeProcessingInstruction:@"Class" attributes:[NSString stringWithFormat:@"name=\"%@\" version=\"%ld\"",className,version]];
        }
        [classVersionTable setObject:[NSNumber numberWithLong:version] forKey:className];
        aClass=[aClass superclass];
        if ( aClass ) {
            [self writeClass:aClass];
        }
    }
}

-(void)encodeAnObject:anObject
{
    int oldIndex=ivarIndex;
    id oldObject=currentObject;
    id encodedObject = [anObject replacementObjectForCoder:self];
    Class objectClass=[encodedObject classForArchiver];
//    const char* className=class_getName( objectClass );
    const char* className=class_getName( objectClass);
    
    long objid = NSCountMapTable(objectTable);
    NSMapInsert( objectTable, anObject, (void*)objid );
    currentObject = encodedObject;
	
    [self writeClass:objectClass];
    [target beginStartTag:className];
    [target writeCStrAttribute:"id" value:[NSString stringWithFormat:@"%lx",objid]];
    [target endStartTag:className single:NO];

//    [target indent];
//    [target cr];
    ivarIndex=0;
    [currentObject encodeWithXmlCoder:self];
//    [currentObject release];
//    [target outdent];
    [target closeTag];
    ivarIndex=oldIndex;
    currentObject=oldObject;
}

-(void)addReference:anObject name:(const char*)cname
{
    long ref;
//	const char *cname=[name cString];
    if ( !(ref=(NSInteger)NSMapGet(objectTable,anObject )) ) {
//        [objectTable addObject:anObject];
        if ( cname ) {
            [target writeStartTag:cname attributes:@"t='@'" single:NO];
            [target indent];
            [target cr];
        }
        [self encodeAnObject:anObject];
        if ( cname ) {
            [target outdent];
            [target closeTag];
        }
    } else {
        [target writeElementName:cname attributes:[NSString stringWithFormat:@"idref='%lx'",ref] contents:nil];
        [target cr];
    }
}

-(void)encodePropertyList:plist
{

}

-(void)encodeValueOfObjCType:(const char *)itemType at:(const void*)address withName:(const char*)name
{
    if ( *itemType == '@' && *(id*)address!=nil ) {
        [*(id*)address encodeXmlOn:self withName:name];
    } else {
        id content=nil;
        id valueType=nil;
        char charcontent[100]="";
        switch ( *itemType ) {
            
            case 'c':
            case 'C':
                valueType=@"valuetype='c'";
//              content = [NSString stringWithFormat:@"%d",*(char*)address];
                sprintf(charcontent, "%d",*(char*)address);
                break;
            case 'i':
                valueType=@"valuetype='i'";
//              content = [NSString stringWithFormat:@"%d",*(int*)address];
                sprintf(charcontent, "%d",*(int*)address);
                break;
            case 'I':
                valueType=@"valuetype='i'";
//              content = [NSString stringWithFormat:@"%D",*(unsigned int*)address];
                sprintf(charcontent, "%D",*(unsigned int*)address);

                break;
           case 'q':
                content = [NSString stringWithFormat:@"%ld",*( long*)address];
                break;
            case 'Q':
				content = [NSString stringWithFormat:@"%ld",*( long*)address];
                break;
            case 's':
                valueType=@"valuetype='s'";
//              content = [NSString stringWithFormat:@"%d",*(short*)address];
                sprintf(charcontent, "%d",*(short*)address);
                break;
            case 'S':
                valueType=@"valuetype='S'";
//              content = [NSString stringWithFormat:@"%D",*(unsigned short*)address];
                sprintf(charcontent, "%D",*(unsigned short*)address);
                break;
            case 'f':
                valueType=@"valuetype='f'";
//              content = [NSString stringWithFormat:@"%g",(double)*(float*)address];
                sprintf(charcontent, "%g",(double)*(float*)address);
                break;
            case 'd':
                valueType=@"valuetype='d'";
//                content = [NSString stringWithFormat:@"%g",*(double*)address];
                sprintf(charcontent, "%g",*(double*)address);
                break;
            case '@':
                valueType=@"valuetype='@'";
                content = @"";
                break;
            case ':':
                content = NSStringFromSelector( *(SEL*)address );
                break;
            case '*':
                content = [NSString stringWithCString:*(char**)address encoding:NSASCIIStringEncoding];
				break;
            case '#':
//                NSLog(@"encode class");
                content = NSStringFromClass( *(Class*)address) ;;
//                NSLog(@"content: %@",content);
                break;
            default:
                if ( !strcmp( itemType, "{?={?=ff}{?=ff}}" )   ||
                     !strcmp( itemType, "{_NSRect={_NSPoint=ff}{_NSSize=ff}}") ) {
                    content = NSStringFromRect( *(NSRect*)address );
                } else  if ( !strcmp( itemType, "{?=ff}}" )   ||
                             !strcmp( itemType, "{_NSPoint=ff}") ) {
                    content = NSStringFromPoint( *(NSPoint*)address );
                } else  if ( !strcmp( itemType, "{_NSSize=ff}") ) {
                    content = NSStringFromSize( *(NSSize*)address );
                } else{
                    [NSException raise:@"UnknownType"
                        format:@"tried to encode unknown type-code: %s",
                        itemType]  ;
                    content = @"";
 
                }
                break;
                ;
        }
        if ( content)  {
            [content getCString:charcontent maxLength:120 encoding:NSASCIIStringEncoding];
        }
        [target beginStartTag:name];
        [target writeCStrAttribute:"t" value:[NSString stringWithCString:itemType encoding:NSASCIIStringEncoding]];
        [target endStartTag:name single:NO];
        [target appendBytes:charcontent length:strlen(charcontent)];
//      [target writeElementName:name attributes:valueType contents:content];
        [target writeCloseTag:name];

    }
}

-(void)encodeKey:aKey ofObject:anObject
{
	id object=[anObject valueForKey:aKey];
	[self encodeValueOfObjCType:"@" at:&object withName:[aKey cString]];
}



-(void)encodeArrayOfObjCType:(const char *)itemType count:(unsigned)count at:(const void*)address withName:(const char*)name
{
    int i;
    int elemSize;
    if ( *itemType == 'c' || *itemType=='C' ) {
        [self encodeString:[[[NSString alloc] initWithBytes:address length:count encoding:NSUTF8StringEncoding] autorelease]  name:name];
    } else {
        elemSize=4;
        for (i=0;i<count;i++) {
            [self encodeValueOfObjCType:itemType at:address withName:name];
            address=((char*)address)+elemSize;
        }
    }
}

-(void)encodeArrayOfObjCType:(const char *)itemType count:(unsigned)count at:(const void*)address
{
    [self encodeArrayOfObjCType:itemType count:count at:address withName:[[currentObject ivarNameForVarPointer:address orIndex:++ivarIndex] cStringUsingEncoding:NSASCIIStringEncoding ]] ;
}

-(void)encodeString:(NSString*)value name:(const char*)name
{
    id utf8Data = [value dataUsingEncoding:NSUTF8StringEncoding];
    id utf8String = [[[NSString alloc] initWithBytes:[utf8Data bytes] length:[utf8Data length] encoding:NSUTF8StringEncoding] autorelease];
    [target writeElementName:name attributes:nil contents:utf8String];
}

-(void)encodeObjects
{
    while ( [todo count] > 0 ) {
        id anObject = [[todo lastObject] retain];
        [todo removeLastObject];
        [self encodeAnObject:anObject];
        [anObject release];
    }
}

-(void)encodeRootObject:someObject
{
    [target writeStandardXmlHeader];
    [todo addObject:someObject];
    [self encodeObjects];
}

-(void)encodeValueOfObjCType:(const char *)itemType at:(const void*)address
{
//    NSLog( @"%x - %x = %d",address,currentObject,address-(void*)currentObject);
	[self encodeValueOfObjCType:itemType at:address withName:[[currentObject ivarNameForVarPointer:address orIndex:++ivarIndex] cStringUsingEncoding:NSASCIIStringEncoding]];
}


-(void)decodeValueOfObjCType:(const char *)itemType at:(void*)address
{
    [NSException raise:@"DecodeOnArchiver" format:@"tried to decode from an archiver"];
}

-(void)encodeDataObject:(NSData*)theObject
{
    [target writeElementName:"data" attributes:[NSString stringWithFormat:@"length=%lu",(unsigned long)[theObject length]]
        contents:theObject];
}

-(NSData*)decodeDataObject
{
    return nil;
}

-(NSInteger)versionForClassName:(NSString*)className
{
    return 0;
}

-(void)close
{
    [target close];
}

@end

@implementation NSObject(xmlArchiving)


-(void)encodeXmlOn:aCoder withName:(const char*)name
{
    [aCoder addReference:self name:name];
}

-(void)encodeWithXmlCoder:(NSCoder*)aCoder
{
    [(id)self encodeWithCoder:aCoder];
}

@end

@implementation NSString(xmlArchiving)

-(void)encodeXmlOn:aCoder withName:(const char*)name
{
    [aCoder encodeString:self name:name];
}

@end

@implementation MPWSubData(xmlArchiving)

-(void)encodeXmlOn:aCoder withName:(const char*)name
{
    [aCoder addReference:self name:name];
}

@end


@implementation MPWXmlArchiver(testing)

+_simpleTestString
{
    return @"hi";
}

+_encodedRepOfSimpleTestString
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<?Class name=\"NSString\" version=\"1\"?>\n<NSString id='0'>\n\t<unnamed_1 valuetype='I'>2</unnamed_1>\n\t<unnamed_2>hi</unnamed_2>\n</NSString>\n";
}

+(void)testArchiveSimpleString
{
    id encodedString = [[self archivedDataWithRootObject:[self _simpleTestString]] stringValue];
    NSAssert3( [encodedString isEqual:[self _encodedRepOfSimpleTestString]] ,@"encoding '%@' yielded '%@' instead of the expected '%@'",[self _simpleTestString],encodedString,[self _encodedRepOfSimpleTestString]);
}

+_archiveAndUnarchive:objectGraph
{
    id data = [self archivedDataWithRootObject:objectGraph];
	id unarchived;
//	NSLog(@"archived: %@",[data stringValue]);
    unarchived = [MPWXmlUnarchiver unarchiveObjectWithData:data];
    return unarchived;
}

+(void)testSubstitutedClassArchiving
{
    id pool=[[NSAutoreleasePool alloc] init];
    id data = [@"The wonderful test data" asData];
    id sub1=[[MPWSubData alloc] initWithData:data bytes:[data bytes]+2 length:5];
    id result=nil;
    [pool release];
    [sub1 autorelease];
    NS_DURING
    result = [[self _archiveAndUnarchive:sub1] stringValue];
    NS_HANDLER
        NSAssert1( NO, @"en/de-coding a sub-data (with substitution) raise: %@",localException);
    NS_ENDHANDLER
    NSAssert2( [result isEqual:sub1] , @"en/de-coding '%@' resulted in '%@'",sub1,result);
}

+(void)testEncodingNSNumber
{
	NSNumber *num=[NSNumber numberWithInt:3];
	NSNumber *result;
	NSLog(@"num objCType: %s",[num objCType]);
	result=[self _archiveAndUnarchive:num];
	IDEXPECT( result, num , @"unarchived number should equal original");
}

+testSelectors
{
    return @[
//		@"testArchiveSimpleString",
//		@"testSubstitutedClassArchiving",
//		@"testEncodingNSNumber",
		];
}

@end
