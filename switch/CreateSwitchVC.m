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

@property (weak, nonatomic) IBOutlet UIButton *backB;
@property (weak, nonatomic) IBOutlet UIButton *doneB;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *scanningAI;

@property (weak, nonatomic) IBOutlet UITableView *switchTV;

@property (strong, nonatomic) BluetoothComm *btComm;

@property (strong, nonatomic) NSArray *boardA,
                                      *pinCountDisplayA,
                                      *pinCountA;

@property (strong, nonatomic) NSMutableArray *peripheralMA,
                                             *brandMA,
                                             *connectorsMA,
                                             *relaysMA;

@property (nonatomic) NSNumber *uuidI,
                               *boardI,
                               *connectorCountI,
                               *connectorSelectionI,
                               *brandI,
                               *pinCountI;

@property (nonatomic) NSInteger counter;

@property (strong, nonatomic) UISegmentedControl *connectorCountSC,
                                                 *brandSC,
                                                 *pinCountSC;

@property (strong, nonatomic) UIAlertView *noNewSwitchAV,
                                          *createdSwitchAV;

@end

@implementation CreateSwitchVC


- (IBAction)buttonPress:(id)sender
{
 if (sender == self.doneB)
    {
    PFObject *obj = (PFObject *)self.connectorsMA[self.connectorSelectionI.integerValue];   //  get the connector we just finished entering info for
    
    obj[@"brand"]    = self.brandMA[self.brandI.integerValue];
    obj[@"pinCount"] = self.pinCountA[self.pinCountI.integerValue];
    obj[@"relays"]   = self.relaysMA[self.connectorSelectionI.integerValue];
    
    [self.brandSC    setSelectedSegmentIndex:UISegmentedControlNoSegment];
    [self.pinCountSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
    
    [self.switchTV reloadData];
    
    if (self.connectorSelectionI == self.connectorCountI) [self saveConnectorsToParse];
    else
       {
       self.connectorSelectionI = [NSNumber numberWithInteger:self.connectorSelectionI.integerValue + 1];
       
       if (self.connectorCountI == self.connectorSelectionI) [self.doneB setTitle:@"Done" forState:UIControlStateNormal];  // if we have begun the last connector, change the title to Done
       }
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
 return 6;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
 if (section == 0) return @"UUID";
 else
 if (section == 1) return @"Board";
 else
 if (section == 2) return @"Connector Count";
 else
 if (section == 3) return [NSString stringWithFormat:@"Connector %i Brand", self.connectorSelectionI.intValue + 1];
 else
 if (section == 4) return [NSString stringWithFormat:@"Connector %i Pin Count", self.connectorSelectionI.intValue + 1];
 else
 if (section == 5) return [NSString stringWithFormat:@"Connector %i Relay Use", self.connectorSelectionI.intValue + 1];
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
 if (section == 3) return 1;  // connector brand
 else
 if (section == 4) return 1;  // connector pin count
 else
 if (section == 5) return 4;  // connector relay use
 else              return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
 UITableViewCell *cell = UITableViewCell.new;
 
 if (indexPath.section == 0)   //  uuid
    {
    CBPeripheral *per = (CBPeripheral *)self.peripheralMA[indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", per.name, per.identifier.UUIDString];
    
    if (self.uuidI && (indexPath.row == self.uuidI.integerValue)) [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
 else
 if (indexPath.section == 1)   //  board
    {
    cell.textLabel.text = ((PFObject *)self.boardA[indexPath.row])[@"name"];
    
    if (self.boardI && (indexPath.row == self.boardI.integerValue)) [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
 else
 if (indexPath.section == 2)   //  connector count
    {
    [cell.contentView addSubview:self.connectorCountSC];
    self.connectorCountSC.frame = cell.frame;
    }
 else
 if (indexPath.section == 3)   // connector brand
    {
    [cell.contentView addSubview:self.brandSC];
    self.brandSC.frame = cell.frame;
    }
 else
 if (indexPath.section == 4)   // connector pin count
    {
    [cell.contentView addSubview:self.pinCountSC];
    self.pinCountSC.frame = cell.frame;
    }
 if (indexPath.section == 5)   // connector relay use
    {
    cell.textLabel.text = [NSString stringWithFormat:@"%li", indexPath.row + 1];
    }

 return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
 
 cell = [tableView cellForRowAtIndexPath:indexPath];
 
 if (indexPath.section == 0)   //  UUID
    {
    if (self.uuidI) [[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.uuidI.integerValue inSection:indexPath.section]] setAccessoryType:UITableViewCellAccessoryNone];   // set the previously selected row to none
    
    self.uuidI = [NSNumber numberWithInteger:indexPath.row];
    
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
 else
 if (indexPath.section == 1)   //  Board
    {
    if (self.boardI) [[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.boardI.integerValue inSection:indexPath.section]] setAccessoryType:UITableViewCellAccessoryNone];   // set the previously selected row to none
    
    self.boardI = [NSNumber numberWithInteger:indexPath.row];
    
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
 else
 if (indexPath.section == 5)   //  Relays
    {
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark)
       {
       [cell setAccessoryType:UITableViewCellAccessoryNone];
       
       for (int i = 0; i < ((NSMutableArray *)self.relaysMA[self.connectorSelectionI.integerValue]).count; i++)
          {
          if ([(NSNumber *)self.relaysMA[self.connectorSelectionI.integerValue][i] isEqualToNumber:[NSNumber numberWithInteger:indexPath.row + 1]])   //  remove the correct number from the array
             [self.relaysMA[self.connectorSelectionI.integerValue] removeObjectAtIndex:i];
          }
       }
    else
       {    // set checkmark and add to array
       [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
       [self.relaysMA[self.connectorSelectionI.integerValue] addObject:[NSNumber numberWithInteger:indexPath.row + 1]];
       }
    }
}


- (void)connectorCount:(id)sender  // user selected the count of connectors
{
 self.connectorCountI = [NSNumber numberWithInteger:self.connectorCountSC.selectedSegmentIndex];
 
 [self createConnectorDicts];
}


- (void)brandSelection:(id)sender   //  user selected the brand of the connector
{
 self.brandI = [NSNumber numberWithInteger:self.brandSC.selectedSegmentIndex];
}


- (void)pinCountSelection:(id)sender   //  user selected the brand of the connector
{
 self.pinCountI = [NSNumber numberWithInteger:self.pinCountSC.selectedSegmentIndex];
}


- (void)createConnectorDicts
{
 self.connectorsMA = NSMutableArray.new;
 
 for (int i = -1; i < self.connectorCountI.integerValue; i++)   // self.connectorCountI is zero relative, so i needs to start at -1
    {
    PFObject *connector = [PFObject objectWithClassName:@"SwitchConnector"];   // create the connector objects
    [self.connectorsMA addObject:connector];
    
    NSMutableArray *mA = NSMutableArray.new;
    [self.relaysMA addObject:mA];
    }
}


- (void)saveConnectorsToParse
{
 [PFObject saveAllInBackground:self.connectorsMA block:^(BOOL succeeded, NSError *error)
    {
    if (succeeded)
       {
       for (PFObject *connector in self.connectorsMA)
          {
          NSLog(@"New connector object id: %@", connector.objectId);
          }
       
       [self saveSwitchDataToParse];
       }
    else
       {
       NSLog(@"Error: %@ %@", error, [error userInfo]);
       }
    }
 ];
}


- (void)saveSwitchDataToParse
{
 PFObject *wirelessSwitch = [PFObject objectWithClassName:@"WirelessSwitch"];
 
 wirelessSwitch[@"isSetup"]    = [NSNumber numberWithBool:NO];
 wirelessSwitch[@"uuid"]       = ((CBPeripheral *)self.peripheralMA[self.uuidI.integerValue]).identifier.UUIDString;
 wirelessSwitch[@"board"]      = (PFObject *)self.boardA[self.boardI.integerValue];
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
 if (alertView == self.noNewSwitchAV) [self resetForNewSwitch];
}


- (void)resetForNewSwitch
{
 [self.doneB setTitle:@"Next" forState:UIControlStateNormal];
 
 [self.switchTV scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
 self.switchTV.userInteractionEnabled = NO;

 self.uuidI  = nil;
 self.boardI = nil;
 self.connectorCountI = nil;
 self.connectorSelectionI = nil;
 
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
 [self lookupConnectorBrands];
 
 self.connectorCountSC = [[UISegmentedControl alloc] initWithItems:@[@"1", @"2", @"3", @"4"]];
 [self.connectorCountSC addTarget:self action:@selector(connectorCount:) forControlEvents:UIControlEventValueChanged];
 
 self.connectorSelectionI = 0;
 
 self.pinCountDisplayA = @[@"2", @"3"];
 self.pinCountA = @[[NSNumber numberWithInteger:2], [NSNumber numberWithInteger:3]];
 self.pinCountSC = [[UISegmentedControl alloc] initWithItems:self.pinCountDisplayA];
 [self.pinCountSC addTarget:self action:@selector(pinCountSelection:) forControlEvents:UIControlEventValueChanged];
 
 self.relaysMA = NSMutableArray.new;
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


- (void)lookupConnectorBrands
{
 PFQuery *query = [PFQuery queryWithClassName:@"SwitchConnectorBrand"];
 
 [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
    if (!error)
       {
       self.brandMA = NSMutableArray.new;
       for (PFObject *object in objects) [self.brandMA addObject:object[@"brand"]];
       }
    else NSLog(@"Error: %@ %@", error, [error userInfo]);
    
    self.brandSC = [[UISegmentedControl alloc] initWithItems:self.brandMA];
    [self.brandSC addTarget:self action:@selector(brandSelection:) forControlEvents:UIControlEventValueChanged];   // create segmented controller for brands
    
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
       self.noNewSwitchAV = [[UIAlertView alloc] initWithTitle:@"Fail" message:@"Did not find a new switch." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try again", nil];
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
