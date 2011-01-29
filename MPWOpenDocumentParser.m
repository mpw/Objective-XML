//
//  MPWOpenDocumentParser.m
//  MPWXmlKit
//
//  Created by Marcel Weiher on 2/19/08.
//	with code from NSOpenDocumentReader.m by Doug Davidson

#import "MPWOpenDocumentParser.h"
#import "MPWMAXParser.h"
#import "MPWXmlAttributes.h"



static CGFloat _postscriptPointsFromStringWithUnits(NSString *val) {
	char buffer[80]="", suffix[6]="\0\0\0\0\0";
	char *suffixes[]={ "in", "inch", "pt", "cm", "mm", "pc" };
	double multiplier[]={ 72.0, 72.0, 1.0, 72/2.54, 72/25.4, 12.0 };
 	float value=0;
	int i;
	[val getCString:buffer maxLength:70 encoding:NSASCIIStringEncoding];
	sscanf( buffer, "%g%4s",&value,suffix);
	for (i=0;i<6;i++) {
		if ( !strncmp( suffix, suffixes[i],strlen(suffixes[i]) ) ) {
			value*=multiplier[i];
			break;
		}
	}
	return round( value * 100) / 100;			//  keep two digits after the decimal point, round the rest
}

static CGFloat _nonNegativeFloatFromStringWithUnits( NSString *val ) {
	CGFloat result=_postscriptPointsFromStringWithUnits( val );
	return result > 0 ? result : 0;
}


static NSColor *_colorFromString(NSString *string) {
    NSColor *color = nil;
    if (string && [string length] > 1 && [string characterAtIndex:0] == '#') {
        NSUInteger rgbVal = (NSUInteger)strtol([[string substringFromIndex:1] UTF8String], NULL, 16); 
        uint8_t redVal = (rgbVal >> 16) & 0xff, greenVal = (rgbVal >> 8) & 0xff, blueVal = rgbVal & 0xff;
		if ( redVal == greenVal && greenVal == blueVal ) {
			color = [NSColor colorWithCalibratedWhite:((CGFloat)redVal)/255.0 alpha:1.0];
		} else {
			color = [NSColor colorWithCalibratedRed:((CGFloat)redVal)/255.0 green:((CGFloat)greenVal)/255.0 blue:((CGFloat)blueVal)/255.0 alpha:1.0];
		}
    }
    return color;
}



@interface MPWUnderlineStyle : MPWObject		//  this is currently in progress
{
	int styleFlags;
	NSColor *color;
}
@property(assign) int styleFlags;
@property(assign,nonatomic) NSColor * color;

+styleOrNilFromODFStyle:odfStyle	style1:odfStyle1 type:odfUnderlineType  colorString:underlineColorString;
-(void)addParametersToDict:(NSMutableDictionary*)attributeDict flagsKey:flagsKey colorKey:colorKey defaultColor:defaultColor;

@end

@implementation MPWUnderlineStyle

@synthesize styleFlags;
@synthesize color;

-(void)addParametersToDict:(NSMutableDictionary*)attributeDict flagsKey:flagsKey colorKey:colorKey defaultColor:defaultColor
{
	if ( styleFlags ) {
		[attributeDict setObject:[NSNumber numberWithFloat:styleFlags] forKey:flagsKey];
		[attributeDict setValue:[self color] ? [self color]:defaultColor forKey:colorKey];		
	}
}

+styleOrNilFromODFStyle:odfStyle	style1:odfStyle1 type:odfUnderlineType width:odfWidthString colorString:underlineColorString
{
	if ( odfStyle || odfStyle1 ) {
		int flags=0;
		MPWUnderlineStyle* style=[[[self alloc] init] autorelease];

		if ( [odfStyle isEqual:@"dash"] ) {
			flags |=  NSUnderlinePatternDash;
		} else if ( [odfStyle isEqual:@"dotted"] ) {
			flags |=  NSUnderlinePatternDot;
		} else if ( [odfStyle isEqual:@"dot-dash"] ) {
			flags |=  NSUnderlinePatternDashDot;
		} else if ( [odfStyle isEqual:@"dot-dot-dash"] ) {
			flags |=  NSUnderlinePatternDashDotDot;
		} else {
			flags |=  NSUnderlinePatternSolid;
		}
	
		if ( [odfUnderlineType isEqual:@"double"] ) { 
			flags |= NSUnderlineStyleDouble;
		} else {
			flags |= NSUnderlineStyleSingle;
		}
		
		if ( [odfWidthString isEqual:@"bold"] ) {
			flags |= NSUnderlineStyleThick;
		}
		
		[style setStyleFlags:flags];
		if ( underlineColorString ) {
			[style setColor:_colorFromString( underlineColorString )];
		}
//		NSLog(@"style: %@ style1: %@ type: %@",odfStyle,odfStyle1,odfUnderlineType);
		return style;
	}
	return nil;
}

@end


@interface MPWTextStyle : MPWObject
{
	id paragraphProperties,attributesDict;
	id fontName;
	float fontSize;
	int fontTraits;
	int superscript;
	float baselineOffset;
	float characterKern;
	BOOL outline;
	id	foregroundColor,backgroundColor;
	id	underlineStyleParameters,strikethroughStyleParameters;
}

@property(assign, nonatomic) id fontName;
@property( nonatomic) id paragraphProperties;
@property(assign) int fontTraits;
@property(assign) int superscript;

@property(assign) float fontSize;
@property(assign) float characterKern;
@property(assign) float baselineOffset;
@property(assign) BOOL outline;
@property(assign,nonatomic) id foregroundColor;
@property(assign,nonatomic) id backgroundColor;
@property(assign,nonatomic) id underlineStyleParameters;
@property(assign,nonatomic) id strikethroughStyleParameters;

@end

@implementation MPWTextStyle


-initWithParent:parentStyle paragraphProperties:paraProps
{
	self = [super init];
	if ( parentStyle ) {
		[self setFontName:[parentStyle fontName]];
		[self setFontSize:[parentStyle fontSize]];
		[self setParagraphProperties:[parentStyle paragraphProperties]];
	}
	if ( paraProps ) {
		[self setParagraphProperties:paraProps];
	}
	return self;
}

@synthesize fontName;
@synthesize paragraphProperties;
@synthesize fontSize;
@synthesize fontTraits;
@synthesize superscript;
@synthesize baselineOffset;
@synthesize characterKern;
@synthesize outline;
@synthesize foregroundColor;
@synthesize backgroundColor;
@synthesize underlineStyleParameters;
@synthesize strikethroughStyleParameters;


