/*
 *  mpwfoundation_imports.h
 *  MPWXmlKit
 *
 *  Created by Marcel Weiher on 6/3/08.
 *  Copyright 2008 Apple. All rights reserved.
 *
 */
#ifdef __OBJC__


#ifdef MPWXmlCoreOnly 

#import "MPWObject.h"
#import "MPWObjectCache.h"
#import "MPWSmallStringTable.h"
#import "MPWCaseInsensitiveSmallStringTable.h"
#import "MPWFastInvocation.h"
#import "MPWSubData.h"
#import "DebugMacros.h"
#import "MPWFlattenStream.h"
#import "MPWByteStream.h"

#else

#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWSmallStringTable.h>
#import <MPWFoundation/MPWCaseInsensitiveSmallStringTable.h>
#import <MPWFoundation/MPWFastInvocation.h>
#import <MPWFoundation/DebugMacros.h>
#import <MPWFoundation/MPWMessageCatcher.h>
#import <MPWFoundation/MPWFlattenStream.h>
#import <MPWFoundation/MPWByteStream.h>
#import <MPWFoundation/MPWSubData.h>


#endif
#endif