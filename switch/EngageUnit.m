//
//  EngageUnit.m
//  switch
//
//  Created by Ben Calder on 10/10/15.
//  Copyright © 2015 BTS. All rights reserved.
//

#import "EngageUnit.h"

@implementation EngageUnit

- (id)init
{
 if (self = [super init])
    {
    }
 
 return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:self.accessories forKey:@"accessories"];
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
  if (self = [super init])
     {
     self.accessories = [aDecoder decodeObjectForKey:@"accessories"];
     }
 
  return self;
}

@end
