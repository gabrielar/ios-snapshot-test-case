/*
 *  Copyright (c) 2015, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */


#import <UIKit/UIKit.h>


@class FBSnapshotTestController;

void __FBSnapshotTestCase__TestClassSetSnapshotController(id<NSObject> testClass, FBSnapshotTestController *snapshotController);
FBSnapshotTestController *__FBSnapshotTestCase__TestClassSnapshotController(id<NSObject> testClass);

NSInvocation *__FBSnapshotTestCase__InvocationWithTestClass(id<NSObject> testClass);
NSString *__FBSnapshotTestCase__getReferenceImageDirectoryWithDefault(id<NSObject> testClass, NSString *dir);




