//
//  PeripheralVC.m
//  switch
//
//  Created by Ben Calder on 4/1/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "PeripheralVC.h"
#import "ViewController.h"

@interface PeripheralVC () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *disconnectB;

@property (weak, nonatomic) IBOutlet UIButton *readB;

@property (weak, nonatomic) IBOutlet UILabel *connectedL;
@property (weak, nonatomic) IBOutlet UILabel *uuidL;

@property (weak, nonatomic) IBOutlet UITableView *switchTV;

@property (strong, nonatomic) NSTimer *rssiT,
                                      *optionsT;

@property (strong, nonatomic) NSMutableArray *onOffMA;

@property (strong, nonatomic) NSArray *titlesA,
                                      *onCommandsA,
                                      *offCommandsA;

@end

@implementation PeripheralVC


- (IBAction)buttonPresses:(id)sender
{
 if (sender == self.disconnectB)
    {
    if (self.btComm.activePeripheral) [self.btComm disconnect:self.btComm.activePeripheral];
    }
 else
 if (sender == self.readB) [self.btComm.activePeripheral readValueForCharacteristic:((CBService *)self.btComm.activePeripheral.services[0]).characteristics[0]];

}


//- (void)sendCommand:(NSNumber *)offOn atRow:(NSInteger)row    //  offOnAll: 0 = off, 1 = on
//{
//NSString *str;
//
// if (row == 4) str = @"d";  // turn them all on
// else
// if (row == 5) str = @"n";  // turn them all off
// else
// if (offOn.intValue == 0) str = self.offCommandsA[row];
// else                     str = self.onCommandsA[row];
// 
// [self sendMsgToBT:str];
//}


- (void)sendCommand:(NSNumber *)offOn atRow:(NSInteger)row    //  offOnAll: 0 = off, 1 = on
{
NSString *str;

 if ((row == 2) || (row == 3))   //  strobe and high/medium
    {
    NSTimeInterval time;
    
     str = @"g";  // turn on the third relay
    
     if (row == 2) time = 0.2;  // if high/medium, turn off in 0.2 seconds
     else          time = 2.5;
    
     self.optionsT = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(optionsOff) userInfo:nil repeats:NO];
    }
 else
 if (row == 4) str = @"d";  // turn both on
 else
 if (row == 5) str = @"n";  // turn them all off
 else
 if (offOn.intValue == 0) str = self.offCommandsA[row];
 else                     str = self.onCommandsA[row];
 
 [self sendMsgToBT:str];
}


- (void)sendMsgToBT:(NSString *)msg  
{
 NSLog(@"Writing to characteristic: %@", ((CBService *)self.btComm.activePeripheral.services[0]).characteristics[0]);
 
 [self.btComm.activePeripheral writeValue:[msg dataUsingEncoding:[NSString defaultCStringEncoding]] forCharacteristic:((CBService *)self.btComm.activePeripheral.services[0]).characteristics[0] type:CBCharacteristicWriteWithoutResponse];
}


- (void)optionsOff
{
 [self sendMsgToBT:@"q"];
}


- (void)rssiReading
{
 [self.btComm.activePeripheral readRSSI];

 if (self.btComm.rssiN)
    {
    if ([self.btComm.rssiN intValue] == 0)
       {
       self.connectedL.text = @"Not connected";
       self.connectedL.backgroundColor = [UIColor grayColor];
       }
    else
       {
       self.connectedL.text = @"Connected";
       
       if ([self.btComm.rssiN intValue] > -75)  self.connectedL.backgroundColor = [UIColor greenColor];
       else
       if ([self.btComm.rssiN intValue] > -85)  self.connectedL.backgroundColor = [UIColor yellowColor];
       else
       if ([self.btComm.rssiN intValue] > -100) self.connectedL.backgroundColor = [UIColor redColor];
       }
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
 
 cell = UITableViewCell.new;
 
 cell.textLabel.text = self.titlesA[indexPath.row];

 return cell;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 return 6;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
 return @"Switches";
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
NSNumber *num;
 
 cell = [tableView cellForRowAtIndexPath:indexPath];
 
 if (indexPath.row < 4)
    {
    if ([self.onOffMA[indexPath.row] isEqualToNumber:[NSNumber numberWithInt:0]])  // switch is currently off
       {
       num = [NSNumber numberWithInt:1];    // turn on
       [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
       }
    else
       {
       num = [NSNumber numberWithInt:0];    // turn off
       [cell setAccessoryType:UITableViewCellAccessoryNone];
       }
     
    [self.onOffMA setObject:num atIndexedSubscript:indexPath.row];  // update onOff array to current setting
    }
 else
    {
    if (indexPath.row == 4) num = [NSNumber numberWithInt:1];   //  if it's the 5th cell, then turn all of them on
    else                    num = [NSNumber numberWithInt:0];
    
    for (int i = 0; i < 4; i++)
        {
        [self.onOffMA setObject:num atIndexedSubscript:i];   // update every object in the onOff array to the correct setting
        
        cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        
        if (num == [NSNumber numberWithInt:1]) [cell setAccessoryType:UITableViewCellAccessoryCheckmark];  //  update every cell
        else                                   [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    }
 
 [self sendCommand:num atRow:indexPath.row];
}


- (void)viewDidLoad
{
 [super viewDidLoad];
 
 self.btComm.delegate = self;
 
 self.rssiT = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(rssiReading) userInfo:nil repeats:YES];
 
 self.onOffMA = [NSMutableArray arrayWithArray:@[@0, @0, @0, @0]];
 self.titlesA = @[@"Rigid Industries 20\" bar", @"Baja Designs Clear", @"High/Medium", @"Strobe", @"Both on", @"Both off"];
// self.titlesA = @[@"Switch 1", @"Switch 2", @"Switch 3", @"Switch 4", @"All on", @"All off"];

 self.onCommandsA  = @[@"e", @"f", @"g", @"h"];   // ASCII serial commands
 self.offCommandsA = @[@"o", @"p", @"q", @"r"];
}


- (void)didReceiveMemoryWarning
{
 [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)setConnect
{
 self.uuidL.text = self.btComm.activePeripheral.identifier.UUIDString;
 NSLog(@"Connected to peripheral");
}


-(void)setDisconnect
{
 NSLog(@"Disconnected from peripheral");
 [self.navigationController popViewControllerAnimated:YES];
}


@end
