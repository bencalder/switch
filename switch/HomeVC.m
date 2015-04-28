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
#import "SwitchVC.h"

@interface HomeVC () <UITableViewDelegate, UITableViewDataSource, BTDelegate>

@property (weak, nonatomic) IBOutlet UITableView *switchTV;

@property (strong, nonatomic) NSArray *switchA,
                                      *functionsA,
                                      *switchDataA,
                                      *retrievedPeripheralsA;

@property (strong, nonatomic) NSMutableArray *switchAccessoriesMA,
                                             *btPeripheralsMA,
                                             *switchObjectIdMA,
                                             *switchUUIDMA;

@property (nonatomic) NSInteger counter;

@property (strong, nonatomic) NSIndexPath *selectedAccessoryIP;

@property (strong, nonatomic) DataManager *sharedData;

@property (strong, nonatomic) UIRefreshControl *switchRC;

@end


@implementation HomeVC


- (IBAction)unwindFromAddSwitch:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind from AddSwitchVC");
}


- (IBAction)unwindFromCreateSwitch:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind from CreateSwitchVC");
}


- (IBAction)unwindToHomeFromSummary:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind to Home from SummaryVC");
}


- (IBAction)unwindFromSwitch:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind from SwitchVC");
}


- (IBAction)unwindFromWrite:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind from WriteVC");
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
 return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 return self.switchA.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
NSDictionary *switchD;
NSUUID *uuid;
 
 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"subtitle"];
 
 switchD = self.switchA[indexPath.row];
 
 uuid = self.switchUUIDMA[indexPath.row];
 
 cell.textLabel.text = switchD[@"name"];
 
 for (CBPeripheral *bt in self.btPeripheralsMA)
    {
    if ([bt.identifier.UUIDString isEqualToString:uuid.UUIDString])  //  found bluetooth device that matches a known switch
       {
       cell.detailTextLabel.text = @"AVAILABLE";
       break;
       }
    else cell.detailTextLabel.text = @"DEVICE NOT FOUND";
    }

 return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
CBPeripheral *selected;
NSUUID *uuid;

 self.sharedData.selectedSwitchPFO = self.switchA[indexPath.row];
 
 uuid = self.switchUUIDMA[indexPath.row];
 
 for (CBPeripheral *bt in self.btPeripheralsMA)
    {
    if ([bt.identifier.UUIDString isEqualToString:uuid.UUIDString])
       {
       selected = bt;
       [self.btComm connect:selected];
       break;
       }
    }
}


- (void)setConnect
{
 NSLog(@"set connect home");
}


- (void)didConnect:(CBPeripheral *)peripheral
{
 NSLog(@"Connected to peripheral in home: %@", peripheral);
 
 [self performSegueWithIdentifier:@"hometoswitch" sender:self];
}


- (void)didDiscoverServices:(CBPeripheral *)peripheral
{
 NSLog(@"Discovered services on peripheral: %@", peripheral);
}


- (void)didDisconnect:(CBPeripheral *)peripheral
{
 NSLog(@"Disconnected from peripheral: %@", peripheral);

}


- (void)viewDidLoad
{
 [super viewDidLoad];

 self.btComm = BluetoothComm.new;
 [self.btComm setup];
 self.btComm.delegate = self;
 
 self.sharedData = [DataManager sharedDataManager];
 self.sharedData.btComm = self.btComm;
 
 self.switchRC = UIRefreshControl.new;
 [self.switchRC addTarget:self action:@selector(scanForPeripherals) forControlEvents:UIControlEventValueChanged];
 [self.switchTV addSubview:self.switchRC];
}


- (void)viewDidAppear:(BOOL)animated
{
 [super viewDidAppear:animated];
 
 [self loadSwitchArray];
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
 
 NSLog(@"Scanning");
 
 [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    
 [self.btComm findPeripheralsWithTimeout:2];
}


- (void)scanTimer:(NSTimer *)timer
{

}


- (void)peripheralFound:(CBPeripheral *)peripheral
{
 [self.switchRC endRefreshing];
 
 NSLog(@"Found peripheral with UUID: %@", peripheral.identifier.UUIDString);

 [self.btPeripheralsMA addObject:peripheral];

 [self.switchTV reloadData];
}


- (void)loadSwitchArray
{
 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
 
 if ((self.switchDataA = [defaults objectForKey:@"switchArray"]) != nil)  // if switch data is already saved on phone
    {
    self.counter = 0;
    
    self.switchObjectIdMA = NSMutableArray.new;
    self.switchUUIDMA     = NSMutableArray.new;
    
    for (NSDictionary *d in self.switchDataA)
       {
       [self.switchObjectIdMA addObject:d[@"objectId"]];
       [self.switchUUIDMA     addObject:[[NSUUID alloc] initWithUUIDString:d[@"uuid"]]];
       }
 
    self.retrievedPeripheralsA = [self.btComm.manager retrievePeripheralsWithIdentifiers:self.switchUUIDMA];
    
    [self lookupSwitchData];
    [self lookupFunctions];
    [self lookupSerialCommands];
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
       [self loadAccessoryDataAndScan];
       }
    else NSLog(@"Error: %@ %@", error, [error userInfo]);
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
       [self loadAccessoryDataAndScan];
       }
    else NSLog(@"Error: %@ %@", error, [error userInfo]);
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
       [self loadAccessoryDataAndScan];
       }
    else NSLog(@"Error: %@ %@", error, [error userInfo]);
    }
 ];
}


- (void)loadAccessoryDataAndScan
{
 self.counter++;
 
 if (self.counter < 3) return;

 [self scanForPeripherals];
 
 self.switchTV.hidden = NO;
}


- (void)didReceiveMemoryWarning
{
 [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
 if ([segue.identifier isEqualToString:@"hometoswitch"])
    {
    [self.btComm stopScan];
     
    ((SwitchVC *)[segue destinationViewController]).btComm = self.btComm;
    }
}


@end
