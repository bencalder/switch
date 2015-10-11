//
//  NewSwitchVC.m
//  switch
//
//  Created by Ben Calder on 4/29/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "NewSwitchVC.h"
#import "DataManager.h"
#import "BluetoothComm.h"
#import "EngageUnit.h"
#import "EngageAccessory.h"
#import "EngageFunction.h"
#import "EngageConnector.h"

@interface NewSwitchVC () <UITableViewDataSource, UITableViewDelegate, BTDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backB,
                                              *doneB;

@property (weak, nonatomic) IBOutlet UITableView *switchTV;

@property (strong, nonatomic) UIButton *keyboardDoneB;

@property (strong, nonatomic) NSMutableArray *sectionTitlesMA,
                                             *displayAccessoriesMA,
                                             *selectedAccessoriesMA,
                                             *peripheralMA;

@property (strong, nonatomic) DataManager *sharedData;

@property (nonatomic) BOOL choosingAccessory,
                           scanCompleted,
                           productIdAccepted,
                           nameAccepted,
                           connectorCountSelected;

@property (nonatomic) NSInteger choosingAccessoryI,
                                connectorCount;

@property (strong, nonatomic) BluetoothComm *btComm;

@property (strong, nonatomic) NSString *scanMessageS;

@property (strong, nonatomic) UIActivityIndicatorView *processingAI;

@end

@implementation NewSwitchVC


- (IBAction)buttonPress:(id)sender
{
 if (sender == self.backB)
    {
    [self.btComm stopScan];
    [self performSegueWithIdentifier:@"unwindtohomefromnewswitch" sender:self];
    }
 else
 if (sender == self.doneB) [self saveSwitch];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
 return self.sectionTitlesMA.count;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
 return self.sectionTitlesMA[section];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 if (section == 1)
    {
    if (self.connectorCountSelected) return 1;
    else                             return 4;
    }
 else
 if (section == 2)   // Accessories
    {
    if (self.choosingAccessory) return self.sharedData.accessories.count;
    else                        return self.connectorCount;
    }
 else return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
NSDictionary *d;
 
 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"subtitle"];
 
 if (indexPath.section == 0)    // Scan
    {
    cell.textLabel.text = self.scanMessageS;
    
    if (self.scanCompleted) [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    else
       {
       [cell setAccessoryType:UITableViewCellAccessoryNone];
       [cell addSubview:[self buildActivityIndicatorForCell:cell]];
       }
    }
 else
 if (indexPath.section == 1)    //  Number of connectors
    {
    if (self.connectorCountSelected) cell.textLabel.text = [NSString stringWithFormat:@"%li", self.connectorCount];
    else                             cell.textLabel.text = [NSString stringWithFormat:@"%li", indexPath.row + 1];
    }
 else
 if (indexPath.section == 2)   //  Accessories
    {
    if (self.choosingAccessory) cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", self.displayAccessoriesMA[indexPath.row][@"brand"], self.displayAccessoriesMA[indexPath.row][@"model"]];
    else
       {
       if (self.selectedAccessoriesMA.count < self.connectorCount)  //  user has not chosen an accessory for this connector
          {
          cell.textLabel.text = @"Choose an accessory";
          }
       else
          {
          d = self.selectedAccessoriesMA[indexPath.row];
       
          cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:13.0];
          cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", d[@"brand"], d[@"model"]];
          }
        
       cell.detailTextLabel.text = [NSString stringWithFormat:@"Connector %ld", indexPath.row + 1];
       }
    }

 return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
 if (indexPath.section == 0) // scan
    {
    if (!self.scanCompleted)
       {
       [self.processingAI startAnimating];
       [self scanForPeripherals];
       }
    }
 else
 if (indexPath.section == 1)
    {
    self.connectorCount = indexPath.row + 1;
    
    self.connectorCountSelected = YES;
    
    [self.sectionTitlesMA addObject:@"Select accessories"];
       
    [self.switchTV beginUpdates];
    [self.switchTV reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.switchTV insertSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.switchTV endUpdates];
    }
 else
 if (indexPath.section == 2) // accessory
    {
    if (self.choosingAccessory)
       {
       [self.selectedAccessoriesMA addObject:self.displayAccessoriesMA[indexPath.row]];
       
       self.choosingAccessory = NO;
       }
    else
       {
       self.choosingAccessory = YES;
       self.displayAccessoriesMA = [NSMutableArray arrayWithArray:self.sharedData.accessories];
       }
     
    [self.switchTV reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self showDoneButton];
    }
}


