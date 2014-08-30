//
//  ComputingRealTimeData.h
//  Real Time
//
//  Created by David Adalsteinsson on 11/15/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Dictionary with two DTContainerForDoubleArray objects, for X and Y.
// Fakes how long it will take by pausing the current thread.
extern NSDictionary *ComputeXYDataNumber(double t, double dt, int ndts);

