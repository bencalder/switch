//
//  DataManager.h
//  switch
//
//  Created by Ben Calder on 4/22/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface DataManager : NSObject

@property (nonatomic, strong) NSMutableDictionary *buildSwitchMD;

@property (nonatomic, strong) PFObject *freshSwitchPFO;

+ (id)sharedDataManager;

@end
