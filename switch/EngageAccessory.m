//
//  EngageAccessory.m
//  switch
//
//  Created by Ben Calder on 10/10/15.
//  Copyright © 2015 BTS. All rights reserved.
//

#import "EngageAccessory.h"

@implementation EngageAccessory

- (void)encodeWithCoder:(NSCoder *)aCoder
{
 [aCoder encodeObject:self.objectId                               forKey:@"objectId"];
 [aCoder encodeObject:self.brand                                  forKey:@"brand"];
 [aCoder encodeObject:self.model                                  forKey:@"model"];
 [aCoder encodeObject:[NSNumber numberWithFloat:self.currentDraw] forKey:@"currentDraw"];
 [aCoder encodeObject:self.connectors                             forKey:@"connectors"];
 [aCoder encodeObject:self.functions                              forKey:@"functions"];
 [aCoder encodeObject:self.primaryFunction                        forKey:@"primaryFunction"];
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
 if (self = [super init])
    {
    self.objectId        = [aDecoder              decodeObjectForKey:@"objectId"];
    self.brand           = [aDecoder              decodeObjectForKey:@"brand"];
    self.model           = [aDecoder              decodeObjectForKey:@"model"];
    self.currentDraw     = ((NSNumber *)[aDecoder decodeObjectForKey:@"currentDraw"]).floatValue;
    self.connectors      = [aDecoder              decodeObjectForKey:@"connectors"];
    self.functions       = [aDecoder              decodeObjectForKey:@"functions"];
    self.primaryFunction = [aDecoder              decodeObjectForKey:@"primaryFunction"];
    }
 
 return self;
}

@end
