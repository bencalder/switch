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

@property (strong, nonatomic) NSArray *accessoriesA,
                                      *connectorsA;

@property (strong, nonatomic) NSMutableArray *chosenAccessoriesMA;

@property (strong, nonatomic) DataManager *sharedData;

@property (nonatomic) NSInteger counter,
                                choosingConnectorI,
                                totalConnectorsI;

@property (nonatomic) BOOL accordionOpen;

@end

@implementation SelectAccessoriesVC


- (IBAction)buttonPress:(id)sender
{
 if (sender == self.doneB)
    {
    for (int i = 0; i < self.totalConnectorsI; i++)
       {
       [self.sharedData.freshSwitchPFO[@"connectors"][i] setObject:((PFObject *)self.chosenAccessoriesMA[i]).objectId forKey:@"accessoryId"];
       [self.sharedData.freshSwitchPFO[@"connectors"][i] setObject:((PFObject *)self.chosenAccessoriesMA[i])[@"brand"] forKey:@"accessoryBrand"];
       [self.sharedData.freshSwitchPFO[@"connectors"][i] setObject:((PFObject *)self.chosenAccessoriesMA[i])[@"model"] forKey:@"accessoryModel"];
       }
    }
}


- (IBAction)unwindFromSummary:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind from SummaryVC");
    // Pull any data from the view controller which initiated the unwind segue.
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
 if (self.accordionOpen) return self.accessoriesA.count;
 else                    return 1;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
 if (self.accordionOpen) return self.accessoriesA[section][0][@"brand"];
 else                    return nil;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 if (self.accordionOpen) return ((NSArray *)self.accessoriesA[section]).count;
 else return self.totalConnectorsI;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
 UITableViewCell *cell;
 
 if (self.accordionOpen)
    {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"subtitle"];
 
    PFObject *accessory = self.accessoriesA[indexPath.section][indexPath.row];
 
    cell.textLabel.text = accessory[@"model"];
 
    for (PFObject *connectorType in self.connectorsA)
       {
       if ([accessory[@"connectors"][0][@"objectId"] isEqualToString:connectorType.objectId])
          {
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ pin connector", connectorType[@"brand"], connectorType[@"pinCount"]];
          break;
          }
       }
    
    if (self.chosenAccessoriesMA.count > self.choosingConnectorI)
       {
       if ([accessory.objectId isEqualToString:((PFObject *)self.chosenAccessoriesMA[self.choosingConnectorI]).objectId])
          [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
       }
    }
 else
    {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"default"];
    
    if (self.chosenAccessoriesMA.count > indexPath.row)
       {
       if ([self.chosenAccessoriesMA[indexPath.row] isKindOfClass:[PFObject class]]) cell.textLabel.text = [NSString stringWithFormat:@"Connector %li: %@ %@", indexPath.row + 1, self.chosenAccessoriesMA[indexPath.row][@"brand"], self.chosenAccessoriesMA[indexPath.row][@"model"]];
       else cell.textLabel.text = [NSString stringWithFormat:@"Choose accessory for Connector %li", indexPath.row + 1];
       }
    else cell.textLabel.text = [NSString stringWithFormat:@"Choose accessory for Connector %li", indexPath.row + 1];
    }
 
 return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;

 if (self.accordionOpen)
    {
    cell = [tableView cellForRowAtIndexPath:indexPath];
 
    if (cell.accessoryType == UITableViewCellAccessoryNone)
       {
       [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        
       if (self.chosenAccessoriesMA.count > self.choosingConnectorI)
          {
          [self.chosenAccessoriesMA replaceObjectAtIndex:self.choosingConnectorI withObject:self.accessoriesA[indexPath.section][indexPath.row]];
          }
       else [self.chosenAccessoriesMA insertObject:self.accessoriesA[indexPath.section][indexPath.row] atIndex:self.choosingConnectorI];
       }
     
    self.accordionOpen = NO;
    }
 else
    {
    self.choosingConnectorI = indexPath.row;
    self.accordionOpen = YES;
    }
 
 [self.accessoryTV reloadData];
}


- (void)viewDidLoad
{
 [super viewDidLoad];
 
 self.sharedData = [DataManager sharedDataManager];
 
 self.counter = 0;

 [self lookupAccessories];
 [self lookupConnectors];
 
 self.chosenAccessoriesMA = NSMutableArray.new;
 
 self.accordionOpen = NO;
 
 self.totalConnectorsI = ((NSArray *)self.sharedData.freshSwitchPFO[@"connectors"]).count;  // number of connectors that need to be set
 
 self.messageL.text = [NSString stringWithFormat:@"%@ has %lu connectors. What will you plug in to Connector 1?", self.sharedData.freshSwitchPFO[@"name"], (unsigned long)((NSArray *)self.sharedData.freshSwitchPFO[@"connectors"]).count];
}


- (void)lookupAccessories
{
 PFQuery *query = [PFQuery queryWithClassName:@"Accessory"];
 
 [query addAscendingOrder:@"brand"];   // sort by brand
 
 [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
    if (!error)
       {
       NSMutableArray *brandsMA, *accMA;
       NSString *str;
       
       brandsMA = NSMutableArray.new;
       accMA    = NSMutableArray.new;
       str      = objects[0][@"brand"];
       
       for (int i = 0; i < objects.count; i++)
          {
          PFObject *obj = objects[i];
          
          if ([obj[@"brand"] isEqualToString:str])   // same brand
             {
             [accMA addObject:obj];
             }
          else    // new brand
             {
             [brandsMA addObject:[accMA mutableCopy]];
             [accMA removeAllObjects];
             str = objects[i + 1][@"brand"];
             }
          }
        
       self.accessoriesA = brandsMA;
       [self buildTable];
       }
    else NSLog(@"Error: %@ %@", error, [error userInfo]);
    }
 ];
}


- (void)lookupConnectors
{
 PFQuery *query = [PFQuery queryWithClassName:@"Connector"];
 
 [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
    if (!error)
       {
       self.connectorsA = objects;
       [self buildTable];
       }
    else NSLog(@"Error: %@ %@", error, [error userInfo]);
    }
 ];
}


- (void)buildTable
{
 self.counter++;
 
 if (self.counter < 2) return;
 
 [self.accessoryTV reloadData];
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
