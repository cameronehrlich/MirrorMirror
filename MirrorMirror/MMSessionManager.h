//
//  MMSessionManager.h
//  MirrorMirror
//
//  Created by Cameron Ehrlich on 9/27/13.
//  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
//

#import <Foundation/Foundation.h>

@import AVFoundation;
@import QuartzCore;

#define DegreesToRadians(degrees) degrees * M_PI / 180

@protocol MMSessionManagerDelegate

-(void)didStartDetectingFace;
-(void)didStopDetectingFace;

@end


@interface MMSessionManager : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, assign) id<MMSessionManagerDelegate>delegate;
@property (nonatomic, assign) BOOL isDetectingFace;

@property (nonatomic, weak)     UIView *previewView;
@property (nonatomic, strong)   AVCaptureSession *session;
@property (nonatomic, strong)   AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong)   AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic)           dispatch_queue_t videoDataOutputQueue;

@property (nonatomic, strong)   CIDetector *faceDetector;
@property (nonatomic, strong)   CIDetector *smileDetector;
@property (nonatomic, strong)   CIDetector *blinkDetector;

@property (nonatomic, assign)   BOOL isUsingFrontFacingCamera;

-(instancetype) initWithView:(UIView *) previewView;
-(void) switchCamera;

@end
