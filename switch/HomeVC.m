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

@property (strong, nonatomic) NSArray *switchIdA,
                                      *switchA,
                                      *functionsA;

@property (strong, nonatomic) NSMutableArray *switchAccessoriesMA,
                                             *btPeripherals;

@property (nonatomic) NSInteger counter;

@property (strong, nonatomic) NSIndexPath *selectedAccessoryIP;

@property (strong, nonatomic) DataManager *sharedData;

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
 
 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"subtitle"];
 
 switchD = self.switchA[indexPath.row];
 
 cell.textLabel.text = switchD[@"name"];
 
 for (CBPeripheral *bt in self.btPeripherals)
    {
    if ([bt.identifier.UUIDString isEqualToString:switchD[@"uuid"]])  //  found bluetooth device that matches a known switch
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

 self.sharedData.selectedSwitchPFO = self.switchA[indexPath.row];
 
 for (CBPeripheral *bt in self.btPeripherals)
    {
    if ([bt.identifier.UUIDString isEqualToString:self.sharedData.selectedSwitchPFO[@"uuid"]])
       {
       selected = bt;
       break;
       }
    }

 [self.btComm connect:selected];
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


- (void)viewDidLoad
{
 [super viewDidLoad];

 self.btComm = BluetoothComm.new;
 [self.btComm setup];
 self.btComm.delegate = self;
 
 self.sharedData = [DataManager sharedDataManager];
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
    
 self.btComm.delegate = self;
 NSLog(@"Scanning");
 [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    
 [self.btComm findPeripheralsWithTimeout:2];
}


- (void)scanTimer:(NSTimer *)timer
{

}


- (void)peripheralFound:(CBPeripheral *)peripheral
{
 [self.btPeripherals addObject:peripheral];

 [self.switchTV reloadData];
}


- (void)loadSwitchArray
{
 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
 
 if ((self.switchIdA = [defaults objectForKey:@"switchArray"]) != nil)  // if switch data is already saved on phone
    {
    self.counter = 0;
    
    [self lookupSwitchData];
    [self lookupFunctions];
    [self lookupSerialCommands];
    }
}


- (void)lookupSwitchData
{
 PFQuery *query = [PFQuery queryWithClassName:@"WirelessSwitch"];
 
 [query whereKey:@"objectId" containedIn:self.switchIdA];
 
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
 
 self.btPeripherals = NSMutableArray.new;

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
