//
//  PauseViewController.h
//  Snap Scramble
//
//  Created by Tim Gorer on 3/27/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Snap_Scramble-Swift.h"

@interface PauseViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton* solveLaterButton;
@property (weak, nonatomic) IBOutlet UIButton* reportButton;
@property (weak, nonatomic) IBOutlet UIButton* resignButton;
@property (weak, nonatomic) IBOutlet UIButton* cancelButton;
@property (weak, nonatomic) IBOutlet SpringView *pauseView;



@end
