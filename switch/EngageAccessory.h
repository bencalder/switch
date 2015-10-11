//
//  EngageAccessory.h
//  switch
//
//  Created by Ben Calder on 10/10/15.
//  Copyright © 2015 BTS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EngageFunction.h"

@interface EngageAccessory : NSObject

@property (strong, nonatomic) NSString *objectId,
                                       *brand,
                                       *model;

@property (nonatomic) float currentDraw;

@property (strong, nonatomic) NSArray *connectors,
                                      *functions;

@property (strong, nonatomic) EngageFunction *primaryFunction;

@end
