//
//  SwitchVC.m
//  switch
//
//  Created by Ben Calder on 4/24/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "SwitchVC.h"
#import "DataManager.h"
#import "HomeVC.h"
#import <Parse/Parse.h>
#import "SwitchEditVC.h"


@interface SwitchVC () < UITableViewDataSource, UITableViewDelegate, BTDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backB;
@property (weak, nonatomic) IBOutlet UIButton *disconnectB;

@property (weak, nonatomic) IBOutlet UITableView *switchTV;

@property (weak, nonatomic) IBOutlet UILabel *switchNameL;

@property (weak, nonatomic) IBOutlet UIImageView *signalStrengthIV;

@property (strong, nonatomic) PFObject *switchPFO;

@property (strong, nonatomic) NSArray *accessoriesA;

@property (strong, nonatomic) NSMutableArray *functionIdsMA,
                                             *functionsMA,
                                             *relaysMA,
                                             *currentStateMA,
                                             *relayStatusMA;

@property (strong, nonatomic) DataManager *sharedData;

@property (nonatomic) BOOL tableOpen;

@property (strong, nonatomic) NSIndexPath *selectedAccessoryIP;

@property (strong, nonatomic) NSTimer *rssiTimer;

@end

@implementation SwitchVC


- (IBAction)buttonPress:(id)sender
{
 if (sender == self.disconnectB) [self.btComm disconnect:self.btComm.activePeripheral];
}


- (IBAction)unwindFromSwitchEditToSwitch:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind from SwitchEditVC to SwitchVC");
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
 return self.accessoriesA.count;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
 return [NSString stringWithFormat:@"%@ %@", self.accessoriesA[section][@"accessoryBrand"], self.accessoriesA[section][@"accessoryModel"]];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
BOOL on;

 on = ((NSNumber *)self.relayStatusMA[section]).boolValue;
 
 if (on) return ((NSArray *)self.functionsMA[section]).count;
 else    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
NSDictionary *function;
BOOL on;
NSInteger relayI;
 
 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"subtitle"];
 
 function = self.functionsMA[indexPath.section][indexPath.row];
 
 cell.textLabel.text = function[@"onName"];
 
 if (indexPath.row > 0) relayI = ((NSNumber *)self.relaysMA[indexPath.section][1]).integerValue - 1;
 else                   relayI = ((NSNumber *)self.relaysMA[indexPath.section][0]).integerValue - 1;
 
 on = ((NSNumber *)self.relayStatusMA[relayI]).boolValue;
 
 if (on) [cell setAccessoryType:UITableViewCellAccessoryCheckmark];

 return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
PFObject *function;
NSNumber *momentary, *relayN;

 function = self.functionsMA[indexPath.section][indexPath.row];
 
 momentary = function[@"signalDuration"];
 
 if (indexPath.row > 0) relayN = self.relaysMA[indexPath.section][1];
 else                   relayN = self.relaysMA[indexPath.section][0];
 
 [self determineSerialCommand:relayN withMomentaryDelay:momentary atIndexPath:indexPath];
}


- (void)determineSerialCommand:(NSNumber *)relay withMomentaryDelay:(NSNumber *)delay atIndexPath:(NSIndexPath *)indexPath
{
NSInteger idx;
BOOL on;
NSNumber *num;
NSString *str;

 idx = relay.integerValue - 1;   // relayStatusMA is zero relative, so subtract 1 from the relay number

 on = ((NSNumber *)self.relayStatusMA[idx]).boolValue;   //  get the current setting of the relay

 for (PFObject *command in self.sharedData.serialCommands)
    {
    if ([command[@"relay"] isEqualToString:relay.stringValue])  // found the relay record
       {
       if (on) str = command[@"off"]; // relay is currently on, so turn it off
       else    str = command[@"on"];
       }
    }
    
 [self sendSerialCommand:str];  // send the command
 
 [self.relayStatusMA replaceObjectAtIndex:idx withObject:[NSNumber numberWithBool:!on]];   //  update the relay to the new status
 
 [self.switchTV reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
 
 if (delay.floatValue > 0.0f)
    {
    NSInvocation *invocation;
    
    num = [NSNumber numberWithFloat:0.0f];
    
    invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(determineSerialCommand:withMomentaryDelay:atIndexPath:)]];
    
    [invocation setTarget:self];
    [invocation setSelector:@selector(determineSerialCommand:withMomentaryDelay:atIndexPath:)];
    [invocation setArgument:&relay atIndex:2];
    [invocation setArgument:&num   atIndex:3];
    [invocation setArgument:&indexPath    atIndex:4];
    
    [NSTimer scheduledTimerWithTimeInterval:delay.floatValue invocation:invocation repeats:NO];
    }
}


