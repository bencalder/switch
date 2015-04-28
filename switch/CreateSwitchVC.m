//
//  CreateSwitchVC.m
//  switch
//
//  Created by Ben Calder on 4/21/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "CreateSwitchVC.h"
#import "BluetoothComm.h"
#import <Parse/Parse.h>

@interface CreateSwitchVC () <UITableViewDataSource, UITableViewDelegate, BTDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backB,
                                              *doneB;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *scanningAI;

@property (weak, nonatomic) IBOutlet UITableView *switchTV;

@property (strong, nonatomic) BluetoothComm *btComm;

@property (strong, nonatomic) NSArray *boardA,
                                      *connectorTypeA,
                                      *relayDisplayA;

@property (strong, nonatomic) NSMutableArray *peripheralMA,
                                             *connectorsMA,
                                             *relaysMA;

@property (nonatomic) NSNumber *uuidN,
                               *boardN,
                               *connectorCountN,
                               *connectorSelectionN,
                               *connectorTypeN;

@property (nonatomic) NSInteger counter;

@property (strong, nonatomic) UISegmentedControl *connectorCountSC;

@property (strong, nonatomic) UIAlertView *noNewSwitchAV,
                                          *createdSwitchAV;

@end

@implementation CreateSwitchVC


- (IBAction)buttonPress:(id)sender
{
 if (sender == self.doneB)
    {
    [self.connectorsMA addObject:@{@"objectId" : ((PFObject *)self.connectorTypeA[self.connectorTypeN.integerValue]).objectId, @"relays" : [self.relaysMA mutableCopy]}];
    
    [self.relaysMA removeAllObjects];
    self.connectorTypeN = nil;
    
    [self.switchTV reloadData];
    
    if (self.connectorSelectionN == self.connectorCountN) [self saveSwitchDataToParse];  // we've finished entering data for all of the connectors, so save the switch data
    else
       {
       self.connectorSelectionN = [NSNumber numberWithInteger:self.connectorSelectionN.integerValue + 1];
       
       if (self.connectorCountN == self.connectorSelectionN) [self.doneB setTitle:@"Done" forState:UIControlStateNormal];  // if we have begun the last connector, change the title to Done
       }
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
 return 5;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
 if (section == 0) return @"UUID";
 else
 if (section == 1) return @"Board";
 else
 if (section == 2) return @"Connector Count";
 else
 if (section == 3) return [NSString stringWithFormat:@"Connector %i Type", self.connectorSelectionN.intValue + 1];
 else
 if (section == 4) return [NSString stringWithFormat:@"Connector %i Relay Use", self.connectorSelectionN.intValue + 1];
 else              return @"";
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 if (section == 0) return self.peripheralMA.count;
 else
 if (section == 1) return self.boardA.count;
 else
 if (section == 2) return 1;  // connector count
 else
 if (section == 3) return self.connectorTypeA.count;  // connector type
 else
 if (section == 4) return self.relayDisplayA.count;  // connector relay use
 else              return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
 UITableViewCell *cell = UITableViewCell.new;
 
 if (indexPath.section == 0)   //  uuid
    {
    CBPeripheral *per = (CBPeripheral *)self.peripheralMA[indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", per.name, per.identifier.UUIDString];
    
    if (self.uuidN && (indexPath.row == self.uuidN.integerValue)) [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
 else
 if (indexPath.section == 1)   //  board
    {
    cell.textLabel.text = ((PFObject *)self.boardA[indexPath.row])[@"name"];
    
    if (self.boardN && (indexPath.row == self.boardN.integerValue)) [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
 else
 if (indexPath.section == 2)   //  connector count
    {
    [cell.contentView addSubview:self.connectorCountSC];
    self.connectorCountSC.frame = cell.frame;
    }
 else
 if (indexPath.section == 3)   // connector type
    {
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ pin", self.connectorTypeA[indexPath.row][@"brand"], ((NSNumber *)self.connectorTypeA[indexPath.row][@"pinCount"]).stringValue];
    
    if (self.connectorTypeN && (indexPath.row == self.connectorTypeN.integerValue)) [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
 if (indexPath.section == 4)   // connector relay use
    {
    cell.textLabel.text = self.relayDisplayA[indexPath.row];
    }

 return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
 
 cell = [tableView cellForRowAtIndexPath:indexPath];
 
 if (indexPath.section == 0)   //  UUID
    {
    if (self.uuidN) [[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.uuidN.integerValue inSection:indexPath.section]] setAccessoryType:UITableViewCellAccessoryNone];   // set the previously selected row to none
    
    self.uuidN = [NSNumber numberWithInteger:indexPath.row];
    
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
 else
 if (indexPath.section == 1)   //  Board
    {
    if (self.boardN) [[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.boardN.integerValue inSection:indexPath.section]] setAccessoryType:UITableViewCellAccessoryNone];   // set the previously selected row to none
    
    self.boardN = [NSNumber numberWithInteger:indexPath.row];
    
    [self buildRelayDisplayA];
    
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
 else
 if (indexPath.section == 3)   //  Connector type
    {
    if (self.connectorTypeN) [[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.connectorTypeN.integerValue inSection:indexPath.section]] setAccessoryType:UITableViewCellAccessoryNone];   // set the previously selected row to none
    
    self.connectorTypeN = [NSNumber numberWithInteger:indexPath.row];
    
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
 else
 if (indexPath.section == 4)   //  Relays
    {
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark)
       {
       [cell setAccessoryType:UITableViewCellAccessoryNone];
       
       for (int i = 0; i < ((NSMutableArray *)self.relaysMA[self.connectorSelectionN.integerValue]).count; i++)
          {
          if ([(NSNumber *)self.relaysMA[self.connectorSelectionN.integerValue][i] isEqualToNumber:[NSNumber numberWithInteger:indexPath.row + 1]])   //  remove the correct number from the array
             [self.relaysMA[self.connectorSelectionN.integerValue] removeObjectAtIndex:i];
          }
       }
    else
       {    // set checkmark and add to array
       [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
       [self.relaysMA addObject:[NSNumber numberWithInteger:indexPath.row + 1]];
       }
    }
}


- (void)connectorCount:(id)sender  // user selected the count of connectors
{
 self.connectorCountN = [NSNumber numberWithInteger:self.connectorCountSC.selectedSegmentIndex];
 
 [self.switchTV reloadData];
}


- (void)buildRelayDisplayA
{
 NSMutableArray *ary = NSMutableArray.new;
 
 for (int i = 0; i < ((NSNumber *)self.boardA[self.boardN.integerValue][@"relayCount"]).integerValue; i++)
     [ary addObject:[NSString stringWithFormat:@"%i", i + 1]];
 
 self.relayDisplayA = ary;
 
 [self.switchTV reloadData];
}


- (void)saveSwitchDataToParse
{
 PFObject *wirelessSwitch = [PFObject objectWithClassName:@"WirelessSwitch"];
 
 wirelessSwitch[@"isSetup"]    = [NSNumber numberWithBool:NO];
// wirelessSwitch[@"uuid"]       = ((CBPeripheral *)self.peripheralMA[self.uuidN.integerValue]).identifier.UUIDString;
 wirelessSwitch[@"board"]      = (PFObject *)self.boardA[self.boardN.integerValue];
 wirelessSwitch[@"connectors"] = self.connectorsMA;
 
 [wirelessSwitch saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
    {
    if (succeeded)
       {
       NSLog(@"Saved new wireless switch: %@", wirelessSwitch);
       
       self.createdSwitchAV = [[UIAlertView alloc] initWithTitle:@"Success" message:[NSString stringWithFormat:@"Created new wireless switch with ID: %@", wirelessSwitch.objectId] delegate:self cancelButtonTitle:nil otherButtonTitles:@"Add another switch", @"Done", nil];
       [self.createdSwitchAV show];
       }
    else
       {
       NSLog(@"Error: %@ %@", error, [error userInfo]);
       }
    }
 ];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
 if (alertView == self.createdSwitchAV)
    {
    if (buttonIndex == 0) [self resetForNewSwitch];
    else
    if (buttonIndex == 1) [self performSegueWithIdentifier:@"unwindToHomeFromCreateSwitch" sender:self];
    }
 else
 if (alertView == self.noNewSwitchAV)
    {
    if (buttonIndex == 0) [self resetForNewSwitch];
    else
    if (buttonIndex == 1) [self performSegueWithIdentifier:@"unwindToHomeFromCreateSwitch" sender:self];
    }
}


- (void)resetForNewSwitch
{
 [self.doneB setTitle:@"Next" forState:UIControlStateNormal];
 
 [self.switchTV scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
 self.switchTV.userInteractionEnabled = NO;

 self.uuidN  = nil;
 self.boardN = nil;
 self.connectorCountN = nil;
 self.connectorSelectionN = nil;
 
 [self.peripheralMA removeAllObjects];
 [self.connectorsMA removeAllObjects];
 [self.relaysMA     removeAllObjects];
 
 [self.switchTV reloadData];
       
 [self.connectorCountSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
       
 self.counter = 2;  // set counter to be used when lookupUUIDs completes
 
 [self scanForPeripherals];
}


- (void)viewDidLoad
{
 [super viewDidLoad];
 
 self.counter = 0;
 
 self.btComm = BluetoothComm.new;
 [self.btComm setup];
 self.btComm.delegate = self;
 
 [self.scanningAI startAnimating];
 
 self.switchTV.userInteractionEnabled = NO;
 
 [self lookupBoards];
 [self lookupConnectors];
 
 self.connectorCountSC = [[UISegmentedControl alloc] initWithItems:@[@"1", @"2", @"3", @"4"]];
 [self.connectorCountSC addTarget:self action:@selector(connectorCount:) forControlEvents:UIControlEventValueChanged];
 
 self.connectorSelectionN = [NSNumber numberWithInteger:0];
 
 self.relaysMA = NSMutableArray.new;
 self.connectorsMA = NSMutableArray.new;
}


- (void)viewDidAppear:(BOOL)animated
{
 [super viewDidAppear:animated];
 
 [self scanForPeripherals];
}


- (void)lookupBoards
{
 PFQuery *query = [PFQuery queryWithClassName:@"Board"];
 
 [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
    if (!error) self.boardA = objects;
    else NSLog(@"Error: %@ %@", error, [error userInfo]);
    
    [self buildTable];
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
       self.connectorTypeA = objects;
       }
    else NSLog(@"Error: %@ %@", error, [error userInfo]);
    
    [self buildTable];
    }
 ];
}


- (void)scanForPeripherals
{
 if ([self.btComm activePeripheral])
    {
    if (self.btComm.activePeripheral.state == CBPeripheralStateConnected)
       {
       [self.btComm.manager cancelPeripheralConnection:self.btComm.activePeripheral];
       self.btComm.activePeripheral = nil;
       }
    }
    
 if ([self.btComm peripherals])
    {
    self.btComm.peripherals = nil;
    }
    
 self.btComm.delegate = self;
 NSLog(@"Scanning for peripherals.");
 [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(lookupUUIDs) userInfo:nil repeats:NO];
 
 self.peripheralMA = NSMutableArray.new;
 
 [self.btComm findPeripheralsWithTimeout:2];
}


- (void)peripheralFound:(CBPeripheral *)peripheral
{
 NSLog(@"Found peripheral with UUID: %@", peripheral.identifier.UUIDString);
 
 [self.peripheralMA addObject:peripheral];
}


- (void)lookupUUIDs
{
PFQuery *query;
NSMutableArray *mA;

 query = [PFQuery queryWithClassName:@"WirelessSwitch"];
 
 mA = NSMutableArray.new;
 
 for (CBPeripheral *per in self.peripheralMA) [mA addObject:per.identifier.UUIDString];
 
 [query whereKey:@"uuid" containedIn:mA];
 [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
    {
    if (!error)
       {
       NSLog(@"Switch already exists");
       self.noNewSwitchAV = [[UIAlertView alloc] initWithTitle:@"Fail" message:@"Did not find a new switch." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try again", @"Cancel", nil];
       [self.noNewSwitchAV show];
       }
    else
       {
       NSLog(@"Error: %@ %@", error, [error userInfo]);
       if (error.code == 101) [self buildTable];
       }
    }
 ];
}


- (void)buildTable
{
 self.counter++;
 
 if (self.counter < 3) return;   // wait until all three have completed
 
 [self.switchTV reloadData];
 
 [self.scanningAI stopAnimating];
 
 self.switchTV.userInteractionEnabled = YES;
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
