//
//  MMViewController.h
//  MirrorMirror
//
//  Created by Cameron Ehrlich on 9/23/13.
//  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIView *previewView;
- (IBAction)switchCameraAction:(id)sender;
- (IBAction)scanAction:(id)sender;

@end
