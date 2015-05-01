//
//  SwitchEditVC.m
//  switch
//
//  Created by Ben Calder on 4/28/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "SwitchEditVC.h"
#import "DataManager.h"
#import <Parse/Parse.h>
#import "HomeVC.h"

@interface SwitchEditVC () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, BTDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backB;
@property (weak, nonatomic) IBOutlet UIButton *saveB;

@property (strong, nonatomic) UIButton *keyboardDoneB,
                                       *keyboardCancelB;

@property (strong, nonatomic) UITextField *nameTF;

@property (weak, nonatomic) IBOutlet UITableView *editTV;

@property (strong, nonatomic) NSArray *sectionTitleA;

@property (strong, nonatomic) NSMutableArray *selectedAccessoriesMA,
                                             *displayAccessoriesMA;

@property (strong, nonatomic) DataManager *sharedData;

@property (strong, nonatomic) UIActionSheet *deleteAS;

@property (strong, nonatomic) UIAlertView *savedAV;

@property (nonatomic) BOOL choosingAccessory;

@property (nonatomic) NSInteger choosingAccessoryI;

@property (strong, nonatomic) NSString *cancelNameS;

@end

@implementation SwitchEditVC


- (IBAction)buttonPress:(id)sender
{
 if (sender == self.backB)
    {
    
    }
 else
 if (sender == self.saveB)
    {
    [self.nameTF resignFirstResponder];
    [self saveSwitchEditsToParse];
    }
}


