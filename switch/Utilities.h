//
//  Utilities.h
//  switch
//
//  Created by Ben Calder on 10/11/15.
//  Copyright © 2015 BTS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EngageAccessory.h"

@interface Utilities : NSObject

+ (NSArray *)buildAccessoryArrayFromSourceArray:(NSArray *)source;

+ (void)determineRelaysForAccessory:(EngageAccessory *)accessory atConnector:(NSInteger)connectorIdx;

+ (NSString *)stringFromAccessory:(EngageAccessory *)accessory;

@end
