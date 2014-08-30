//
//  DTContainerForDoubleArray.mm
//  Real Time
//
//  Created by David Adalsteinsson on 11/15/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "DTContainerForDoubleArray.h"


@implementation DTContainerForDoubleArray

- (void)dealloc
{
    delete array;
    [super dealloc];
}

- (id)init
{
    [super init];
    appendedLength = 0;
    array = new DTDoubleArray();
    return self;
}

- (DTContainerForDoubleArray*)initWithDoubleArrayOfSize:(int)size
{
    [super init];
    appendedLength = 0;
    array = new DTMutableDoubleArray(size);
    return self;    
}


- (id)initWithDoubleArray:(const DTDoubleArray &)d
{
    [super init];
    appendedLength = 0;
    array = new DTDoubleArray(d);
    return self;
}

+ (DTContainerForDoubleArray *)createWithDoubleArray:(const DTDoubleArray &)d
{
    return [[[DTContainerForDoubleArray alloc] initWithDoubleArray:d] autorelease];
}

@synthesize appendedLength;

- (DTDoubleArray)getDTDoubleArray
{
    return *array;
}

- (DTDoubleArray*)getDTDoubleArrayPtr
{
    return array;
}


@end
