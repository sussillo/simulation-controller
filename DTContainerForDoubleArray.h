//
//  DTContainerForDoubleArray.h
//  Real Time
//
//  Created by David Adalsteinsson on 11/15/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DTDoubleArray.h"

// This is a simple wrapper around a DTDoubleArray class.
// Allows you to easily hand it between Objective-C++ classes.

@interface DTContainerForDoubleArray : NSObject
{
    int appendedLength;
    DTDoubleArray *array;
}
@property(assign) int appendedLength;

+ (DTContainerForDoubleArray *)createWithDoubleArray:(const DTDoubleArray &)d;

- (DTContainerForDoubleArray*)initWithDoubleArrayOfSize:(int)size;

- (DTDoubleArray)getDTDoubleArray;
- (DTDoubleArray*)getDTDoubleArrayPtr;
@end
