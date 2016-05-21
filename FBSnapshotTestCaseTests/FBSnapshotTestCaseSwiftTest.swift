//
//  FBSnapshotTestCaseSwiftTest.swift
//  FBSnapshotTestCase
//
//  Created by Gabriel Radu on 21/05/2016.
//  Copyright © 2016 Facebook. All rights reserved.
//

import XCTest
@testable import GDRSSnapshotTestCase


protocol BundleReader {
  func readDataForTestBundleResource(resurceName: String, ofType: String) -> NSData
  func selfClass() -> AnyClass
}

extension BundleReader {
  func readDataForTestBundleResource(resurceName: String, ofType: String) -> NSData {
    let testBundle = NSBundle(forClass: selfClass())
    let dataPath = testBundle.pathForResource(resurceName, ofType: ofType)
    return NSData(contentsOfFile: dataPath!)!
  }
}



class FBSnapshotTestCaseSwiftTest: XCTestCase, FBSnapshotCapableTestCase, BundleReader {

  var testIsCheckingForFailure = false
  var testHasFailed = false
  var testFailureMessage: String?
  
  override func setUp() {
    super.setUp()
    testIsCheckingForFailure = false
    //FBSnapshotRecordMode = true
  }
  
  override func tearDown() {
    testIsCheckingForFailure = false
    super.tearDown()
  }

  func testVerifyView() {
    let testView = TestView(subViewColor: UIColor.redColor())
    FBSnapshotVerifyView(testView)
  }
  
  func testVerifyViewWithNonMatchingImage() {
    
    testIsCheckingForFailure = true
    
    var testView = TestView(subViewColor: UIColor.redColor())
    if (FBSnapshotRecordMode) {
      testView = TestView(subViewColor: UIColor.blueColor())
    }
    
    FBSnapshotVerifyView(testView)
    
    XCTAssert(testHasFailed)
    XCTAssertNotNil(testFailureMessage)
    if let tfm = testFailureMessage {
      XCTAssert(tfm.containsString("Snapshot comparison failed: Error Domain=FBSnapshotTestControllerErrorDomain Code=4"))
    }
    
  }
  
  func testVerifyLayer() {
    let testView = TestView(subViewColor: UIColor.redColor())
    FBSnapshotVerifyLayer(testView.layer)
  }
  
  func testVerifyLayerWithNonMatchingImage() {
    
    testIsCheckingForFailure = true
    
    var testView = TestView(subViewColor: UIColor.redColor())
    if (FBSnapshotRecordMode) {
      testView = TestView(subViewColor: UIColor.blueColor())
    }
    
    FBSnapshotVerifyLayer(testView.layer)
    
    XCTAssert(testHasFailed)
    XCTAssertNotNil(testFailureMessage)
    if let tfm = testFailureMessage {
      XCTAssert(tfm.containsString("Snapshot comparison failed: Error Domain=FBSnapshotTestControllerErrorDomain Code=4"))
    }

  }

  func testVerifyImage() {
    let squareWithText = UIImage(data: readDataForTestBundleResource("square_with_text", ofType: "png"))!
    FBSnapshotVerifyImage(squareWithText, identifier: "testVerifyImage")
  }
  
  func testVerifyImageWithNonMatchingImage() {
    
    testIsCheckingForFailure = true
    
    var image = UIImage(data: readDataForTestBundleResource("square_with_text", ofType: "png"))!
    if FBSnapshotRecordMode {
      image = UIImage(data: readDataForTestBundleResource("square_with_pixel", ofType: "png"))!
    }
    
    FBSnapshotVerifyImage(image)
    
    XCTAssert(testHasFailed)
    XCTAssertNotNil(testFailureMessage)
    if let tfm = testFailureMessage {
      XCTAssert(tfm.containsString("Snapshot comparison failed: Error Domain=FBSnapshotTestControllerErrorDomain Code=4"))
    }
    
  }
  
  
  func fbAssert(assertion: Bool, message: String, file: StaticString, line: UInt) {
    
    if !assertion {

      testHasFailed = true
      testFailureMessage = message
      
      if !testIsCheckingForFailure {
        XCTFail(message, file: file, line: line)
      }
      
    } else {
      testHasFailed = false
      testFailureMessage = nil
    }
    
  }

  func selfClass() -> AnyClass {
    return FBSnapshotTestCaseSwiftTest.self
  }

}
