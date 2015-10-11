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
#import "EngageAccessory.h"
#import "Utilities.h"

@interface SwitchEditVC () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, BTDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backB;

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
 if (sender == self.backB) [self performSegueWithIdentifier:@"unwindfromswitchedittohome" sender:self];
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
 if (section == 0)
    {
    if (self.choosingAccessory) return self.displayAccessoriesMA.count;
    else                        return self.selectedAccessoriesMA.count;
    }
 else return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
EngageAccessory *accessory, *displayAccessory;
 
 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"subtitle"];
 
 if (indexPath.section == 0)   //  Accessories
    {
    if (self.choosingAccessory)
       {
       displayAccessory = self.displayAccessoriesMA[indexPath.row];
        
       cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", displayAccessory.brand, displayAccessory.model];
       
       for (EngageAccessory *selectedAccessory in self.selectedAccessoriesMA)
          if ([selectedAccessory.objectId isEqualToString:((EngageAccessory *)self.displayAccessoriesMA[indexPath.row]).objectId])
             {
             cell.accessoryType = UITableViewCellAccessoryCheckmark;
             }
          else cell.accessoryType = UITableViewCellAccessoryNone;
       }
    else
       {
       accessory = self.selectedAccessoriesMA[indexPath.row];
       
       cell.textLabel.font       = [UIFont fontWithName:@"Helvetica" size:13.0];
       cell.textLabel.text       = [NSString stringWithFormat:@"%@ %@", accessory.brand, accessory.model];
       cell.detailTextLabel.text = [NSString stringWithFormat:@"Connector %ld", indexPath.row + 1];
       }
    }

 return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
 if (indexPath.section == 0)
    {
    if (self.choosingAccessory)
       {
       [self.selectedAccessoriesMA replaceObjectAtIndex:self.choosingAccessoryI withObject:self.displayAccessoriesMA[indexPath.row]];
       
       [Utilities determineRelaysForAccessory:self.selectedAccessoriesMA[self.choosingAccessoryI] atConnector:self.choosingAccessoryI + 1];
       
       self.sharedData.primaryUnit.accessories = self.selectedAccessoriesMA;
       
       self.choosingAccessory = NO;
       }
    else
       {
       self.choosingAccessory = YES;
//       [self buildAccessoryArrayForConnector:indexPath.row];
       }
     
    [self.editTV reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
// else
// if (indexPath.section == 2)  // delete
//    {
//    self.deleteAS = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to delete the switch?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Delete switch", nil];
//    [self.deleteAS showInView:self.view];
//    }
}


- (void)deleteSwitch
{
NSUserDefaults *defaults;
NSArray *a;
NSMutableArray *switchA;

 defaults = [NSUserDefaults standardUserDefaults];
 
 a = [defaults objectForKey:@"switchArray"];
 
 switchA = NSMutableArray.new;
    
 for (NSDictionary *d in a) [switchA addObject:d];
    
 for (NSDictionary *switchD in switchA)
    if ([switchD[@"objectId"] isEqualToString:self.sharedData.selectedSwitchPFO.objectId])
       [switchA removeObject:switchD];
     
 if (switchA.count > 0) [defaults setObject:switchA forKey:@"switchArray"];
 else                   [defaults removeObjectForKey:@"switchArray"];
    
 [defaults synchronize];
 
 [self performSegueWithIdentifier:@"unwindfromswitchedittohome" sender:self];
}


- (void)didDisconnect:(CBPeripheral *)peripheral
{
 NSLog(@"Disconnected from peripheral in SwitchEditVC");

}


- (void)viewDidLoad
{
 [super viewDidLoad];
 
 self.sharedData = [DataManager sharedDataManager];
 
// self.selectedAccessoriesMA = [[NSMutableArray alloc] initWithArray:self.sharedData.selectedSwitchPFO[@"connectors"] copyItems:YES];

 self.selectedAccessoriesMA = [NSMutableArray arrayWithArray:self.sharedData.primaryUnit.accessories];
 self.displayAccessoriesMA  = [NSMutableArray arrayWithArray:self.sharedData.accessories];
 
 self.sectionTitleA = @[@"Accessories"];
 
 self.choosingAccessory = NO;
}


- (void)didReceiveMemoryWarning
{
 [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
