//
//  AddSwitchVC.m
//  switch
//
//  Created by Ben Calder on 4/21/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "AddSwitchVC.h"
#import "BluetoothComm.h"
#import "DataManager.h"

@interface AddSwitchVC () <BTDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *nameAndConnectorCV;

@property (weak, nonatomic) IBOutlet UIButton *xB;
@property (weak, nonatomic) IBOutlet UIButton *addSwitchB;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchingAI;

@property (weak, nonatomic) IBOutlet UILabel *searchingL;

@property (weak, nonatomic) IBOutlet UIProgressView *searchingPV;

@property (strong, nonatomic) BluetoothComm *btComm;

@property (strong, nonatomic) NSMutableArray *peripheralMA;

@property (nonatomic) float searchingProgressF;

@property (strong, nonatomic) DataManager *sharedData;

@end

@implementation AddSwitchVC


- (IBAction)buttonPress:(id)sender
{
 if (sender == self.addSwitchB)
    {
    
    }
}


- (IBAction)unwindFromNameSwitch:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind from NameSwitchVC");
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

 [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
 
 self.searchingProgressF = 0.0;
 [self progress:nil];
 
 self.peripheralMA = NSMutableArray.new;  // make new array to add UUID's to
 
 [self.btComm findPeripheralsWithTimeout:2];
}


- (void)didDiscoverServices:(CBPeripheral *)peripheral
{
 NSLog(@"Discovered services in AddSwitchVC: %@", peripheral);

}


- (void)scanTimer:(NSTimer *)timer   // show CV or prompt to plug in, buy, or scan again
{
 if (self.peripheralMA.count > 0)
    {
    self.searchingL.text  = @"Found your switch!";
    self.addSwitchB.hidden = NO;
    }
 else  // Didn't find any Bluetooth devices
    {
    self.searchingL.text = @"We couldn't find any switches nearby. Make sure the switch's battery cables are securely attached to your battery terminals.";
    [self showPlugInOrBuyView];
    }
}


- (void)peripheralFound:(CBPeripheral *)peripheral
{
 NSLog(@"Found peripheral with UUID: %@", peripheral.identifier.UUIDString);
 
 [self.peripheralMA addObject:peripheral];
 [self.btComm connect:peripheral];
}


- (void)didConnect:(CBPeripheral *)peripheral
{
 NSLog(@"Successfully connected to the new peripheral.");

}


- (void)progress:(NSTimer *)timer
{
 self.searchingProgressF += 0.1;
 
 if (self.searchingProgressF > 2)
    {
    self.searchingPV.hidden = YES;
    return;
    }
 
 self.searchingPV.progress = self.searchingProgressF / 2.0;
 
 [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(progress:) userInfo:nil repeats:NO];
}


- (void)showPlugInOrBuyView
{
 NSLog(@"Switch not found. User needs to plug in or buy.");
}


- (void)viewDidLoad
{
 [super viewDidLoad];
 
 self.sharedData = [DataManager sharedDataManager];

 self.btComm = self.sharedData.btComm;
 self.btComm.delegate = self;
}


- (void)viewDidAppear:(BOOL)animated
{
 [super viewDidAppear:animated];
 
 [self scanForPeripherals];
 
 [self.searchingAI startAnimating];
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
