//
//  EngageConnector.h
//  switch
//
//  Created by Ben Calder on 10/10/15.
//  Copyright © 2015 BTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EngageConnector : NSObject

@property (strong, nonatomic) NSString *objectId,
                                       *brand;

@property (nonatomic) NSInteger pinCount;

@property (strong, nonatomic) NSArray *relays;

@end
