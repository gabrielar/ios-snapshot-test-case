/*
 *  Copyright (c) 2015, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "FBSnapshotTestController.h"
#import "FBSnapshotTestCasePlatform.h"
#import "UIImage+Compare.h"
#import "UIImage+Diff.h"
#import "UIImage+Snapshot.h"

#import <UIKit/UIKit.h>

NSString *const FBSnapshotTestControllerErrorDomain = @"FBSnapshotTestControllerErrorDomain";
NSString *const FBReferenceImageFilePathKey = @"FBReferenceImageFilePathKey";
NSString *const FBReferenceImageKey = @"FBReferenceImageKey";
NSString *const FBCapturedImageKey = @"FBCapturedImageKey";
NSString *const FBDiffedImageKey = @"FBDiffedImageKey";

typedef NS_ENUM(NSUInteger, FBTestSnapshotFileNameType) {
  FBTestSnapshotFileNameTypeReference,
  FBTestSnapshotFileNameTypeFailedReference,
  FBTestSnapshotFileNameTypeFailedTest,
  FBTestSnapshotFileNameTypeFailedTestDiff,
};


@interface FBSnapshotTestController()
@property (nonatomic) NSInvocation *invocation;
@end

@implementation FBSnapshotTestController
{
  NSString *_testName;
  NSFileManager *_fileManager;
}

#pragma mark - Initializers

- (instancetype)initWithTestClass:(Class)testClass invocation:(NSInvocation *)invocation;
{
  return [self initWithTestName:NSStringFromClass(testClass) invocation:invocation];
}

- (instancetype)initWithTestName:(NSString *)testName invocation:(NSInvocation *)invocation
{
  if (self = [super init]) {
    _testName = [testName copy];
    self.invocation = invocation;
    _deviceAgnostic = NO;
    
    _fileManager = [[NSFileManager alloc] init];
  }
  return self;
}

#pragma mark - Overrides

- (NSString *)description
{
  return [NSString stringWithFormat:@"%@ %@", [super description], _referenceImagesDirectory];
}

#pragma mark - Public API

- (BOOL)compareSnapshotOfLayer:(CALayer *)layer
                      selector:(SEL)selector
                    identifier:(NSString *)identifier
                     tolerance:(CGFloat)tolerance
                         error:(NSError **)errorPtr
{
  return [self compareSnapshotOfViewLayerOrImage:layer
                                        selector:selector
                                      identifier:identifier
                                       tolerance:tolerance
                                           error:errorPtr];
}

- (BOOL)compareSnapshotOfView:(UIView *)view
                     selector:(SEL)selector
                   identifier:(NSString *)identifier
                    tolerance:(CGFloat)tolerance
                        error:(NSError **)errorPtr
{
  return [self compareSnapshotOfViewLayerOrImage:view
                                        selector:selector
                                      identifier:identifier
                                       tolerance:tolerance
                                           error:errorPtr];
}

- (BOOL)compareSnapshotOfImage:(UIImage *)image
                      selector:(SEL)selector
                    identifier:(NSString *)identifier
                     tolerance:(CGFloat)tolerance
                         error:(NSError **)errorPtr
{
  return [self compareSnapshotOfViewLayerOrImage:image
                                        selector:selector
                                      identifier:identifier
                                       tolerance:tolerance
                                           error:errorPtr];
}

- (BOOL)compareSnapshotOfViewLayerOrImage:(id)viewLayerOrImage
                                 selector:(SEL)selector
                               identifier:(NSString *)identifier
                                tolerance:(CGFloat)tolerance
                                    error:(NSError **)errorPtr
{
  if (self.recordMode) {
    return [self _recordSnapshotOfViewLayerOrImage:viewLayerOrImage selector:selector identifier:identifier error:errorPtr];
  } else {
    return [self _performPixelComparisonWithViewLayerOrImage:viewLayerOrImage selector:selector identifier:identifier tolerance:tolerance error:errorPtr];
  }
}

- (CGFloat)scaleOfViewLayerOrImage:(id)viewLayerOrImage
{
  if ([viewLayerOrImage isKindOfClass:[UIImage class]]) {
    return ((UIImage* )viewLayerOrImage).scale;
  }
  return [UIScreen mainScreen].scale;
}

- (UIImage *)referenceImageForSelector:(SEL)selector
                            identifier:(NSString *)identifier
                                 error:(NSError **)errorPtr
{
  return [self referenceImageForSelector:selector
                              identifier:identifier
                                   scale:[UIScreen mainScreen].scale
                                   error:errorPtr];
}

- (UIImage *)referenceImageForSelector:(SEL)selector
                            identifier:(NSString *)identifier
                                 scale:(CGFloat)scale
                                 error:(NSError **)errorPtr
{
  NSString *filePath = [self _referenceFilePathForSelector:selector identifier:identifier scale:scale];
  UIImage *image = [UIImage imageWithContentsOfFile:filePath];
  if (nil == image && NULL != errorPtr) {
    BOOL exists = [_fileManager fileExistsAtPath:filePath];
    if (!exists) {
      *errorPtr = [NSError errorWithDomain:FBSnapshotTestControllerErrorDomain
                                      code:FBSnapshotTestControllerErrorCodeNeedsRecord
                                  userInfo:@{
               FBReferenceImageFilePathKey: filePath,
                 NSLocalizedDescriptionKey: @"Unable to load reference image.",
          NSLocalizedFailureReasonErrorKey: @"Reference image not found. You need to run the test in record mode",
                   }];
    } else {
      *errorPtr = [NSError errorWithDomain:FBSnapshotTestControllerErrorDomain
                                      code:FBSnapshotTestControllerErrorCodeUnknown
                                  userInfo:nil];
    }
  }
  return image;
}

- (BOOL)compareReferenceImage:(UIImage *)referenceImage
                      toImage:(UIImage *)image
                    tolerance:(CGFloat)tolerance
                        error:(NSError **)errorPtr
{
  BOOL sameImageDimensions = CGSizeEqualToSize(referenceImage.size, image.size);
  if (sameImageDimensions && [referenceImage fb_compareWithImage:image tolerance:tolerance]) {
    return YES;
  }
  
  if (NULL != errorPtr) {
    NSString *errorDescription = sameImageDimensions ? @"Images different" : @"Images different sizes";
    NSString *errorReason = sameImageDimensions ? [NSString stringWithFormat:@"image pixels differed by more than %.2f%% from the reference image", tolerance * 100]
                                                : [NSString stringWithFormat:@"referenceImage:%@, image:%@", NSStringFromCGSize(referenceImage.size), NSStringFromCGSize(image.size)];
    FBSnapshotTestControllerErrorCode errorCode = sameImageDimensions ? FBSnapshotTestControllerErrorCodeImagesDifferent : FBSnapshotTestControllerErrorCodeImagesDifferentSizes;
    
    *errorPtr = [NSError errorWithDomain:FBSnapshotTestControllerErrorDomain
                                    code:errorCode
                                userInfo:@{
                                           NSLocalizedDescriptionKey: errorDescription,
                                           NSLocalizedFailureReasonErrorKey: errorReason,
                                           FBReferenceImageKey: referenceImage,
                                           FBCapturedImageKey: image,
                                           FBDiffedImageKey: [referenceImage fb_diffWithImage:image],
                                           }];
  }
  return NO;
}

- (BOOL)saveFailedReferenceImage:(UIImage *)referenceImage
                       testImage:(UIImage *)testImage
                        selector:(SEL)selector
                      identifier:(NSString *)identifier
                           error:(NSError **)errorPtr
{
  NSData *referencePNGData = UIImagePNGRepresentation(referenceImage);
  NSData *testPNGData = UIImagePNGRepresentation(testImage);

  NSString *referencePath = [self _failedFilePathForSelector:selector
                                                  identifier:identifier
                                                       scale:referenceImage.scale
                                                fileNameType:FBTestSnapshotFileNameTypeFailedReference];

  NSError *creationError = nil;
  BOOL didCreateDir = [_fileManager createDirectoryAtPath:[referencePath stringByDeletingLastPathComponent]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&creationError];
  if (!didCreateDir) {
    if (NULL != errorPtr) {
      *errorPtr = creationError;
    }
    return NO;
  }

  if (![referencePNGData writeToFile:referencePath options:NSDataWritingAtomic error:errorPtr]) {
    return NO;
  }

  NSString *testPath = [self _failedFilePathForSelector:selector
                                             identifier:identifier
                                                  scale:testImage.scale
                                           fileNameType:FBTestSnapshotFileNameTypeFailedTest];

  if (![testPNGData writeToFile:testPath options:NSDataWritingAtomic error:errorPtr]) {
    return NO;
  }

  UIImage *diffImage = [referenceImage fb_diffWithImage:testImage];
  NSData *diffImageData = UIImagePNGRepresentation(diffImage);
  
  NSString *diffPath = [self _failedFilePathForSelector:selector
                                             identifier:identifier
                                                  scale:diffImage.scale
                                           fileNameType:FBTestSnapshotFileNameTypeFailedTestDiff];

  if (![diffImageData writeToFile:diffPath options:NSDataWritingAtomic error:errorPtr]) {
    return NO;
  }

  NSLog(@"If you have Kaleidoscope installed you can run this command to see an image diff:\n"
        @"ksdiff \"%@\" \"%@\"", referencePath, testPath);

  return YES;
}

#pragma mark - Private API

- (NSString *)_fileNameForSelector:(SEL)selector
                        identifier:(NSString *)identifier
                             scale:(CGFloat)scale
                      fileNameType:(FBTestSnapshotFileNameType)fileNameType
{
  NSString *fileName = nil;
  switch (fileNameType) {
    case FBTestSnapshotFileNameTypeFailedReference:
      fileName = @"reference_";
      break;
    case FBTestSnapshotFileNameTypeFailedTest:
      fileName = @"failed_";
      break;
    case FBTestSnapshotFileNameTypeFailedTestDiff:
      fileName = @"diff_";
      break;
    default:
      fileName = @"";
      break;
  }
  fileName = [fileName stringByAppendingString:NSStringFromSelector(selector)];
  if (0 < identifier.length) {
    fileName = [fileName stringByAppendingFormat:@"_%@", identifier];
  }
  
  if (self.isDeviceAgnostic) {
    fileName = FBDeviceAgnosticNormalizedFileName(fileName);
  }
  
  if (scale < 0.2) {
    scale = [[UIScreen mainScreen] scale];
  }
  if (scale > 1) {
    fileName = [fileName stringByAppendingFormat:@"@%.fx", scale];
  }
  fileName = [fileName stringByAppendingPathExtension:@"png"];
  return fileName;
}

- (NSString *)_referenceFilePathForSelector:(SEL)selector
                                 identifier:(NSString *)identifier
                                      scale:(CGFloat)scale
{
  NSString *fileName = [self _fileNameForSelector:selector
                                       identifier:identifier
                                            scale:scale
                                     fileNameType:FBTestSnapshotFileNameTypeReference];
  NSString *filePath = [_referenceImagesDirectory stringByAppendingPathComponent:_testName];
  filePath = [filePath stringByAppendingPathComponent:fileName];
  return filePath;
}

- (NSString *)_failedFilePathForSelector:(SEL)selector
                              identifier:(NSString *)identifier
                                   scale:(CGFloat)scale
                            fileNameType:(FBTestSnapshotFileNameType)fileNameType
{
  NSString *fileName = [self _fileNameForSelector:selector
                                       identifier:identifier
                                            scale:scale
                                     fileNameType:fileNameType];
  NSString *folderPath = NSTemporaryDirectory();
  if (getenv("IMAGE_DIFF_DIR")) {
    folderPath = @(getenv("IMAGE_DIFF_DIR"));
  }
  NSString *filePath = [folderPath stringByAppendingPathComponent:_testName];
  filePath = [filePath stringByAppendingPathComponent:fileName];
  return filePath;
}

- (BOOL)_performPixelComparisonWithViewLayerOrImage:(id)viewLayerOrImage
                                           selector:(SEL)selector
                                         identifier:(NSString *)identifier
                                          tolerance:(CGFloat)tolerance
                                              error:(NSError **)errorPtr
{
  UIImage *referenceImage = [self referenceImageForSelector:selector
                                                 identifier:identifier
                                                      scale:[self scaleOfViewLayerOrImage:viewLayerOrImage]
                                                      error:errorPtr];
  if (nil != referenceImage) {
    UIImage *snapshot = [self _imageForViewLayerOrImage:viewLayerOrImage];
    BOOL imagesSame = [self compareReferenceImage:referenceImage toImage:snapshot tolerance:tolerance error:errorPtr];
    if (!imagesSame) {
      NSError *saveError = nil;
      if ([self saveFailedReferenceImage:referenceImage testImage:snapshot selector:selector identifier:identifier error:&saveError] == NO) {
        NSLog(@"Error saving test images: %@", saveError);
      }
    }
    return imagesSame;
  }
  return NO;
}

- (BOOL)_recordSnapshotOfViewLayerOrImage:(id)viewLayerOrImage
                                 selector:(SEL)selector
                               identifier:(NSString *)identifier
                                    error:(NSError **)errorPtr
{
  UIImage *snapshot = [self _imageForViewLayerOrImage:viewLayerOrImage];
  return [self _saveReferenceImage:snapshot selector:selector identifier:identifier error:errorPtr];
}

- (BOOL)_saveReferenceImage:(UIImage *)image
                   selector:(SEL)selector
                 identifier:(NSString *)identifier
                      error:(NSError **)errorPtr
{
  BOOL didWrite = NO;
  if (nil != image) {
    NSString *filePath = [self _referenceFilePathForSelector:selector identifier:identifier scale:image.scale];
    NSData *pngData = UIImagePNGRepresentation(image);
    if (nil != pngData) {
      NSError *creationError = nil;
      BOOL didCreateDir = [_fileManager createDirectoryAtPath:[filePath stringByDeletingLastPathComponent]
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&creationError];
      if (!didCreateDir) {
        if (NULL != errorPtr) {
          *errorPtr = creationError;
        }
        return NO;
      }
      didWrite = [pngData writeToFile:filePath options:NSDataWritingAtomic error:errorPtr];
      if (didWrite) {
        NSLog(@"Reference image save at: %@", filePath);
      }
    } else {
      if (nil != errorPtr) {
        *errorPtr = [NSError errorWithDomain:FBSnapshotTestControllerErrorDomain
                                        code:FBSnapshotTestControllerErrorCodePNGCreationFailed
                                    userInfo:@{
                                               FBReferenceImageFilePathKey: filePath,
                                               }];
      }
    }
  }
  return didWrite;
}

- (UIImage *)_imageForViewLayerOrImage:(id)viewLayerOrImage
{
  if ([viewLayerOrImage isKindOfClass:[UIView class]]) {
    if (_usesDrawViewHierarchyInRect) {
      return [UIImage fb_imageForView:viewLayerOrImage];
    } else {
      return [UIImage fb_imageForViewLayer:viewLayerOrImage];
    }
  } else if ([viewLayerOrImage isKindOfClass:[CALayer class]]) {
    return [UIImage fb_imageForLayer:viewLayerOrImage];
  } else if ([viewLayerOrImage isKindOfClass:[UIImage class]]) {
    return viewLayerOrImage;
  } else {
    [NSException raise:@"Only UIView and CALayer classes can be snapshotted" format:@"%@", viewLayerOrImage];
  }
  return nil;
}

@end
