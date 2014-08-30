//
//  DGControllerStateAddition.h
//  Real Time
//
//  Created by David Adalsteinsson on 11/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <DataGraph/DGController.h>


@interface DGController (StateAddition)

// Expects the state to be a dictionary of DTContainerForDoubleArray objects.
// The keys need to be the same as the column names.
- (void)setDataFromArrays:(NSDictionary *)state;

@end
