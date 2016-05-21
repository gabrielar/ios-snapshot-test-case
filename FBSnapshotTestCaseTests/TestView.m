//
//  TestView.m
//  FBSnapshotTestCase
//
//  Created by Gabriel Radu on 21/05/2016.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "TestView.h"

@implementation TestView

- (instancetype)initWithSubViewColor:(UIColor *)subViewColor
{
  self = [super initWithFrame:CGRectMake(0, 0, 200, 80)];
  if (self) {
    
    UIView *testView = self;
    testView.backgroundColor = [UIColor whiteColor];
    
    UIView *subview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    subview.backgroundColor = subViewColor;
    [testView addSubview:subview];
    self.subview = subview;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 80)];
    label.text = @"Some Text";
    [testView addSubview:label];
    
    self.label = label;
    
  }
  return self;
}

@end
