//
//  ViewController.m
//  switch
//
//  Created by Ben Calder on 4/1/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "ViewController.h"
#import "PeripheralVC.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *scanB;

@property (weak, nonatomic) IBOutlet UITableView *deviceTV;

@property (strong, nonatomic) BluetoothComm *btComm;

@property (strong, nonatomic) NSString *uuidS;

@end

@implementation ViewController


- (IBAction)buttonPresses:(id)sender
{
 if (sender == self.scanB) [self scanForPeripherals];
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
    [self.deviceTV reloadData];
    }
    
 self.btComm.delegate = self;
 NSLog(@"Scanning");
 [self.scanB setTitle:@"Scanning"];
 [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    
 [self.btComm findPeripheralsWithTimeout:5];
}


- (void)scanTimer:(NSTimer *)timer
{
 [self.scanB setTitle:@"Scan"];
}


- (void)peripheralFound:(CBPeripheral *)peripheral
{
 [self.deviceTV reloadData];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
CBPeripheral *peripheral;
 
 cell = UITableViewCell.new;
 peripheral = self.btComm.peripherals[indexPath.row];
 
 cell.textLabel.text = peripheral.name;

 return cell;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 return self.btComm.peripherals.count;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
 return @"Available Bluetooth Devices";
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
 [self.btComm connect:self.btComm.peripherals[indexPath.row]];
 
 [self performSegueWithIdentifier:@"ScanToPeripheralSegue" sender:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
 [self.btComm stopScan];
 
 ((PeripheralVC *)[segue destinationViewController]).btComm = self.btComm;    //  pass off BluetoothComm delegate responsibilities to PeripheralVC
}


- (void)viewDidLoad
{
 [super viewDidLoad];
 
 self.btComm = BluetoothComm.new;
 [self.btComm setup];
 self.btComm.delegate = self;
}


- (void)didReceiveMemoryWarning
{
 [super didReceiveMemoryWarning];
 // Dispose of any resources that can be recreated.
}


@end
