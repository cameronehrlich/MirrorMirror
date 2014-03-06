//
//  MMViewController.m
//  MirrorMirror
//
//  Created by Cameron Ehrlich on 9/23/13.
//  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
//

#import "MMViewController.h"
#import "MMResponseGenerator.h"


#define kFramesToDrop 1

@implementation MMViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.sessionManager = [[MMSessionManager alloc] initWithView:self.previewView];
    [self.sessionManager setDelegate:self];
    
    CALayer *rootLayer = [self.previewView layer];
    [rootLayer setMasksToBounds:NO];
    [self.sessionManager.previewLayer setFrame:[rootLayer bounds]];
    [rootLayer addSublayer:self.sessionManager.previewLayer];
    [self.sessionManager.session startRunning];
    
    [self.scanningLabel setHidden:YES];
    [self.messageField setHidden:YES];
    [self.messageField setBackgroundColor:[UIColor clearColor]];
    [self.messageField.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.messageField.layer setShadowOffset:CGSizeMake(2, 2)];
    [self.messageField.layer setShadowRadius:5];
    [self.messageField.layer setShadowOpacity:1];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)switchCameraAction:(id)sender
{
    [self.sessionManager switchCamera];
}

-(void)didStartDetectingFace
{
    NSLog(@"did start");
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.scanningLabel setHidden:NO];
        
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [self.scanningLabel setHidden:YES];
            
            if (self.sayNiceThings) {
                [self.messageField setText:[MMResponseGenerator getNiceThing]];
            }else{
                [self.messageField setText:[MMResponseGenerator getMeanThing]];
            }

            [self.messageField setHidden:NO];
        });
    });
}

-(void)didStopDetectingFace
{
    [self.scanningLabel setHidden:YES];
    [self.messageField setHidden:YES];
    [self setSayNiceThings:NO];
    
    NSLog(@"STAHP");
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.sayNiceThings = YES;
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.sayNiceThings = YES;
}

@end