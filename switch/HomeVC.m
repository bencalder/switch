//
//  HomeVC.m
//  switch
//
//  Created by Ben Calder on 4/21/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "HomeVC.h"
#import <Parse/Parse.h>
#import "DataManager.h"
#import "EngageConnector.h"
#import "EngageFunction.h"
#import "EngageSerialCommand.h"
#import "EngageAccessory.h"
#import "EngageUnit.h"

@interface HomeVC () <UITableViewDelegate, UITableViewDataSource, BTDelegate>

@property (weak, nonatomic) IBOutlet UIButton *addSwitchB,
                                              *editB;

@property (weak, nonatomic) IBOutlet UITableView *switchTV;

@property (weak, nonatomic) IBOutlet UIImageView *signalStrengthIV;

@property (weak, nonatomic) IBOutlet UILabel *messageL;

@property (weak, nonatomic) IBOutlet UILabel *switchNameL;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingAI;

@property (strong, nonatomic) NSTimer *rssiTimer;

@property (strong, nonatomic) NSArray *switchA,
                                      *functionsA,
                                      *retrievedPeripheralsA;

@property (strong, nonatomic) NSArray *accessoriesA;

@property (strong, nonatomic) NSMutableArray *switchAccessoriesMA,
                                             *btPeripheralsMA,
                                             *btRSSIMA,
                                             *switchObjectIdMA,
                                             *switchUUIDMA;

@property (strong, nonatomic) NSMutableArray *functionIdsMA,
                                             *functionsMA,
                                             *relaysMA,
                                             *currentStateMA,
                                             *relayStatusMA;

@property (nonatomic) NSInteger counter;

@property (strong, nonatomic) NSIndexPath *selectedAccessoryIP;

@property (strong, nonatomic) DataManager *sharedData;

@property (strong, nonatomic) CBPeripheral *connectedToNewP;

@property (nonatomic) BOOL connectToNewMode;

@end


@implementation HomeVC


- (IBAction)buttonPress:(id)sender
{
 if (sender == self.editB)
    {
    [self performSegueWithIdentifier:@"hometoswitchedit" sender:self];
    }
}


- (IBAction)unwindFromNewSwitch:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind to HomeVC from NewSwitchVC");

 self.accessoriesA = self.sharedData.primaryUnit.accessories;
 
 [self loadArrays];
 
 [self.switchTV reloadData];
 
 self.messageL.hidden   = YES;
 self.switchTV.hidden   = NO;
 self.addSwitchB.hidden = YES;
 self.editB.hidden      = NO;
 
 [self.btComm connect:self.btComm.peripherals[0]];
}


- (IBAction)unwindFromCreateSwitch:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind to HomeVC from CreateSwitchVC");
}


- (IBAction)unwindFromWrite:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind to HomeVC from WriteVC");
}


- (IBAction)unwindFromSwitchEditToHome:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind to HomeVC from SwitchEditVC");
 
 self.switchTV.hidden = YES;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
 return self.accessoriesA.count;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
EngageAccessory *accessory;

 accessory = self.accessoriesA[section];
 
 return [NSString stringWithFormat:@"%@ %@", accessory.brand, accessory.model];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
BOOL on;
NSInteger relay;

 relay = ((NSNumber *)self.relaysMA[section][0]).integerValue;    //  find the "base" relay for each accessory and subtract 1 because relayStatusMA is zero relative

 on = ((NSNumber *)self.relayStatusMA[relay - 1]).boolValue;
 
 if (on) return ((EngageAccessory *)self.accessoriesA[section]).functions.count;
 else    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
BOOL on;
NSInteger relayI;
EngageFunction *function;

 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"subtitle"];
 
 function = ((EngageAccessory *)self.accessoriesA[indexPath.section]).functions[indexPath.row];

 cell.textLabel.text = function.onName;
 
 if (indexPath.row > 0) relayI = ((NSNumber *)self.relaysMA[indexPath.section][1]).integerValue - 1;   //  get the number of the relay (1 - 4) and subtract 1 in order to index into relayStatusMA
 else                   relayI = ((NSNumber *)self.relaysMA[indexPath.section][0]).integerValue - 1;
 
 on = ((NSNumber *)self.relayStatusMA[relayI]).boolValue;
 
 if (on) [cell setAccessoryType:UITableViewCellAccessoryCheckmark];

 return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
