//
//  EngageConnector.m
//  switch
//
//  Created by Ben Calder on 10/10/15.
//  Copyright © 2015 BTS. All rights reserved.
//

#import "EngageConnector.h"

@implementation EngageConnector

- (void)encodeWithCoder:(NSCoder *)aCoder
{
 [aCoder encodeObject:self.objectId                              forKey:@"objectId"];
 [aCoder encodeObject:self.brand                                 forKey:@"brand"];
 [aCoder encodeObject:[NSNumber numberWithInteger:self.pinCount] forKey:@"pinCount"];
 [aCoder encodeObject:self.relays                                forKey:@"relays"];
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
 if (self = [super init])
    {
    self.objectId = [aDecoder              decodeObjectForKey:@"objectId"];
    self.brand    = [aDecoder              decodeObjectForKey:@"brand"];
    self.pinCount = ((NSNumber *)[aDecoder decodeObjectForKey:@"pinCount"]).integerValue;
    self.relays   = [aDecoder              decodeObjectForKey:@"relays"];
    }
 
 return self;
}

@end
