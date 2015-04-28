//
//  WriteVC.m
//  switch
//
//  Created by Ben Calder on 4/27/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "WriteVC.h"
#import "BluetoothComm.h"

@interface WriteVC () <UITableViewDelegate, UITableViewDataSource, BTDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backB;
@property (weak, nonatomic) IBOutlet UIButton *writeB;
@property (weak, nonatomic) IBOutlet UIButton *readB;

@property (weak, nonatomic) IBOutlet UITableView *peripheralTV;

@property (weak, nonatomic) IBOutlet UILabel *connectedL;

@property (strong, nonatomic) BluetoothComm *btComm;

@property (strong, nonatomic) NSMutableArray *peripheralMA;

@property (strong, nonatomic) UIRefreshControl *peripheralRC;

@property (strong, nonatomic) CBPeripheral *connectedP;

@end

@implementation WriteVC


- (IBAction)buttonPress:(id)sender
{
 if (sender == self.readB)
    {
    [self read];
    }

}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
CBPeripheral *peripheral;
 
 cell = UITableViewCell.new;
 peripheral = self.peripheralMA[indexPath.row];
 
 cell.textLabel.text = peripheral.name;

 return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 return self.peripheralMA.count;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
 [self.btComm connect:self.peripheralMA[indexPath.row]];
}


- (void)didConnect:(CBPeripheral *)peripheral
{
 NSLog(@"Connected to peripheral in switch: %@", peripheral);
 self.connectedL.text = peripheral.identifier.UUIDString;
 
 self.connectedP = peripheral;
 
 [peripheral discoverServices:nil];
}


- (void)read
{
 for (CBService *service in self.connectedP.services)
    {
     NSLog(@"Service: %@ with UUID: %@", service, service.UUID.UUIDString);
     
     for (CBCharacteristic *charac in service.characteristics)
        {
        NSLog(@"Characteristic: %@ with UUID: %@", charac, charac.UUID.UUIDString);
//        [self.connectedP writeValue:[@"NEWVALUE"dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:charac type:CBCharacteristicWriteWithResponse];
//        [self.connectedP writeValue:[@"NEWVALUE"dataUsingEncoding:NSUTF8StringEncoding] forDescriptor:charac.descriptors[0]];
        }
     }
}


- (void)viewDidLoad
{
 [super viewDidLoad];

 self.btComm = BluetoothComm.new;
 [self.btComm setup];
 self.btComm.delegate = self;
 
 self.peripheralRC = UIRefreshControl.new;
 [self.peripheralRC addTarget:self action:@selector(scanForPeripherals) forControlEvents:UIControlEventValueChanged];
 
 [self.peripheralTV addSubview:self.peripheralRC];
}


- (void)scanForPeripherals
{
 
 self.peripheralMA = NSMutableArray.new;

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
 
 [self.btComm findPeripheralsWithTimeout:2];
}


- (void)peripheralFound:(CBPeripheral *)peripheral
{
 NSLog(@"Found peripheral with UUID: %@", peripheral.identifier.UUIDString);
 
 [self.peripheralRC endRefreshing];
 
 [self.peripheralMA addObject:peripheral];
 [self.peripheralTV reloadData];
}


- (void)didDisconnect:(CBPeripheral *)peripheral
{
 NSLog(@"Disconnected from peripheral: %@", peripheral);

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
