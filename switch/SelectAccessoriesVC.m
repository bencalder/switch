//
//  SelectAccessoriesVC.m
//  switch
//
//  Created by Ben Calder on 4/23/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "SelectAccessoriesVC.h"
#import <Parse/Parse.h>
#import "DataManager.h"

@interface SelectAccessoriesVC () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backB,
                                              *doneB;

@property (weak, nonatomic) IBOutlet UILabel *messageL;

@property (weak, nonatomic) IBOutlet UITableView *accessoryTV;

@property (strong, nonatomic) NSArray *accessoriesA;

@property (strong, nonatomic) NSMutableArray *selectedAccessoriesMA,
                                             *displayAccessoriesMA;

@property (strong, nonatomic) DataManager *sharedData;

@property (nonatomic) NSInteger counter,
                                choosingAccessoryI;

@property (nonatomic) BOOL choosingAccessory;

@end

@implementation SelectAccessoriesVC


- (IBAction)buttonPress:(id)sender
{
 if (sender == self.doneB) self.sharedData.freshSwitchPFO[@"connectors"] = self.selectedAccessoriesMA;
}


- (IBAction)unwindFromSummary:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind from SummaryVC");
    // Pull any data from the view controller which initiated the unwind segue.
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
 return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 if (self.choosingAccessory) return self.displayAccessoriesMA.count;
    else                     return self.selectedAccessoriesMA.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
PFObject *switchPFO;
NSString *str;
 
 switchPFO = self.sharedData.freshSwitchPFO;
 
 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"subtitle"];
 
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
    if ((str = self.selectedAccessoriesMA[indexPath.row][@"accessoryBrand"]) == nil)  //  user has not chosen an accessory for this connector
       {
       cell.textLabel.text = [NSString stringWithFormat:@"Choose an accessory for Connector %li", indexPath.row + 1];
       }
    else
       {
       cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:13.0];
       cell.textLabel.text = [NSString stringWithFormat:@"Connector %ld: %@ %@", indexPath.row + 1, switchPFO[@"connectors"][indexPath.row][@"accessoryBrand"], switchPFO[@"connectors"][indexPath.row][@"accessoryModel"]];
       }
    }
 
 return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
 if (self.choosingAccessory)
    {
    self.choosingAccessory = NO;

    self.selectedAccessoriesMA[self.choosingAccessoryI][@"accessoryBrand"]     = self.displayAccessoriesMA[indexPath.row][@"brand"];
    self.selectedAccessoriesMA[self.choosingAccessoryI][@"accessoryModel"]     = self.displayAccessoriesMA[indexPath.row][@"model"];
    self.selectedAccessoriesMA[self.choosingAccessoryI][@"accessoryFunctions"] = self.displayAccessoriesMA[indexPath.row][@"functions"];
    self.selectedAccessoriesMA[self.choosingAccessoryI][@"accessoryId"]        = ((PFObject *)self.displayAccessoriesMA[indexPath.row]).objectId;
    }
 else
    {
    self.choosingAccessory = YES;
    [self buildAccessoryArrayForConnector:indexPath.row];
    }
 
 [self.accessoryTV reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
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


- (void)viewDidLoad
{
 [super viewDidLoad];
 
 self.sharedData = [DataManager sharedDataManager];
 
 self.choosingAccessory = NO;
 
 self.selectedAccessoriesMA = self.sharedData.freshSwitchPFO[@"connectors"];
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
