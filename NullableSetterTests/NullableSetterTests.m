//
//  NullableSetterTests.m
//  NullableSetterTests
//
//  Created by Dan Cong on 18/11/15.
//  Copyright © 2015 dancyd. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "UserInfo.h"
#import "NSObject+NullableSetter.h"

@interface NullableSetterTests : XCTestCase

@property(nonatomic, strong)UserInfo *info;

@end

@implementation NullableSetterTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.info = [UserInfo new];
    [self.info protectNullableSetters];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    self.info = nil;
}

- (void)testPrimitives {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    self.info.age = 31;
    self.info.height = 183.4;
    self.info.weight = 75.1;
    self.info.gender = Male;
    self.info.married = NO;
    self.info.mobile = 13811708004;
    self.info.card = 12345678;
    
    
    XCTAssertEqual(self.info.age, 31);
    XCTAssertEqual(self.info.height, 183.4);
    XCTAssertEqualWithAccuracy(self.info.weight, 75.1, 0.000002);
    XCTAssertEqual(self.info.gender, Male);
    XCTAssertEqual(self.info.married, NO);
    XCTAssertEqual(self.info.mobile, 13811708004);
    XCTAssertEqual(self.info.card, 12345678);
}

- (void)testFamousAliasPrimitives {
    
}

- (void)testObjects {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    self.info.name = @"1";
    self.info.extDic = @{};
    self.info.extArr = @[];
    XCTAssertEqualObjects(self.info.name, @"1");
    XCTAssertEqualObjects(self.info.extDic, @{});
    XCTAssertEqualObjects(self.info.extArr, @[]);
    
    self.info.name = nil;
    self.info.extDic = nil;
    self.info.extArr = nil;
    XCTAssertEqualObjects(self.info.name, @"1");
    XCTAssertEqualObjects(self.info.extDic, @{});
    XCTAssertEqualObjects(self.info.extArr, @[]);    
}

- (void)testStruct {
    
    self.info.rect = CGRectZero;
    
    XCTAssertTrue(CGRectEqualToRect(self.info.rect, CGRectZero));
}


//you start by writing a closure literal, hand it to the API and, after a few hoops, you want to assert that a certain closure reference is the same as the original closure literal you’ve written.
//but there's no such closure equality API, so I just check it's not nil.
- (void)testBlock {
    self.info.aBlock = ^{};
    XCTAssertTrue(self.info.aBlock != nil);
    
    self.info.aBlock = nil;
    XCTAssertTrue(self.info.aBlock != nil);
}

@end
