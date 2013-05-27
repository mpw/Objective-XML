/* MPWXmlGeneratorStream.m Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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

, created  on Mon 26-Oct-1998 */

#import "MPWXmlGeneratorStream.h"
#import "mpwfoundation_imports.h"


@implementation MPWXmlGeneratorStream

-initWithTarget:aTarget
{
    self = [super initWithTarget:aTarget];
    atBOL=YES;
    indent=0;
    return self;
}

-(SEL)streamWriterMessage
{
    return @selector(generateXmlOnto:);
}

+defaultTarget
{
    return [MPWXMLByteStream stream];
}

-(void)cr
{
    FORWARDCHARS("\n");
    atBOL=YES;
}
-(void)indent
{
    indent++;
}
-(void)outdent
{
    indent--;
    if (indent<0 ) {
        indent=0;
    }
}

-(void)writeIndent
{
    char spaces[]="                                                                                                                           ";
    if ( atBOL && shouldIndent ) {
        int numSpacesToOutput = MIN( indent, sizeof spaces - 2);
        [target appendBytes:spaces length:numSpacesToOutput];
        atBOL=NO;
    }
}

-(void)writeProcessingInstruction:piName attributes:attrs
{
    FORWARDCHARS("<?");
    FORWARD( piName );
    if ( attrs  ) {
        FORWARDCHARS(" ");
        [self writeObject:attrs];
    }
    FORWARDCHARS("?>");
    [self cr];
}

-(void)writeStandardXmlHeader
{
    [self writeProcessingInstruction:@"xml" attributes:@"version=\"1.0\" encoding=\"UTF-8\""];
}


-(void)writeAttribute:(NSString*)attributeName value:(NSString*)attributeValue
{
	FORWARDCHARS(" ");
    [target writeString:attributeName];
    FORWARDCHARS("=\"");
    [target writeString:attributeValue];
    FORWARDCHARS("\"");
}

-(void)writeCStrAttribute:(const char*)attributeName value:(const char*)attributeValue
{
	FORWARDCHARS(" ");
    FORWARDCHARS(attributeName);
    FORWARDCHARS("=\"");
    FORWARDCHARS(attributeValue);
    FORWARDCHARS("\"");
}

-(void)beginStartTag:(const char*)name
{
    [self writeIndent];
    FORWARDCHARS( "<" );
    FORWARDCHARS( name );
}

-(void)endStartTag:(const char*)name single:(BOOL)isSingle
{
    if ( isSingle ) {
        FORWARDCHARS("/>");
    } else {
		tagStack[curTagDepth++]=name;
        FORWARDCHARS(">");
    }
}


-writeStartTag:(const char*)name attributes:attrs single:(BOOL)isSingle
{
    [self beginStartTag:name];
    if ( attrs && [attrs length] ) {
        FORWARDCHARS(" ");
        [self writeObject:attrs];
    }
    [self endStartTag:name single:isSingle];
	return self;
}

-startTag:(const char*)tag
{
	return [self writeStartTag:tag attributes:nil single:NO];
}

-writeCloseTag:(const char*)name
{
    [self writeIndent];
    FORWARDCHARS( "</" );
    FORWARDCHARS( name );
    FORWARDCHARS(">");
	if ( indent) {
		[self cr];
	}
	curTagDepth--;
	return self;
}

-closeTag
{
	if ( curTagDepth >= 0 ) {	
		return [self writeCloseTag:tagStack[curTagDepth-1]];
	} else {
		[NSException raise:@"tagnesting" format:@"closed tag that wasn't opened"];
	}
	return nil;
}

-writeContentObject:anObject
{
	[self writeObject:anObject];
	return self;
}

-(void)writeObject:anObject forKey:aKey
{
    FORWARD( aKey );
    FORWARDCHARS( "='" );
    FORWARD( anObject );
    FORWARDCHARS( "'" );
}


-writeElementName:(const char*)name attributes:attrs contents:contents
{

    [self writeStartTag:name attributes:attrs single:contents==nil];
    if ( contents ) {
        BOOL simpleContent = [contents isSimpleXmlContent];
        if ( !simpleContent ) {
			if ( shouldIndent ) {
				[self cr];
				[self indent];
			}
        }
        [self writeContent:contents];
        if ( !simpleContent ) {
            [self outdent];
        }
        [self closeTag];
    }
	return self;
}

