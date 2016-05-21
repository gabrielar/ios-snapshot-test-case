//
//  Created by Gabriel Radu on 1/5/2016.
//  Copyright (c) 2016. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//


#import "TestView.h"

#import <XCTest/XCTest.h>
#import <GDRSSnapshotTestCase/GDRSSnapshotTestCase.h>


#define TestableFBSnapshotVerifyViewLayerOrImage(what__, viewLayerOrImage__, identifier__) \
  TestableFBSnapshotVerifyViewLayerOrImageWithOptions(what__, viewLayerOrImage__, identifier__, FBSnapshotTestCaseDefaultSuffixes(), 0)


#define TestableFBSnapshotVerifyViewLayerOrImageWithOptions(what__, viewLayerOrImage__, identifier__, suffixes__, tolerance__) \
  \
  BOOL testSuccess__ = NO; \
  NSMutableArray *errors__ = [NSMutableArray array]; \
  \
  _FBSnapshotVerifyViewLayerOrImageWithOptions(what__, viewLayerOrImage__, identifier__, suffixes__, tolerance__) \


@interface FBSnapshotTestCaseTest : XCTestCase

@end

@implementation FBSnapshotTestCaseTest

- (void)setUp {
    [super setUp];
    //FBSnapshotRecordMode = YES;
}

- (void)tearDown {
    [super tearDown];
}

- (void)testVerifyView
{
  UIView *testView = [[TestView alloc] initWithSubViewColor:[UIColor redColor]];
  FBSnapshotVerifyView(testView, nil);
}

- (void)testVerifyViewWithNonMatchingImage
{
  UIView *testView = [[TestView alloc] initWithSubViewColor:[UIColor redColor]];
  if (FBSnapshotRecordMode) {
    testView = [[TestView alloc] initWithSubViewColor:[UIColor blueColor]];
  }
  
  TestableFBSnapshotVerifyViewLayerOrImage(View, testView, @"testVerifyImageWithWrongImage");
  
  XCTAssertFalse(testSuccess__);
  NSError *firstError = errors__.firstObject;
  XCTAssertNotNil(firstError);
  XCTAssertEqualObjects(firstError.domain, @"FBSnapshotTestControllerErrorDomain");
  XCTAssertEqual(firstError.code, 4);
}

- (void)testVerifyLayer
{
  UIView *testView = [[TestView alloc] initWithSubViewColor:[UIColor redColor]];
  FBSnapshotVerifyLayer(testView.layer, nil);
}

- (void)testVerifyLayerWithNonMatchingImage
{
  UIView *testView = [[TestView alloc] initWithSubViewColor:[UIColor redColor]];
  if (FBSnapshotRecordMode) {
    testView = [[TestView alloc] initWithSubViewColor:[UIColor blueColor]];
  }
  
  TestableFBSnapshotVerifyViewLayerOrImage(Layer, testView.layer, @"testVerifyImageWithWrongImage")
  
  XCTAssertFalse(testSuccess__);
  NSError *firstError = errors__.firstObject;
  XCTAssertNotNil(firstError);
  XCTAssertEqualObjects(firstError.domain, @"FBSnapshotTestControllerErrorDomain");
  XCTAssertEqual(firstError.code, 4);
}

- (void)testVerifyImage
{
    UIImage *sqareWithText = [self _bundledImageNamed:@"square_with_text" type:@"png"];
    FBSnapshotVerifyImage(sqareWithText, @"testVerifyImage")
}

- (void)testVerifyImageWithNonMatchingImage
{
  UIImage *image = [self _bundledImageNamed:@"square_with_text" type:@"png"];
  if (FBSnapshotRecordMode) {
    image = [self _bundledImageNamed:@"square_with_pixel" type:@"png"];
  }
  
  TestableFBSnapshotVerifyViewLayerOrImage(Image, image, @"testVerifyImageWithWrongImage")
  
  XCTAssertFalse(testSuccess__);
  NSError *firstError = errors__.firstObject;
  XCTAssertNotNil(firstError);
  XCTAssertEqualObjects(firstError.domain, @"FBSnapshotTestControllerErrorDomain");
  XCTAssertEqual(firstError.code, 4);
}


#pragma mark - Private helper methods

- (UIImage *)_bundledImageNamed:(NSString *)name type:(NSString *)type
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:name ofType:type];
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    return [[UIImage alloc] initWithData:data];
}

@end
