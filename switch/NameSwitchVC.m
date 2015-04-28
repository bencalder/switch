//
//  NameSwitchVC.m
//  switch
//
//  Created by Ben Calder on 4/22/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "NameSwitchVC.h"
#import "DataManager.h"
#import <Parse/Parse.h>

@interface NameSwitchVC () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *codeTF;
@property (weak, nonatomic) IBOutlet UITextField *nameTF;

@property (weak, nonatomic) IBOutlet UIButton *backB;
@property (weak, nonatomic) IBOutlet UIButton *doneB;

@property (strong, nonatomic) DataManager *sharedData;

@end

@implementation NameSwitchVC


- (IBAction)buttonPress:(id)sender
{
 if (sender == self.doneB)
    {
    [self lookupSwitchCode];
    }
}


- (void)saveAndMoveForward
{
 self.sharedData.freshSwitchPFO[@"name"] = self.nameTF.text;

 [self performSegueWithIdentifier:@"nameswitchtoselect" sender:self];
}


- (void)lookupSwitchCode
{
 PFQuery *query = [PFQuery queryWithClassName:@"WirelessSwitch"];
 [query whereKey:@"objectId" equalTo:self.codeTF.text];
 [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
    {
    if (!error)
       {
       self.sharedData.freshSwitchPFO = object;
       self.sharedData.freshSwitchPFO[@"uuid"] = self.sharedData.btComm.activePeripheral.identifier.UUIDString;
       [self saveAndMoveForward];
       }
    else NSLog(@"Error: %@ %@", error, [error userInfo]);
    }
 ];
}


- (IBAction)unwindFromSelectAccessory:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind from SelectAccessoryVC");
    // Pull any data from the view controller which initiated the unwind segue.
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
 if (textField == self.codeTF) [self.nameTF becomeFirstResponder];
 else
 if (textField == self.nameTF) [self buttonPress:self.doneB];
 
 return YES;
}


- (void)viewDidLoad
{
 [super viewDidLoad];
    
 self.sharedData = [DataManager sharedDataManager];
}


- (void)viewDidAppear:(BOOL)animated
{
 [super viewDidAppear:animated];
 
 [self.codeTF becomeFirstResponder];
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
