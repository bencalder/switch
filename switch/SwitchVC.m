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
 return ((NSArray *)self.functionsMA[section]).count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
NSDictionary *function;
 
 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"subtitle"];
 
 function = self.functionsMA[indexPath.section][indexPath.row];
 
 cell.textLabel.text = function[@"onName"];

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
       if (on)   // relay is currently on, so turn it off
          {
          str = command[@"off"];
          [[self.switchTV cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryNone];
          }
       else
          {
          str = command[@"on"];
          [[self.switchTV cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
          }
       }
    }
    
 [self sendSerialCommand:str];  // send the command
 
 [self.relayStatusMA replaceObjectAtIndex:idx withObject:[NSNumber numberWithBool:!on]];   //  update the relay to the new status
 
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
 [self.btComm.activePeripheral writeValue:[msg dataUsingEncoding:[NSString defaultCStringEncoding]] forCharacteristic:((CBService *)self.btComm.activePeripheral.services[0]).characteristics[0] type:CBCharacteristicWriteWithoutResponse];

}


- (void)viewDidLoad
{
 [super viewDidLoad];
 
 self.sharedData = [DataManager sharedDataManager];
 
 self.functionIdsMA = NSMutableArray.new;
 self.functionsMA   = NSMutableArray.new;
 self.relaysMA      = NSMutableArray.new;
 self.relayStatusMA = NSMutableArray.new;
}


- (void)viewDidAppear:(BOOL)animated
{
 [super viewDidAppear:animated];
 
 self.switchPFO = self.sharedData.selectedSwitchPFO;
 
 self.accessoriesA = self.switchPFO[@"connectors"];
 
 [self loadArrays];
 
 self.switchNameL.text = self.switchPFO[@"name"];
 
 [self.switchTV reloadData];
}


- (void)loadArrays
{
 for (int i = 0; i < self.accessoriesA.count; i++)
    {
    [self.functionIdsMA addObject:self.accessoriesA[i][@"accessoryFunctions"]];
    [self.relaysMA    addObject:self.accessoriesA[i][@"relays"]];
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


- (void)didReceiveMemoryWarning
{
 [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setConnect
{
 NSLog(@"set connect switchVC");
}


- (void)didConnect:(CBPeripheral *)peripheral
{
 NSLog(@"Connected to peripheral in switch: %@", peripheral);
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
 [self.btComm stopScan];
 
 if ([segue.identifier isEqualToString:@"unwindtohomefromswitch"]) ((HomeVC *)[segue destinationViewController]).btComm = self.btComm;
 else
 if ([segue.identifier isEqualToString:@"switchtoswitchedit"]) ((SwitchEditVC *)[segue destinationViewController]).btComm = self.btComm;
}



@end
