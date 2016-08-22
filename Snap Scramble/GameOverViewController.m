//
//  GameOverViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 7/27/15.
//  Copyright (c) 2015 Tim Gorer. All rights reserved.
//

#import "GameOverViewController.h"
#import "ChallengeViewController.h"
#import "Snap_Scramble-Swift.h"
#import "GameOverViewModel.h"
#import "GameViewController.h"

@interface GameOverViewController ()

@property(nonatomic, strong) GameOverViewModel *viewModel;

@end

// this view controller displays stats
@implementation GameOverViewController

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _viewModel = [[GameOverViewModel alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.doneButton addTarget:self action:@selector(doneButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    self.doneButton.adjustsImageWhenHighlighted = NO;
    self.currentUserTimeLabel.adjustsFontSizeToFitWidth = YES;
    self.currentUserTimeLabel.contentScaleFactor = 0.5;
    self.opponentTimeLabel.adjustsFontSizeToFitWidth = YES;
    self.opponentTimeLabel.contentScaleFactor = 0.5;
    self.headerStatsLabel.adjustsFontSizeToFitWidth = YES;
    self.headerStatsLabel.contentScaleFactor = 0.5;
    [self updateStatsView]; // update the stats view since the game is over
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.navigationController.navigationBar setHidden:true];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:false];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


# pragma mark - set view model properties

- (void)setViewModelProperties {
    self.viewModel.createdGame = self.createdGame;
    self.viewModel.roundObject = self.roundObject;
    self.viewModel.currentUserTotalSeconds = self.currentUserTotalSeconds;
    self.viewModel.opponent = self.opponent;
}


# pragma mark - view controller methods

- (void)updateStatsView {
    [self setViewModelProperties]; // set view model properties
    [self.viewModel updateGame]; // update the game in the cloud appropriately once current user has played
    [KVNProgress showWithStatus:@"Loading..."];

        
    
            
    // format the current user's time
    int intValueTotalSeconds = [self.currentUserTotalSeconds intValue];
    NSLog(@"intval: %d", intValueTotalSeconds);
    int minutes = 0; int seconds = 0;
    
    seconds = intValueTotalSeconds % 60;
    if (intValueTotalSeconds >= 60) {
        minutes = intValueTotalSeconds / 60;
    }
    
    if (seconds < 10) {
        self.currentUserTimeLabel.text = [NSString stringWithFormat:@"Your time: %d:0%d", minutes, seconds];
    }
    
    else if (seconds >= 10) {
        self.currentUserTimeLabel.text = [NSString stringWithFormat:@"Your time: %d:%d", minutes, seconds];
    }
    
    // update the stats labels
    if ([[self.createdGame objectForKey:@"receiverName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the receiver. This code is executed when the user plays a game someone else sent him.
        NSString *opponentName = [self.createdGame objectForKey:@"senderName"];
        self.opponentTotalSeconds = [self.roundObject objectForKey:@"senderTime"];
        
        if (self.opponentTotalSeconds != nil) {
            
            // format the opponent's time
            int intValueTotalSeconds = [self.opponentTotalSeconds intValue];
            int minutes = 0; int seconds = 0;
            
            seconds = intValueTotalSeconds % 60;
            if (intValueTotalSeconds >= 60) {
                minutes = intValueTotalSeconds / 60;
            }
            
            if (seconds < 10) {
                self.opponentTimeLabel.text = [NSString stringWithFormat:@"%@'s time: %d:0%d", opponentName, minutes, seconds];
            }
            
            else if (seconds >= 10) {
                self.opponentTimeLabel.text = [NSString stringWithFormat:@"%@'s time: %d:%d", opponentName, minutes, seconds];
            }
            
            
            // check who won
            if (self.currentUserTotalSeconds < self.opponentTotalSeconds) {
                self.headerStatsLabel.text = [NSString stringWithFormat:@"You won! It is your turn to reply now!"]; // since current user is the receiver, inform him it is his turn to reply now.
            }
            
            else if (self.currentUserTotalSeconds > self.opponentTotalSeconds) {
                self.headerStatsLabel.text = [NSString stringWithFormat:@"You lost! It is your turn to reply now!"]; // since current user is the receiver, inform him it is his turn to reply now.
            }
            
            else if (self.currentUserTotalSeconds == self.opponentTotalSeconds) {
                self.headerStatsLabel.text = [NSString stringWithFormat:@"Tie! It is your turn to reply now!"]; // since current user is the receiver, inform him it is his turn to reply now.
            }
        }
        
        else {
            NSLog(@"something went wrong.");
        }
    }
    
    else if ([[self.createdGame objectForKey:@"senderName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the sender. This code is executed when the user is sending his own game to someone else.
        [self.viewModel switchTurns]; // switch turns since current user is the sender
        NSString *opponentName = [self.createdGame objectForKey:@"receiverName"];
        self.opponentTimeLabel.text = [NSString stringWithFormat:@"%@ hasn't played yet.", opponentName];
        self.headerStatsLabel.text = [NSString stringWithFormat:@"It is %@'s turn to play your puzzle now!", opponentName]; // inform current user, who is the sender, that it's the opponent's turn to play now.
    }
    
    // save game
    [self.viewModel saveCurrentGame:^(BOOL succeeded, NSError *error) {
        if (error) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"A connection error occurred." message:@"Please quit the app and try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alertView show];
            [KVNProgress dismiss];
        }
        
        else {
            [KVNProgress dismiss];
        }
    }];
}

- (IBAction)doneButtonDidPress:(id)sender {
    self.statsView.animation = @"fall";
    self.statsView.delay = 5.0;
    [self.statsView animate];
    
    //This for loop iterates through all the view controllers in navigation stack.
    for (UIViewController* viewController in self.navigationController.viewControllers) {
        if ([viewController isKindOfClass:[GameViewController class]] ) {
            GameViewController *gameViewController = (GameViewController *)viewController;
            
            // the following if statements figure out which UI to display based on what role the user is in (sender or receiver)
            gameViewController.viewModel.opponent = self.opponent;
            gameViewController.viewModel.createdGame = self.createdGame;
            
            
            if ([[self.createdGame objectForKey:@"receiverName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the receiver (we want the receiver to send back a puzzle). This code is executed when the user plays a game someone else sent him.
                NSLog(@"current user is the receiver, show reply button UI");
                [gameViewController updateToReplyButtonUI];
                
            }
            
            else if ([[self.createdGame objectForKey:@"senderName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the sender. This code is executed when the user starts sending his own game to someone else.
                NSLog(@"current user is the sender, show main menu button UI");
                [gameViewController updateToMainMenuButtonUI];
            }
            
            [self.navigationController popToViewController:gameViewController animated:YES];
            break;
        }
    }
}





/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
