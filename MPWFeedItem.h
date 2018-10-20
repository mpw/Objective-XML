//
//  MPWFeedItem.h
//  ObjectiveXML
//
//  Created by Marcel Weiher on 1/3/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MPWFeedItem : NSObject
{
}

@property (nonatomic, strong)  NSString *guid;
@property (nonatomic, strong)  NSString *title;
@property (nonatomic, strong)  NSString *category;
@property (nonatomic, strong)  NSString *imageLink;
@property (nonatomic, strong)  NSString *pubDate;
@property (nonatomic, strong)  NSDictionary *remainder;
@property (nonatomic, strong)  NSMutableArray *links;


@end

