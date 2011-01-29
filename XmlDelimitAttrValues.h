

#import "XmlCommonMacros.h"

static int delimitAttrValue( const xmlchar *start, const xmlchar *end,
                       const xmlchar **keyStart, unsigned int *keyLen,
                       const xmlchar **valStart, unsigned int *valLen );
#define CHECKEND	    if ( cur >= end ) { return -1;}
#define SYNTAXHECKEND   if ( cur >= end ) {[NSException raise:@"syntax error" format:@"xml attr ended prematurely at '%c' in %.*s",*cur,end-start,start];}
#define SKIPSPACE	    while ( cur < end && isspace(*cur) ) { cur++; }

static int delimitAttrValue( const xmlchar *start, const xmlchar *end,
                       const xmlchar **keyStart, unsigned int *keyLen,
                       const xmlchar **valStart, unsigned int *valLen )
{
    const xmlchar *cur=start;

    SKIPSPACE;
    *keyStart=cur;
    while ( cur < end && (isalnum(*cur) || *cur==':') && *cur!='=') {
        cur++;
    }
    *keyLen=cur-*keyStart;
    SKIPSPACE;
    CHECKEND;
    if ( *cur=='=' ) {
        cur++;
        SKIPSPACE;
        if ( ISSINGLEQUOTE(*cur) || ISDOUBLEQUOTE(*cur) ) {
            xmlchar delimiter=*cur;
            *valStart=++cur;
            while ( cur < end && *cur != delimiter ) {
                cur++;
            }
            SYNTAXHECKEND;
            *valLen=cur-*valStart;
        } else if ( cur < end && !isspace(*cur)) {
    //        NSLog(@"not delimited by quote chars");
            *valStart=cur;
            while ( cur < end && (isalnum(*cur) || *cur=='#' || *cur=='%')) {
                cur++;
            }
            *valLen=cur-*valStart;
        } else {
            *valStart=EMPTYSTRING;
            *valLen=0;
        }
    } else {
#if 1   // lenient: HTML
        *valStart=EMPTYSTRING;
        *valLen=0;
#else   // strict: XML
        [NSException raise:@"syntax error" format:@"xml attr expected '=', got '%c' in %.*s, key=%.*s",*cur,end-start,start,*keyLen,*keyStart];
#endif
    }
    cur++;
    return cur-start;
}

