/* XmlScannerPseudoMacro.h Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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

, created  on Tue 22-Jun-1999 */


//---	needs to be defined 

#define SCAN_OK 0
#define SCAN_UNCLOSED_TAG 1
#define SCAN_OTHER_ERROR 9

typedef enum {
    inText = 0,inSpace,
    inTag,inCloseTag,
    inDeclaration,inProcessingInstruction,
//    inEntityRef,
    inComment,inCData,
    scanDone, inAttributeName,inAttributeValue} scanStateType;
    
#import "XmlCommonMacros.h"

#define CHARSLEFT(n)   (endPtr-currentPtr > n)
#define	INRANGE	( CHARSLEFT(0) )
#define  CURRENTCHARCOUNT  (currentPtr - currentString)
#define  CURRENTBYTECOUNT  ((char*)currentPtr - (char*)currentString)

#define  SECURECALLBACK( callback )  if ( callback == NULL ) { callback = (void*)processDummy;  }
#define  XMLKITCALLBACK( whichCallBack )  whichCallBack( clientData, NULL, currentString, CURRENTCHARCOUNT,spaceOffset )


typedef BOOL (*ProcessFunc) (void *target, void* dummySel,const xmlchar *, unsigned long length,unsigned long nameLen);
typedef BOOL (*AttrFunc) (void *target, void* dummySel,const xmlchar *, unsigned long ,const xmlchar *,unsigned long);


static BOOL processDummy( void *dummyTarget ,void *dummySel ,const xmlchar *textPtr, unsigned int charCount,unsigned int nameLen)
{
//    NSLog(@"dummy processor");
         
          
    return YES;
}

#ifndef	CDATATAG
#define	CDATATAG	"<![CDATA["
#endif
#define	CDATALENGTH	9


#ifndef	ENDCOMMENT
#define ENDCOMMENT	"-->"
#endif
#define ENDCOMMENTLENGTH 3

#ifndef	CHARCOMP
#define	CHARCOMP	strncmp
#endif


static inline scanStateType checkForMarkup( const xmlchar *start, const xmlchar *end )
{
    xmlchar ch=NATIVECHAR(*start);
    if ( ch == XMLCHAR( '<' )) {
        ch = NATIVECHAR(start[1]);
        if ( isalnum( ch ) ) {
            return inTag;
        } else if ( ch=='/' ) {
            return inCloseTag;
        } else if ( ch=='!' ) {
            if ( end-start > 2 ) {
                if ( ISHYPHEN(start[2]) && ISHYPHEN(start[3])) {
                    return inComment;
                } else if ( end-start > CDATALENGTH &&
                            !CHARCOMP( start,CDATATAG,CDATALENGTH )) {
                    return inCData;
                }
            }
            return inDeclaration;
        } else if ( ch == '?' ) {
            return inProcessingInstruction;
        }
    }
    return isspace(ch) ? inSpace : inText;
}

/**
* tries to skip a comment.
*/
static inline const xmlchar *
tryToSkipComment( const xmlchar *start, const xmlchar *end )
{
    const xmlchar *currentPtr = start;
    if (end-start == 0 || !ISHYPHEN(start[0])  ||  !ISHYPHEN(start[1]))  {
       return currentPtr+1;
   } else {
       currentPtr += 2;;
   }
        while ( (currentPtr+1) < end && !ISHYPHEN(currentPtr[0]) && !ISHYPHEN(currentPtr[1]))  {
       currentPtr++;
   }
   if ((currentPtr+1) < end) {
       currentPtr +=2;
   }
   return currentPtr;
}