+defaultODFStyle
{
	NSMutableParagraphStyle* defaultParaStyle;
	MPWTextStyle* style=[[[self alloc] initWithParent:nil paragraphProperties:nil] autorelease];
	[style setFontName:@"Times"];
	[style setFontSize:12.0];
	defaultParaStyle=[[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[defaultParaStyle setTabStops:[NSArray array]];
	[defaultParaStyle setDefaultTabInterval:36.0];
	[style setParagraphProperties:defaultParaStyle];
	return style;
}

-(void)setForegroundColorFromString:(NSString*)colorString
{
	[self setForegroundColor:_colorFromString(colorString)];
}


-(void)setBackgroundColorFromString:(NSString*)colorString
{
	[self setBackgroundColor:_colorFromString(colorString)];
}

-textProperties
{
	id font = [NSFont fontWithName:[self fontName] size:[self fontSize]];
	if ( fontTraits ) {
		font=[[NSFontManager sharedFontManager] convertFont:font toHaveTrait:fontTraits];
	}
	return font;
}


#define SETNONZEROINTATTR( dict, attr, key )   if ( attr != 0 ) {  [dict setObject:[NSNumber numberWithInt:attr] forKey:key]; }
#define SETNONZEROFLOATATTR( dict, attr, key )   if ( attr != 0 ) {  [dict setObject:[NSNumber numberWithFloat:attr] forKey:key]; }
-attributesDict
{
	if (!attributesDict) {
		attributesDict = [[NSMutableDictionary alloc] init];
		[attributesDict setValue:[self textProperties] forKey:NSFontAttributeName];
		[attributesDict setValue:[self paragraphProperties] forKey:NSParagraphStyleAttributeName];
		[attributesDict setValue:[self foregroundColor] forKey:NSForegroundColorAttributeName];
		[attributesDict setValue:[self backgroundColor] forKey:NSBackgroundColorAttributeName];
		SETNONZEROINTATTR( attributesDict, fontTraits, NSFontTraitsAttribute );
		SETNONZEROINTATTR( attributesDict, superscript, NSSuperscriptAttributeName );
		[[self underlineStyleParameters] addParametersToDict:attributesDict flagsKey:NSUnderlineStyleAttributeName colorKey:NSUnderlineColorAttributeName defaultColor:nil];
		[[self strikethroughStyleParameters] addParametersToDict:attributesDict flagsKey:NSStrikethroughStyleAttributeName colorKey:NSStrikethroughColorAttributeName defaultColor:[NSColor blackColor]];

		if ( outline ) {
			[attributesDict setObject:[NSNumber numberWithInt:3] forKey:NSStrokeWidthAttributeName];
		}
		SETNONZEROFLOATATTR( attributesDict, characterKern, NSKernAttributeName );
	}
	return attributesDict;
}

-(void)dealloc{
	[fontName release];
	[paragraphProperties release];
	[attributesDict release];
	[foregroundColor release];
	[backgroundColor release];
	[underlineStyleParameters release];
	[super dealloc];
}

@end 


@implementation MPWOpenDocumentParser

// Attributes
enum {
    // Style attributes
    NSODFAttributeStyleMin  = 0,		NSODFAttributeStyleName  =0,
    NSODFAttributeParentStyleName,		NSODFAttributeFamily,				NSODFAttributeFontName,
	NSODFAttributeTextPosition,			NSODFAttributeTextUnderline,		NSODFAttributeTextUnderlineStyle,
	NSODFAttributeTextUnderlineWidth,	NSODFAttributeTextUnderlineColor,	NSODFAttributeTextLineThroughStyle, 
	NSODFAttributeLineHeightAtLeast,	NSODFAttributeTabStopDistance,		NSODFAttributeTabStopPosition,
	NSODFAttributeTextOutline,			NSODFAttributeUnderlineType,		NSODFAttributeTextLineThroughType,
	NSODFAttributeTextLineThroughColor,	NSODFAttributeStrikethroughWidth,	NSODFAttributeTabType,
    // Text attributes
    NSODFAttributeTextMin        = 30,	NSODFAttributeTextStyleName      = 30,
	NSODFAttributeBulletChar,			NSODFAttributeNumSufix,
    // Fo attributes
    NSODFAttributeFoMin          = 60,	NSODFAttributeFontSize       = 60,
    NSODFAttributeFontStyle, NSODFAttributeFontWeight, NSODFAttributeLetterSpacing, NSODFAttributeTextAlign,
    NSODFAttributeMarginTop, NSODFAttributeMarginBottom, NSODFAttributeMarginLeft, NSODFAttributeMarginRight,
    NSODFAttributeTextIndent,NSODFAttributeForegroundColor,NSODFAttributeBackgroundColor,
    // xlink attributes
    NSODFAttributeXlinkMin       = 90,	NSODFAttributeXlinkHref       = 90

};

enum {
    // Office elements
    NSODFElementOfficeMin    = 0,	NSODFElementDocument             = 0,
    NSODFElementDocumentContent,	NSODFElementDocumentStyles,			NSODFElementDocumentMeta,
    NSODFElementStyles,				NSODFElementAutomaticStyles,		NSODFElementMasterStyles,
    NSODFElementBody,				NSODFElementMeta,					NSODFElementText,
    // Style elements
    NSODFElementStyleMin    = 30,	NSODFElementStyle		= 30,
    NSODFElementDefaultStyle,		NSODFElementProperties,				NSODFElementParagraphProperties,
    NSODFElementTextProperties,		NSODFElementTabStops,				NSODFElementTabStop,
    NSODFElementFontFace,			NSODFElementListLevelProperties,	
    // Text elements
    NSODFElementTextMin	= 50,		NSODFElementP = 50,
    NSODFElementSpan,				NSODFElementS,						NSODFElementA,
	NSODFElementList,				NSODFElementListItem,				NSODFElementTab,
	NSODFElementLinebreak,			NSODFElementListStyle,				NSODFElementListLevelStyleBullet,
	NSODFElementListLevelNumberElement,									NSODFElementH,
	NSODFElementSectionElement,
    // Meta elements
    NSODFElementMetaMin = 70,		NSODFElementGenerator = 70,
    NSODFElementInitialCreator,		NSODFElementCreationDate,			NSODFElementKeyword,
    // Dc elements
    NSODFElementDcMin = 80,			NSODFElementTitle = 80,
    NSODFElementDescription,		NSODFElementSubject,				NSODFElementCreator,
    NSODFElementDate,
	// Table elements
	NSODFElementTableMin=90,			NSODFElementTable=90,
	NSODFElementTableColumn,			NSODFElementTableRow,			NSODFElementTableCell,
	NSODFElementTableHeaderRows,
 };



idAccessor( declaredFonts, setDeclaredFonts )
idAccessor( documentAttributes, setDocumentAttributes )
-styles { return styles; }
+parse:(NSData*)odtXMLData
{
	id parser =[[[self alloc] init] autorelease];
	return [parser parse:odtXMLData];
}

+parseZip:(NSData*)odtZipData documentAttributes:(id*)dictPtr
{
	return [[[[self alloc] init] autorelease] parseZip:odtZipData documentAttributes:dictPtr];
}

-parseZip:(NSData*)odtZipData documentAttributes:(id*)dictPtr
{
	id zipClass = NSClassFromString( @"NSZipFileArchive");

	id zipFile = [[[zipClass alloc] initWithData:odtZipData options:0 error:nil] autorelease];

	if ( dictPtr ) {
		[self parse:[zipFile contentsForEntryName:@"meta.xml"]];
		*dictPtr = [[self documentAttributes] retain];
		parser=nil;
	}
	[self parse:[zipFile contentsForEntryName:@"styles.xml"]];
	return [self parse:[zipFile contentsForEntryName:@"content.xml"]];

}

+parseZip:(NSData*)odtZipData
{
	return [self parseZip:odtZipData documentAttributes:nil];
}


-(void)_createParser
{
	if ( !parser ) {
		id xmlparser =  [MPWMAXParser parser];
		parser=xmlparser;
		[xmlparser setShouldProcessNamespaces:YES];
		[xmlparser setDocumentHandler:(NSObject <SaxDocumentHandler>*)self];

		[xmlparser setHandler:self forElements:[NSArray arrayWithObjects:@"style",@"default-style",@"properties",@"paragraph-properties",
																			@"text-properties",@"tab-stops",@"tab-stop",@"font-face",
																			 @"list-level-properties",
																			nil]
					inNamespace:@"urn:oasis:names:tc:opendocument:xmlns:style:1.0" prefix:@"Style" tagBase:NSODFElementStyleMin
					map:[NSDictionary dictionaryWithObjectsAndKeys:@"fontFace",@"font-face",@"textProperties",@"text-properties",
							@"tabStop",@"tab-stop",@"tabStops",@"tab-stops",@"paragraphProperties",@"paragraph-properties",
							@"listLevelProperties", @"list-level-properties",
								nil  ]];
		[xmlparser declareAttributes:[NSArray arrayWithObjects:@"name", @"parent-style-name", @"family", @"font-name",
					@"text-position", @"text-underline", @"text-underline-style", @"text-underline-width", 
					@"text-underline-color", @"text-line-through-style", @"line-height-at-least", @"tab-stop-distance",@"position",
					@"text-outline",@"text-underline-type",@"text-line-through-type",@"text-line-through-color",
					@"text-strikethrough-width", @"type",  nil]
					withTagBase:NSODFAttributeStyleMin inNamespace:@"urn:oasis:names:tc:opendocument:xmlns:style:1.0"];

		[xmlparser setHandler:self forElements:[NSArray arrayWithObjects:@"p",@"span",@"s",@"a",@"list",@"list-item",@"tab",@"line-break",
							@"list-style",	@"list-level-style-bullet",@"list-level-style-number",@"h",@"section", nil] 
					inNamespace:@"urn:oasis:names:tc:opendocument:xmlns:text:1.0" prefix:@"Text"  tagBase:NSODFElementTextMin
					map:[NSDictionary dictionaryWithObjectsAndKeys:@"listItem",@"list-item",@"linebreak",@"line-break",
							@"listStyle",@"list-style",  @"listLevelStyleBullet",	@"list-level-style-bullet", 
							@"listLevelStyleNumber",@"list-level-style-number",
						nil  ]];
		[xmlparser declareAttributes:[NSArray arrayWithObjects:@"style-name",@"bullet-char",nil]
					withTagBase:NSODFAttributeTextMin inNamespace:@"urn:oasis:names:tc:opendocument:xmlns:text:1.0"];


		[xmlparser declareAttributes:[NSArray arrayWithObjects:@"href",nil]
					withTagBase:NSODFAttributeXlinkMin inNamespace:@"http://www.w3.org/1999/xlink"];


		[xmlparser declareAttributes:[NSArray arrayWithObjects:@"font-size",@"font-style",@"font-weight",@"letter-spacing",@"text-align",
					@"margin-top",@"margin-bottom",@"margin-left",@"margin-right",@"text-indent",@"color",@"background-color",nil]
					withTagBase:NSODFAttributeFoMin inNamespace:@"urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"];

		[xmlparser setHandler:self forElements:[NSArray arrayWithObjects:@"table",@"table-column",@"table-row",@"table-cell",
					@"table-header-rows", nil] 
					inNamespace:@"urn:oasis:names:tc:opendocument:xmlns:table:1.0" prefix:@"Table"  tagBase:NSODFElementTableMin
					map:[NSDictionary dictionaryWithObjectsAndKeys:@"column",@"table-column",@"row",@"table-row",@"cell",@"table-cell",
						@"headerRows", @"table-header-rows",  nil  ]];


		[xmlparser setHandler:self forElements:[NSArray arrayWithObjects:@"document",@"content",
						@"document-styles",@"document-meta",@"styles",@"automatic-styles",@"master-styles",@"body",@"meta",
						@"text",@"font-face-decls",nil]
					inNamespace:@"urn:oasis:names:tc:opendocument:xmlns:office:1.0" prefix:@"Office"  tagBase:NSODFElementOfficeMin
					map:[NSDictionary dictionaryWithObjectsAndKeys:@"fontFaceDeclarations",@"font-face-decls",nil  ]];
	 

		[xmlparser setHandler:self forElements:[NSArray arrayWithObjects:@"generator",@"initial-creator",@"creation-date",@"keyword",nil]
					inNamespace:@"urn:oasis:names:tc:opendocument:xmlns:meta:1.0" prefix:@"Meta"  tagBase:NSODFElementMetaMin
					map:[NSDictionary dictionaryWithObjectsAndKeys:@"passThrough",@"keyword",@"passThrough",@"generator",
							@"passThrough",@"initial-creator",@"passThrough",@"creation-date",nil  ]];


		[xmlparser setHandler:self forElements:[NSArray arrayWithObjects:@"title",@"description",@"subject",@"creator",@"date",nil]
					inNamespace:@"http://purl.org/dc/elements/1.1/" prefix:@"Dc"  tagBase:NSODFElementDcMin
					map:[NSDictionary dictionaryWithObjectsAndKeys:@"passThrough",@"title", @"passThrough",@"description",
											@"passThrough",@"subject",@"passThrough",@"creator",@"passThrough",@"date",nil  ]];
		resultString = [[NSMutableAttributedString alloc] init];
		styles=[[NSMutableDictionary alloc] init];
		documentAttributes=[[NSMutableDictionary alloc] init];
	}
}


-parse:odtXmlData
{
	[self _createParser];
	
	[parser scan:odtXmlData];
	return resultString;
}

//----	utilities

-attributedString:aText withDefaultAttributesFrom:attributes
{
	NSRange r={0,[aText length]};
	id defaultDict=[attributes attributesDict];
	id defaultKeys = [defaultDict allKeys];
	id stringAttributes = [[aText attributesAtIndex:0 effectiveRange:&r] retain];
	int nonDefaultFonTraits=[[stringAttributes objectForKey:NSFontTraitsAttribute] intValue];
	for (id key in defaultKeys ) {
		if ( ![stringAttributes objectForKey:key] && ![key isEqual:NSFontTraitsAttribute] ) {
			[aText addAttribute:key value:[defaultDict objectForKey:key]  range:r];
		}
	}
	if ( nonDefaultFonTraits != [attributes fontTraits] ) {
		id convertedFont = [[NSFontManager sharedFontManager] convertFont:[defaultDict objectForKey:NSFontAttributeName] toHaveTrait:nonDefaultFonTraits];
		if ( convertedFont ) {
			[aText addAttribute:NSFontAttributeName value:convertedFont   range:r];
			[aText removeAttribute:NSFontTraitsAttribute range:r];
		}
	}
	[stringAttributes release];	
	return aText;
}

-(void)writeText:aText withTextStyle:attributes into:target
{
	if ( [aText length] >0 ) {
		if (![aText isKindOfClass:[NSAttributedString class]] ) {
			aText=[[[NSAttributedString alloc] initWithString:aText attributes:[attributes attributesDict]] autorelease];
		} else {
			aText=[self attributedString:aText withDefaultAttributesFrom:attributes];
		}
		[target appendAttributedString:aText];
	}
}


-(void)combineElements:(id*)objs count:(int)count  attributes:attributes into:result
{
	int i;
	for (i=0;i<count;i++) {
		[self writeText:objs[i] withTextStyle:attributes into:result];
	}
}

-combinedElementsForChildren:children withStyle:aStyle
{
	NSMutableAttributedString *str=[[NSMutableAttributedString alloc] init];
	[self combineElements:[children pointerToObjects] count:[children count] attributes:aStyle into:str];
	return str;
}

-(void)setStyle:aStyle forName:(NSString*)styleName
{
	[styles setObject:aStyle forKey:styleName];
}

-styleForName:(NSString*)styleName
{
	id style = [styles objectForKey:styleName];
	if ( !style && [styleName isEqual:@"Standard"] ) {
		style=[MPWTextStyle defaultODFStyle];
		[self setStyle:style forName:@"Standard"];
	}
	return style;
}


- (NSDate *)_dateForString:(NSString *)string {
	int year,month,day,hour,minute,second;
	char buffer[200]="";
	BOOL wellFormed ;
	[string getCString:buffer maxLength:180 encoding:NSASCIIStringEncoding];
	wellFormed=( 6== sscanf( buffer, "%4d-%2d-%2dT%2d:%2d:%2d",&year,&month,&day,&hour,&minute,&second));
	if ( wellFormed ) {
		CFGregorianDate date={ year, month, day,hour,minute,second};
		return [(NSDate *)CFDateCreate(NULL, CFGregorianDateGetAbsoluteTime(date, NULL)) autorelease];
	}
	return nil;
}


-textOfficeElement:children  attributes:attributes parser:parser
{
	[self combineElements:[children pointerToObjects] count:[children count]  attributes:nil into:resultString];
	return nil;
}

-combineChildrenIfNecessary:children textStyle:aStyle
{
	if ( [children count] > 1 ) {
		NSMutableAttributedString* str=[[NSMutableAttributedString alloc] init];
		[self combineElements:[children pointerToObjects] count:[children count] attributes:aStyle into:str];
		return str;
	} else {
		return [children lastObject];
	}
}

//----	element handling methods

//	table: elements

-tableTableElement:children attributes:attributes parser:parser
{
	int row, rowCount;
	NSTextTable* table=[[[NSTextTable alloc] init] autorelease];
	NSArray* headerRows = [children objectForTag:NSODFElementTableHeaderRows];
	NSMutableArray *rows=[NSMutableArray array];
	NSArray *childRows=[children objectsForTag:NSODFElementTableRow];
	id result=[[NSMutableAttributedString alloc] init];
	int maxColumns;

	if ( headerRows ) {
		[rows addObjectsFromArray:headerRows];
	}
	[rows addObjectsFromArray:childRows];
	maxColumns = [[rows objectAtIndex:0] count];
	[table setLayoutAlgorithm:NSTextTableAutomaticLayoutAlgorithm];
	[table setCollapsesBorders:YES];
	[table setHidesEmptyCells:NO];

	rowCount = [rows count];
	for ( row=0;row<rowCount; row++) {
		id columns=[rows objectAtIndex:row];
		int columnCount=[columns count];
		int column;
		maxColumns=MAX(columnCount,maxColumns);
		for (column=0;column<columnCount;column++) {
			NSRange r={0,1};
			NSMutableAttributedString *str=[columns objectAtIndex:column];
			NSTextTableBlock* cellBlock=[[[NSTextTableBlock alloc] initWithTable:table startingRow:row rowSpan:1 startingColumn:column columnSpan:1] autorelease];
			[cellBlock setWidth:1.0 type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockBorder];
			[cellBlock setWidth:5.0 type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockPadding edge:NSMinXEdge];
			[cellBlock setWidth:5.0 type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockPadding edge:NSMaxXEdge];
			[cellBlock setVerticalAlignment:NSTextBlockMiddleAlignment];
			[cellBlock setBorderColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];
			while ( r.location != NSNotFound && r.length > 0 && r.location < [str length]) {
				NSMutableParagraphStyle *style=[[[str attribute:NSParagraphStyleAttributeName atIndex:r.location effectiveRange:&r] mutableCopy] autorelease];
				[style setTextBlocks:[NSArray arrayWithObject:cellBlock]];
				[str addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:style,NSParagraphStyleAttributeName,nil] range:r];
				r.location+=r.length+1;
			}
			[self writeText:str withTextStyle:nil into:result];
		}
	}
	[table setNumberOfColumns:maxColumns];
//	NSLog(@"have a full table: %@",result);
	return result;	
}

-rowTableElement:children attributes:attributes parser:parser
{
	return [NSArray arrayWithObjects:[children pointerToObjects] count:[children count]];
}

-headerRowsTableElement:children attributes:attributes parser:parser
{
	return [NSArray arrayWithObjects:[children pointerToObjects] count:[children count]];
}


-columnTableElement:children attributes:attributes parser:parser
{
	return nil;
}

-cellTableElement:children attributes:attributes parser:parser
{
	return [self combinedElementsForChildren:children withStyle:nil];
}


//	text: elements

-(id)_getNestedListsInfo:aParser
{
	int i;
	int maxDepth=[aParser tagDepth];
	id name;
	int nesting=0;
	for (i=maxDepth-1;i>=0; i--) {
		if ( [[aParser elementNameAtDepth:i] isEqual:@"text:list"] ) {
			nesting++;
			name = [[aParser elementAttributesAtDepth:i] objectForTag:NSODFAttributeTextStyleName];
			if ( name ) {
				id listStyleArray=[self styleForName:name];
				return [listStyleArray objectAtIndex:nesting-1];
			}
		}
	}
	return nil;
}


-listTextElement:children attributes:attributes parser:aParser
{
	id result = [[NSMutableAttributedString alloc] init];
	int i;
	
	
	
	NSString* styleName = [attributes objectForTag:NSODFAttributeTextStyleName];
	NSArray *listArray = [self styleForName:styleName];
	NSTextList* list=[[[listArray objectAtIndex:0] copy] autorelease];
//	NSArray* listArray;
	if (!list ) {
		//--- this (probably) means that this is a sublist of a nested list, and the
		//--- actual style is defined by the top-level list
		list = [self _getNestedListsInfo:aParser];
		if ( !list ) {
			list=[[[NSTextList alloc] initWithMarkerFormat:@"{disc}" options:0] autorelease];
		}
	}
//	listArray=[NSArray arrayWithObject:list];
//	NSLog(@"list style for name '%@' is %@'",styleName,list);
	for (i=0;i<[children count];i++) {
		id text=[children objectAtIndex:i];
		id stringToInsert=[NSString stringWithFormat:@"\t%@\t",[list markerForItemNumber:i+1]];
		[text replaceCharactersInRange:NSMakeRange(0,0) withString:stringToInsert];
		[result appendAttributedString:text];
//		NSLog(@"%d added '%@' to get '%@'",i,[text string],[result string]);
	}
	if ( listArray ) {
		id paraStyle = [result attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
		int listIndex=0;					// FIXME:  should reflect list nesting
        float listLocation = (listIndex + 1) * 36.0;		//  should this be hardcoded?
//		float markerLocation = listLocation - 25.0;
		[paraStyle setFirstLineHeadIndent:0];
        [paraStyle setHeadIndent:listLocation];
		[paraStyle setTextLists:listArray];

	}
	return result;
}

-listItemTextElement:children attributes:attributes parser:parser
{
	return [self combineChildrenIfNecessary:children textStyle:nil];
}

-sectionTextElement:children attributes:attributes parser:parser
{
	return [self combinedElementsForChildren:children  withStyle:nil];

//	return [self combineChildrenIfNecessary:children textStyle:nil];
}

-spanTextElement:children  attributes:attributes parser:parser
{
	return [self combinedElementsForChildren:children withStyle:[self styleForName:[attributes objectForTag:NSODFAttributeTextStyleName]]];
#if 0
	if ( [children count] && [children lastObject] ) {
		return [[NSMutableAttributedString alloc] initWithString:[children lastObject] attributes:[ attributesDict]] ;
	} else {
		return nil;
	}
#endif	
}

-aTextElement:children  attributes:attributes parser:parser
{
	id text = [children lastObject];
	id urlString = [attributes objectForTag:NSODFAttributeXlinkHref];
	if ( urlString ) {
		[text addAttribute:NSLinkAttributeName value:[NSURL URLWithString:urlString] range:NSMakeRange(0,[text length])];
	}
	return text;
}


-sTextElement:children  attributes:attributes parser:parser
{
	return @" ";
}


-tabTextElement:children  attributes:attributes parser:parser
{
	return @"\t";
}


-linebreakTextElement:children  attributes:attributes parser:parser
{
	unichar linebreak=NSLineSeparatorCharacter;
	return [[NSString alloc] initWithCharacters:&linebreak length:1];
}

-pTextElement:children  attributes:attributes parser:parser
{
	id style = [self styleForName:[attributes objectForTag:NSODFAttributeTextStyleName]];
	id result=[[NSMutableAttributedString alloc] init];

	[self combineElements:[children pointerToObjects] count:[children count]  attributes:style into:result];
	[self writeText:@"\n" withTextStyle:style into:result];
	return result;
}

-hTextElement:children  attributes:attributes parser:aParser
{
	return [self pTextElement:children attributes:attributes parser:aParser];
}

//	style:  elements

-listLevelPropertiesStyleElement:children  attributes:attributes parser:parser
{
	return [attributes copy];
}

-textPropertiesStyleElement:children  attributes:attributes parser:parser
{
	return [attributes copy];
}

-paragraphPropertiesStyleElement:children attributes:attributes parser:parser
{
	NSTextAlignment alignment = NSNaturalTextAlignment; 
	id paraStyle=[[NSMutableParagraphStyle alloc] init];
	id alignmentString = [attributes objectForTag:NSODFAttributeTextAlign];
	if ( alignmentString ) {
		int len=[alignmentString length];
		if ( len==7 && [alignmentString isEqual:@"justify"]) {
			alignment=NSJustifiedTextAlignment;
		} else if ( len==3 && [alignmentString isEqual:@"end"]) {
			alignment=NSRightTextAlignment;
		} else if ( len==6 && [alignmentString isEqual:@"center"]) {
			alignment=NSCenterTextAlignment;
		} else if ( len==4 && [alignmentString isEqual:@"left"]) {
			alignment=NSLeftTextAlignment;
		}
	}
	[paraStyle setTabStops:[children objectForTag:NSODFElementTabStops]];
	[paraStyle setAlignment:alignment];
	[paraStyle setHeadIndent:_nonNegativeFloatFromStringWithUnits([attributes objectForTag:NSODFAttributeMarginLeft] )];
	[paraStyle setFirstLineHeadIndent:[paraStyle headIndent]+_nonNegativeFloatFromStringWithUnits([attributes objectForTag:NSODFAttributeTextIndent] )];
	{
		float tailIndent=_nonNegativeFloatFromStringWithUnits([attributes objectForTag:NSODFAttributeMarginRight] );
		if ( tailIndent > 0 ) {
			[paraStyle setTailIndent: -tailIndent];
		}
	}
	[paraStyle setParagraphSpacing:_nonNegativeFloatFromStringWithUnits([attributes objectForTag:NSODFAttributeMarginBottom] )];
	[paraStyle setParagraphSpacingBefore:_nonNegativeFloatFromStringWithUnits([attributes objectForTag:NSODFAttributeMarginTop] )];
	[paraStyle setMinimumLineHeight:_nonNegativeFloatFromStringWithUnits([attributes objectForTag:NSODFAttributeLineHeightAtLeast] )];
	return paraStyle;
}

-styleStyleElement:children attributes:attributes parser:parser
{
	MPWTextStyle* style,*parent=[self styleForName:[attributes objectForTag:NSODFAttributeParentStyleName]];
	int traits=0;
	id textAttributes = [children objectForTag:NSODFElementTextProperties];
	NSString* baselineString;
	NSString* fontName=[textAttributes objectForTag:NSODFAttributeFontName],*fontSizeAttribute=[textAttributes objectForTag:NSODFAttributeFontSize];
	if ( [[textAttributes objectForTag:NSODFAttributeFontWeight] isEqual:@"bold"] ) {
		traits |= NSBoldFontMask;
	}
	if ( [[textAttributes objectForTag:NSODFAttributeFontStyle] isEqual:@"italic"] ) {
		traits |= NSItalicFontMask;
	}
	style = [[[MPWTextStyle alloc] initWithParent:parent paragraphProperties:[children objectForTag:NSODFElementParagraphProperties]] autorelease];
	[style setOutline:[[textAttributes objectForTag:NSODFAttributeTextOutline] isEqual:@"true"]];
	if ( fontName) { [style setFontName:fontName]; }
	if ( fontSizeAttribute ) { [style setFontSize:[fontSizeAttribute floatValue]]; }
	[style setFontTraits:traits];
	[style setCharacterKern:_postscriptPointsFromStringWithUnits([textAttributes objectForTag:NSODFAttributeLetterSpacing] )];
	[style setForegroundColorFromString:[textAttributes objectForTag:NSODFAttributeForegroundColor]];
	[style setBackgroundColorFromString:[textAttributes objectForTag:NSODFAttributeBackgroundColor]];
	
	
	[style setUnderlineStyleParameters:[MPWUnderlineStyle styleOrNilFromODFStyle:[textAttributes objectForTag:NSODFAttributeTextUnderlineStyle]
															style1:[textAttributes objectForTag:NSODFAttributeTextUnderline]
															type:[textAttributes objectForTag:NSODFAttributeUnderlineType]
															width:[textAttributes objectForTag:NSODFAttributeTextUnderlineWidth]
															colorString:[textAttributes objectForTag:NSODFAttributeTextUnderlineColor]]];
	[style setStrikethroughStyleParameters:[MPWUnderlineStyle styleOrNilFromODFStyle:[textAttributes objectForTag:NSODFAttributeTextLineThroughStyle]
															style1:nil
															type:[textAttributes objectForTag:NSODFAttributeTextLineThroughType]
															width:[textAttributes objectForTag:NSODFAttributeStrikethroughWidth]
															colorString:[textAttributes objectForTag:NSODFAttributeTextLineThroughColor]]];
	baselineString = [textAttributes objectForTag:NSODFAttributeTextPosition];
	if ( baselineString ) {
		int prefixLen=0;
		float multiplier=1;
		if ( [baselineString hasPrefix:@"sub"] ) {
			prefixLen=3;
			multiplier*=-1;
		} else if ( [baselineString hasPrefix:@"super"] ) {
			prefixLen=5;
		}
		[style setSuperscript:(int)multiplier];
		[style setBaselineOffset:_postscriptPointsFromStringWithUnits([baselineString substringFromIndex:prefixLen+1])* multiplier ];
	}
	[self setStyle:style forName:[attributes objectForTag:NSODFAttributeStyleName]];
	return nil;
}



-tabStopStyleElement:children  attributes:attributes parser:parser
{
	id positionString = [attributes objectForTag:NSODFAttributeTabStopPosition];
	if ( positionString ) {
		int type = NSLeftTabStopType;
		NSString *typeString = [attributes objectForTag:NSODFAttributeTabType];
		if ( typeString ) {
			if ( [typeString isEqual:@"right"] ) {
				type=NSRightTabStopType;
			} else if ( [typeString isEqual:@"center"] ) {
				type=NSCenterTabStopType;
			} else if ([typeString isEqualToString:@"char"]) {
                type = NSDecimalTabStopType;
            }

		}
		return [[NSTextTab alloc] initWithType:type location:_postscriptPointsFromStringWithUnits( positionString )];
	}
	return nil;
}

-tabStopsStyleElement:children  attributes:attributes parser:parser
{
	return [[NSArray alloc] initWithObjects:[children pointerToObjects] count:[children count]];
}


-fontFaceStyleElement:children  attributes:attributes parser:parser
{
	return [[attributes objectForTag:NSODFAttributeStyleName] retain];
}

-listStyleTextElement:children  attributes:attributes parser:parser
{
	id styleName = [attributes objectForTag:NSODFAttributeStyleName];
//	NSLog(@"listStyleTextElement attributes: %@ ",attributes);
//	NSLog(@"listStyle: %@ = %@",styleName,children);
	if ( [children count] > 0 && styleName != nil) {
		[self setStyle:[NSArray arrayWithObjects:[children pointerToObjects] count:[children count]] forName:styleName];
	}
	return nil;
}

-listLevelStyleBulletTextElement:children  attributes:attributes parser:parser
{
//	id listProps = [children objectForTag:NSODFElementListLevelProperties];
	id markerFormat=@"{disc}";
	id bulletProperties=attributes;
	id bulletChar=[bulletProperties objectForTag:NSODFAttributeBulletChar];
	unichar uniBulletChar;
	
	//	FIXME:  custom UTF8 conversion, should be handled automagically by XML parser
	
	char buffer[ [bulletChar length] + 1];
	memcpy( buffer, [bulletChar bytes],[bulletChar length] );
	buffer[[bulletChar length]]=0;
	bulletChar=[NSString stringWithUTF8String:buffer];
	
	
	uniBulletChar=[bulletChar characterAtIndex:0];
//	NSLog(@"bullet char: '%@' %x",bulletChar,uniBulletChar);
	if ( bulletChar && uniBulletChar  ) {
		switch ( uniBulletChar ) {
			case '-':
			case 0x2022: markerFormat=@"{disc}";	break;
			case 0x2043: markerFormat=@"{hyphen}";	break;
			case 0x25aa: markerFormat=@"{square}";	break;
			case 0x2713: markerFormat=@"{check}";	break;
			default:
				NSLog(@"bullet char: '%@' %x",bulletChar,uniBulletChar);
				
		}
	}
//	NSLog(@"bullet char: '%@'",bulletChar);
	return [[NSTextList alloc] initWithMarkerFormat:markerFormat options:0];
}

-listLevelStyleNumberTextElement:children  attributes:attributes parser:parser
{
//	NSLog(@"listLevelStyleNumberTextElement: %@",attributes);
	id suffix=[attributes objectForKey:@"num-suffix"];
	id format=[attributes objectForKey:@"num-format"];
	unichar formatChar=[format length] ? [format characterAtIndex:0] : 0;
	switch (formatChar) {
		case 'i':	format=@"lower-roman";	break;
		case 'I':	format=@"upper-roman";	break;
		case 'a':	format=@"lower-alpha";	break;
		case 'A':	format=@"upper-alpha";	break;
		case '1':
		default:	format=@"decimal";	
	}
	
	return [[NSTextList alloc] initWithMarkerFormat:[NSString stringWithFormat:@"{%@}%@",format,suffix?suffix:@""] options:0];
}


//	misc elements

-fontFaceDeclarationsOfficeElement:children  attributes:attributes parser:parser
{
	[self setDeclaredFonts:[[[NSArray alloc] initWithObjects:[children pointerToObjects] count:[children count]] autorelease]];
	return nil;
}

-passThroughMetaElement:children attributes:attributes parser:parser
{
	return [[NSString alloc] initWithString:[children lastObject]];
}

-passThroughDcElement:children attributes:attributes parser:parser
{
	return [[NSString alloc] initWithString:[children lastObject]];
}

-metaOfficeElement:children attributes:attributes parser:parser
{
	[documentAttributes setValue:[children objectForTag:NSODFElementInitialCreator] forKey:NSAuthorDocumentAttribute];
	[documentAttributes setValue:[children objectForTag:NSODFElementTitle] forKey:NSTitleDocumentAttribute];
	[documentAttributes setValue:[children objectForTag:NSODFElementSubject] forKey:NSSubjectDocumentAttribute];
	[documentAttributes setValue:[children objectForTag:NSODFElementDescription] forKey:NSCommentDocumentAttribute];
	[documentAttributes setValue:[children objectForTag:NSODFElementCreator] forKey:NSEditorDocumentAttribute];
	[documentAttributes setValue:[children objectsForTag:NSODFElementKeyword] forKey:NSKeywordsDocumentAttribute];
	[documentAttributes setValue:[self _dateForString:[children objectForTag:NSODFElementCreationDate]] forKey:NSCreationTimeDocumentAttribute];
	[documentAttributes setValue:[self _dateForString:[children objectForTag:NSODFElementDate]] forKey:NSModificationTimeDocumentAttribute];

	return nil;
}

-defaultElement:children attributes:attrs parser:parser
{
	return nil;
}


-(void)dealloc
{
	[parser release];
	[resultString release];
	[declaredFonts release];
	[styles release];
	[documentAttributes release];
	[super dealloc];
}


@end


@implementation MPWOpenDocumentParser(testing)



+(void)testSimpleTextExtract
{
	id text = [self parse:[self frameworkResource:@"tiny_odt" category:@"xml"]];
	IDEXPECT( [text string] , @"A small amount of text\n", @"extracted text");
}


+(void)testSecondSimpleTextExtract
{
	id text = [self parse:[self frameworkResource:@"tiny1_odt" category:@"xml"]];
	IDEXPECT( [text string] , @"A different piece of text\n", @"extracted text");
}

+(void)testMappedTagProcessingViaFontDecls
{
	id parser =[[[self alloc] init] autorelease];
	[parser parse:[self frameworkResource:@"tiny_odt" category:@"xml"]];
	INTEXPECT( [[parser declaredFonts] count] ,1,  @"Number of fonts declared in tiny1_odt.xml");
	IDEXPECT( [[parser declaredFonts] lastObject] ,@"Helvetica",  @"font declared in tiny1_odt.xml");
}

+(void)testEmptyElementNamespaceBugViaFontDecls
{
	id parser =[[[self alloc] init] autorelease];
	[parser parse:[self frameworkResource:@"tiny1_odt" category:@"xml"]];
	INTEXPECT( [[parser declaredFonts] count] ,1,  @"Number of fonts declared in tiny1_odt.xml");
	IDEXPECT( [[parser declaredFonts] lastObject] ,@"Helvetica",  @"font declared in tiny1_odt.xml");
}

+(void)testCharacterStyleFont
{
	id text =[self parse:[self frameworkResource:@"times-odt-content" category:@"xml"]];
	id font = [[text fontAttributesInRange:NSMakeRange(0,2)] objectForKey:NSFontAttributeName];
	INTEXPECT( (int)[font pointSize], 14, @"font size");
	IDEXPECT( [font fontName], @"Times-Roman" , @"font size");
}

+(void)testPragraphStyleTabTypes
{
	id parser =[[[self alloc] init] autorelease];
	[parser parse:[self frameworkResource:@"tabtypes_odt" category:@"xml"]];

	INTEXPECT( [[[[[parser styleForName:@"P1"] paragraphProperties] tabStops] objectAtIndex:0] tabStopType],   NSLeftTabStopType , @"1st tab is left" );
	INTEXPECT( [[[[[parser styleForName:@"P2"] paragraphProperties] tabStops] objectAtIndex:0] tabStopType],   NSRightTabStopType , @"2nd tab is right" );
	INTEXPECT( [[[[[parser styleForName:@"P3"] paragraphProperties] tabStops] objectAtIndex:0] tabStopType],   NSCenterTabStopType , @"3rd tab is center" );
	INTEXPECT( [[[[[parser styleForName:@"P4"] paragraphProperties] tabStops] objectAtIndex:0] tabStopType],   NSDecimalTabStopType , @"4th tab is decimal" );

}

+(void)testPragraphStyleTabLocations
{
	id text =[self parse:[self frameworkResource:@"times-odt-content" category:@"xml"]];
	id paragraphStyle = [[text rulerAttributesInRange:NSMakeRange(0,2)] objectForKey:NSParagraphStyleAttributeName];
	id tabs=[paragraphStyle tabStops];
	INTEXPECT( [tabs count], 12, @"number of tab stops");
	INTEXPECT( (int)([[tabs objectAtIndex:0] location]*10),5*72  , @"location of first tab stop");
	INTEXPECT( (int)([[tabs objectAtIndex:1] location]*10),10*72 , @"location of 2nd tab stop");
	INTEXPECT( (int)([[tabs objectAtIndex:2] location]*10),15 *72 , @"location of 3rd tab stop");
}


+(void)testDocumentAttributes
{
	id parser =[[[self alloc] init] autorelease];
	id attributes;
	id creationDate,date;
	[parser parse:[self frameworkResource:@"meta" category:@"xml"]];
	attributes=[parser documentAttributes];
	IDEXPECT( [attributes objectForKey:NSAuthorDocumentAttribute], @"Marcel Weiher", @"author");
	IDEXPECT( [attributes objectForKey:NSTitleDocumentAttribute], @"Bogus test", @"title");
	IDEXPECT( [attributes objectForKey:NSSubjectDocumentAttribute], @"ODT test", @"subject");
	IDEXPECT( [[attributes objectForKey:NSKeywordsDocumentAttribute] componentsJoinedByString:@"-"], @"test-xml-parser", @"keywords");
	IDEXPECT( [attributes objectForKey:NSCommentDocumentAttribute], @"Wuhu", @"description/comment");
	IDEXPECT( [attributes objectForKey:NSEditorDocumentAttribute], @"Douglas Davidson", @"editor / creator");
	creationDate = [[attributes objectForKey:NSCreationTimeDocumentAttribute] dateWithCalendarFormat:nil timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	INTEXPECT( [creationDate yearOfCommonEra], 2003, @"creation year");
	INTEXPECT( [creationDate monthOfYear], 4, @"creation month");
	INTEXPECT( [creationDate dayOfMonth], 11, @"creation day");
	INTEXPECT( [creationDate hourOfDay], 21, @"hour of day");
	INTEXPECT( [creationDate minuteOfHour], 23, @"minute of hour");
	INTEXPECT( [creationDate secondOfMinute], 0, @"second");
	date = [[attributes objectForKey:NSModificationTimeDocumentAttribute] dateWithCalendarFormat:nil timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	INTEXPECT( [date yearOfCommonEra], 2006, @"modification year");
	INTEXPECT( [date monthOfYear], 10, @"modification month");
	INTEXPECT( [date dayOfMonth], 25, @"modification day");
	INTEXPECT( [date hourOfDay], 14, @"hour of day");
	INTEXPECT( [date minuteOfHour], 16, @"minute of hour");
	INTEXPECT( [date secondOfMinute], 0, @"second");
}

+(void)testCharacterBoldAndItalicStylesInIsolation
{
	id parser =[[[self alloc] init] autorelease];
	[parser parse:[self frameworkResource:@"character_attributes_odt" category:@"xml"]];
	INTEXPECT( [[parser styleForName:@"T2"] fontTraits],  NSBoldFontMask , @"style 2 is bold" );
	INTEXPECT( [[parser styleForName:@"T3"] fontTraits],   NSItalicFontMask , @"style 3 is italic" );
}

+(void)testNonFontCharacterStyles
{
	id parser =[[[self alloc] init] autorelease];
	[parser parse:[self frameworkResource:@"character_attributes_odt" category:@"xml"]];
	INTEXPECT( [[parser styleForName:@"T5"] superscript],   1 , @"superscript value for superscript" );
	INTEXPECT( [[parser styleForName:@"T6"] superscript],   -1 , @"superscript value for subscript" );
	INTEXPECT( (int)round([[parser styleForName:@"T5"] baselineOffset]),   100 , @"superscript baselines offset" );
	INTEXPECT( (int)round([[parser styleForName:@"T6"] baselineOffset]),   -100 , @"subscript baseline offset" );
	INTEXPECT( (int)round([[[parser styleForName:@"T4"] underlineStyleParameters] styleFlags]),   NSUnderlineStyleSingle|NSUnderlinePatternSolid , @"underline" );
	INTEXPECT( (int)round([[[parser styleForName:@"T7"] strikethroughStyleParameters] styleFlags]),   NSUnderlineStyleSingle|NSUnderlinePatternSolid , @"strikethrough" );
}



+(void)testParagraphAlignment
{
	id parser =[[[self alloc] init] autorelease];
	[parser parse:[self frameworkResource:@"paragrap_alignment_props_odt" category:@"xml"]];
	INTEXPECT( [[[parser styleForName:@"P1"] paragraphProperties] alignment],   NSJustifiedTextAlignment , @"first paragraph justified" );
	INTEXPECT( [[[parser styleForName:@"P2"] paragraphProperties] alignment],   NSNaturalTextAlignment , @"2nd paragraph natural" );
	INTEXPECT( [[[parser styleForName:@"P3"] paragraphProperties] alignment],   NSRightTextAlignment , @"3rd paragraph right" );
	INTEXPECT( [[[parser styleForName:@"P4"] paragraphProperties] alignment],   NSCenterTextAlignment , @"4th paragraph center" );

}


+(void)testParagraphMargins
{
	id parser =[[[self alloc] init] autorelease];
	[parser parse:[self frameworkResource:@"paragrap_margin_props_odt" category:@"xml"]];
	INTEXPECT( (int)round([[[parser styleForName:@"P1"] paragraphProperties] headIndent]),   42 , @"first paragraph left margin" );
	//--- existing implementation doesn't write out right margin, probably should file
//	INTEXPECT( (int)round([[[parser styleForName:@"P1"] paragraphProperties] tailIndent]),   24 , @"first paragraph right margin" );
	INTEXPECT( (int)round([[[parser styleForName:@"P1"] paragraphProperties] firstLineHeadIndent]),   72 , @"first line indent" );
	INTEXPECT( (int)round([[[parser styleForName:@"P1"] paragraphProperties] paragraphSpacingBefore]),   14 , @"para spacing before" );
	INTEXPECT( (int)round([[[parser styleForName:@"P1"] paragraphProperties] paragraphSpacing]),   16 , @"para spacing after" );
	INTEXPECT( (int)round([[[parser styleForName:@"P1"] paragraphProperties] minimumLineHeight]),   13 , @"para minimum line height" );

}

+(void)testCharacterKerning
{
	id parser =[[[self alloc] init] autorelease];
	[parser parse:[self frameworkResource:@"character_attributes_odt" category:@"xml"]];
	INTEXPECT( (int)round([[parser styleForName:@"T8"] characterKern]*100),   -16  , @"tightening kern" );
	INTEXPECT( (int)round([[parser styleForName:@"T9"] characterKern]*100),   16  , @"loosening kern" );
}

+(void)testNullStringReturnsZero
{
	INTEXPECT( (int)_postscriptPointsFromStringWithUnits( nil ), 0, @"getting float value from a nil string");
}


+(void)testClampNegativeNumber
{
	INTEXPECT( (int)_nonNegativeFloatFromStringWithUnits( @"-1" ), 0, @"clamped -1 ");
}


+(void)testPercentIgnoredWhenConvertingToFloat
{
	INTEXPECT( (int)_nonNegativeFloatFromStringWithUnits( @" 100%" ), 100, @" '100%' as a number");
}

+(void)testSimpleTextOfContentXMLWithCharacterAttributes
{
	id text =[[self parse:[self frameworkResource:@"character_attributes_odt" category:@"xml"]] string];
	IDEXPECT( text, @"helvetica times bold italic underline superscript subscript helvetica strikethrough tightened kerning loosened kerning outline helvetica\n",
						@"plain text of the character attributes content xml");
	
}
+(void)testRichTextOfContentODTWithCharacterAttributes
{
	id  text =[self parseZip:[self frameworkResource:@"character_attributes" category:@"odt"]];
	NSAttributedString* reference = [[[NSAttributedString alloc] initWithRTF:[self frameworkResource:@"character_attributes" category:@"rtf"] documentAttributes:nil] autorelease];
	int i;
	for (i=0;i<MIN( [text length]-1, [reference length]-1 ); i++ ) {
		NSRange r={i,1};
		id positionString = [NSString stringWithFormat: @"full rich text with character attributes at position %d",i];
		IDEXPECT( [text attributedSubstringFromRange:r] , [reference attributedSubstringFromRange:r], positionString);
	}
}

+(void)testSimpleTextOfContentODTWithCharacterAttributes
{
	id text =[[self parseZip:[self frameworkResource:@"character_attributes" category:@"odt"]] string];
	IDEXPECT( text, @"helvetica times bold italic underline superscript subscript strikethrough outline\n",
						@"plain text of the character attributes content  xml");
}

+(void)testLinkTextIsPresent
{
	id text =[self parse:[self frameworkResource:@"ahref_odt" category:@"xml"]];
	IDEXPECT([text string],@"Release Notes\n",@"text of link")
}


+(void)testLinkHrefIsPresent
{
	id text =[self parse:[self frameworkResource:@"ahref_odt" category:@"xml"]];
	NSRange r;
	NSURL *expectedURL=[NSURL URLWithString:@"file:///Volumes/User/marcel/programming/Tests/xperf/index.html#//apple_ref/doc/uid/TP30000872"];
	IDEXPECT([text attribute:NSLinkAttributeName  atIndex:1 effectiveRange:&r],expectedURL,@"url of link")
}

+(void)singleTabText
{
	IDEXPECT( [[self parse:[self frameworkResource:@"singletab_odt" category:@"xml"]] string], @"\tLeft Tab\n" , @"Text with a single tab");
}

+(void)testListTextIsPresent
{
	id text =[self parse:[self frameworkResource:@"simplelist_odt" category:@"xml"]];
	IDEXPECT([text string],@"A list\n\t•\titem 1\n\t•\titem 2\n",@"total text of list")
}


+(void)testSimpleListEqualToRTFVersion
{
	id text =[self parse: [self frameworkResource:@"simplelist_odt" category:@"xml"]];
	id rtfExpectedString = [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"simplelist" ofType:@"rtf"]];
	id rtfActual = [text RTFFromRange:NSMakeRange(0,[text length]) documentAttributes:nil];
	rtfActual = [[[NSString alloc] initWithData:rtfActual encoding:NSUTF8StringEncoding] autorelease];
	IDEXPECT( rtfActual, rtfExpectedString ,@"text with lists" );
}



+(void)testForegroundColor
{
	id text =[self parse:[self frameworkResource:@"color_odt" category:@"xml"]];
	NSRange r;
	NSColor *expectedColor=[NSColor redColor];
	IDEXPECT([text string],@"foreground background\n",@"text part of colored text");
	IDEXPECT([text attribute:NSForegroundColorAttributeName  atIndex:1 effectiveRange:&r],expectedColor,@"foregroundColor")
}

+(void)testBackgroundColor
{
	id text =[self parse:[self frameworkResource:@"fonteffects_odt" category:@"xml"]];
	NSRange r=[[text string] rangeOfString:@"backgroundred"];
	NSColor *expectedColor=[NSColor redColor];
	IDEXPECT([text attribute:NSBackgroundColorAttributeName  atIndex:r.location effectiveRange:&r],expectedColor,@"bacgkroundColor")
}

+(void)testUnitParse
{
	INTEXPECT( (int)_postscriptPointsFromStringWithUnits( @"16"), 16 ,@"no unit");
	INTEXPECT( (int)_postscriptPointsFromStringWithUnits( @"0.5in"), 36 ,@"1/2 inch inch");
	INTEXPECT( (int)_postscriptPointsFromStringWithUnits( @"0.5inch"), 36 ,@"1/2 inch inch");
	INTEXPECT( (int)_postscriptPointsFromStringWithUnits( @"1cm"), 28 ,@"");
	INTEXPECT( (int)_postscriptPointsFromStringWithUnits( @"10mm"), 28 ,@"");
	INTEXPECT( (int)_postscriptPointsFromStringWithUnits( @"12px"), 12 ,@"");
	INTEXPECT( (int)_postscriptPointsFromStringWithUnits( @"10pc"), 120 ,@"");
}

+(void)testUnitParseRounding
{
	INTEXPECT( (int)(_postscriptPointsFromStringWithUnits( @"16.235pt")*1000), 16240 ,@"points");
	INTEXPECT( (int)(_postscriptPointsFromStringWithUnits( @"16.234pt")*1000), 16230 ,@"points");
}

+(void)testDocumentWithListEqualToItself
{
	NSAttributedString* ref1 = [[[NSAttributedString alloc] initWithRTF:[self frameworkResource:@"simplelist" category:@"rtf"] documentAttributes:nil] autorelease];
	NSAttributedString* ref2 = [[[NSAttributedString alloc] initWithRTF:[self frameworkResource:@"simplelist" category:@"rtf"] documentAttributes:nil] autorelease];
	IDEXPECT( ref1, ref2, @"two instances of the same RTF file with list");

}

+(void)testDocumentWithoutListEqualToItself
{
	NSAttributedString* ref1 = [[[NSAttributedString alloc] initWithRTF:[self frameworkResource:@"character_attributes" category:@"rtf"] documentAttributes:nil] autorelease];
	NSAttributedString* ref2 = [[[NSAttributedString alloc] initWithRTF:[self frameworkResource:@"character_attributes" category:@"rtf"] documentAttributes:nil] autorelease];
	IDEXPECT( ref1, ref2, @"two instances of the same RTF file");

}

+(void)testTryToOverflowUnitBufferFailsConversion
{
	INTEXPECT( (int)_postscriptPointsFromStringWithUnits( @"10mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm"), 0 ,@"");
}

+(void)testUnderlineStrikeThroughStyles
{
	id parser =[[[self alloc] init] autorelease];
	[parser parse:[self frameworkResource:@"underline_strikethrough_odt" category:@"xml"]];
	INTEXPECT( [[[parser styleForName:@"T1"] underlineStyleParameters] styleFlags], NSUnderlineStyleSingle|NSUnderlinePatternSolid   , @"solid single underline in T1" );
	INTEXPECT( [[[parser styleForName:@"T2"] underlineStyleParameters] styleFlags], NSUnderlinePatternSolid | NSUnderlineStyleDouble   , @"solid double underline in T2" );
	IDEXPECT( [[[parser styleForName:@"T3"] underlineStyleParameters] color], [NSColor redColor]   , @"underline color in T3" );
	INTEXPECT( [[[parser styleForName:@"T4"] strikethroughStyleParameters] styleFlags], NSUnderlineStyleSingle|NSUnderlinePatternSolid   , @"strikethrough single underline in T4" );
	INTEXPECT( [[[parser styleForName:@"T5"] strikethroughStyleParameters] styleFlags], NSUnderlinePatternSolid | NSUnderlineStyleDouble   , @"strikethrough double underline in T5" );
	IDEXPECT( [[[parser styleForName:@"T6"] strikethroughStyleParameters] color], [NSColor redColor]   , @"strikethrough color in T6" );
}

+(void)testUnderlineStrikeThroughDashesAndDots
{
	id parser =[[[self alloc] init] autorelease];
	[parser parse:[self frameworkResource:@"fonteffects_odt" category:@"xml"]];
	INTEXPECT( [[[parser styleForName:@"T13"] underlineStyleParameters] styleFlags]&0xff00, NSUnderlinePatternDash   , @"underline dash " );
	INTEXPECT( [[[parser styleForName:@"T14"] underlineStyleParameters] styleFlags]&0xff00, NSUnderlinePatternDashDot   , @"underline dash " );
	INTEXPECT( [[[parser styleForName:@"T16"] underlineStyleParameters] styleFlags]&0xff00, NSUnderlinePatternDashDotDot   , @"underline dash dot dot" );
	INTEXPECT( [[[parser styleForName:@"T10"] underlineStyleParameters] styleFlags]&0xff00, NSUnderlinePatternDot   , @"underline dot" );
	INTEXPECT( [[[parser styleForName:@"T11"] underlineStyleParameters] styleFlags]& NSUnderlineStyleThick, NSUnderlineStyleThick   , @"underline thick" );
}

static NSTextTableBlock* _tableBlockOfString( NSAttributedString *str, NSString *checkString ) {
	NSRange r=[[str string] rangeOfString:checkString];
	NSParagraphStyle* style=(NSParagraphStyle*)[str attribute:NSParagraphStyleAttributeName atIndex:r.location effectiveRange:NULL];
	NSTextTableBlock* textBlock=[[style textBlocks] lastObject];
	return textBlock;
}	
	

+(void)testSimpleTable
{
	id str =[self parse:[self frameworkResource:@"tables_odt" category:@"xml"]];
	IDEXPECT( [str string], @"\ntopleft\ntopright\nbottomleft\nbottomright\n\n", @"plain text extract");
	INTEXPECT( [_tableBlockOfString(str,@"topleft") startingRow], 0, @"top left row");
	INTEXPECT( [_tableBlockOfString(str,@"topleft") startingColumn], 0, @"top left column");
	INTEXPECT( [_tableBlockOfString(str,@"topright") startingRow], 0, @"top right row");
	INTEXPECT( [_tableBlockOfString(str,@"topright") startingColumn],1, @"top right column");
	INTEXPECT( [_tableBlockOfString(str,@"bottomleft") startingRow], 1, @"bottom left row");
	INTEXPECT( [_tableBlockOfString(str,@"bottomleft") startingColumn], 0, @"bottom left column");
	INTEXPECT( [_tableBlockOfString(str,@"bottomright") startingRow], 1, @"bottom right row");
	INTEXPECT( [_tableBlockOfString(str,@"bottomright") startingColumn],1, @"bottom right column");
}

+(void)testLinebreak
{
	id str =[[self parse:[self frameworkResource:@"linebreak_odt" category:@"xml"]] string];
	id ref =[[[[NSAttributedString alloc] initWithRTF:[self frameworkResource:@"linebreak" category:@"rtf"] documentAttributes:nil] autorelease] string];
	INTEXPECT( [str length], [ref length], @"number of characters");
	INTEXPECT( [str characterAtIndex:0], [ref characterAtIndex:0], @"text with only a linebreak character");
	INTEXPECT( [str characterAtIndex:1], [ref characterAtIndex:1], @"second char");
	IDEXPECT( str, ref, @"text with only a linebreak character");
}

+(void)testListStyleInfo
{
	id parser =[[[self alloc] init] autorelease];
	[parser parse:[self frameworkResource:@"liststyles_odt" category:@"xml"]];
	IDEXPECT( [[[parser styleForName:@"L1"] lastObject] markerFormat] , @"{hyphen}"   , @"hyphen list style " );
	IDEXPECT( [[[parser styleForName:@"L2"] lastObject] markerFormat] , @"{disc}"   , @"disc list style " );
	IDEXPECT( [[[parser styleForName:@"L3"] lastObject] markerFormat] , @"{square}"   , @"square list style " );
	IDEXPECT( [[[parser styleForName:@"L4"] lastObject] markerFormat] , @"{check}"   , @"check list style " );
	IDEXPECT( [[[parser styleForName:@"L5"] lastObject] markerFormat] , @"{decimal}."   , @"list style " );
}

#define TESTAT( INDEX ) 	IDEXPECT( [str objectAtIndex:INDEX], [ref objectAtIndex:INDEX], ([NSString stringWithFormat:@"at %d",INDEX]) )


+(void)testListStylesConvertedToPlainText
{
	int i;
	id str = [[[self parse:[self frameworkResource:@"liststyles_odt" category:@"xml"]] string] componentsSeparatedByString:@"\n"];
	id ref =[[[[[NSAttributedString alloc] initWithRTF:[self frameworkResource:@"liststyles" category:@"rtf"] documentAttributes:nil] autorelease] string] componentsSeparatedByString:@"\n"];
	INTEXPECT( [str count], [ref count], @"same number of lines of lines/paragraphs");

	INTEXPECT( [str objectAtIndex:1], [ref objectAtIndex:1], @"same number of lines of lines/paragraphs");
	for (i=0;i<[str count];i++) {
		TESTAT( i );
	}
}

+(void)testNestedListStylesArray
{
	id parser =[[[self alloc] init] autorelease];
	[parser parse:[self frameworkResource:@"nested-lists_odt" category:@"xml"]];
	INTEXPECT( [[parser styleForName:@"L1"] count] , 2  , @"style with 2 nested lists " );
	IDEXPECT( [[[parser styleForName:@"L1"] objectAtIndex:0] markerFormat] , @"{decimal}."   , @"list style " );
	IDEXPECT( [[[parser styleForName:@"L1"] objectAtIndex:1] markerFormat] , @"{lower-roman}."   , @"list style " );
	
}
+(void)testNestedListsConvertedToPlainText
{
	int i;
	id str = [[[self parse:[self frameworkResource:@"nested-lists_odt" category:@"xml"]] string] componentsSeparatedByString:@"\n"];
	id ref =[[[[[NSAttributedString alloc] initWithRTF:[self frameworkResource:@"nested-lists" category:@"rtf"] documentAttributes:nil] autorelease] string] componentsSeparatedByString:@"\n"];
	INTEXPECT( [str count], [ref count], @"same number of lines of lines/paragraphs");

	for (i=0;i<[str count];i++) {
		TESTAT( i );
	}
}

+(void)testDefaultAttributes
{
	NSAttributedString* str = [self parse:[self frameworkResource:@"a_odt" category:@"xml"]];
	NSAttributedString* ref =[[[NSAttributedString alloc] initWithRTF:[self frameworkResource:@"a" category:@"rtf"] documentAttributes:nil] autorelease];
	IDEXPECT([str string],[ref string],@"plain text");
	IDEXPECT([str attribute:NSFontAttributeName atIndex:0 effectiveRange:nil],[ref attribute:NSFontAttributeName atIndex:0 effectiveRange:nil],@"font");
	IDEXPECT( str, ref, @"entire string");
}

+(void)testStandardStyle
{
	MPWTextStyle* defaultStyle=[MPWTextStyle defaultODFStyle];
	NSFont* font = [defaultStyle textProperties];
	IDEXPECT( [font fontName], @"Times-Roman", @"font name");
	INTEXPECT( (int)round([font pointSize]*10), 120, @"font size*10");
}

+(void)testTextHElement
{
	NSString* str = [[[self parse:[self frameworkResource:@"text_heading_odt" category:@"xml"]] string] substringToIndex:21];
	IDEXPECT( str, @"I am a heading1 title", @"text with text:h (headline) element");
	
}

+(void)testTextSectionElement
{
	NSString* str = [[[self parse:[self frameworkResource:@"text_section_odt" category:@"xml"]] string] substringToIndex:12];
	IDEXPECT( str, @"Objective: \n", @"text with text:section  element");
	
}

+(void)testStylesInWrapperTakenIntoAccount
{
	id  text =[self parseZip:[self frameworkResource:@"external_styles" category:@"odt"]];
	IDEXPECT( [text attribute:NSFontAttributeName atIndex:1 effectiveRange:NULL],[NSFont fontWithName:@"Arial" size:14], @"font in first lines");
}


+(void)testRequestingDocumentAttriutesDoesntKillParsing
{
	NSDictionary *attributes=nil;
	id  text =[self parseZip:[self frameworkResource:@"external_styles" category:@"odt"] documentAttributes:&attributes];
	IDEXPECT( [text attribute:NSFontAttributeName atIndex:1 effectiveRange:NULL],[NSFont fontWithName:@"Arial" size:14], @"font in first lines");
	IDEXPECT( [[text string] substringToIndex:3],@"Doc", @"start of text");
}

+(void)testTableCellsShouldMaintainStyles
{
	NSAttributedString* str = [self parse:[self frameworkResource:@"fontstyles-in-table-cells_odt" category:@"xml"]];
//	NSLog(@"str: %@",str);
	IDEXPECT( [str attribute:NSFontAttributeName atIndex:6 effectiveRange:NULL],[NSFont fontWithName:@"Helvetica-Bold" size:14], @"font in first lines");
}

+(void)testHeaderRowsOfTablesShouldBeIncluded
{
	id expectedString = @"CSOC Data Owner";
	id  text =[[self parseZip:[self frameworkResource:@"access_rqst" category:@"odt"]] string];
	NSRange r =[text rangeOfString:expectedString];
	INTEXPECT( r.length, [expectedString length], @"wanted to find the string somewhere");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testSimpleTextExtract",
		@"testSecondSimpleTextExtract",
		@"testMappedTagProcessingViaFontDecls",
		@"testEmptyElementNamespaceBugViaFontDecls",
		@"testCharacterStyleFont",
		@"testCharacterBoldAndItalicStylesInIsolation",
		@"testPragraphStyleTabLocations",
		@"testPragraphStyleTabTypes",
		@"testDocumentAttributes",
		@"testParagraphAlignment",
		@"testParagraphMargins",
		@"testNullStringReturnsZero",
		@"testClampNegativeNumber",
		@"testNonFontCharacterStyles",
		@"testCharacterKerning",
		@"testPercentIgnoredWhenConvertingToFloat",
		@"testSimpleTextOfContentXMLWithCharacterAttributes",
		@"testSimpleTextOfContentODTWithCharacterAttributes",
		@"testRichTextOfContentODTWithCharacterAttributes",
		@"testLinkTextIsPresent",
		@"testLinkHrefIsPresent",
		@"testForegroundColor",
		@"testBackgroundColor",
		@"testUnitParse",
		@"testUnitParseRounding",
		@"testTryToOverflowUnitBufferFailsConversion",
		@"testListTextIsPresent",
		@"testDocumentWithoutListEqualToItself",
		@"testDocumentWithListEqualToItself",
		@"testSimpleListEqualToRTFVersion",		//	cannot test RTF equivalence because presence of lists prevents equality
		@"testUnderlineStrikeThroughStyles",
		@"testUnderlineStrikeThroughDashesAndDots",
		@"testSimpleTable",
		@"singleTabText",
		@"testLinebreak",
		@"testListStyleInfo",
		@"testListStylesConvertedToPlainText",
		@"testNestedListStylesArray",
		@"testNestedListsConvertedToPlainText",
		@"testDefaultAttributes",
		@"testStandardStyle",
		@"testTextHElement",
		@"testTextSectionElement",
		@"testStylesInWrapperTakenIntoAccount",
		@"testRequestingDocumentAttriutesDoesntKillParsing",
		@"testTableCellsShouldMaintainStyles",
		@"testHeaderRowsOfTablesShouldBeIncluded",
		nil];
}	

@end


@implementation NSTextList(equality)

-(NSUInteger)hash {  return [_markerFormat hash] + _listFlags; }

-(BOOL)isEqual:otherObject
{
        return [self listOptions] == [otherObject listOptions] &&
                        [[self markerFormat] isEqual:[otherObject markerFormat]];
}

-description {  return [NSString stringWithFormat:@"<%@ markerFormat:'%@' listOptions: %d>",[self class],[self markerFormat],[self listOptions]]; }


@end

@implementation NSTextTableBlock(description)

-description {  return [NSString stringWithFormat:@"<%@ %d-%d %d-%d>",[self class],[self startingRow],[self rowSpan],[self startingColumn],[self columnSpan]]; }

@end