//
//  EngageSerialCommand.h
//  switch
//
//  Created by Ben Calder on 10/10/15.
//  Copyright © 2015 BTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EngageSerialCommand : NSObject

@property (strong, nonatomic) NSString *objectId,
                                       *offInstruction,
                                       *onInstruction;

@property (nonatomic) NSInteger relay;

@end
