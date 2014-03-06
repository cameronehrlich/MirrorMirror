//
//  MMSessionManager.m
//  MirrorMirror
//
//  Created by Cameron Ehrlich on 9/27/13.
//  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
//

#import "MMSessionManager.h"

#define kStartingCameraPosition AVCaptureDevicePositionFront
#define kSessionPreset AVCaptureSessionPreset640x480
#define kDetectorAccuracy CIDetectorAccuracyLow

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define UIColorFromRGBWithAlpha(rgbValue,a) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:a]

@implementation MMSessionManager
{
    CAShapeLayer *faceLayer;
    CAShapeLayer *rightEyeLayer;
    CAShapeLayer *leftEyeLayer;
    CAShapeLayer *mouthLayer;
    
    UIColor *openColor;
    UIColor *closedColor;
}

-(instancetype) initWithView:(UIView *) previewView;
{
    self = [super init];
    if (self) {
        
        self.previewView = previewView;
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:@{CIDetectorAccuracy: kDetectorAccuracy}];
        
        openColor = UIColorFromRGBWithAlpha(0x00fff0, 0.5);
        closedColor = UIColorFromRGBWithAlpha(0x0066ff, 0.5);
        
        [self setupSession];
    }
    return self;
}

- (void) setupSession
{
	NSError *error = nil;
	
	self.session = [[AVCaptureSession alloc] init];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
	    [self.session setSessionPreset:kSessionPreset];
	} else {
	    [self.session setSessionPreset:AVCaptureSessionPresetPhoto];
	}
    
    // Select a video device, make an input
    AVCaptureDevice *device;
    
    AVCaptureDevicePosition desiredPosition = kStartingCameraPosition;
	
    // find the front facing camera
	for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if ([d position] == desiredPosition) {
			device = d;
            self.isUsingFrontFacingCamera = YES;
			break;
		}
	}
    // fall back to the default camera.
    if(!device)
    {
        self.isUsingFrontFacingCamera = NO;
        device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    // get the input device
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
	if(!error) {
        
        // add the input to the session
        if ( [self.session canAddInput:deviceInput] ){
            [self.session addInput:deviceInput];
        }else{
            //error out here
        }
        
        
        // Make a video data output
        self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        
        // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
        NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                           [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [self.videoDataOutput setVideoSettings:rgbOutputSettings];
        [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked
        
        // create a serial dispatch queue used for the sample buffer delegate
        // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
        // see the header doc for setSampleBufferDelegate:queue: for more information
        self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
        
        if ( [self.session canAddOutput:self.videoDataOutput] ){
            [self.session addOutput:self.videoDataOutput];
        }
        
        // get the output for doing face detection.
        [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
        
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        self.previewLayer.backgroundColor = [[UIColor whiteColor] CGColor];
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
    }
    
	if (error) {
        NSLog(@"Session Manager error: %@", error.localizedDescription);
	}
}

// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
	
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}


- (NSNumber *) exifOrientation: (UIDeviceOrientation) orientation
{
	int exifOrientation;
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants.
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
	};
	
	switch (orientation) {
		case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
			break;
		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
			if (self.isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			break;
		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
			if (self.isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			break;
		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
		default:
			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
			break;
	}
    return [NSNumber numberWithInt:exifOrientation];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	// get the image
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
	if (attachments) {
		CFRelease(attachments);
    }
    
    // make sure your device orientation is not locked.
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    
    
    
	NSDictionary *imageOptions = @{CIDetectorImageOrientation: [self exifOrientation:curDeviceOrientation],  CIDetectorEyeBlink : @YES, CIDetectorSmile: @YES, CIDetectorTracking: @YES};
    
    
	
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
	CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	CGRect cleanAperture = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
    
    
    NSArray *faceFeatures = [self.faceDetector featuresInImage:ciImage options:imageOptions];
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self drawFaces:faceFeatures forVideoBox:cleanAperture orientation:curDeviceOrientation];
    });
    
    
}

