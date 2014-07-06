/* MPWXmlUnarchiver.m Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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

#import "MPWXmlUnarchiver.h"
#import "MPWXmlElement.h"
#import "MPWXmlAttributes.h"
#import "mpwfoundation_imports.h"
#import "MPWMAXParser_private.h"

@interface ValueHolder : MPWObject
{
    id	valueName;
    id	value;
    char	valueType;
}

@end
 
@implementation ValueHolder

idAccessor( valueName, setValueName )
idAccessor( value, setValue )
intAccessor( valueType, setValueType )

-description
{
    return [NSString stringWithFormat:@"value-holder name=%@, type=%c value=%@",
valueName,valueType,valueType == '@' ? (id)[value class] : value];
}

-(void)dealloc
{
    [valueName release];
    [value release];
    [super dealloc];
}

@end

@interface ObjectHolder : MPWObject
{
    id	objid;
    id	className;
    id	values;
    id	objClass;
}

-valueAtIndex:(unsigned)anIndex;

@end

@implementation ObjectHolder

idAccessor( objid, setObjid )
idAccessor( className,_setClassName )
idAccessor( values, setValues )
idAccessor( objClass, setObjClass )

-init
{
    self = [super init];
    if ( values ) {
        [values removeAllObjects];
    } 
    return self;
}

-(Class)classForArchivedClassName:(NSString*)aClassName
{
	return NSClassFromString( aClassName );
}

-(void)setClassName:newName
{
    Class newClass=[self classForArchivedClassName:newName];
    if ( newClass ) {
        [self _setClassName:newName];
        [self setObjClass:newClass];
    } else {
        [NSException raise:@"invalidarchive" format:@"archive contains objects of class %@ that is not available",newName];
    }
}
-(void)addValue:aValue
{
    if (!values) {
        [self setValues:[NSMutableArray array]];
    }
    [values addObject:aValue];
//	NSLog(@"did add: %@, now %@",aValue,self);
}

-valueAtIndex:(unsigned)anIndex
{
    return [values objectAtIndex:anIndex];
}

-(void)dealloc
{
    [objid release];
    [className release];
    [values release];
    [super dealloc];
}

-description
{
    return [NSString stringWithFormat:@"object-holder, class=%@, id=%@, values=%@",
        className,objid,values];
}

@end

@implementation XmlDecoder

objectAccessor( ObjectHolder , currentObjectHolder, setCurrentObjectHolder )
idAccessor( currentObject ,setCurrentObject )
idAccessor( classVersionTable, setClassVersionTable )
intAccessor( currentValue, setCurrentValue )

static id defaultVersions=nil;

+ (void)setDefaultVersion:(int)version forClass:(Class)aClass
{
	NSString *className=NSStringFromClass(aClass);
	NSNumber *versionNumber=[NSNumber numberWithInt:version];
	if ( !defaultVersions ) {
		defaultVersions=[[NSMutableDictionary alloc] init];
        [defaultVersions setObject:[NSNumber numberWithInt:17]
            forKey:@"NSEPSImageRep"];
        [defaultVersions setObject:[NSNumber numberWithInt:17]
            forKey:@"NSImageRep"];
	}
	[defaultVersions setObject:versionNumber forKey:className];
}

-(unsigned)versionForClassName:(NSString*)className
{
    id classVersion = [classVersionTable objectForKey:className];
    int version;
    if ( classVersion ) {
        version = [classVersion intValue];
    } else {
//        version = [NSClassFromString( className) version];
        version =  [[defaultVersions objectForKey:className] intValue];
    }
    return version;
}

-init
{
    self = [super init];
    [self setCurrentValue:0];
    [self setClassVersionTable:[NSMutableDictionary dictionary]];
    return self;
}

-(void)dealloc
{
    [currentObjectHolder release];
//    [currentObject release];
    [super dealloc];
}

-(void)decodeValueOfObjCType:(const char *)itemType at:(void*)address withName:(const char*)cname
{
    id value;
//	id name=[NSString stringWithCString:cname];
    value = [currentObjectHolder valueAtIndex:currentValue];
	const char *valueName=[[value valueName] cStringUsingEncoding:NSASCIIStringEncoding];
    if ( *itemType == [value valueType]  && (!strcmp( cname, valueName ) || !strncmp( "unnamed", cname, 6  ) ||   !strncmp( "unnamed", valueName, 6  ) ) ) {
        id val = [value value];
        switch ( *itemType ) {

            case 'c':
            case 'C':
                *(char*)address = [val intValue];
                break;
            case 'i':
            case 'I':
                *(int*)address = [val intValue];
                break;
            case 's':
            case 'S':
                *(short*)address = [val intValue];
                break;
//			case 'q':
  //          case 'Q':
   //             *(int*)address = [val intValue];
//                *(long long*)address = [val intValue];
                break;
           case 'f':
                *(float*)address = [val floatValue];
                break;
            case 'd':
                *(double*)address = [val doubleValue];
                break;
            case '@':
                *(id*)address = [val retain];
                [value setValue:nil];
//				[val validate];
                break;
            case ':':
                *(SEL*)address = NSSelectorFromString( [val stringValue]);
                break;
            case '*':
                *(char**)address=malloc( [val length]+1);
                strcpy( *(char**)address, [val cString] );
                break;
            case '#':
                *(Class*)address=NSClassFromString(val);
                break;
            default:
#if !TARGET_OS_IPHONE
                if ( !strcmp( itemType, "{?={?=ff}{?=ff}}" )  ||
                     !strcmp( itemType, "{_NSRect={_NSPoint=ff}{_NSSize=ff}}") ) {
                    *(NSRect*)address=NSRectFromString( val );
                } else  if ( !strcmp( itemType, "{?=ff}}" )   ||
                     !strcmp( itemType, "{_NSPoint=ff}") ) {
                    *(NSPoint*)address=NSPointFromString( val );
                } else  if ( !strcmp( itemType, "{_NSSize=ff}") ) {
                    *(NSSize*)address=NSSizeFromString( val );
                } else
#endif
                {
                    NSLog(@"tried to decode unknown type-code %s",itemType);
//                    [NSException raise:@"UnknownType" format:@"tried to decode unknown type-code %s",itemType];
                }
                break;
        }
    } else {
		NSLog(@"coding mismatch!");
        NSLog(@"type: %d",*itemType==[value valueType]);
 //       NSLog(@"name: %d",[name isEqual:[value valueName]]);
//		NSLog(@"name length: %d",[name length]);
//		NSLog(@"name : %@",name);
//		NSLog(@"name class : %@",[name class]) ;
		NSLog(@"value name length: %d",(int)[[value valueName] length]);
		NSLog(@"value name : %@",[value valueName]);
		NSLog(@"value name class : %@",[[value valueName] class]) ;
		
        [NSException raise:@"CodingMismatch" format:@"item's name (%s) or type (%c) does not match encoded (%@,%c) for XmlCoder %@",cname,*itemType,[value valueName],[value valueType],self];
    }
    currentValue++;
}

-(void)decodeKey:aKey ofObject:anObject
{
	id object=nil;
	[self decodeValueOfObjCType:"@" at:&object withName:[aKey cStringUsingEncoding:NSASCIIStringEncoding]];
	[anObject setValue:object forKey:aKey];
}


-(void)decodeArrayOfObjCType:(const char *)itemType count:(unsigned)count at:(void*)address withName:(const char*)name
{
    int i;
    int elemSize;
    if ( *itemType == 'c' || *itemType=='C' ) {
        id string;
        [self decodeValueOfObjCType:"@" at:&string withName:name];
        [string getCString:address maxLength:count];
        [string release];
    } else {
        elemSize=4;
        for (i=0;i<count;i++) {
            [self decodeValueOfObjCType:itemType at:address withName:name];
            address=((char*)address)+elemSize;
        }
    }
}



-(void)decodeValueOfObjCType:(const char *)itemType at:(void*)address
{
	
     [self decodeValueOfObjCType:itemType at:address withName:[[[currentObjectHolder objClass] ivarNameForVarPointer:address orIndex:currentValue+1 ofInstance:currentObject]  cStringUsingEncoding:NSASCIIStringEncoding]];
}

-(void)decodeArrayOfObjCType:(const char *)itemType count:(unsigned)count at:(void*)address
{
    [self decodeArrayOfObjCType:itemType count:count at:address withName:[[currentObject ivarNameForVarPointer:address orIndex:currentValue+1] cStringUsingEncoding:NSASCIIStringEncoding]];
}

-decodeDataObject
{
	//    return [NSData dataWithData:[[currentObjectHolder valueAtIndex:currentValue] value]];
    id data = [[currentObjectHolder valueAtIndex:currentValue] value];
//	[data validate];
	return data;
}

-decodeStringObject
{
	//    return [NSData dataWithData:[[currentObjectHolder valueAtIndex:currentValue] value]];
    return [[currentObjectHolder valueAtIndex:currentValue] value];
}

-decodeObjectHolder:holder withObjectTable:objectTable
{
    id objid=[holder objid];
//    id pool=[[NSAutoreleasePool alloc] init];
    [self setCurrentObjectHolder:holder];
    currentValue=0;
//	NSLog(@"holder class: %@",[holder objClass]);
    currentObject = [[holder objClass] alloc];
    if ( [[holder objClass] canHaveRecursiveReferences] ) {
        [objectTable setObject:currentObject forKey:objid];
    }
    currentObject = [currentObject initWithXmlCoder:self];
//	NSLog(@"decodeObjectHolder objid:",objid);
//	NSLog(@"decodeObjectHolder currentObject:",currentObject);
	[objectTable setObject:currentObject forKey:objid];
//	NSLog(@"did set object: %@ forKey: %@",currentObject,objid);
 //   [pool release];
    [currentObject release];
    return currentObject;
}

-description
{
    return [NSString stringWithFormat:@"XmlDecoder "];
//    return [NSString stringWithFormat:@"XmlDecoder with currentObjectHolder: %@, at %d",currentObjectHolder,currentValue];
}

@end


@implementation MPWXmlUnarchiver

idAccessor( target, setTarget )
idAccessor( objectTable, setObjectTable )
idAccessor( currentValue, setCurrentValue )

static id idKey=nil;
static id classKey=nil;
static id object=nil;

+unarchiveObjectWithData:(NSData*)archivedData
{
    id pool = [[NSAutoreleasePool alloc] init];
    id unarchiver = [[self alloc] initWithTarget:[NSMutableArray array]];
    id result;
    result = [unarchiver unarchiveObjectWithData:archivedData];
//    NSLog(@"result is %@ with retainCount %d",[result class],[result retainCount]);
    [unarchiver release];
    [pool release];
//    NSLog(@"result retainCount %d (before autorelease)",[result retainCount]);
    return [result autorelease];
}

-unarchiveObjectWithData:(NSData*)archivedData
{
    [self parse:archivedData];
//	NSLog(@"target: %@",[self target]);
	if ( [target count] ) {
		return [[self target] objectAtIndex:0];
	} else {
		[NSException raise:@"invalidarchive" format:@"couldn't unarchive data"];
	}
	return nil;
}

+_xmldecoder
{
	return [[XmlDecoder alloc] init];
}

-initWithTarget:aTarget
{
    id pool=[[NSAutoreleasePool alloc] init];
    self = [super init];
	[self setTarget:aTarget];
    [self setObjectTable:[NSMutableDictionary dictionary]];
    holderCache=[[MPWObjectCache alloc] initWithCapacity:20 class:[ObjectHolder class]];
    [holderCache setUnsafeFastAlloc:NO];
    valueCache=[[MPWObjectCache alloc] initWithCapacity:30 class:[ValueHolder class]];
    [valueCache setUnsafeFastAlloc:NO];
    decoder = [[self class] _xmldecoder];
    if (!idKey ) {
        idKey = [@"id" uniqueString];
        classKey = [@"class" uniqueString];
        object = [@"object" uniqueString];
    }
    ignoreSpace=YES;
    [pool release];
    return self;
}

-currentObject
{
    return [objects lastObject];
}

-(void)pushObject:anObject
{
    if (!objects){
        objects=[[NSMutableArray alloc] init];
    }
    [objects addObject:anObject];
}

-(void)popObject
{
    [objects removeLastObject];
}

-(void)makeValue:endName
{
	id value=GETOBJECT( (MPWObjectCache*)valueCache );
//	NSLog(@"setting up value holder with name: %@ value: %@ valueType: %c",endName,[[self currentValue] class],valueType);
	[value setValueName:endName];
	[value setValue:[self currentValue]];
	[value setValueType:valueType];
	[[self currentObject] addValue:value];
	[self setCurrentValue:nil];
	valueType=0;
}

-(NSString*)mapArchiveClassNameToLiveClassName:(NSString*)archiveClassName
{
	return archiveClassName;
}

-(Class)classForName:aName
{
	return NSClassFromString( [self mapArchiveClassNameToLiveClassName:aName] );
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)endName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    ignoreSpace=YES;

	NSLog(@"end with '%@', object=%@ count = %ld",endName,object,(long)[objects count]);
//	NSLog(@"class = %@/%x",NSClassFromString( endName ),NSClassFromString( endName ));
    NSString *s=[endName stringValue];
    
    if ( [self classForName:s]) {
        id newObject;
//		NSLog(@" will decode object with %@",[self currentObject]);
        newObject=[decoder decodeObjectHolder:[self currentObject] withObjectTable:objectTable];
//		NSLog(@"newObject: %@",newObject);
        [self setCurrentValue:newObject];
        valueType='@';
//		NSLog(@"end with '%@', count = %d",endName,[objects count]);
//		NSLog(@"end with '%@'",objects);
        if ( [objects count] == 1 ) {
//			NSLog(@"add %@ to target %@",[self currentValue],target);
            [target addObject:[self currentValue]];
//			NSLog(@"target after: %p %@",target,target);
        } 
        [self popObject];
    } else {
//		NSLog(@"makeValue: %@",endName);
		[self makeValue:endName];
    }
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)tag namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attrs
{
    id className = [NSString stringWithString: tag];
    Class class = [self classForName:className];
//	NSLog(@"attrs: %@",attrs);
    if ( class ) {
        //---	handle start of object
        id newObject;
        id objid,objclass;
        objid = [attrs objectForKey:idKey];
        objclass = class;
//		NSLog(@"new object: %@ %@",className,objid);
        ignoreSpace=YES;
        newObject = GETOBJECT( (MPWObjectCache*)holderCache );  //
        [newObject setObjid:objid];
        [newObject setClassName:[self mapArchiveClassNameToLiveClassName:className]];
        [self pushObject:newObject];
    } else {
        if ( [attrs count] > 0) {
            id value=nil;
           NSLog(@"attributes: %@",attrs);
            if (nil != (value = [attrs objectForKey:@"idref"])  ) {
				id referencedObject=[objectTable objectForKey:value];
                valueType='@';
//				NSAssert1( referencedObject != nil, @"unresolved object reference for '%@'",value);
                [self setCurrentValue:referencedObject];
            } else if ( nil != (value = [attrs objectForKey:@"t"])  ) {
                unichar vtype;
//                NSLog(@"valueType: %@",value);
                [value getCharacters:&vtype range:NSMakeRange(0,1)];
                valueType=vtype;
//                [value getCString:&valueType maxLength:1];
            } else  if (nil != (value = [attrs objectForKey:@"id"])  ) {
                //---	handle start of object
                id newObject;
                id objid,objclass;
                objid = [attrs objectForKey:idKey];
                objclass = tag;
                ignoreSpace=YES;
                newObject = GETOBJECT( (MPWObjectCache*)holderCache );  //
                [newObject setObjid:objid];
                [newObject setClassName:[self mapArchiveClassNameToLiveClassName:objclass]];
                [self pushObject:newObject];
            } else if ( nil != (value = [attrs objectForKey:@"length"])) {
                valueType='@';
                dataLen = [value intValue];
 //               NSLog(@"expecting data with length %d",dataLen);
            } else {
                NSLog(@"neither valuetype nor idref '%@'",attrs);
            }
            ignoreSpace = (valueType == '@');
        } else {
//            NSLog(@"no attributes, value is string");
            ignoreSpace=NO;
            valueType='@';
            [self setCurrentValue:@""];
        }
    }
}

-(BOOL)characterDataAllowed:parser
{
    return ( [self currentTag] != object && (!ignoreSpace || dataLen>0) );
}

-(void)parser:aParser foundCharacters:(MPWSubData*)chars
{
//	NSLog(@"found characters: %@",chars);
    [chars setMustUnique:YES];
    if ( dataLen>0 ) {
//        NSLog(@"characters: expecting dataLen = %d, got %d '%@'",dataLen,[chars length],chars);
        if ( [chars isEqual:@">]]&gt;"] ) {
            chars=[NSData dataWithBytes:"]]>" length:3];
        }
        dataLen-=[chars length];
        if ( currentValue ) {
            [currentValue appendData:(NSData*)chars];
        } else {
            if ( dataLen == 0 ) {
                [self setCurrentValue:chars];
            } else {
                [self setCurrentValue:[NSMutableData dataWithData:(NSData*)chars]];
            }
//			NSLog(@"parser:aParser foundCharacters currentValue now: '%@' / %@",currentValue,[currentValue class]);
        }
    } else {
        [self setCurrentValue:[[[NSString alloc] initWithData:(NSData*)chars encoding:NSUTF8StringEncoding] autorelease]];
//		NSLog(@"0 datalen, currentValue now: '%@'",currentValue);
    }
//	NSLog(@"at end of characters callback: %@",[self currentValue]);
    //--- also have to check for non '@' valueType
}

-(void)parser:aParser foundCDATA:(NSData*)data_chars
{
	MPWSubData *chars=(MPWSubData*)data_chars;
    [chars setMustUnique:YES];
    if ( dataLen>0 ) {
//        NSLog(@"cdata: expecting dataLen = %d, got %d, retainCount: %d",dataLen,[chars length],[chars retainCount]);
        dataLen-=[chars length];
//        NSLog(@"currentValue: %x/%d",currentValue,[currentValue length]);
        if ( currentValue ) {
            [currentValue appendData:(NSData*)chars];
//            NSLog(@"did append %d bytes currentValue length now %d bytes",[chars length],[currentValue length]);
        } else {
            if ( dataLen == 0 ) {
                [self setCurrentValue:chars];
            } else {
                [self setCurrentValue:[NSMutableData dataWithData:(NSData*)chars]];
            }
        }
    } else {
        [self setCurrentValue:chars];
    }
    //--- also have to check for non '@' valueType
}

-(void)parser:aParser foundProcessingInstructionWithTarget:piTarget data:piData
{
    if ( [piTarget isEqual:@"Class"] ) {
        [[decoder classVersionTable] setObject:[piData objectForKey:@"version"] forKey:[piData objectForKey:@"name"]];
    }
}

-(void)dealloc
{
    [objectTable release];
    [holderCache release];
    [valueCache release];
    [decoder release];
    [objects release];
    [super dealloc];
}

@end

@implementation NSObject(xmlUnarchiving)

-initWithXmlCoder:(NSCoder*)coder
{
    return [self initWithCoder:coder];
}

+(BOOL)canHaveRecursiveReferences
{
    return YES;
}

+(void)setDefaultXmlVersion:(int)version
{
	[XmlDecoder setDefaultVersion:version forClass:self];
}

@end

@implementation NSData(recursiveRefs)

+(BOOL)canHaveRecursiveReferences
{
    return NO;
}

@end


@implementation NSString(xmlCodingSupport)

-initWithXmlCoder_disabled:aCoder
{
	int _len;
	[aCoder decodeValueOfObjCType:"I" at:&_len withName:"unnamed_1"];
	return [self initWithString:[aCoder decodeStringObject]];
}

+(BOOL)canHaveRecursiveReferences
{
    return NO;
}

@end


@implementation MPWXmlUnarchiver(testing)

+_simpleTestString
{
    return @"hi";
}

+_encodedRepOfSimpleTestString
{
    return @"<?xml version=\"1.0\" encoding=\"UTF8\"?>\n<?Class name=\"NSString\" version=\"1\"?>\n<NSString id=0>\n\t<unnamed_1 valuetype='I'>2</unnamed_1>\n\t<unnamed_2>hi</unnamed_2>\n</NSString>\n";
}

+(void)testUnarchiveSimpleString
{
    id decodedString = [self unarchiveObjectWithData:[[self _encodedRepOfSimpleTestString] asData]];
    NSAssert3( [decodedString isEqual:[self _simpleTestString]] ,@"decoding '%@' yielded '%@' instead of the expected '%@'",[self _encodedRepOfSimpleTestString],decodedString,[self _simpleTestString]);
}

+testSelectors
{
    return [NSArray arrayWithObjects:
//		@"testUnarchiveSimpleString",
		nil];
}

@end
