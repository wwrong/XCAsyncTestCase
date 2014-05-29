//
//  XCTestCase+AsyncTesting.m
//  AsyncXCTestingKit
//
//  Created by 小野 将司 on 12/03/17.
//  Modified for XCTest by Vincil Bishop
//  Copyright (c) 2012年 AppBankGames Inc. All rights reserved.
//

#import "XCTestCase+AsyncTesting.h"
#import "objc/runtime.h"

static void *kNotified_Key = "kNotified_Key";
static void *kNotifiedStatus_Key = "kNotifiedStatus_Key";
static void *kExpectedStatus_Key = "kExpectedStatus_Key";

@implementation XCTestCase (AsyncTesting)

#pragma mark - Public
-(void)waitForStatus:(XCTAsyncTestCaseStatus)expectedStatus timeout:(NSTimeInterval)timeout withBlock:(void(^)(void))block {
    self.notified = NO;
    self.expectedStatus = expectedStatus;
    if (block) {
        block();
        NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:timeout];
        [self waitUntilDate:loopUntil];
		
		// Only assert when notified. Do not assert when timed out
		// Fail if not notified
		if (self.notified) {
			XCTAssertEqual(self.notifiedStatus, self.expectedStatus, @"Returned status %u did not match expected status %u", self.notifiedStatus, self.expectedStatus);
		} else {
			XCTFail(@"Async test timed out.");
		}
    }
    else {
        XCTFail(@"No testing block to perform");
    }
}

- (void)waitForStatus:(XCTAsyncTestCaseStatus)status timeout:(NSTimeInterval)timeout
{
    self.notified = NO;
    self.expectedStatus = status;
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:timeout];
    [self waitUntilDate:loopUntil];

    // Only assert when notified. Do not assert when timed out
    // Fail if not notified
    if (self.notified) {
        XCTAssertEqual(self.notifiedStatus, self.expectedStatus, @"Notified status does not match the expected status.");
    } else {
        XCTFail(@"Async test timed out.");
    }
}

-(void)waitUntilDate:(NSDate *)date {
    NSDate *dt = [NSDate dateWithTimeIntervalSinceNow:0.1];
    while (!self.notified && [date timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:dt];
        dt = [NSDate dateWithTimeIntervalSinceNow:0.1];
    }
}

- (void)waitForTimeout:(NSTimeInterval)timeout
{
    self.notified = NO;
    self.expectedStatus = XCTAsyncTestCaseStatusUnknown;
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:timeout];
    [self waitUntilDate:loopUntil];
}

- (void)notify:(XCTAsyncTestCaseStatus)status
{
    self.notifiedStatus = status;
    // self.notified must be set at the last of this method
    self.notified = YES;
}

#pragma nark - Object Association Helpers -

- (void) setAssociatedObject:(id)anObject key:(void*)key
{
    objc_setAssociatedObject(self, key, anObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id) getAssociatedObject:(void*)key
{
    id anObject = objc_getAssociatedObject(self, key);
    return anObject;
}

#pragma mark - Property Implementations -
- (BOOL) notified
{
    NSNumber *valueNumber = [self getAssociatedObject:kNotified_Key];
    return [valueNumber boolValue];
}

- (void) setNotified:(BOOL)value
{
    NSNumber *valueNumber = [NSNumber numberWithBool:value];
    [self setAssociatedObject:valueNumber key:kNotified_Key];
}

- (XCTAsyncTestCaseStatus) notifiedStatus
{
    NSNumber *valueNumber = [self getAssociatedObject:kNotifiedStatus_Key];
    return [valueNumber integerValue];
}

- (void) setNotifiedStatus:(XCTAsyncTestCaseStatus)value
{
    NSNumber *valueNumber = [NSNumber numberWithUnsignedInteger:value];
    [self setAssociatedObject:valueNumber key:kNotifiedStatus_Key];
}

- (XCTAsyncTestCaseStatus) expectedStatus
{
    NSNumber *valueNumber = [self getAssociatedObject:kExpectedStatus_Key];
    return [valueNumber integerValue];
}

- (void) setExpectedStatus:(XCTAsyncTestCaseStatus)value
{
    NSNumber *valueNumber = [NSNumber numberWithUnsignedInteger:value];
    [self setAssociatedObject:valueNumber key:kExpectedStatus_Key];
}

@end
