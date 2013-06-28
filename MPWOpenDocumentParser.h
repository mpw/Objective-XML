//
//  MPWOpenDocumentParser.h
//  MPWXmlKit
//
//  Created by Marcel Weiher on 2/19/08.
//  Copyright 2008 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MPWOpenDocumentParser : NSObject {
	id parser;
	id resultString;
	id declaredFonts;
	id styles;
	id documentAttributes;
}

-styleForName:(NSString*)styleName;


@end