NSNumber *relayN;
float momentary;
EngageFunction *function;
 
 function = ((EngageAccessory *)self.accessoriesA[indexPath.section]).functions[indexPath.row];
 
 momentary = function.signalDuration;
 
 if (indexPath.row > 0) relayN = self.relaysMA[indexPath.section][1];
 else                   relayN = self.relaysMA[indexPath.section][0];
 
 [self determineSerialCommand:relayN withMomentaryDelay:momentary atIndexPath:indexPath];
}


- (void)determineSerialCommand:(NSNumber *)relay withMomentaryDelay:(float)delay atIndexPath:(NSIndexPath *)indexPath
{
NSInteger idx;
BOOL on;
NSNumber *num;
NSString *str;

 idx = relay.integerValue - 1;   // relayStatusMA is zero relative, so subtract 1 from the relay number
 
 NSLog(@"Relay number: %i  Relay index: %li", relay.intValue, (long)idx);

 on = ((NSNumber *)self.relayStatusMA[idx]).boolValue;   //  get the current setting of the relay

 for (NSDictionary *command in self.sharedData.serialCommands)
    {
    if ([command[@"relay"] isEqualToString:relay.stringValue])  // found the relay record
       {
       if (on) str = command[@"off"]; // relay is currently on, so turn it off
       else    str = command[@"on"];
       }
    }
 
 NSLog(@"Sent command: %@", str);
 [self sendSerialCommand:str];  // send the command
 
 [self.relayStatusMA replaceObjectAtIndex:idx withObject:[NSNumber numberWithBool:!on]];   //  update the relay to the new status
 
 [self.switchTV reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
 
 if (delay > 0.0f && !on)
    {
    NSInvocation *invocation;
    
    num = [NSNumber numberWithFloat:0.0f];
    
    invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(determineSerialCommand:withMomentaryDelay:atIndexPath:)]];
    
    [invocation setTarget:self];
    [invocation setSelector:@selector(determineSerialCommand:withMomentaryDelay:atIndexPath:)];
    [invocation setArgument:&relay     atIndex:2];
    [invocation setArgument:&num       atIndex:3];
    [invocation setArgument:&indexPath atIndex:4];
    
    [NSTimer scheduledTimerWithTimeInterval:delay invocation:invocation repeats:NO];
    }
}


- (void)sendSerialCommand:(NSString *)msg
{
 NSLog(@"Characteristic: %@", ((CBService *)self.btComm.activePeripheral.services[0]).characteristics[0]);

 [self.btComm.activePeripheral writeValue:[msg dataUsingEncoding:[NSString defaultCStringEncoding]]
                        forCharacteristic:((CBService *)self.btComm.activePeripheral.services[0]).characteristics[0]
                                     type:CBCharacteristicWriteWithoutResponse];
}


- (void)addSignalStrengthToCell:(UITableViewCell *)cell withIndex:(int)index
{
UIImageView *iV;
NSNumber *sigStrengthN;
NSString *str;

 iV = UIImageView.new;
 iV.frame = CGRectMake(cell.frame.size.width - 10, 30, 30, 30);
 
 sigStrengthN = self.btRSSIMA[index];
 
 if (sigStrengthN.intValue > -60) str = @"icon_signalstrength_100.png";
 else
 if (sigStrengthN.intValue > -70) str = @"icon_signalstrength_80.png";
 else
 if (sigStrengthN.intValue > -80) str = @"icon_signalstrength_60.png";
 else
 if (sigStrengthN.intValue > -90) str = @"icon_signalstrength_40.png";
 else                             str = @"icon_signalstrength_20.png";
 
 iV.image = [UIImage imageNamed:str];
 
 [cell addSubview:iV];
}


- (void)didConnect:(CBPeripheral *)peripheral
{
 NSLog(@"Connected to peripheral in home: %@", peripheral);
 
 if (self.connectToNewMode)
    {
    self.connectToNewMode = NO;
    [self performSegueWithIdentifier:@"hometoswitch" sender:self];
    }
 
  [self setNameAndNotifier];
}


- (void)didDiscoverServices:(CBPeripheral *)peripheral
{
 NSLog(@"Discovered services on peripheral: %@", peripheral);
}


