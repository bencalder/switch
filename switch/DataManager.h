//
//  DataManager.h
//  switch
//
//  Created by Ben Calder on 4/22/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "BluetoothComm.h"
#import "EngageUnit.h"

@interface DataManager : NSObject

@property (nonatomic, strong) NSMutableDictionary *buildSwitchMD;

@property (nonatomic, strong) PFObject *freshSwitchPFO;

@property (nonatomic, strong) PFObject *selectedSwitchPFO;

@property (nonatomic, strong) NSArray *functions,      //  downloaded data from Parse
                                      *serialCommands,
                                      *accessories,
                                      *connectors,
                                      *savedSwitchData,
                                      *savedAccessories;

@property (nonatomic, strong) BluetoothComm *btComm;

@property (nonatomic, strong) EngageUnit *primaryUnit;

+ (id)sharedDataManager;

@end
