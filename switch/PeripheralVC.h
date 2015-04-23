//
//  PeripheralVC.h
//  switch
//
//  Created by Ben Calder on 4/1/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BluetoothComm.h"

@interface PeripheralVC : UIViewController <BTDelegate>

@property (strong, nonatomic) CBPeripheral *peripheral;

@property (strong, nonatomic) BluetoothComm *btComm;

@end
