//
//  NameSwitchVC.m
//  switch
//
//  Created by Ben Calder on 4/22/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "NameSwitchVC.h"
#import "DataManager.h"

@interface NameSwitchVC () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTF;
@property (weak, nonatomic) IBOutlet UIButton *backB;
@property (weak, nonatomic) IBOutlet UIButton *doneB;

@property (strong, nonatomic) DataManager *sharedData;

@end

@implementation NameSwitchVC


- (IBAction)buttonPress:(id)sender
{
 if (sender == self.doneB) self.sharedData.freshSwitchPFO[@"name"] = self.nameTF.text;

}


- (IBAction)unwindFromSelectAccessory:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind from SelectAccessoryVC");
    // Pull any data from the view controller which initiated the unwind segue.
}


- (void)viewDidLoad
{
 [super viewDidLoad];
    
 self.sharedData = [DataManager sharedDataManager];
}

- (void)viewDidAppear:(BOOL)animated
{
 [super viewDidAppear:animated];
 
 [self.nameTF becomeFirstResponder];
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
