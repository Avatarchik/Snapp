//
//  FriendsTableViewController.h
//  Snap Scramble
//
//  Created by Tim Gorer on 3/5/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <KVNProgress/KVNProgress.h>
#import "UserSelectionViewController.h"

@class UserSelectionViewController;

@interface FriendsTableViewController : UITableViewController

@property (weak, nonatomic) id<FirstVCDelegate> delegate;
@property (nonatomic, strong) PFUser *opponent;
@property (nonatomic, strong) PFRelation *friendsRelation; // remove later on........
@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSMutableArray *mutableFriendsList;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addFriendBarButton;


@end
