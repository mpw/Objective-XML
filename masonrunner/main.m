
#import <ObjectiveXML/MPWMASONParser.h>
#import <MPWFoundation/MPWPListBuilder.h>
#import <MPWFoundation/MPWObjectCache.h>
#import <Foundation/Foundation.h>

#define ARRAYTOS    (NSMutableArray*)(*tos)
#define DICTTOS        (NSMutableDictionary*)(*tos)

@interface TestClass : NSObject {
}

@property (assign) int hi,there;
@property (nonatomic, strong ) NSString *comment;


@end

@implementation TestClass

-(void)dealloc
{
    [_comment release];
    [super dealloc];
}

@end



@interface TestClassBuilder :MPWPListBuilder

@property (nonatomic, strong) MPWObjectCache *cache;
@property (nonatomic, assign) long objectCount;

@end

@implementation TestClassBuilder

-(instancetype)init
{
    self=[super init];
    _cache=[[MPWObjectCache alloc] initWithCapacity:20 class:[TestClass class] allocSel:@selector(alloc) initSel:@selector(init)];

    return self;
}


-(void)beginDictionary
{
    [self pushContainer:GETOBJECT(_cache) ];
}

-(void)endDictionary
{
    tos--;
    [self writeObject:[ARRAYTOS lastObject]];
    [ARRAYTOS removeLastObject];
    self.objectCount++;
}

-(void)writeObject:anObject forKey:aKey
{
}



@end




int main(int argc, char *argv[]) {
    NSString *filename = @(argv[1]);
    NSData *data=[NSData dataWithContentsOfMappedFile:filename];

    NSArray* result = nil;
    MPWMASONParser *parser=nil;
    TestClassBuilder *builder=nil;
    for (int i=0;i<10;i++) {
#if 1
        parser=[MPWMASONParser parser];
        builder = [TestClassBuilder new];
        parser.builder = builder;
        [parser setFrequentStrings: @[ @"hi" , @"there", @"comment" ]];
        result = [parser parsedData:data];
#else
        result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
#endif
    }
    NSLog(@"result: %@",[result class]);
    NSLog(@"count: %ld",[result count]);
    NSLog(@"count: %ld",[builder objectCount]);
    NSLog(@"last: %@",[result lastObject]);
    return 0;
}
