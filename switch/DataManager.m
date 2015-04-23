//
//  DataManager.m
//  switch
//
//  Created by Ben Calder on 4/22/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "DataManager.h"

@implementation DataManager


+ (id)sharedDataManager
{
 static DataManager *sharedData = nil;
 static dispatch_once_t onceToken;
 
 dispatch_once(&onceToken,
    ^{
     sharedData = [[self alloc] init];
     }
 );
 
 return sharedData;
}


- (id)init
{
 if (self = [super init])
    {
    }
 
 return self;
}


- (void)dealloc
{
}


@end
