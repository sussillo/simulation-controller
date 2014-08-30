//
//  DGControllerStateAddition.mm
//  Real Time
//
//  Created by David Adalsteinsson on 11/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "DGControllerStateAddition.h"

#import "DTContainerForDoubleArray.h"

#import <DataGraph/DGDataColumn.h>

@implementation DGController (StateAddition)

- (void)setDataFromArrays:(NSDictionary *)state
{
    NSEnumerator *enumerator = [state keyEnumerator];
    DTContainerForDoubleArray *item;
    NSString *key;
    DTDoubleArray array;
    DGBinaryDataColumn *column;
    
    while (key = [enumerator nextObject]) {
        item = [state objectForKey:key];
        array = [item getDTDoubleArray];
        
        column = [self binaryColumnWithName:key];
        if (column==nil) continue;
        
        [column setDataFromPointer:array.Pointer() length:array.Length()];
    }
}

@end
