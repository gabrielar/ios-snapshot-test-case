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


@implementation XCTestCase (FBSnapshotTestCase)

@dynamic __FBSnapshotTestCase__snapshotController;


static char __FBSnapshotTestCase__snapshotControllerKey[] = "__FBSnapshotTestCase__snapshotController";

- (void)__FBSnapshotTestCase__setSnapshotController:(FBSnapshotTestController *)snapshotController
{
  objc_setAssociatedObject(self,
                           __FBSnapshotTestCase__snapshotControllerKey,
                           snapshotController,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FBSnapshotTestController *)__FBSnapshotTestCase__snapshotController
{
  
  FBSnapshotTestController *sc = objc_getAssociatedObject(self, __FBSnapshotTestCase__snapshotControllerKey);
  if (!sc || (sc.invocation != self.invocation)) {
    sc = [[FBSnapshotTestController alloc] initWithTestName:NSStringFromClass([self class])
                                                 invocation:self.invocation];
    [self __FBSnapshotTestCase__setSnapshotController: sc];
  }
  
  return sc;
  
}


#pragma mark - Public API

- (BOOL)__FBSnapshotTestCase__compareSnapshotOfLayer:(CALayer *)layer
                            referenceImagesDirectory:(NSString *)referenceImagesDirectory
                                          identifier:(NSString *)identifier
                                           tolerance:(CGFloat)tolerance
                                               error:(NSError **)errorPtr
{
  return [self __FBSnapshotTestCase__compareSnapshotOfViewLayerOrImage:layer
                                              referenceImagesDirectory:referenceImagesDirectory
                                                            identifier:identifier
                                                             tolerance:tolerance
                                                                 error:errorPtr];
}

- (BOOL)__FBSnapshotTestCase__compareSnapshotOfView:(UIView *)view
                           referenceImagesDirectory:(NSString *)referenceImagesDirectory
                                         identifier:(NSString *)identifier
                                          tolerance:(CGFloat)tolerance
                                              error:(NSError **)errorPtr
{
  return [self __FBSnapshotTestCase__compareSnapshotOfViewLayerOrImage:view
                                              referenceImagesDirectory:referenceImagesDirectory
                                                            identifier:identifier
                                                             tolerance:tolerance
                                                                 error:errorPtr];
}

- (BOOL)__FBSnapshotTestCase__compareSnapshotOfImage:(UIImage *)image
                            referenceImagesDirectory:(NSString *)referenceImagesDirectory
                                          identifier:(NSString *)identifier
                                           tolerance:(CGFloat)tolerance
                                               error:(NSError **)errorPtr
{
  return [self __FBSnapshotTestCase__compareSnapshotOfViewLayerOrImage:image
                                              referenceImagesDirectory:referenceImagesDirectory
                                                            identifier:identifier
                                                             tolerance:tolerance
                                                                 error:errorPtr];
}

- (BOOL)__FBSnapshotTestCase__referenceImageRecordedInDirectory:(NSString *)referenceImagesDirectory
                                                     identifier:(NSString *)identifier
                                                          scale:(CGFloat)scale
                                                          error:(NSError **)errorPtr
{
  NSAssert1(self.__FBSnapshotTestCase__snapshotController, @"%s cannot be called before [super setUp]", __FUNCTION__);
  self.__FBSnapshotTestCase__snapshotController.referenceImagesDirectory = referenceImagesDirectory;
  UIImage *referenceImage = [self.__FBSnapshotTestCase__snapshotController referenceImageForSelector:self.invocation.selector
                                                                                          identifier:identifier
                                                                                               scale:scale
                                                                                               error:errorPtr];
  
  return (referenceImage != nil);
}

- (CGFloat)__FBSnapshotTestCase__scaleOfViewLayerOrImage:(id)viewLayerOrImage
{
  return [self.__FBSnapshotTestCase__snapshotController scaleOfViewLayerOrImage:viewLayerOrImage];
}

- (NSString *)getReferenceImageDirectoryWithDefault:(NSString *)dir
{
  NSString *envReferenceImageDirectory = [NSProcessInfo processInfo].environment[@"FB_REFERENCE_IMAGE_DIR"];
  if (envReferenceImageDirectory) {
    return envReferenceImageDirectory;
  }
  if (dir && dir.length > 0) {
    return dir;
  }
  return [[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"ReferenceImages"];
}


#pragma mark - Private API

- (BOOL)__FBSnapshotTestCase__compareSnapshotOfViewLayerOrImage:(id)viewLayerOrImage
                                       referenceImagesDirectory:(NSString *)referenceImagesDirectory
                                                     identifier:(NSString *)identifier
                                                      tolerance:(CGFloat)tolerance
                                                          error:(NSError **)errorPtr
{
  self.__FBSnapshotTestCase__snapshotController.referenceImagesDirectory = referenceImagesDirectory;
  return [self.__FBSnapshotTestCase__snapshotController compareSnapshotOfViewLayerOrImage:viewLayerOrImage
                                                                                 selector:self.invocation.selector
                                                                               identifier:identifier
                                                                                tolerance:tolerance
                                                                                    error:errorPtr];
}


@end


@implementation FBSnapshotTestCase

#pragma mark - Overrides

- (BOOL)recordMode
{
  return self.__FBSnapshotTestCase__snapshotController.recordMode;
}

- (void)setRecordMode:(BOOL)recordMode
{
  NSAssert1(self.__FBSnapshotTestCase__snapshotController, @"%s cannot be called before [super setUp]", __FUNCTION__);
  self.__FBSnapshotTestCase__snapshotController.recordMode = recordMode;
}

- (BOOL)isDeviceAgnostic
{
  return self.__FBSnapshotTestCase__snapshotController.deviceAgnostic;
}

- (void)setDeviceAgnostic:(BOOL)deviceAgnostic
{
  NSAssert1(self.__FBSnapshotTestCase__snapshotController, @"%s cannot be called before [super setUp]", __FUNCTION__);
  self.__FBSnapshotTestCase__snapshotController.deviceAgnostic = deviceAgnostic;
}

- (BOOL)usesDrawViewHierarchyInRect
{
  return self.__FBSnapshotTestCase__snapshotController.usesDrawViewHierarchyInRect;
}

- (void)setUsesDrawViewHierarchyInRect:(BOOL)usesDrawViewHierarchyInRect
{
  NSAssert1(self.__FBSnapshotTestCase__snapshotController, @"%s cannot be called before [super setUp]", __FUNCTION__);
  self.__FBSnapshotTestCase__snapshotController.usesDrawViewHierarchyInRect = usesDrawViewHierarchyInRect;
}

@end
