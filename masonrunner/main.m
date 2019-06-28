
#import <ObjectiveXML/MPWMASONParser.h>
#import <ObjectiveXML/MPWObjectBuilder.h>

#import <Foundation/Foundation.h>


@interface TestClass : NSObject {
}

@property (assign) int hi,there;
@property (nonatomic, strong ) NSString *comment;


@end

@implementation TestClass

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: hi: %d there: %d comment: %@>",
            [self class],self,self.hi,self.there,self.comment];
}

-(void)dealloc
{
    [_comment release];
    [super dealloc];
}

@end





int main(int argc, char *argv[]) {
    NSString *filename = @(argv[1]);
    NSData *data=[NSData dataWithContentsOfMappedFile:filename];

    NSArray* result = nil;
    MPWMASONParser *parser=nil;
    MPWObjectBuilder *builder=nil;
    for (int i=0;i<1;i++) {
#if 1
        parser=[MPWMASONParser parser];
        builder = [[[MPWObjectBuilder alloc] initWithClass:[TestClass class]] autorelease];
        builder.streamingThreshold=1;
//        builder.target = [MPWByteStream Stdout];
        parser.builder = builder;
        [parser setFrequentStrings: @[ @"hi" , @"there"  ]];
        result = [parser parsedData:data];
#else
        result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
#endif
    }
    NSLog(@"result: %@",[result class]);
    NSLog(@"array count: %ld",[result count]);
    NSLog(@"stram count: %ld",[builder objectCount]);
    NSLog(@"last: %@",[result lastObject]);
    NSLog(@"first: %@",[result firstObject]);
    NSLog(@"last comment: %@",[[result lastObject] comment]);
    NSLog(@"first comment: %@",[[result firstObject] comment]);
    NSLog(@"last comment: %p",[[result lastObject] comment]);
    NSLog(@"first comment: %p",[[result firstObject] comment]);
    return 0;
}
