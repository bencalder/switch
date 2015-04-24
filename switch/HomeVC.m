//
//  HomeVC.m
//  switch
//
//  Created by Ben Calder on 4/21/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "HomeVC.h"
#import <Parse/Parse.h>

@interface HomeVC ()

@property (strong, nonatomic) NSArray *switchIdA,
                                      *switchA;

@end


@implementation HomeVC


- (IBAction)unwindFromAddSwitch:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind from AddSwitchVC");
    // Pull any data from the view controller which initiated the unwind segue.
}


- (IBAction)unwindFromCreateSwitch:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind from CreateSwitchVC");
    // Pull any data from the view controller which initiated the unwind segue.
}


- (IBAction)unwindToHomeFromSummary:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind to Home from SummaryVC");
    // Pull any data from the view controller which initiated the unwind segue.
}


- (void)viewDidLoad
{
 [super viewDidLoad];
    // Do any additional setup after loading the view.
}


- (void)viewDidAppear:(BOOL)animated
{
 [super viewDidAppear:animated];
 
 [self loadSwitchArray];
}


- (void)loadSwitchArray
{
 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
 
 if (((NSArray *)[defaults objectForKey:@"switchArray"]).count > 0)
    {
    self.switchIdA = [defaults objectForKey:@"switchArray"];
    
    [self lookupSwitchData];
    }
}


- (void)lookupSwitchData
{
 PFQuery *query = [PFQuery queryWithClassName:@"WirelessSwitch"];
 
 [query whereKey:@"objectId" containedIn:self.switchA];
 
 [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
    if (!error)
       {
       self.switchA = objects;
       }
    else NSLog(@"Error: %@ %@", error, [error userInfo]);
    }
 ];

}


- (void)didReceiveMemoryWarning
{
 [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
