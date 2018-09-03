/* MPWObject.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.


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

*/


#import <Foundation/NSObject.h>
//#import <glib.h>

typedef id (*IMP0)(id, SEL, ...);

@interface MPWObject : NSObject
{
    @public
			int _retainCount;
			int flags;
}
-(void)mydealloc;

@end
extern id retainMPWObject( MPWObject *obj );
extern void retainMPWObjects( MPWObject **objs, unsigned count );
extern void releaseMPWObject( MPWObject *obj );
extern void releaseMPWObjects( MPWObject **objs, unsigned count );

#if __OBJC_GC__
#include <objc/objc-auto.h>
#define	IS_OBJC_GC_ON  objc_collecting_enabled()
#define	ALLOC_POINTERS( size )  NSAllocateCollectable( (size), NSScannedOption)
#else
#define	IS_OBJC_GC_ON  NO
#define	ALLOC_POINTERS( size)  malloc( (size) )
#endif
