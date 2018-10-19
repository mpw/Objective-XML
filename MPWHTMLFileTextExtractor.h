//
//  NSHTMLFileTextExtractor.h
//  AKCmds
//
//  Created by  on 29/7/06.
//  Copyright 2006 Apple Computer. All rights reserved.
//

#import "MPWXmlParser.h"

@interface MPWHTMLFileTextExtractor : MPWSAXParser {
//	id	parser;
	id	string;
	int	maxLen;
	id	title;
	BOOL	inBody,inScript,inTitle,inFragment;
	id	metadata;
}

+extractTextFromPath:url maxLength:(long)maxLen attributes:dict;
@end
