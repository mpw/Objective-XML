/* MPWObject.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
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
