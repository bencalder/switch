//
//  HomeVC.m
//  switch
//
//  Created by Ben Calder on 4/21/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "HomeVC.h"

@interface HomeVC ()

@end


@implementation HomeVC


- (IBAction)unwindFromAddSwitch:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind from AddSwitchVC");
    // Pull any data from the view controller which initiated the unwind segue.
}


- (IBAction)unwindFromCreateSwitch:(UIStoryboardSegue *)sender
{
 NSLog(@"Unwind from CreateSwitchVC");
    // Pull any data from the view controller which initiated the unwind segue.
}


- (void)viewDidLoad
{
 [super viewDidLoad];
    // Do any additional setup after loading the view.
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
