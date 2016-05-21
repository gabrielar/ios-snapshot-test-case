//
//  GDRSSnapshotTestCase.h
//  FBSnapshotTestCase
//
//  Created by Gabriel Radu on 10/05/2016.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "FBSnapshotTestCasePlatform.h"
#import "FBSnapshotTestController.h"
#import "FBSnapshotTestCase.h"



/*
 There are three ways of setting reference image directories.

 1. Set the preprocessor macro FB_REFERENCE_IMAGE_DIR to a double quoted
    c-string with the path.
 2. Set an environment variable named FB_REFERENCE_IMAGE_DIR with the path. This
    takes precedence over the preprocessor macro to allow for run-time override.
 3. Keep everything unset, which will cause the reference images to be looked up
    inside the bundle holding the current test, in the
    Resources/ReferenceImages_* directories.
 */
#ifndef FB_REFERENCE_IMAGE_DIR
#define FB_REFERENCE_IMAGE_DIR ""
#endif


/**
 Similar to our much-loved XCTAssert() macros. Use this to perform your test. No need to write an explanation, though.
 @param view The view to snapshot
 @param identifier An optional identifier, used if there are multiple snapshot tests in a given -test method.
 @param suffixes An NSOrderedSet of strings for the different suffixes
 @param tolerance The percentage of pixels that can differ and still count as an 'identical' view
 */
#define FBSnapshotVerifyViewWithOptions(view__, identifier__, suffixes__, tolerance__) \
  FBSnapshotVerifyViewLayerOrImageWithOptions(View, view__, identifier__, suffixes__, tolerance__)

#define FBSnapshotVerifyView(view__, identifier__) \
  FBSnapshotVerifyViewWithOptions(view__, identifier__, FBSnapshotTestCaseDefaultSuffixes(), 0)


/**
 Similar to our much-loved XCTAssert() macros. Use this to perform your test. No need to write an explanation, though.
 @param layer The layer to snapshot
 @param identifier An optional identifier, used if there are multiple snapshot tests in a given -test method.
 @param suffixes An NSOrderedSet of strings for the different suffixes
 @param tolerance The percentage of pixels that can differ and still count as an 'identical' layer
 */
#define FBSnapshotVerifyLayerWithOptions(layer__, identifier__, suffixes__, tolerance__) \
  FBSnapshotVerifyViewLayerOrImageWithOptions(Layer, layer__, identifier__, suffixes__, tolerance__)

#define FBSnapshotVerifyLayer(layer__, identifier__) \
  FBSnapshotVerifyLayerWithOptions(layer__, identifier__, FBSnapshotTestCaseDefaultSuffixes(), 0)


/**
 Similar to our much-loved XCTAssert() macros. Use this to perform your test. No need to write an explanation, though.
 @param layer The layer to snapshot
 @param identifier An optional identifier, used if there are multiple snapshot tests in a given -test method.
 @param suffixes An NSOrderedSet of strings for the different suffixes
 @param tolerance The percentage of pixels that can differ and still count as an 'identical' layer
 */
#define FBSnapshotVerifyImageWithOptions(image__, identifier__, suffixes__, tolerance__) \
  FBSnapshotVerifyViewLayerOrImageWithOptions(Image, image__, identifier__, suffixes__, tolerance__)

#define FBSnapshotVerifyImage(image__, identifier__) \
  FBSnapshotVerifyImageWithOptions(image__, identifier__, FBSnapshotTestCaseDefaultSuffixes(), 0)


#define FBSnapshotVerifyViewLayerOrImageWithOptions(what__, viewLayerOrImage__, identifier__, suffixes__, tolerance__) \
{ \
  \
  BOOL testSuccess__ = NO; \
  NSMutableArray *errors__ = [NSMutableArray array]; \
  \
  _FBSnapshotVerifyViewLayerOrImageWithOptions(what__, viewLayerOrImage__, identifier__, suffixes__, tolerance__) \
  \
  XCTAssertTrue(testSuccess__, @"Snapshot comparison failed: %@", errors__.firstObject); \
  XCTAssertFalse(FBSnapshotRecordMode, @"Test ran in record mode. Reference image is now saved. Disable record mode to perform an actual snapshot comparison!"); \
}

#define _FBSnapshotVerifyViewLayerOrImageWithOptions(what__, viewLayerOrImage__, identifier__, suffixes__, tolerance__) \
{ \
  \
  NSString *referenceImageDirectory = __FBSnapshotTestCase__getReferenceImageDirectoryWithDefault(self, (@FB_REFERENCE_IMAGE_DIR)); \
  XCTAssertNotNil(referenceImageDirectory, @"Missing value for referenceImagesDirectory - Set FB_REFERENCE_IMAGE_DIR as Environment variable in your scheme.");\
  XCTAssertTrue((suffixes__.count > 0), @"Suffixes set cannot be empty %@", suffixes__); \
  \
  NSError *error__ = nil; \
  \
  for (NSString *suffix__ in suffixes__) { \
    FBSnapshotTestController *snapshotTestController = __FBSnapshotTestCase__TestClassSnapshotController(self); \
    snapshotTestController.referenceImagesDirectory = [NSString stringWithFormat:@"%@%@", referenceImageDirectory, suffix__]; \
    BOOL comparisonSuccess__ = [snapshotTestController compareSnapshotOf ## what__ :(viewLayerOrImage__) selector:__FBSnapshotTestCase__InvocationWithTestClass(self).selector identifier:(identifier__) tolerance:(tolerance__) error:&error__]; \
    if (comparisonSuccess__ || FBSnapshotRecordMode) { \
      testSuccess__ = YES; \
      break; \
    } else { \
      [errors__ addObject:error__]; \
    } \
  } \
}


#define FBSnapshotRecordMode \
  __FBSnapshotTestCase__TestClassSnapshotController(self).recordMode

#define FBSnapshotSetRecordMode(newValue) \
{ \
  __FBSnapshotTestCase__TestClassSnapshotController(self).recordMode = newValue; \
}

#define FBSnapshotDeviceAgnostic \
  __FBSnapshotTestCase__TestClassSnapshotController(self).deviceAgnostic \

#define FBSnapshotSetDeviceAgnostic(newValue) \
{ \
__FBSnapshotTestCase__TestClassSnapshotController(self).deviceAgnostic = newValue; \
}

#define FBSnapshotUsesDrawViewHierarchyInRect \
  __FBSnapshotTestCase__TestClassSnapshotController(self).usesDrawViewHierarchyInRect \

#define FBSnapshotSetUsesDrawViewHierarchyInRect(newValue) \
{ \
  __FBSnapshotTestCase__TestClassSnapshotController(self).usesDrawViewHierarchyInRect = newValue; \
}


