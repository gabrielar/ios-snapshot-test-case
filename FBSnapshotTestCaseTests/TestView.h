//
//  TestView.h
//  FBSnapshotTestCase
//
//  Created by Gabriel Radu on 21/05/2016.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestView : UIView

@property (nonatomic) UIView *subview;
@property (nonatomic) UILabel *label;

- (instancetype)initWithSubViewColor:(UIColor *)subViewColor;


@end