- (void)saveSwitchEditsToParse
{
 self.sharedData.selectedSwitchPFO[@"name"]       = self.nameTF.text;
 self.sharedData.selectedSwitchPFO[@"connectors"] = self.selectedAccessoriesMA;
 
 [self.sharedData.selectedSwitchPFO saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
    {
    if (!error)
       {
       self.saveB.hidden = YES;
       
       self.savedAV = [[UIAlertView alloc] initWithTitle:@"Saved" message:@"The switch information was saved successfully." delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
       [self.savedAV show];
       
       [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(dismissAlertView:) userInfo:nil repeats:NO];
       }
    else NSLog(@"Error: %@ %@", error, [error userInfo]);
    }
 ];
}


- (void)dismissAlertView:(NSTimer *)timer
{
 [self.savedAV dismissWithClickedButtonIndex:0 animated:YES];
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
 return self.sectionTitleA.count;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
 return self.sectionTitleA[section];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 if (section == 1)
    {
    if (self.choosingAccessory) return self.displayAccessoriesMA.count;
    else                        return self.selectedAccessoriesMA.count;
    }
 else              return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
PFObject *switchPFO;
NSDictionary *d;
 
 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"subtitle"];
 
 switchPFO = self.sharedData.selectedSwitchPFO;
 
 if (indexPath.section == 0)    // Name
    {
    for (UIView *vw in cell.contentView.subviews) [vw removeFromSuperview];
    
    self.nameTF                    = UITextField.new;
    self.nameTF.frame              = CGRectMake(20, 0, self.editTV.frame.size.width - 40, cell.frame.size.height);
    self.nameTF.delegate           = self;
    self.nameTF.autocorrectionType = UITextAutocorrectionTypeNo;
    self.nameTF.borderStyle        = UITextBorderStyleNone;
    self.nameTF.text               = switchPFO[@"name"];
    [self.nameTF setInputAccessoryView:[self accessoryViewForTextField]];
    [self.nameTF setReturnKeyType:UIReturnKeyDone];
    
    [cell.contentView addSubview:self.nameTF];
    }
 else
 if (indexPath.section == 1)   //  Accessories
    {
    if (self.choosingAccessory)
       {
       cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", self.displayAccessoriesMA[indexPath.row][@"brand"], self.displayAccessoriesMA[indexPath.row][@"model"]];
       
       if ([((PFObject *)self.displayAccessoriesMA[indexPath.row]).objectId isEqualToString:self.selectedAccessoriesMA[self.choosingAccessoryI][@"accessoryId"]])
          {
          cell.accessoryType = UITableViewCellAccessoryCheckmark;
          }
       else cell.accessoryType = UITableViewCellAccessoryNone;
       }
    else
       {
       d = self.selectedAccessoriesMA[indexPath.row];
       
       cell.textLabel.font       = [UIFont fontWithName:@"Helvetica" size:13.0];
       cell.textLabel.text       = [NSString stringWithFormat:@"%@ %@", d[@"accessoryBrand"], d[@"accessoryModel"]];
       cell.detailTextLabel.text = [NSString stringWithFormat:@"Connector %ld", indexPath.row + 1];
       }
    }
 else
 if (indexPath.section == 2)    // Delete switch
    {
    cell.textLabel.text       = @"Delete switch";
    cell.detailTextLabel.text = @"This will permanently delete this switch from your account.";
    }

 return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
 if (indexPath.section == 1)
    {
    if (self.choosingAccessory)
       {
       NSDictionary *d;
       
       d = @{@"accessoryBrand"     : self.displayAccessoriesMA[indexPath.row][@"brand"],
             @"accessoryModel"     : self.displayAccessoriesMA[indexPath.row][@"model"],
             @"accessoryFunctions" : self.displayAccessoriesMA[indexPath.row][@"functions"],
             @"accessoryId"        : ((PFObject *)self.displayAccessoriesMA[indexPath.row]).objectId,
             @"objectId"           : self.selectedAccessoriesMA[self.choosingAccessoryI][@"objectId"],
             @"relays"             : self.selectedAccessoriesMA[self.choosingAccessoryI][@"relays"]
            };
       
       [self.selectedAccessoriesMA replaceObjectAtIndex:self.choosingAccessoryI withObject:d];
       
       self.choosingAccessory = NO;
       
       self.saveB.hidden = NO;
       }
    else
       {
       self.choosingAccessory = YES;
       [self buildAccessoryArrayForConnector:indexPath.row];
       }
     
    [self.editTV reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
 else
 if (indexPath.section == 2)  // delete
    {
    self.deleteAS = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to delete the switch?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Delete switch", nil];
    [self.deleteAS showInView:self.view];
    }
}


- (void)buildAccessoryArrayForConnector:(NSInteger)connectorInt
{
 self.choosingAccessoryI = connectorInt;

 self.displayAccessoriesMA = NSMutableArray.new;
 
 for (PFObject *accessory in self.sharedData.accessories)  // loop through all of the possible accessories
    {
    for (int i = 0; i < ((NSArray *)accessory[@"connectors"]).count; i++)   //  loop through each connector of each accessory
       {
       if ([accessory[@"connectors"][i][@"objectId"] isEqualToString:self.selectedAccessoriesMA[connectorInt][@"objectId"]])
          {
          [self.displayAccessoriesMA addObject:accessory];
          break;
          }
       }
    }
}


- (UIView *)accessoryViewForTextField
{
UIView *vw;

 vw                 = UIView.new;
 vw.frame           = CGRectMake(0, 0, self.view.frame.size.width, 50);
 vw.backgroundColor = [UIColor whiteColor];
 
 self.keyboardDoneB       = [UIButton buttonWithType:UIButtonTypeSystem];
 self.keyboardDoneB.frame = CGRectMake(vw.frame.size.width - 60, 0, 50, 50);
 [self.keyboardDoneB setTitle:@"Done" forState:UIControlStateNormal];
 [self.keyboardDoneB addTarget:self action:@selector(doneWithKeyboard:) forControlEvents:UIControlEventTouchUpInside];
 
 self.keyboardCancelB       = [UIButton buttonWithType:UIButtonTypeSystem];
 self.keyboardCancelB.frame = CGRectMake(10, 0, 50, 50);
 [self.keyboardCancelB setTitle:@"Cancel" forState:UIControlStateNormal];
 [self.keyboardCancelB addTarget:self action:@selector(cancelKeyboard:) forControlEvents:UIControlEventTouchUpInside];

 self.cancelNameS = self.nameTF.text;
 
 [vw addSubview:self.keyboardDoneB];
 [vw addSubview:self.keyboardCancelB];

return vw;
}


- (void)doneWithKeyboard:(UIButton *)sender
{
 [self.nameTF resignFirstResponder];
}


- (void)cancelKeyboard:(UIButton *)sender
{
 [self.nameTF resignFirstResponder];
 self.nameTF.text = self.cancelNameS;
 
 self.saveB.hidden = YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
 if (textField == self.nameTF) [self.nameTF resignFirstResponder];
 
 return YES;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
 self.saveB.hidden = NO;

 return YES;
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
 if (buttonIndex == 0)   // remove the dict of the current switch from user defaults and send user back to HomeVC
    {
    [self.btComm disconnect:self.btComm.activePeripheral];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSArray *a = [defaults objectForKey:@"switchArray"];
    NSMutableArray *switchA = NSMutableArray.new;
    
    for (NSDictionary *d in a)
       [switchA addObject:d];
    
    for (NSDictionary *switchD in switchA)
       {
       if ([switchD[@"objectId"] isEqualToString:self.sharedData.selectedSwitchPFO.objectId])
          [switchA removeObject:switchD];
       }
     
    if (switchA.count > 0) [defaults setObject:switchA forKey:@"switchArray"];
    else                   [defaults removeObjectForKey:@"switchArray"];
    
    [defaults synchronize];
    
    [self performSegueWithIdentifier:@"unwindfromswitchedittohome" sender:self];
    }
}


- (void)didDisconnect:(CBPeripheral *)peripheral
{
 NSLog(@"Disconnected from peripheral in SwitchEditVC");

}


- (void)viewDidLoad
{
 [super viewDidLoad];
 
 self.sharedData = [DataManager sharedDataManager];
 
 self.selectedAccessoriesMA = [[NSMutableArray alloc] initWithArray:self.sharedData.selectedSwitchPFO[@"connectors"] copyItems:YES];
 
 self.sectionTitleA = @[@"Switch name", @"Accessories", @"Delete"];
 
 self.choosingAccessory = NO;
}


- (void)didReceiveMemoryWarning
{
 [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
 if ([segue.identifier isEqualToString:@"unwindfromswitchedittohome"]) ((HomeVC *)[segue destinationViewController]).btComm = self.btComm;
}


@end