// called asynchronously as the capture output is capturing sample buffers, this method asks the face detector
// to detect features and for each draw the green border in a layer and set appropriate orientation
- (void)drawFaces:(NSArray *)features forVideoBox:(CGRect)clearAperture orientation:(UIDeviceOrientation)orientation
{
    
    if ( features.count == 0 ) {
        if (self.isDetectingFace) {
            [self.delegate didStopDetectingFace];
            self.isDetectingFace = NO;
        }

        [faceLayer removeFromSuperlayer];
        [rightEyeLayer removeFromSuperlayer];
        [leftEyeLayer removeFromSuperlayer];
        [mouthLayer removeFromSuperlayer];
        faceLayer = rightEyeLayer = leftEyeLayer = mouthLayer = nil;
        return;
    }else{
        if (!self.isDetectingFace) {
            [self.delegate didStartDetectingFace];
            [self setIsDetectingFace:YES];
        }

    }
    
	CGSize parentFrameSize = [self.previewView frame].size;
	NSString *gravity = [self.previewLayer videoGravity];
	CGRect previewBox = [MMSessionManager videoPreviewBoxForGravity:gravity frameSize:parentFrameSize apertureSize:clearAperture.size];
    
    CGFloat widthScaleBy = previewBox.size.width / clearAperture.size.height;
    CGFloat heightScaleBy = previewBox.size.height / clearAperture.size.width;
    
    if (!faceLayer || !rightEyeLayer || !leftEyeLayer || !mouthLayer) {
        
        // face
        faceLayer = [CAShapeLayer layer];
        [self.previewLayer addSublayer:faceLayer];
        
        //right
        rightEyeLayer = [CAShapeLayer layer];
        [self.previewLayer addSublayer:rightEyeLayer];
        
        //left
        leftEyeLayer = [CAShapeLayer layer];
        [self.previewLayer addSublayer:leftEyeLayer];
        
        //mouth
        mouthLayer = [CAShapeLayer layer];
        [self.previewLayer addSublayer:mouthLayer];
    }
	
	for ( CIFaceFeature *ff in features ) {
		// find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
        
        
        
        
        
        CGRect faceRect = [ff bounds];
        CGFloat temp = faceRect.size.width;
        
        if (false) {             //disabling round light gray curcle
            // face
            faceRect.size.width = faceRect.size.height;
            faceRect.size.height = temp;
            temp = faceRect.origin.x;
            faceRect.origin.x = faceRect.origin.y;
            faceRect.origin.y = temp;
            faceRect.size.width *= widthScaleBy;
            faceRect.size.height *= heightScaleBy;
            faceRect.origin.x *= widthScaleBy;
            faceRect.origin.y *= heightScaleBy;
            
            faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
            
            //face
            UIBezierPath *bPath = [UIBezierPath bezierPathWithOvalInRect:faceRect];
            [faceLayer setPath:[bPath CGPath]];
            [faceLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0))];
            [faceLayer setFillColor:[[UIColor colorWithRed:.2 green:.2 blue:.2 alpha:.2] CGColor]];
        }
        
        if ([ff hasRightEyePosition]) {
            // right eye
            CGPoint rightEyePoint = [ff rightEyePosition];
            temp = rightEyePoint.y;
            rightEyePoint.y = rightEyePoint.x;
            rightEyePoint.x = temp;
            
            rightEyePoint.x *= widthScaleBy;
            rightEyePoint.y *= heightScaleBy;
            
            rightEyePoint.x += previewBox.origin.x + previewBox.size.width  - (rightEyePoint.x * 2);
            rightEyePoint.y += previewBox.origin.y;
            
            UIBezierPath *rightEyePath = [UIBezierPath bezierPathWithArcCenter:rightEyePoint radius:15 startAngle:0 endAngle:DegreesToRadians(360) clockwise:YES];
            [rightEyeLayer setPath:rightEyePath.CGPath];
            [rightEyeLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0))];
            
            if ([ff rightEyeClosed]) {
                [rightEyeLayer setFillColor:closedColor.CGColor];
            }else {
                
                [rightEyeLayer setFillColor:openColor.CGColor];
            }
        }
        
        
        
        if ([ff hasLeftEyePosition]) {
            // left eye
            CGPoint leftEyePoint = [ff leftEyePosition];
            temp = leftEyePoint.y;
            leftEyePoint.y = leftEyePoint.x;
            leftEyePoint.x = temp;
            
            leftEyePoint.x *= widthScaleBy;
            leftEyePoint.y *= heightScaleBy;
            
            leftEyePoint.x += previewBox.origin.x + previewBox.size.width  - (leftEyePoint.x * 2);
            leftEyePoint.y += previewBox.origin.y;
            
            //left
            UIBezierPath *leftEyePath = [UIBezierPath bezierPathWithArcCenter:leftEyePoint radius:15 startAngle:0 endAngle:DegreesToRadians(360) clockwise:YES];
            [leftEyeLayer setPath:leftEyePath.CGPath];
            [leftEyeLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0))];
            
            if ([ff leftEyeClosed]) {
                [leftEyeLayer setFillColor:closedColor.CGColor];
            }else {
                
                [leftEyeLayer setFillColor:openColor.CGColor];
            }
        }
        
        
        if ([ff hasMouthPosition]) {
            // mouth
            CGPoint mouthPoint = [ff mouthPosition];
            temp = mouthPoint.y;
            mouthPoint.y = mouthPoint.x;
            mouthPoint.x = temp;
            
            mouthPoint.x *= widthScaleBy;
            mouthPoint.y *= heightScaleBy;
            
            mouthPoint.x += previewBox.origin.x + previewBox.size.width  - (mouthPoint.x * 2);
            mouthPoint.y += previewBox.origin.y;
            
            //mouth
            UIBezierPath *mouthPath = [UIBezierPath bezierPathWithArcCenter:mouthPoint radius:15 startAngle:0 endAngle:DegreesToRadians(360) clockwise:YES];
            [mouthLayer setPath:mouthPath.CGPath];
            [mouthLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0))];
            if ([ff hasSmile]) {
                [mouthLayer setFillColor:openColor.CGColor];
            }else {
                
                [mouthLayer setFillColor:closedColor.CGColor];
            }
        }
        
	}
	
}

-(void) switchCamera
{
    // Select a video device, make an input
    AVCaptureDevice *device;
    AVCaptureDevicePosition desiredPosition;
    
    if (!self.isUsingFrontFacingCamera) {
        desiredPosition = AVCaptureDevicePositionFront;
    }else{
        desiredPosition = AVCaptureDevicePositionBack;
    }
    self.isUsingFrontFacingCamera = !self.isUsingFrontFacingCamera;
	
    // find the front facing camera
	for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if ([d position] == desiredPosition) {
			device = d;
            break;
		}
	}
    
    NSError *error;
    
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if (error) {
        NSLog(@"Device input error: %@", error.localizedDescription);
    }
    
    // add the input to the session
    if ([self.session canAddInput:deviceInput]) {
        [self.session addInput:deviceInput];
    }else{
        [self.session removeInput:[self.session.inputs lastObject]];
        [self.session addInput:deviceInput];
    }
    
}

@end
