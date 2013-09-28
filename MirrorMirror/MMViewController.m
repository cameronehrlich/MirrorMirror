//
//  MMViewController.m
//  MirrorMirror
//
//  Created by Cameron Ehrlich on 9/23/13.
//  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
//

#import "MMViewController.h"
#import "MMSessionManager.h"

@import AVFoundation;
@import CoreImage;
@import ImageIO;
@import AssetsLibrary;

#define kFramesToDrop 1

@implementation MMViewController{
    
    MMSessionManager *sessionManager;

}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    sessionManager = [[MMSessionManager alloc] initWithView:self.previewView];
    
    CALayer *rootLayer = [self.previewView layer];
    [rootLayer setMasksToBounds:YES];
    [sessionManager.previewLayer setFrame:[rootLayer bounds]];
    [rootLayer addSublayer:sessionManager.previewLayer];
    [sessionManager.session startRunning];

    

}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)switchCameraAction:(id)sender
{
    [sessionManager switchCamera];
}

- (IBAction)scanAction:(id)sender {
    NSLog(@"scan");
}
@end