- (void)didDisconnect:(CBPeripheral *)peripheral
{
 NSLog(@"Disconnected from peripheral: %@", peripheral);
 
 if (self.connectToNewMode) [self.btComm connect:self.connectedToNewP];   //   if we're handling disconnect/reconnect then connect the one we want
}


- (void)viewDidLoad
{
 [super viewDidLoad];

 self.btComm = BluetoothComm.new;
 [self.btComm setup];
 self.btComm.delegate = self;
 
 self.sharedData        = [DataManager sharedDataManager];
 self.sharedData.btComm = self.btComm;
 
 self.messageL.text = @"You haven't added an Engage switch. Tap the + button above to get started.";
 
 self.connectToNewMode = NO;
 
// [self lookupFunctions];
// [self lookupSerialCommands];
// [self lookupAccessories];
// [self lookupConnectors];
 
 self.functionIdsMA = NSMutableArray.new;
 self.functionsMA   = NSMutableArray.new;
 self.relaysMA      = NSMutableArray.new;
 self.relayStatusMA = NSMutableArray.new;
 
 self.sharedData.accessories    = @[];
 self.sharedData.functions      = @[];
 self.sharedData.serialCommands = @[];
 self.sharedData.connectors     = @[];
 
 [self setNameAndNotifier];
 
 [self loadJSONFiles];
 
 NSArray *unarchiveArray;
 
 if ((unarchiveArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"primaryUnit"]) != nil)
    {
    for (NSData *primaryUnit in unarchiveArray) self.sharedData.primaryUnit = [NSKeyedUnarchiver unarchiveObjectWithData:primaryUnit];
    
    self.accessoriesA = self.sharedData.primaryUnit.accessories;
 
    [self loadArrays];
 
    self.messageL.hidden   = YES;
    self.switchTV.hidden   = NO;
    self.addSwitchB.hidden = YES;
    self.editB.hidden      = NO;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
 [super viewDidAppear:animated];
 
 self.btComm.delegate = self;
 
 if (self.btComm.activePeripheral == nil) [self loadSwitchArray];     //  no active peripheral exists so load new data and scan
 else                                     [self.switchTV reloadData]; // active peripheral exists so just reload the table to show which one is connected
 
 [self scanForPeripherals];
}


- (void)loadArrays
{
 for (EngageAccessory *accessory in self.accessoriesA)
    for (EngageConnector *connector in accessory.connectors)
       [self.relaysMA addObject:connector.relays];
 
 for (NSArray *ary in self.relaysMA)
    for (int i = 0; i < ary.count; i++)
       [self.relayStatusMA addObject:[NSNumber numberWithBool:NO]];
}


- (void)setNameAndNotifier
{
 if (self.btComm.activePeripheral != nil)
    {
    if ([self.sharedData.selectedSwitchPFO[@"uuid"] isEqualToString:self.btComm.activePeripheral.identifier.UUIDString])
       {
//       self.switchNameL.text = [NSString stringWithFormat:@"%@\nCONNECTED", self.switchPFO[@"name"]];
       [self readRSSI:nil];
       self.switchTV.userInteractionEnabled = YES;
       }
    }
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
 
 self.btPeripheralsMA = NSMutableArray.new;
 self.btRSSIMA        = NSMutableArray.new;
 
 NSLog(@"Scanning");
 
 [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    
 [self.btComm findPeripheralsWithTimeout:2];
}


- (void)scanTimer:(NSTimer *)timer
{
 [self.switchTV reloadData];
}


- (void)peripheralFound:(CBPeripheral *)peripheral withRSSI:(NSNumber *)RSSI
{
 [self.btPeripheralsMA addObject:peripheral];
 [self.btRSSIMA        addObject:RSSI];
 
 [self.btComm connect:peripheral];
}


- (void)loadSwitchArray
{
 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
 
 if ((self.sharedData.savedSwitchData = [defaults objectForKey:@"switchArray"]) != nil)  // if switch data is already saved on phone
    {
    self.counter = 0;
    
    self.switchObjectIdMA = NSMutableArray.new;
    self.switchUUIDMA     = NSMutableArray.new;
    
    for (NSDictionary *d in self.sharedData.savedSwitchData)
       {
       [self.switchObjectIdMA addObject:d[@"objectId"]];
       [self.switchUUIDMA     addObject:[[NSUUID alloc] initWithUUIDString:d[@"uuid"]]];
       }
 
    self.retrievedPeripheralsA = [self.btComm.manager retrievePeripheralsWithIdentifiers:self.switchUUIDMA];
    
    [self lookupSwitchData];
    }
}


- (void)readRSSI:(NSTimer *)timer
{
 [self.btComm.activePeripheral readRSSI];
}


- (void)didReadRSSI:(NSNumber *)RSSI
{
NSString *str;

 if (self.btComm.activePeripheral != nil) self.rssiTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(readRSSI:) userInfo:nil repeats:NO];
 
 if (RSSI.intValue == 0) return;

 if (RSSI.intValue > -60) str = @"icon_signalstrength_100.png";
 else
 if (RSSI.intValue > -70) str = @"icon_signalstrength_80.png";
 else
 if (RSSI.intValue > -80) str = @"icon_signalstrength_60.png";
 else
 if (RSSI.intValue > -90) str = @"icon_signalstrength_40.png";
 else                     str = @"icon_signalstrength_20.png";
 
 self.signalStrengthIV.image = [UIImage imageNamed:str];
}