-writeElementName:(const char*)name contents:contents
{
	return [self writeElementName:name attributes:nil contents:contents];
}

-(void)writeContent:anObject
{
    [anObject generateXmlContentOnto:self];
}
static const char *scanCData( const char *currentPtr, const char *endPtr )
{
    currentPtr+=2;
    while ( currentPtr < endPtr ) {	
        if ( *currentPtr == '>' ) {
            if ( currentPtr[-1]==']' && currentPtr[-2]==']' ) {
                currentPtr-=2;
                break;
            } else {
                currentPtr+=3;
            }
        } else if ( *currentPtr == ']' ) {
            currentPtr+=1;
        } else {
            currentPtr+=3;
        }
    }
    return MIN(currentPtr,endPtr);
}

-(void)writeCData:(NSData*)data
{
    const char *currentPtr = [data bytes];
    const char *endPtr = currentPtr + [data length];
    id subdata=[[MPWSubData alloc] initWithData:data bytes:currentPtr length:endPtr-currentPtr];
    while ( currentPtr < endPtr ) {
        const char *newPtr = scanCData( currentPtr, endPtr );
//        NSLog(@"got newPtr %x, endPtr %x, orig-len = %d, this-len = %d, last bytes = %.*s",
//              newPtr,endPtr,[data length],newPtr-currentPtr,2,endPtr-3);
        FORWARDCHARS("<![CDATA[");
        [subdata reInitWithData:data bytes:currentPtr length:newPtr-currentPtr];
        FORWARD( subdata );
        FORWARDCHARS( "]]>");
        if ( newPtr < endPtr-1 ) {
            newPtr+=3;
            FORWARDCHARS("]]&gt;");
        }
        currentPtr=newPtr;
    }
    [subdata release];
}

-(void)writeNSDataContent:(NSData*)data
{
    FORWARD(data);
//    [self writeCData:data];
}

-(void)writeString:aString
{
    FORWARD(aString);
}

boolAccessor( shouldIndent, setShouldIndent )

@end

@implementation NSObject(MPWXmlGeneratorStream)

-(void)generateXmlContentOnto:(MPWXmlGeneratorStream*)aStream
{
    [self flattenOntoStream:aStream];
}

-(void)generateXmlOnto:(MPWXmlGeneratorStream*)aStream
{
    [self generateXmlContentOnto:aStream];
}

-(BOOL)isSimpleXmlContent
{
    return NO;
}

@end

@implementation NSString(MPWXmlGeneratorStream)

-(void)generateXmlContentOnto:(MPWXmlGeneratorStream*)aStream
{
    [aStream writeString:self];
}

-(BOOL)isSimpleXmlContent
{
    return YES;
}

@end

@implementation NSData(MPWXmlGeneratorStream)

-(void)generateXmlContentOnto:(MPWXmlGeneratorStream*)aStream
{
    [aStream writeNSDataContent:self];
}

-(BOOL)isSimpleXmlContent
{
    return YES;
}


@end


@implementation  MPWXMLByteStream


-(void)writeString:(NSString*)string
{
    int maxLen = [string length] * 4;
    NSUInteger length=0;
    char utf8bytes[  maxLen ];
    [string getBytes:utf8bytes maxLength:maxLen-1 usedLength:&length encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0,[string length]) remainingRange:NULL];
	int base=0;
	int i;
	for (i=0;i<length;i++) {
		char ch=utf8bytes[i];
		char *extra=NULL;
		switch (ch) {
			case '<':
				extra="&lt;";
				break;
			case '>':
				extra="&gt;";
				break;
			case '&':
				extra="&amp;";
				break;
			default:
				continue;
		}
		if ( extra ) {
//			NSLog(@"flush bytes at %d-%d of %d",base,i-base,length);
			[self appendBytes:utf8bytes+base length: i-base];
			[self appendBytes:extra length:strlen(extra)];
			base=i+1;
		}
	}

//    NSLog(@"final flush bytes at %d-%d of %d",base,i-base,length);
	[self appendBytes:utf8bytes+base length:length-base];
}



@end

