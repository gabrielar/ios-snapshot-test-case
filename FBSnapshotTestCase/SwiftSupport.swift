/*
*  Copyright (c) 2015, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/


import Foundation

public protocol FBSnapshotCapableTestCase: class {
  
  var FBSnapshotRecordMode: Bool {set get}
  
  func FBSnapshotVerifyView(view: UIView, identifier: String, suffixes: NSOrderedSet, tolerance: CGFloat, file: StaticString, line: UInt)
  func FBSnapshotVerifyLayer(layer: CALayer, identifier: String, suffixes: NSOrderedSet, tolerance: CGFloat, file: StaticString, line: UInt)
  func FBSnapshotVerifyImage(image: UIImage, identifier: String, suffixes: NSOrderedSet, tolerance: CGFloat, file: StaticString, line: UInt)
  
  func fbAssert(assertion: Bool, message: String, file: StaticString, line: UInt)
  
}

public extension FBSnapshotCapableTestCase where Self: NSObject {
  
  public var FBSnapshotRecordMode: Bool {
    set { __FBSnapshotTestCase__TestClassSnapshotController(self).recordMode = newValue }
    get { return __FBSnapshotTestCase__TestClassSnapshotController(self).recordMode }
  }
  
  public func FBSnapshotVerifyView(view: UIView, identifier: String = "", suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(), tolerance: CGFloat = 0, file: StaticString = #file, line: UInt = #line) {
    FBSnapshotVerifyViewLayerOrImage(view, identifier: identifier, suffixes: suffixes, tolerance: tolerance, file: file, line: line)
  }

  public func FBSnapshotVerifyLayer(layer: CALayer, identifier: String = "", suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(), tolerance: CGFloat = 0, file: StaticString = #file, line: UInt = #line) {
    FBSnapshotVerifyViewLayerOrImage(layer, identifier: identifier, suffixes: suffixes, tolerance: tolerance, file: file, line: line)
  }

  public func FBSnapshotVerifyImage(image: UIImage, identifier: String = "", suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(), tolerance: CGFloat = 0, file: StaticString = #file, line: UInt = #line) {
    FBSnapshotVerifyViewLayerOrImage(image, identifier: identifier, suffixes: suffixes, tolerance: tolerance, file: file, line: line)
  }
  
  private func FBSnapshotVerifyViewLayerOrImage(viewOrLayer: AnyObject, identifier: String = "", suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(), tolerance: CGFloat = 0, file: StaticString = #file, line: UInt = #line) {
    
    let snapshotController = __FBSnapshotTestCase__TestClassSnapshotController(self)
    guard let envReferenceImageDirectory = __FBSnapshotTestCase__getReferenceImageDirectoryWithDefault(self, FB_REFERENCE_IMAGE_DIR) else {
      fbAssert(false, message: "Missing value for referenceImagesDirectory - Set FB_REFERENCE_IMAGE_DIR as Environment variable in your scheme.", file: file, line: line)
      return
    }
    
    var errors = [NSError]()
    var comparisonSuccess = false

    for suffix in suffixes {
      
      snapshotController.referenceImagesDirectory = "\(envReferenceImageDirectory)\(suffix)"
      
      switch viewOrLayer {
        
      case let view as UIView:
        do {
          try snapshotController.compareSnapshotOfView(view, selector:__FBSnapshotTestCase__InvocationWithTestClass(self).selector, identifier: identifier, tolerance: tolerance)
          comparisonSuccess = true
        } catch let error1 as NSError {
          errors.append(error1)
          comparisonSuccess = false
        }
        
      case let layer as CALayer:
        do {
          try snapshotController.compareSnapshotOfLayer(layer, selector:__FBSnapshotTestCase__InvocationWithTestClass(self).selector, identifier: identifier, tolerance: tolerance)
          comparisonSuccess = true
        } catch let error1 as NSError {
          errors.append(error1)
          comparisonSuccess = false
        }
        
      case let image as UIImage:
        do {
          try snapshotController.compareSnapshotOfImage(image, selector:__FBSnapshotTestCase__InvocationWithTestClass(self).selector, identifier: identifier, tolerance: tolerance)
          comparisonSuccess = true
        } catch let error1 as NSError {
          errors.append(error1)
          comparisonSuccess = false
        }
        
      default:
        assertionFailure("Only UIView, CALayer or UIImage classes can be snapshotted")
        
      }
      
      fbAssert(self.FBSnapshotRecordMode == false, message: "Test ran in record mode. Reference image is now saved. Disable record mode to perform an actual snapshot comparison!", file: file, line: line)
      
      if comparisonSuccess || self.FBSnapshotRecordMode {
        break
      }

      
    }
    
    let errorMessage = errors.first?.description ?? "unknown error"
    fbAssert(comparisonSuccess, message: "Snapshot comparison failed: \(errorMessage)", file: file, line: line)
    
  }

//  func fbAssert(assertion: Bool, message: String, file: StaticString, line: UInt) {
//    if !assertion {
//      XCTFail(message, file: file, line: line)
//    }
//  }
  
}

