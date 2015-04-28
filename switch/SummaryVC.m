
//
//  SummaryVC.m
//  switch
//
//  Created by Ben Calder on 4/23/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "SummaryVC.h"
#import <Parse/Parse.h>
#import "DataManager.h"

@interface SummaryVC () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backB;
@property (weak, nonatomic) IBOutlet UIButton *doneB;

@property (weak, nonatomic) IBOutlet UITableView *switchSummaryTV;

@property (strong, nonatomic) NSMutableArray *summaryMA;

@property (strong, nonatomic) DataManager *sharedData;

@end

@implementation SummaryVC


- (IBAction)buttonPress:(id)sender
{
 if (sender == self.doneB)
    {
    [self saveSwitchDataToParse];
    }
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
       
       NSDictionary *d = @{@"uuid" : self.sharedData.btComm.activePeripheral.identifier.UUIDString, @"objectId" : self.sharedData.freshSwitchPFO.objectId};
       
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
       
       [self.sharedData.btComm disconnect:self.sharedData.btComm.activePeripheral];
       
       [self performSegueWithIdentifier:@"unwindtohome" sender:self];
       }
    else NSLog(@"Error: %@ %@", error, [error userInfo]);
    }
 ];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 return self.summaryMA.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
 UITableViewCell *cell;
 NSDictionary *connectorD;
 
 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"default"];
 
 if (indexPath.row > 0)
    {
    connectorD = self.summaryMA[indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"Connector %li: %@ %@", indexPath.row, connectorD[@"brand"], connectorD[@"model"]];
    }
 else cell.textLabel.text = [NSString stringWithFormat:@"Switch name: %@", self.summaryMA[indexPath.row]];
 
 return cell;
}


- (void)viewDidLoad
{
 [super viewDidLoad];
 
 self.sharedData = [DataManager sharedDataManager];
 
 self.summaryMA = NSMutableArray.new;
 
 [self buildArray];
}


- (void)buildArray
{
 [self.summaryMA addObject:self.sharedData.freshSwitchPFO[@"name"]];
 
 for (PFObject *obj in self.sharedData.freshSwitchPFO[@"connectors"])
    {
    NSMutableDictionary *mD;
    
    mD = NSMutableDictionary.new;
    
    [mD setObject:obj[@"accessoryModel"] forKey:@"model"];
    [mD setObject:obj[@"accessoryBrand"] forKey:@"brand"];
    
    [self.summaryMA addObject:mD];
    }
 
 [self.switchSummaryTV reloadData];
}

- (void)didReceiveMemoryWarning
{
 [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
//     Get the new view controller using [segue destinationViewController].
//     Pass the selected object to the new view controller.
 

}


@end