- (void)sendSerialCommand:(NSString *)msg
{
 NSLog(@"Characteristic: %@", ((CBService *)self.btComm.activePeripheral.services[0]).characteristics[0]);

 [self.btComm.activePeripheral writeValue:[msg dataUsingEncoding:[NSString defaultCStringEncoding]] forCharacteristic:((CBService *)self.btComm.activePeripheral.services[0]).characteristics[0] type:CBCharacteristicWriteWithoutResponse];
}


- (void)viewDidLoad
{
 [super viewDidLoad];
 
 self.btComm.delegate = self;
 
 self.sharedData = [DataManager sharedDataManager];
 
 self.functionIdsMA = NSMutableArray.new;
 self.functionsMA   = NSMutableArray.new;
 self.relaysMA      = NSMutableArray.new;
 self.relayStatusMA = NSMutableArray.new;
 
 self.switchPFO = self.sharedData.selectedSwitchPFO;
 
 self.accessoriesA = self.switchPFO[@"connectors"];
 
 [self loadArrays];
 
 self.switchNameL.text = self.switchPFO[@"name"];
 
 [self setNameAndNotifier];
}


- (void)viewDidAppear:(BOOL)animated
{
 [super viewDidAppear:animated];
 
 if (self.btComm.activePeripheral == nil) self.switchTV.userInteractionEnabled = NO;
 
 [self.switchTV reloadData];
}


- (void)loadArrays
{
 for (int i = 0; i < self.accessoriesA.count; i++)
    {
    [self.functionIdsMA addObject:self.accessoriesA[i][@"accessoryFunctions"]];
    [self.relaysMA      addObject:self.accessoriesA[i][@"relays"]];
    }
 
 for (NSArray *ary in self.relaysMA)
    {
    for (int i = 0; i < ary.count; i++) [self.relayStatusMA addObject:[NSNumber numberWithBool:NO]];
    }
 
 NSMutableArray *mA;
 for (NSArray *ary in self.functionIdsMA)  // iterate through the arrays of function ID's
    {
    mA = NSMutableArray.new;
    
    for (int i = 0; i < ary.count; i++)    // iterate through each ID
       {
       for (PFObject *func in self.sharedData.functions)  // iterate through each function type from the server
          {
          if ([func.objectId isEqualToString:ary[i]])  // they match
             {
             [mA addObject:func];
             break;
             }
          }
       }
     
    [self.functionsMA addObject:mA];
    }
}


- (void)setNameAndNotifier
{
 if (self.btComm.activePeripheral != nil)
    {
    if ([self.sharedData.selectedSwitchPFO[@"uuid"] isEqualToString:self.btComm.activePeripheral.identifier.UUIDString])
       {
       self.switchNameL.text = [NSString stringWithFormat:@"%@\nCONNECTED", self.switchPFO[@"name"]];
       [self readRSSI:nil];
       self.switchTV.userInteractionEnabled = YES;
       }
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


- (void)didReceiveMemoryWarning
{
 [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)peripheralFound:(CBPeripheral *)peripheral withRSSI:(NSNumber *)RSSI
{
 NSLog(@"Peripheral found with RSSI in SwitchVC");
}


- (void)didConnect:(CBPeripheral *)peripheral
{
 NSLog(@"Connected to peripheral in switchVC: %@", peripheral);
 [self setNameAndNotifier];
}


- (void)didDisconnect:(CBPeripheral *)peripheral
{
 NSLog(@"Disconnected peripheral in SwitchVC");
 self.switchNameL.text = [NSString stringWithFormat:@"%@\nNOT CONNECTED",self.switchPFO[@"name"]];
 self.switchTV.userInteractionEnabled = NO;
}


- (void)didDiscoverServices:(CBPeripheral *)peripheral
{

}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
 if ([segue.identifier isEqualToString:@"unwindtohomefromswitch"]) ((HomeVC *)[segue destinationViewController]).btComm = self.btComm;
 else
 if ([segue.identifier isEqualToString:@"switchtoswitchedit"]) ((SwitchEditVC *)[segue destinationViewController]).btComm = self.btComm;
}



@end
