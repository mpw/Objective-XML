/* MPWXmlTag.h Copyright (c) Marcel P. Weiher 1999, All Rights Reserver, created  on Sun 23-Aug-1998 */

#import <MPWFoundation/MPWFoundation.h>

@interface MPWXmlTag : NSObject
{
    id	name;
}

+tagWithName:aName;
-name;
@end
