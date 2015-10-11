//
//  EngageFunction.m
//  switch
//
//  Created by Ben Calder on 10/10/15.
//  Copyright © 2015 BTS. All rights reserved.
//

#import "EngageFunction.h"

@implementation EngageFunction

- (void)encodeWithCoder:(NSCoder *)aCoder
{
 [aCoder encodeObject:self.objectId                                  forKey:@"objectId"];
 [aCoder encodeObject:self.onName                                    forKey:@"onName"];
 [aCoder encodeObject:[NSNumber numberWithFloat:self.signalDuration] forKey:@"signalDuration"];
 [aCoder encodeObject:[NSNumber numberWithBool:self.momentary]       forKey:@"momentary"];
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
 if (self = [super init])
    {
    self.objectId       = [aDecoder              decodeObjectForKey:@"objectId"];
    self.onName         = [aDecoder              decodeObjectForKey:@"onName"];
    self.signalDuration = ((NSNumber *)[aDecoder decodeObjectForKey:@"signalDuration"]).floatValue;
    self.momentary      = ((NSNumber *)[aDecoder decodeObjectForKey:@"momentary"]).boolValue;
    }
 
 return self;
}

@end