static int scanXml(
                   const xmlchar *data,
                   unsigned int charCount,
                   ProcessFunc openTagCallback,
                   ProcessFunc closeTagCallback,
                   ProcessFunc declarationCallback,
                   ProcessFunc processingInstructionCallback,
                   ProcessFunc entityReferenceCallback,
                   ProcessFunc textCallback,
                   ProcessFunc spaceCallback,
                   ProcessFunc cdataCallback,
                   AttrFunc attributeValueCallBack,
                   void *clientData)
{
    const xmlchar *endPtr;
    const xmlchar *currentPtr;
    scanStateType scanState = inText;
    SECURECALLBACK( openTagCallback );
    SECURECALLBACK( closeTagCallback );
    SECURECALLBACK( declarationCallback );
    SECURECALLBACK( processingInstructionCallback );
    SECURECALLBACK( entityReferenceCallback );
    SECURECALLBACK( textCallback );
    SECURECALLBACK( spaceCallback );
    SECURECALLBACK( cdataCallback );
	SECURECALLBACK( attributeValueCallBack );
    currentPtr=data;
    endPtr=data + charCount;
//	NSLog(@"start scan with %c",*currentPtr);
//	NSLog(@"start scan with client data %x",clientData);
    while ( currentPtr < endPtr ) {
        const xmlchar *currentString = currentPtr;
        long spaceOffset=0;
        ProcessFunc currentCallback;

		//--- scan up to the beginning of a tag (the initial '<' )
		
		//--- first scan up to any occurence of an ampersand
		
		while ( INRANGE && isspace( *currentPtr ) ) {
			currentPtr++;
		}
		spaceOffset=CURRENTCHARCOUNT;
        while ( INRANGE && !ISOPENTAG(*currentPtr)  ) {
			//			NSLog(@"char '%c' isopentag: %d",*currentPtr,ISOPENTAG(*currentPtr));
			if ( CHARSLEFT(2) && ISAMPERSAND( *currentPtr) && !isspace(currentPtr[1]) ) {
				break;
			}
			currentPtr++;
		}
		//--- report any characters that occured before the initial '<'

                if ( CURRENTCHARCOUNT > 0 ) {
//					NSLog(@"do top textCallback");
					if ( spaceOffset == CURRENTCHARCOUNT ) {
//						NSLog(@"spaceCallback");
						XMLKITCALLBACK( spaceCallback );
					} else {
						XMLKITCALLBACK( textCallback );
					}
                }
                if (!INRANGE) {
                    break;
                }
				if ( CHARSLEFT(2) && ISAMPERSAND( *currentPtr )) {
					currentString=currentPtr;
					currentPtr+=2;		//	have at least 1 character after the & so I can skip over that as well
					while ( INRANGE && !ISSEMICOLON( *currentPtr ) && !isspace( *currentPtr ) ) {
						currentPtr++;
					}
					if ( INRANGE && ISSEMICOLON( *currentPtr  )) {
						currentPtr++;
					}
					XMLKITCALLBACK( entityReferenceCallback );
					
					//----	start back at the top, whereas usually we try to take advantage of the tag/chars 
					//----	rythm to just go straight to tag processing
					
					continue;
				}
				
		//---	now begin processing a (potential) tag
				
               currentString = currentPtr;

		//---	skip over the initial '<' 
		if ( INRANGE ) {
			   currentPtr++;
				scanState = inTag;
		} else {
			break;
		}
			//---	we initially think it's an open tag, might revise this later
		
               currentCallback=openTagCallback;
			   
                if (isalnum(*currentPtr)) {
					//--- it's an open tag (or an empty tag)
                } else {
					//--- it's something else, check the possibilities
                    if ( INRANGE && *currentPtr == '/' ) {
                        currentCallback=closeTagCallback;
                        currentPtr++;
                    } else if ( INRANGE && *currentPtr == '!' ) {
                        currentPtr++;
                        if ( *currentPtr=='[' && ( CHARSLEFT(CDATALENGTH) &&
                                                   !CHARCOMP( currentPtr,CDATATAG+2,CDATALENGTH-2 ))) {
                            currentPtr+=CDATALENGTH;
							scanState = inCData;
                            //---	searching for CDataEnd "]]>" via hard-coded Boyer-Moore variant
                            while ( INRANGE /* termination via break in '>' case */ ) {	
                                if ( ISCLOSETAG(*currentPtr) ) {
                                    if ( ISRIGHTSQUAREBRACKET(currentPtr[-1]) && ISRIGHTSQUAREBRACKET(currentPtr[-2])) {
//                                        NSLog(@"end of CDATA section");
										currentPtr++;
                                        break;
                                    } else {
                                        currentPtr+=3;
                                    }
                                } else if ( ISRIGHTSQUAREBRACKET(currentPtr[0]) ) {
                                    currentPtr+=1;
                                } else {
                                    currentPtr+=3;
                                }
                            }
							if ( INRANGE ){ 
								XMLKITCALLBACK( cdataCallback );
								continue;
							} else {
								break;
							}
                        } else if ( *currentPtr=='-' && currentPtr[1]=='-' ) {
                            currentCallback=declarationCallback;
                            currentPtr+=2;
							scanState = inComment;
                            do {
                                while ( INRANGE && !ISHYPHEN(*currentPtr) ) {
                                    currentPtr++;
                                }
                                if (  CHARSLEFT(ENDCOMMENTLENGTH) && !CHARCOMP( currentPtr, ENDCOMMENT,ENDCOMMENTLENGTH)) {
                                    currentPtr+=ENDCOMMENTLENGTH;
                                    XMLKITCALLBACK( declarationCallback );
                                    scanState = checkForMarkup( currentPtr, endPtr );
                               } else if ( INRANGE ) {
                                    currentPtr++;
                                }
                            } while ( CHARSLEFT(ENDCOMMENTLENGTH) && scanState == inComment );
                            continue;
                        } else {
                            currentCallback=declarationCallback;
							while ( INRANGE && !ISCLOSETAG(*currentPtr) ) {
								currentPtr++;
							}
                        }
                    } else if ( INRANGE && *currentPtr == '?' ) {
                        currentCallback=processingInstructionCallback;
                        currentPtr++;
                    }
                }
				
			  // --- scan over name of tag
			  
//			  NSLog(@"scan over name or tag: %c",*currentPtr);
                while ( INRANGE && !isspace(*currentPtr) && !ISCLOSETAG(*currentPtr) ) {
                     currentPtr++;
                }
                spaceOffset=CURRENTCHARCOUNT;
//			  NSLog(@"did scan over name or tag: %c, charCount: %d",*currentPtr,CURRENTCHARCOUNT);
//			  NSLog(@"scan attributes");

		  // --- scan attributes
		  
		  
			  while ( INRANGE && ( *currentPtr != '/' && *currentPtr != '>' )  ) {
				  const xmlchar *attNameStart;
				  const xmlchar *attNameEnd;
				   xmlchar attValDelim=' ';
				  const xmlchar *attValStart,*attValEnd;
				  scanStateType saveState = scanState;
				  
				  //--- scan over any leading whitesspace
				  
				  while ( INRANGE &&  isspace(*currentPtr)) {
					  currentPtr++;
				  }
				  
				  //--- scan over name of attribute
				  
				  attNameStart=currentPtr;
				  scanState=inAttributeName;
				  while ( INRANGE && *currentPtr != '=' && !ISCLOSETAG(*currentPtr)) {
					  currentPtr++;
				  }
				  if ( currentPtr == attNameStart ) {
					  break;
				  }
				  attNameEnd = currentPtr;
				  
				  //--- remove any trailing space between the attribute name and the '='
				  
				  while ( attNameEnd > attNameStart &&  isspace(attNameEnd[-1])) {
					  attNameEnd--;
				  }
				  
				  //---	scan over the '='
				  
				  if ( INRANGE && !ISCLOSETAG( *currentPtr ) ) {
				  
					currentPtr++;

					//--- remove any leading space between the '=' and the attribute value

					while ( INRANGE &&  isspace(*currentPtr)) {
					  currentPtr++;
					}
				  
					//---	scan the attribute value
				  
					if (INRANGE && (*currentPtr == '"' || *currentPtr=='\'') ) {
						attValDelim=*currentPtr;
						currentPtr++;
					}
					
					attValStart=currentPtr;
					scanState=inAttributeValue;
					while ( INRANGE && *currentPtr != attValDelim && !ISCLOSETAG(*currentPtr)) {
						currentPtr++;
					}
					attValEnd=currentPtr;
					
					//--- skip over duplicated close quotes (some HTML files have this)
					
					if ( INRANGE && *currentPtr == attValDelim ) {
						currentPtr++;
					}
				  } else {
					//--- found close tag after just the attribute name (key)  -> this is probably an error!
					attValStart=attNameEnd;
					attValEnd=attValStart;
				  }
				  attributeValueCallBack( clientData, NULL, attNameStart, attNameEnd-attNameStart, attValStart, attValEnd-attValStart );
				  if ( INRANGE && attValDelim!=' ' && *currentPtr == attValDelim ) {
					  currentPtr++;
				  }
				  scanState=saveState;
			  }
              while ( INRANGE && (isspace(*currentPtr) ||ISSLASH(*currentPtr)) ) {
                  currentPtr++;
              }
			  if (  INRANGE && *currentPtr=='?' ) {
				  currentPtr++;
				  currentCallback = processingInstructionCallback;
			  } 
				//--- finished parsing tag, should now have a '>' 
                if ( INRANGE && ISCLOSETAG(*currentPtr) ) {
					//--- skip over the '>'
                    currentPtr++;
                    XMLKITCALLBACK( currentCallback );
					scanState=inText;
                } else if ( INRANGE ) {
					//--- did not encounter closing '>', confused, just do a text callback
					//--- maybe I should signal an error here?
//					NSLog(@"textCallBack");
                    XMLKITCALLBACK( textCallback );
                }
        }
    switch (scanState) {
        case inTag:
        case inDeclaration:
        case inAttributeName:
        case inAttributeValue:
		case inCData:
//			NSLog(@"scan state: %d",scanState);
            return SCAN_UNCLOSED_TAG;
        default:
            return SCAN_OK;
    }
}                

