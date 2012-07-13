//
//  MPWTagAction.h
//  ObjectiveXML
//
//  Created by Marcel Weiher on 7/12/12.
//
//

#import <Foundation/Foundation.h>

@class MPWFastInvocation;

@interface MPWTagAction : NSObject
{
    NSString *tagName;
    NSString *mappedName;
    NSString *tagNamespace;
    NSString *namespacePrefix;
    MPWFastInvocation *tagAction;
    MPWFastInvocation *elementAction;
}

-initWithTagName:(NSString*)tag;
+tagActionWithName:(NSString*)tag;
-(NSString*)tagName;
-(MPWFastInvocation*)tagAction;
-(MPWFastInvocation*)elementAction;

-(void)setElementInvocationForTarget:primary backup:backup;
-(void)setNamespacePrefix:(NSString*)aPrefix;
@end