- (void)loadJSONFiles
{
NSArray *dataPaths;
NSMutableArray *data;

 dataPaths = @[@"Accessory", @"AccessoryFunction", @"SerialCommand", @"Connector"];
 
 data = NSMutableArray.new;
 
 for (NSString *path in dataPaths)
    {
    NSError *error;
    NSString *fileContents;
    
     fileContents = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:path ofType:@"json"] encoding:NSUTF8StringEncoding error:&error];
     
     if (!error) [data addObject:[NSJSONSerialization JSONObjectWithData:[fileContents dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL]];
    }
 
 for (int i = 0; i < data.count; i++)
    switch (i)
       {
       case 0 : self.sharedData.accessories    = data[i];
       case 1 : self.sharedData.functions      = data[i];
       case 2 : self.sharedData.serialCommands = data[i];
       case 3 : self.sharedData.connectors     = data[i];
       }
}


- (void)lookupSwitchData
{
 PFQuery *query = [PFQuery queryWithClassName:@"WirelessSwitch"];
 
 [query whereKey:@"objectId" containedIn:self.switchObjectIdMA];
 
 [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
    if (!error)
       {
       self.switchA = objects;
       
       [self scanForPeripherals];
       
       self.switchTV.hidden = NO;
       [self.switchTV reloadData];
       }
    else NSLog(@"Error retrieving valid switches: %@ %@", error, [error userInfo]);
    }
 ];
}


- (void)lookupFunctions
{
 PFQuery *query = [PFQuery queryWithClassName:@"AccessoryFunction"];
 
 [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
    if (!error)
       {
       self.functionsA = objects;
       self.sharedData.functions = objects;
       [self serverCallsCompleted];
       }
    else NSLog(@"Error retrieving accessory functions: %@ %@", error, [error userInfo]);
    }
 ];
}


- (void)lookupSerialCommands
{
 PFQuery *query = [PFQuery queryWithClassName:@"SerialCommand"];
 
 [query orderByAscending:@"relay"];
 
 [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
    if (!error)
       {
       self.sharedData.serialCommands = objects;
       [self serverCallsCompleted];
       }
    else NSLog(@"Error retrieving serial commands: %@ %@", error, [error userInfo]);
    }
 ];
}


- (void)lookupAccessories
{
 PFQuery *query = [PFQuery queryWithClassName:@"Accessory"];
 
 [query orderByAscending:@"brand"];
 
 [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
    if (!error)
       {
       self.sharedData.accessories = objects;
       [self serverCallsCompleted];
       }
    else NSLog(@"Error retrieving accessories: %@ %@", error, [error userInfo]);
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
       self.sharedData.connectors = objects;
       [self serverCallsCompleted];
       }
    else NSLog(@"Error retrieving accessories: %@ %@", error, [error userInfo]);
    }
 ];
}


- (void)serverCallsCompleted
{
 self.counter++;
 
 if (self.counter < 4) return;

 [self.loadingAI stopAnimating];
}


- (void)didReceiveMemoryWarning
{
 [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
 [self.btComm stopScan];
 
}


@end
