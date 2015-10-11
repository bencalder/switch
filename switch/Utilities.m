//
//  Utilities.m
//  switch
//
//  Created by Ben Calder on 10/11/15.
//  Copyright © 2015 BTS. All rights reserved.
//

#import "Utilities.h"
#import "DataManager.h"
#import "EngageConnector.h"
#import "EngageFunction.h"

@implementation Utilities

+ (NSArray *)buildAccessoryArrayFromSourceArray:(NSArray *)source
{
NSMutableArray *accessoryMA;
//NSInteger relayIdx;

 accessoryMA = NSMutableArray.new;
 
// relayIdx = 1;
 
 for (NSDictionary *accessoryData in source)    //    loop through each of the connected accessories
    {
    EngageAccessory *accessory;
    NSMutableArray *connectorsMA, *functionsMA;
    
     accessory             = [[EngageAccessory alloc] init];
     accessory.objectId    = accessoryData[@"objectId"];
     accessory.brand       = accessoryData[@"brand"];
     accessory.model       = accessoryData[@"model"];
     accessory.currentDraw = ((NSNumber *)accessoryData[@"currentDraw"]).floatValue;
     
     connectorsMA = NSMutableArray.new;
     
     for (NSDictionary *connectorIDD in accessoryData[@"connectors"])
        for (NSDictionary *availableConnectorD in [self connectorArray])
           if ([connectorIDD[@"objectId"] isEqualToString:availableConnectorD[@"objectId"]])
              {
              EngageConnector *connector;
              
               connector = [[EngageConnector alloc] init];
               
               connector.brand    = availableConnectorD[@"brand"];
               connector.pinCount = ((NSNumber *)availableConnectorD[@"brand"]).integerValue;

               [connectorsMA addObject:connector];
              }
     
     accessory.connectors = connectorsMA;
     
     for (NSDictionary *availableFunctionD in [self functionArray])
        if ([accessoryData[@"primaryFunction"][@"objectId"] isEqualToString:availableFunctionD[@"objectId"]])
           {
           EngageFunction *primaryFunction;
           
            primaryFunction                = [[EngageFunction alloc] init];
            primaryFunction.objectId       = availableFunctionD[@"objectId"];
            primaryFunction.onName         = availableFunctionD[@"onName"];
            primaryFunction.signalDuration = ((NSNumber *)availableFunctionD[@"signalDuration"]).floatValue;
            primaryFunction.momentary      = ((NSNumber *)availableFunctionD[@"momentary"]).boolValue;
            
            accessory.primaryFunction = primaryFunction;
           }
     
     functionsMA = NSMutableArray.new;
     
     for (NSString *functionID in accessoryData[@"functions"])
        for (NSDictionary *availableFunctionD in [self functionArray])
           if ([functionID isEqualToString:availableFunctionD[@"objectId"]])
              {
              EngageFunction *function;
           
               function                = [[EngageFunction alloc] init];
               function.objectId       = availableFunctionD[@"objectId"];
               function.onName         = availableFunctionD[@"onName"];
               function.signalDuration = ((NSNumber *)availableFunctionD[@"signalDuration"]).floatValue;
               function.momentary      = ((NSNumber *)availableFunctionD[@"momentary"]).boolValue;
               
               [functionsMA addObject:function];
              }
     
     accessory.functions = functionsMA;
     
     [accessoryMA addObject:accessory];
    }
 
 return accessoryMA;
}


+ (void)determineRelaysForAccessory:(EngageAccessory *)accessory atConnector:(NSInteger)connectorIdx
{
NSInteger relayIdx;

 relayIdx = connectorIdx;
 
 for (EngageConnector *connector in accessory.connectors)
//    for (NSDictionary *availableConnectorD in [self connectorArray])
       if ([connector.objectId isEqualToString:@"S8e5Di6Y2E"])
          {
          connector.relays = @[[NSNumber numberWithInteger:relayIdx], [NSNumber numberWithInteger:relayIdx + 1]];
          relayIdx         = relayIdx + 2;
          }
       else
          {
          connector.relays = @[[NSNumber numberWithInteger:relayIdx]];
          relayIdx++;
          }
}


+ (NSString *)stringFromAccessory:(EngageAccessory *)accessory
{
 return [NSString stringWithFormat:@"%@ %@", accessory.brand, accessory.model];
}


+ (NSArray *)connectorArray
{
DataManager *sharedData = [DataManager sharedDataManager];

 return sharedData.connectors;
}


+ (NSArray *)functionArray
{
DataManager *sharedData = [DataManager sharedDataManager];

 return sharedData.functions;
}


@end
