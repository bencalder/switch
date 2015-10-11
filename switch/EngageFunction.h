//
//  EngageFunction.h
//  switch
//
//  Created by Ben Calder on 10/10/15.
//  Copyright © 2015 BTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EngageFunction : NSObject

@property (strong, nonatomic) NSString *objectId,
                                       *onName;

@property (nonatomic) float signalDuration;

@property (nonatomic) BOOL momentary;

@end
