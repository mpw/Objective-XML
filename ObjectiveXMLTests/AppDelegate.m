//
//  AppDelegate.m
//  ObjectiveXMLTests
//
//  Created by Marcel Weiher on 12/9/17.
//

#import "AppDelegate.h"
#import <MPWTest/MPWTestSuite.h>
#import <MPWTest/MPWLoggingTester.h>
#import <MPWTest/MPWClassMirror.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


int runTests( NSArray *testSuiteNames , NSMutableArray *testTypeNames,  BOOL verbose ,BOOL veryVerbose ) {
    NSMutableArray *testsuites=[NSMutableArray array];
    MPWTestSuite* test;
    MPWLoggingTester* results;
    int exitCode=0;
    
    //    if ( [testTypeNames count] == 0 ) {
    //        testTypeNames=[testTypeNames arrayByAddingObject:@"testSelectors"];
    //    }
    //    for ( id suitename in testSuiteNames ) {
    //        id suite = [MPWTestSuite testSuiteForLocalFramework:suitename testTypes:testTypeNames];
    //        //            NSLog(@"suite name= %@",suitename);
    //        //            NSLog(@"suite = %@",suite);
    //        if ( suite ) {
    //            [testsuites addObject:suite];
    //        } else {
    //            NSLog(@"couldn't load framework: %@",suitename);
    //        }
    //
    //    }
    NSArray *classNamesToTest=
    @[
      @"MPWMAXParser",
      @"NSXMLScanner",
      @"MPWXMLAttributes",
      ];
    NSMutableArray *mirrors=[NSMutableArray array];
    for ( NSString *className in classNamesToTest ) {
        [mirrors addObject:[MPWClassMirror mirrorWithClass:NSClassFromString( className)]];
    }
    
    test=[MPWTestSuite testSuiteWithName:@"all" classMirrors:mirrors testTypes:@[ @"testSelectors"]];
    
    
    
    //    test=[MPWTestSuite testSuiteWithName:@"all" testCases:@[]];
    //    NSLog(@"test: %@",test);
    results=[[MPWLoggingTester alloc] init];
    [results setVerbose:veryVerbose];
    fprintf(stderr,"Will run %d tests\n",[test numberOfTests]);
    [results addToTotalTests:[test numberOfTests]];
    [test runTest:results];
    if ( !veryVerbose ){
        if ( verbose) {
            [results printAllResults];
        } else {
            [results printResults];
        }
    }
    if ( [results failureCount] >0 ) {
        exitCode=1;
    }
    return exitCode;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    runTests( @[ @"MPWFoundation"], @[] , NO, NO);
    return YES;
}


@end