- (UIActivityIndicatorView *)buildActivityIndicatorForCell:(UITableViewCell *)cell
{
 self.processingAI = UIActivityIndicatorView.new;
 
 self.processingAI.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
 self.processingAI.frame                      = CGRectMake(cell.frame.size.width - 5, 0, 40, 40);
 self.processingAI.hidesWhenStopped           = YES;

 return self.processingAI;
}


- (void)buildAccessoryArrayForConnector:(NSInteger)connectorInt
{
 self.choosingAccessoryI = connectorInt;

 self.displayAccessoriesMA = NSMutableArray.new;
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

 [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(scanComplete:) userInfo:nil repeats:NO];
 
 self.peripheralMA = NSMutableArray.new;     // make new array to add UUID's to
 
 [self.btComm findPeripheralsWithTimeout:2];
}


- (void)peripheralFound:(CBPeripheral *)peripheral withRSSI:(NSNumber *)RSSI
{
 NSLog(@"Found peripheral with UUID: %@", peripheral.identifier.UUIDString);
 
 [self.peripheralMA addObject:peripheral];
}


- (void)scanComplete:(NSTimer *)timer
{
 [self.processingAI stopAnimating];

 if (self.peripheralMA.count > 0)                                          // found bluetooth devices with desired service
    {
    if (self.sharedData.savedSwitchData != nil)                            // at least one switch already exists on this device
       for (CBPeripheral *per in self.peripheralMA)                        // iterate through each matching Bluetooth device that was found
          for (NSDictionary *d in self.sharedData.savedSwitchData)         // iterate through each existing switch
             if ([per.identifier.UUIDString isEqualToString:d[@"uuid"]])   // match existing switches with found devices
                {
                [self.peripheralMA removeObject:per];                      // if it matches, then remove the existing switch from the array
                break;
                }
 
    if (self.peripheralMA.count == 0) self.scanMessageS = @"Didn't find any new switches.";   //  the scan only found existing switches
    else
    if (self.peripheralMA.count == 1)  // found one switch
       {
       self.scanCompleted = YES;
       self.scanMessageS  = @"Found your Engage switch!";
       [self.sectionTitlesMA addObject:@"Select number of connectors"];
       
       [self.switchTV beginUpdates];
       [self.switchTV reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
       [self.switchTV insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
       [self.switchTV endUpdates];
       }
    else self.scanMessageS = @"Found multiple switches. Try again.";
    }
 else self.scanMessageS = @"No switch found. Tap to scan again.";   // did not find a bluetooth device
 
 [self.switchTV reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}


- (void)showDoneButton
{
 BOOL show = YES;
 
 for (NSDictionary *d in self.selectedAccessoriesMA)
    if (d[@"accessoryBrand"] == nil) show = NO;
 
 if (show) self.doneB.hidden = NO;
}


- (void)saveSwitch
{
NSMutableArray *accessoryMA;
NSInteger relayIdx;

 self.sharedData.primaryUnit = [[EngageUnit alloc] init];
 
 accessoryMA = NSMutableArray.new;
 
 relayIdx = 1;
 
 for (NSDictionary *accessoryData in self.selectedAccessoriesMA)    //    loop through each of the connected accessories
    {
    EngageAccessory *accessory;
    NSMutableArray *connectorsMA, *functionsMA;
    
     accessory             = [[EngageAccessory alloc] init];
     accessory.objectId    = accessoryData[@"objectId"];
     accessory.brand       = accessoryData[@"brand"];
     accessory.model       = accessoryData[@"model"];
     accessory.currentDraw = ((NSNumber *)accessoryData[@"currentDraw"]).floatValue;
     
     connectorsMA = NSMutableArray.new;
     
     for (NSDictionary *connectorIDD in accessoryData[@"connectors"])
        for (NSDictionary *availableConnectorD in self.sharedData.connectors)
           if ([connectorIDD[@"objectId"] isEqualToString:availableConnectorD[@"objectId"]])
              {
              EngageConnector *connector;
              
               connector = [[EngageConnector alloc] init];
               
               if ([(connector.objectId = availableConnectorD[@"objectId"]) isEqualToString:@"S8e5Di6Y2E"])
                  {
                  connector.relays = @[[NSNumber numberWithInteger:relayIdx], [NSNumber numberWithInteger:relayIdx + 1]];
                  relayIdx         = relayIdx + 2;
                  }
               else
                  {
                  connector.relays = @[[NSNumber numberWithInteger:relayIdx]];
                  relayIdx++;
                  }
               
               connector.brand    = availableConnectorD[@"brand"];
               connector.pinCount = ((NSNumber *)availableConnectorD[@"brand"]).integerValue;

               
               [connectorsMA addObject:connector];
              }
     
     accessory.connectors = connectorsMA;
     
     for (NSDictionary *availableFunctionD in self.sharedData.functions)
        if ([accessoryData[@"primaryFunction"][@"objectId"] isEqualToString:availableFunctionD[@"objectId"]])
           {
           EngageFunction *primaryFunction;
           
            primaryFunction                = [[EngageFunction alloc] init];
            primaryFunction.objectId       = availableFunctionD[@"objectId"];
            primaryFunction.onName         = availableFunctionD[@"onName"];
            primaryFunction.signalDuration = ((NSNumber *)availableFunctionD[@"signalDuration"]).floatValue;
            primaryFunction.momentary      = ((NSNumber *)availableFunctionD[@"momentary"]).boolValue;
            
            accessory.primaryFunction = primaryFunction;
           }
     
     functionsMA = NSMutableArray.new;
     
     for (NSString *functionID in accessoryData[@"functions"])
        for (NSDictionary *availableFunctionD in self.sharedData.functions)
           if ([functionID isEqualToString:availableFunctionD[@"objectId"]])
              {
              EngageFunction *function;
           
               function                = [[EngageFunction alloc] init];
               function.objectId       = availableFunctionD[@"objectId"];
               function.onName         = availableFunctionD[@"onName"];
               function.signalDuration = ((NSNumber *)availableFunctionD[@"signalDuration"]).floatValue;
               function.momentary      = ((NSNumber *)availableFunctionD[@"momentary"]).boolValue;
               
               [functionsMA addObject:function];
              }
     
     accessory.functions = functionsMA;
     
     [accessoryMA addObject:accessory];
    }
 
 self.sharedData.primaryUnit.accessories = accessoryMA;
 
 NSUserDefaults *userDefaults;
 userDefaults = [NSUserDefaults standardUserDefaults];
 
 NSMutableArray *archiveArray;
 archiveArray = NSMutableArray.new;
 
 [archiveArray addObject:[NSKeyedArchiver archivedDataWithRootObject:self.sharedData.primaryUnit]];
 [userDefaults setObject:archiveArray forKey:@"primaryUnit"];
 
 [userDefaults synchronize];
 
 [self performSegueWithIdentifier:@"unwindtohomefromnewswitch" sender:self];
}


- (void)viewDidLoad
{
 [super viewDidLoad];
 
 self.sharedData = [DataManager sharedDataManager];
 
 self.btComm = self.sharedData.btComm;
 self.btComm.delegate = self;
 
 self.peripheralMA = NSMutableArray.new;

 self.sectionTitlesMA = NSMutableArray.new;
 self.peripheralMA    = NSMutableArray.new;
 [self.sectionTitlesMA addObject:@"Scan"];
 
 self.scanMessageS = @"Scanning";
 self.scanCompleted = NO;
 
 self.choosingAccessory = NO;
 
 self.connectorCountSelected = NO;
 
 self.displayAccessoriesMA = NSMutableArray.new;
 self.selectedAccessoriesMA = NSMutableArray.new;
}


- (void)viewDidAppear:(BOOL)animated
{
 [super viewDidAppear:animated];
 
 [self scanForPeripherals];
 [self.processingAI startAnimating];
}


- (void)didConnect:(CBPeripheral *)peripheral
{
 NSLog(@"Connected to peripheral in NewSwitchVC: %@", peripheral);
}


- (void)didDiscoverServices:(CBPeripheral *)peripheral
{
 NSLog(@"Discovered services on peripheral: %@", peripheral);
}


- (void)didDisconnect:(CBPeripheral *)peripheral
{
 NSLog(@"Disconnected from peripheral: %@", peripheral);
}


- (void)didReadRSSI:(NSNumber *)RSSI
{
 NSLog(@"RSSI: %i", RSSI.intValue);
}


- (void)didReceiveMemoryWarning
{
 [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
