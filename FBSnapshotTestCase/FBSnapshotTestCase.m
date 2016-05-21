/*
 *  Copyright (c) 2015, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "FBSnapshotTestCase.h"
#import "FBSnapshotTestController.h"

#import <objc/runtime.h>



static char __FBSnapshotTestCase__snapshotControllerKey[] = "__FBSnapshotTestCase__snapshotController";

void __FBSnapshotTestCase__TestClassSetSnapshotController(id<NSObject> testClass, FBSnapshotTestController *snapshotController) {
  
  objc_setAssociatedObject(testClass,
                           __FBSnapshotTestCase__snapshotControllerKey,
                           snapshotController,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
}

FBSnapshotTestController *__FBSnapshotTestCase__TestClassSnapshotController(id<NSObject> testClass) {
  
  FBSnapshotTestController *sc = objc_getAssociatedObject(testClass, __FBSnapshotTestCase__snapshotControllerKey);
  
  // NOTE: This works if this code is used with XCTest. Another solution needs to be found if more test
  // frameworks are to be supported.
  
  NSInvocation *invocation = __FBSnapshotTestCase__InvocationWithTestClass(testClass);
  if (!sc || (sc.invocation != invocation)) {
    sc = [[FBSnapshotTestController alloc] initWithTestName:NSStringFromClass([testClass class]) invocation:invocation];
    __FBSnapshotTestCase__TestClassSetSnapshotController(testClass, sc);
  }
  
  return sc;
  
}





NSInvocation *__FBSnapshotTestCase__InvocationWithTestClass(id<NSObject> testClass) {
  
  // NOTE: This works if this code is used with XCTest. Another solution needs to be found if more test
  // frameworks are to be supported.
  
  NSInvocation *invocation = nil;
  if ([testClass respondsToSelector:@selector(invocation)]) {
    invocation = [testClass performSelector:@selector(invocation) withObject:nil];
  }
  
  return invocation;
}


NSString *__FBSnapshotTestCase__getReferenceImageDirectoryWithDefault(id<NSObject> testClass, NSString *dir)
{
  NSString *envReferenceImageDirectory = [NSProcessInfo processInfo].environment[@"FB_REFERENCE_IMAGE_DIR"];
  if (envReferenceImageDirectory) {
    return envReferenceImageDirectory;
  }
  if (dir && dir.length > 0) {
    return dir;
  }
  return [[NSBundle bundleForClass:testClass.class].resourcePath stringByAppendingPathComponent:@"ReferenceImages"];
}


