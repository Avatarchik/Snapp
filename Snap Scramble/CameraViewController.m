//
//  CameraViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 7/23/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import "CameraViewController.h"
#import "PreviewPuzzleViewController.h"
#import "ViewUtils.h"
#import "LLSimpleCamera.h"
#import "DKEditorView.h"


@interface CameraViewController ()
// camera outlets
@property (strong, nonatomic) LLSimpleCamera *camera;
@property (strong, nonatomic) UILabel *errorLabel;
@property (strong, nonatomic) UIButton *snapButton;
@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UISegmentedControl *segmentedControl;
@property (nonatomic) IBOutlet UIButton *cameraBackButton;


//editor outlets
@property (nonatomic) UIViewController *editorViewController;
@property (nonatomic) IBOutlet DKEditorView *editorView;
@property (nonatomic) IBOutlet UIButton *checkButton;
@property (nonatomic) IBOutlet UIButton *backButton;
@property (nonatomic) IBOutlet UIButton *crayonButton;
@property (nonatomic) IBOutlet UIButton *textButton;
@property (nonatomic) IBOutlet DKVerticalColorPicker *verticalImagePicker;

// editor actions
-(IBAction)confirm:(id)sender;
-(IBAction)backButtonDidPress:(id)sender;
@end

@implementation CameraViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    // ----- initialize camera -------- //
    
    // create camera vc
    self.camera = [[LLSimpleCamera alloc] initWithQuality:AVCaptureSessionPresetHigh
                                                 position:LLCameraPositionRear
                                             videoEnabled:NO];
    
    // attach to a view controller
    [self.camera attachToViewController:self withFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
    
    // read: http://stackoverflow.com/questions/5427656/ios-uiimagepickercontroller-result-image-orientation-after-upload
    // you probably will want to set this to YES, if you are going view the image outside iOS.
    self.camera.fixOrientationAfterCapture = NO;
    
    // take the required actions on a device change
    __weak typeof(self) weakSelf = self;
    [self.camera setOnDeviceChange:^(LLSimpleCamera *camera, AVCaptureDevice * device) {
        
        NSLog(@"Device changed.");
        
        // device changed, check if flash is available
        if([camera isFlashAvailable]) {
            weakSelf.flashButton.hidden = NO;
            
            if(camera.flash == LLCameraFlashOff) {
                weakSelf.flashButton.selected = NO;
            }
            else {
                weakSelf.flashButton.selected = YES;
            }
        }
        else {
            weakSelf.flashButton.hidden = YES;
        }
    }];
    
    [self.camera setOnError:^(LLSimpleCamera *camera, NSError *error) {
        NSLog(@"Camera error: %@", error);
        
        if([error.domain isEqualToString:LLSimpleCameraErrorDomain]) {
            if(error.code == LLSimpleCameraErrorCodeCameraPermission ||
               error.code == LLSimpleCameraErrorCodeMicrophonePermission) {
                
                if(weakSelf.errorLabel) {
                    [weakSelf.errorLabel removeFromSuperview];
                }
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
                label.text = @"We need permission for the camera.\nPlease go to your settings.";
                label.numberOfLines = 2;
                label.lineBreakMode = NSLineBreakByWordWrapping;
                label.backgroundColor = [UIColor clearColor];
                label.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:13.0f];
                label.textColor = [UIColor whiteColor];
                label.textAlignment = NSTextAlignmentCenter;
                [label sizeToFit];
                label.center = CGPointMake(screenRect.size.width / 2.0f, screenRect.size.height / 2.0f);
                weakSelf.errorLabel = label;
                [weakSelf.view addSubview:weakSelf.errorLabel];
            }
        }
    }];
    
    // ----- camera buttons -------- //
    
    // snap button to capture image
    self.snapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.snapButton.frame = CGRectMake(0, 0, 70.0f, 70.0f);
    self.snapButton.clipsToBounds = YES;
    self.snapButton.layer.cornerRadius = self.snapButton.frame.size.width / 2.0f;
    self.snapButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.snapButton.layer.borderWidth = 2.0f;
    self.snapButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.snapButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.snapButton.layer.shouldRasterize = YES;
    [self.snapButton addTarget:self action:@selector(snapButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.snapButton];
    
    // button to go back in camera view
    self.cameraBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cameraBackButton.frame = CGRectMake(0, 0, 18, 42);
    [self.cameraBackButton setImage:[UIImage imageNamed:@"icon-back.png"] forState:UIControlStateNormal];
    [self.cameraBackButton addTarget:self action:@selector(cameraBackButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cameraBackButton];
    
    // button to toggle flash
    self.flashButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.flashButton.frame = CGRectMake(0, 0, 16.0f + 20.0f, 24.0f + 20.0f);
    self.flashButton.tintColor = [UIColor whiteColor];
    [self.flashButton setImage:[UIImage imageNamed:@"camera-flash.png"] forState:UIControlStateNormal];
    self.flashButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    [self.flashButton addTarget:self action:@selector(flashButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.flashButton];
    
    if([LLSimpleCamera isFrontCameraAvailable] && [LLSimpleCamera isRearCameraAvailable]) {
        // button to toggle camera positions
        self.switchButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.switchButton.frame = CGRectMake(0, 0, 29.0f + 20.0f, 22.0f + 20.0f);
        self.switchButton.tintColor = [UIColor whiteColor];
        [self.switchButton setImage:[UIImage imageNamed:@"camera-switch.png"] forState:UIControlStateNormal];
        self.switchButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
        [self.switchButton addTarget:self action:@selector(switchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.switchButton];
    }
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)control
{
    NSLog(@"Segment value changed!");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // start the camera
    [self.camera start];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // enable swipe back functionality
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

/* other lifecycle methods */

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.camera.view.frame = self.view.contentBounds;
    
    self.snapButton.center = self.view.contentCenter;
    self.snapButton.bottom = self.view.height - 15.0f;
    
    self.flashButton.center = self.view.contentCenter;
    self.flashButton.top = 5.0f;
    
    self.switchButton.top = 5.0f;
    self.switchButton.right = self.view.width - 5.0f;
    
    self.cameraBackButton.top = 5.0f;
    self.cameraBackButton.left = 15.0f;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

-(UIImage*)prepareImageForGame:(UIImage*)image {
    if (image.size.height > image.size.width) { // portrait
        image = [self imageWithImage:image scaledToFillSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height)];
    }
    
    else if (image.size.width == image.size.height) { // square
        image = [self resizeImage:image withMaxDimension:self.view.frame.size.width - 20];
    }
    
    NSLog(@"image after resizing: %@", image);
    return image;
}


- (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)size
{
    CGFloat scale = MAX(size.width/image.size.width, size.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)resizeImage:(UIImage *)image withMaxDimension:(CGFloat)maxDimension {
    if (fmax(image.size.width, image.size.height) <= maxDimension) {
        return image;
    }
    
    CGFloat aspect = image.size.width / image.size.height;
    CGSize newSize;
    
    if (image.size.width > image.size.height) {
        newSize = CGSizeMake(maxDimension, maxDimension / aspect);
    } else {
        newSize = CGSizeMake(maxDimension * aspect, maxDimension);
    }
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    CGRect newImageRect = CGRectMake(0.0, 0.0, newSize.width, newSize.height);
    [image drawInRect:newImageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}


/* camera button methods */

- (void)switchButtonPressed:(UIButton *)button
{
    [self.camera togglePosition];
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)flashButtonPressed:(UIButton *)button
{
    if(self.camera.flash == LLCameraFlashOff) {
        BOOL done = [self.camera updateFlashMode:LLCameraFlashOn];
        if(done) {
            self.flashButton.selected = YES;
            self.flashButton.tintColor = [UIColor yellowColor];
        }
    }
    else {
        BOOL done = [self.camera updateFlashMode:LLCameraFlashOff];
        if(done) {
            self.flashButton.selected = NO;
            self.flashButton.tintColor = [UIColor whiteColor];
        }
    }
}

- (void)snapButtonPressed:(UIButton *)button
{
    __weak typeof(self) weakSelf = self;
    
    // capture
    [self.camera capture:^(LLSimpleCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error) {
        if(!error) {
            self.cameraImage = image;
            self.cameraImage = [self prepareImageForGame:self.cameraImage]; // resize camera image for game
            
            // set this up so user can edit the image
            self.editorViewController = [[UIViewController alloc] init];
            [[NSBundle mainBundle] loadNibNamed:@"DKImageEdit" owner:self options:nil];
            self.editorView.frame = self.view.frame;
            self.editorViewController.view = self.editorView;
            self.editorView.image = self.cameraImage;
            self.editorView = nil;
            [self presentViewController:self.editorViewController animated:NO completion:nil];

            
            // [self performSegueWithIdentifier:@"previewPuzzleSender" sender:self]; // transfer photo to next view controller (PreviewPuzzleViewController)
        }
        else {
            NSLog(@"An error has occured: %@", error);
        }
    } exactSeenImage:YES];
}

- (IBAction)cameraBackButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


# pragma mark - image edit methods


-(IBAction)confirm:(id)sender
{
    self.backButton.hidden = YES;
    self.checkButton.hidden = YES;
    self.verticalImagePicker.hidden = YES;
    self.textButton.hidden = YES;
    self.crayonButton.hidden = YES;
    DKEditorView *dkev = (DKEditorView *)self.editorViewController.view;
    UIGraphicsBeginImageContext(dkev.frame.size);
    [dkev.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *temp = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.editorViewController = nil; // release
    self.cameraImage = temp; // set the edited image to be passed.
    self.originalImage = temp; // set the edited image to be passed
    [self.navigationController dismissViewControllerAnimated:NO completion:NULL]; // dismiss the editorviewcontroller
    [self performSegueWithIdentifier:@"previewPuzzleSender" sender:self]; // transfer photo to next view controller (PreviewPuzzleViewController)
}

-(IBAction)backButtonDidPress:(id)sender {
    [self.navigationController dismissViewControllerAnimated:NO completion:NULL]; // dismiss the editorviewcontroller
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"previewPuzzleSender"]) {
        PreviewPuzzleViewController *previewPuzzleViewController = (PreviewPuzzleViewController *)segue.destinationViewController;
        if ([self.createdGame objectForKey:@"receiverPlayed"] == [NSNumber numberWithBool:true]) { // this is the condition if the game already exists but the receiver has yet to send back. he's already played. not relevant if it's an entirely new game because an entirely new game is made.
            NSLog(@"Game already started: %@", self.createdGame);
            previewPuzzleViewController.createdGame = self.createdGame;
            previewPuzzleViewController.roundObject = self.roundObject;
        }
        
        else if (self.createdGame == nil) {
            NSLog(@"Game hasn't been started yet: %@", self.createdGame);
        }
        
        previewPuzzleViewController.originalImage = self.originalImage;
        previewPuzzleViewController.previewImage = self.cameraImage; // pass the original image for preview since it doesn't need to be resized
        previewPuzzleViewController.opponent = self.opponent;
        NSLog(@"Opponent: %@", self.opponent);
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
