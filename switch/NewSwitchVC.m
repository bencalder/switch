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

@interface NewSwitchVC () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, BTDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backB;
@property (weak, nonatomic) IBOutlet UIButton *doneB;

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
                           nameAccepted;

@property (strong, nonatomic) UITextField *productIdTF,
                                          *nameTF;

@property (nonatomic) NSInteger choosingAccessoryI;

@property (strong, nonatomic) BluetoothComm *btComm;

@property (strong, nonatomic) NSString *scanMessageS;

@property (strong, nonatomic) UIActivityIndicatorView *processingAI;

@end

@implementation NewSwitchVC


- (IBAction)buttonPress:(id)sender
{
 if (sender == self.doneB) [self saveSwitchDataToParse];
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
 if (section == 3)   // Accessories
    {
    if (self.choosingAccessory) return self.displayAccessoriesMA.count;
    else                        return self.selectedAccessoriesMA.count;
    }
 else return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *cell;
PFObject *switchPFO;
NSDictionary *d;
NSString *str;
 
 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"subtitle"];
 
 switchPFO = self.sharedData.selectedSwitchPFO;
 
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
 if (indexPath.section == 1)    // Product ID
    {
//    for (UIView *vw in cell.contentView.subviews) [vw removeFromSuperview];
    
    if (self.productIdAccepted)
       {
       [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
       
       cell.textLabel.text = self.sharedData.freshSwitchPFO.objectId;
       }
    else
       {
       self.productIdTF                        = UITextField.new;
       self.productIdTF.frame                  = CGRectMake(15, 0, self.switchTV.frame.size.width - 40, cell.frame.size.height);
       self.productIdTF.delegate               = self;
       self.productIdTF.autocorrectionType     = UITextAutocorrectionTypeNo;
       self.productIdTF.autocapitalizationType = UITextAutocapitalizationTypeNone;
       self.productIdTF.borderStyle            = UITextBorderStyleNone;
       self.productIdTF.placeholder            = @"Enter the code printed on your switch.";
       [self.productIdTF setReturnKeyType:UIReturnKeyDone];
       
       [cell.contentView addSubview:self.productIdTF];
    
       [cell setAccessoryType:UITableViewCellAccessoryNone];
       
       [cell addSubview:[self buildActivityIndicatorForCell:cell]];
       }
    }
 else
 if (indexPath.section == 2)    // Name
    {
//    for (UIView *vw in cell.contentView.subviews) [vw removeFromSuperview];
    
    if (self.nameAccepted)
       {
       [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
       
       cell.textLabel.text = self.sharedData.freshSwitchPFO[@"name"];
       }
    else
       {
       self.nameTF                        = UITextField.new;
       self.nameTF.frame                  = CGRectMake(15, 0, self.switchTV.frame.size.width - 40, cell.frame.size.height);
       self.nameTF.delegate               = self;
       self.nameTF.autocorrectionType     = UITextAutocorrectionTypeNo;
       self.nameTF.autocapitalizationType = UITextAutocapitalizationTypeWords;
       self.nameTF.borderStyle            = UITextBorderStyleNone;
       self.nameTF.placeholder            = @"Enter a name for your switch.";
       [self.nameTF setReturnKeyType:UIReturnKeyDone];
       
       [cell.contentView addSubview:self.nameTF];
    
       [cell setAccessoryType:UITableViewCellAccessoryNone];
       }
    }
 else
 if (indexPath.section == 3)   //  Accessories
    {
    if (self.choosingAccessory)
       {
       cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", self.displayAccessoriesMA[indexPath.row][@"brand"], self.displayAccessoriesMA[indexPath.row][@"model"]];
       
       if ([((PFObject *)self.displayAccessoriesMA[indexPath.row]).objectId isEqualToString:self.selectedAccessoriesMA[self.choosingAccessoryI][@"accessoryId"]])
          {
          cell.accessoryType = UITableViewCellAccessoryCheckmark;
          }
       else cell.accessoryType = UITableViewCellAccessoryNone;
       }
    else
       {
       if ((str = self.selectedAccessoriesMA[indexPath.row][@"accessoryBrand"]) == nil)  //  user has not chosen an accessory for this connector
          {
          cell.textLabel.text = @"Choose an accessory";
          }
       else
          {
          d = self.selectedAccessoriesMA[indexPath.row];
       
          cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:13.0];
          cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", d[@"accessoryBrand"], d[@"accessoryModel"]];
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
    if (!self.scanCompleted) [self scanForPeripherals];
    }
 else
 if (indexPath.section == 3) // accessory
    {
    if (self.choosingAccessory)
       {
       NSDictionary *d;
       
       d = @{@"accessoryBrand"     : self.displayAccessoriesMA[indexPath.row][@"brand"],
             @"accessoryModel"     : self.displayAccessoriesMA[indexPath.row][@"model"],
             @"accessoryFunctions" : self.displayAccessoriesMA[indexPath.row][@"functions"],
             @"accessoryId"        : ((PFObject *)self.displayAccessoriesMA[indexPath.row]).objectId,
             @"objectId"           : self.selectedAccessoriesMA[self.choosingAccessoryI][@"objectId"],
             @"relays"             : self.selectedAccessoriesMA[self.choosingAccessoryI][@"relays"]
            };
       
       [self.selectedAccessoriesMA replaceObjectAtIndex:self.choosingAccessoryI withObject:d];
       
       self.choosingAccessory = NO;
       }
    else
       {
       self.choosingAccessory = YES;
       [self buildAccessoryArrayForConnector:indexPath.row];
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
 
 for (PFObject *accessory in self.sharedData.accessories)  // loop through all of the possible accessories
    {
    for (int i = 0; i < ((NSArray *)accessory[@"connectors"]).count; i++)   //  loop through each connector of each accessory
       {
       if ([accessory[@"connectors"][i][@"objectId"] isEqualToString:self.selectedAccessoriesMA[connectorInt][@"objectId"]])
          {
          [self.displayAccessoriesMA addObject:accessory];
          break;
          }
       }
    }
}


- (void)doneWithKeyboard:(UIButton *)sender
{
 [self.productIdTF resignFirstResponder];
 [self.nameTF      resignFirstResponder];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
 if (textField == self.productIdTF)
    {
    [self.productIdTF resignFirstResponder];
    
    [self.processingAI startAnimating];
    
    [self checkProductId];
    }
 else
 if (textField == self.nameTF)
    {
    [self.nameTF resignFirstResponder];
    
    [self validateName];
    }
 
 return YES;
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
 
 self.peripheralMA = NSMutableArray.new;  // make new array to add UUID's to
 
 [self.btComm findPeripheralsWithTimeout:2];
}


- (void)peripheralFound:(CBPeripheral *)peripheral
{
 NSLog(@"Found peripheral with UUID: %@", peripheral.identifier.UUIDString);
 
 [self.peripheralMA addObject:peripheral];
}


- (void)scanComplete:(NSTimer *)timer
{
 [self.processingAI stopAnimating];

 if (self.peripheralMA.count > 0)   // found bluetooth devices with desired service
    {
    if (self.sharedData.savedSwitchData != nil)   // at least one switch already exists on this device
       {
       for (CBPeripheral *per in self.peripheralMA)   // iterate through each matching Bluetooth device that was found
          {
          for (NSDictionary *d in self.sharedData.savedSwitchData)   // iterate through each existing switch
             {
             if ([per.identifier.UUIDString isEqualToString:d[@"uuid"]])   // match existing switches with found devices
                {
                [self.peripheralMA removeObject:per];   // if it matches, then remove the existing switch from the array
                break;
                }
             }
          }
       }
 
    if (self.peripheralMA.count == 0)   //  the scan only found existing switches
       {
       self.scanMessageS = @"Didn't find any new switches.";
       }
    else
    if (self.peripheralMA.count == 1)  // found our one switch
       {
       self.scanCompleted = YES;
       self.scanMessageS = @"Found your switch!";
       [self.sectionTitlesMA addObject:@"Product ID"];
       
       [self.switchTV beginUpdates];
       [self.switchTV reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
       [self.switchTV insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
       [self.switchTV endUpdates];
       
       [self.productIdTF becomeFirstResponder];
       }
    else self.scanMessageS = @"Found multiple switches. Engage can only add one switch at a time.";
     
    }
 else   // did not find a bluetooth device
    {
    self.scanMessageS = @"No switch found. Tap to scan again.";
    }
 
 [self.switchTV reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}


- (void)checkProductId
{
 PFQuery *query = [PFQuery queryWithClassName:@"WirelessSwitch"];
 
 [query whereKey:@"objectId" equalTo:self.productIdTF.text];
 
 [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
    {
    if (!error)
       {
       [self.processingAI stopAnimating];
       
       self.sharedData.freshSwitchPFO = object;
       self.sharedData.freshSwitchPFO[@"uuid"] = ((CBPeripheral *)self.peripheralMA[0]).identifier.UUIDString;
       
       self.selectedAccessoriesMA = self.sharedData.freshSwitchPFO[@"connectors"];
       
       self.productIdAccepted = YES;
       
       [self.sectionTitlesMA addObject:@"Name"];
       
       [self.switchTV beginUpdates];
       [self.switchTV reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
       [self.switchTV insertSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
       [self.switchTV endUpdates];
       
       [self.nameTF becomeFirstResponder];
       }
    else NSLog(@"Error: %@ %@", error, [error userInfo]);
    }
 ];
}


- (void)validateName
{
 if (self.nameTF.text.length < 26)   // only accept names with 25 characters or less
    {
    self.sharedData.freshSwitchPFO[@"name"] = self.nameTF.text;
    
    self.nameAccepted = YES;
    
    [self.sectionTitlesMA addObject:@"Accessories"];
    
    [self.switchTV beginUpdates];
    [self.switchTV reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.switchTV insertSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.switchTV endUpdates];
    }
}


- (void)showDoneButton
{
 BOOL show = YES;
 
 for (NSDictionary *d in self.selectedAccessoriesMA)
    {
    if (d[@"accessoryBrand"] == nil) show = NO;
    }
 
 if (show) self.doneB.hidden = NO;
}


- (void)saveSwitchDataToParse
{
 self.sharedData.freshSwitchPFO[@"isSetup"] = [NSNumber numberWithBool:YES];

 [self.sharedData.freshSwitchPFO saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
    {
    if (succeeded)
       {
       NSLog(@"Saved new switch.");
       
       NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
       
       NSDictionary *d = @{@"uuid" : self.sharedData.freshSwitchPFO[@"uuid"], @"objectId" : self.sharedData.freshSwitchPFO.objectId};
       
       if ([defaults objectForKey:@"switchArray"] == nil)
          {
          NSMutableArray *switchMA;
    
           switchMA = NSMutableArray.new;
    
           [switchMA addObject:d];
    
           [defaults setObject:switchMA forKey:@"switchArray"];
          }
       else
          {
          NSMutableArray *mA;
          
          mA = NSMutableArray.new;
          
          for (NSDictionary *switchD in [defaults objectForKey:@"switchArray"]) [mA addObject:switchD];
           
          [mA addObject:d];
          
          [defaults setObject:mA forKey:@"switchArray"];
          }
       
       [defaults synchronize];
       
       [self performSegueWithIdentifier:@"unwindtohomefromnewswitch" sender:self];
       }
    else NSLog(@"Error: %@ %@", error, [error userInfo]);
    }
 ];
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
}


- (void)viewDidAppear:(BOOL)animated
{
 [super viewDidAppear:animated];
 
 [self scanForPeripherals];
 [self.processingAI startAnimating];
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
