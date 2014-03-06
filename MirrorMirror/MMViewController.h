//
//  MMViewController.h
//  MirrorMirror
//
//  Created by Cameron Ehrlich on 9/23/13.
//  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMSessionManager.h"

@import AVFoundation;
@import CoreImage;
@import ImageIO;
@import AssetsLibrary;
@import QuartzCore;

@interface MMViewController : UIViewController<MMSessionManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *scanningLabel;
@property (nonatomic, strong) MMSessionManager *sessionManager;
@property (nonatomic, strong) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UITextView *messageField;
@property (nonatomic, assign) BOOL sayNiceThings;

- (IBAction)switchCameraAction:(id)sender;

@end
