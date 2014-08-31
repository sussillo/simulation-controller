//
//  nnm.m
//  Sample
//
//  Created by Soonhac Hong on 7/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "nnm.h"


@implementation nnm

- (id)init {
    
    if (self = [super init]) {
    }
    return self;
}

- (void)dealloc {
    
    [super dealloc];
    
}

- (void) showFramework
{
    DebugNSLog(@"Run Framework.....");
    NSAutoreleasePool* pool = [NSAutoreleasePool new];
    _SCAppController = [[SCAppController alloc] init]; 
    [pool release];
}
@end
