//
//  ComputingRealTimeData.mm
//  Real Time
//
//  Created by David Adalsteinsson on 11/15/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ComputingRealTimeData.h"

#include "DTDoubleArray.h"
#include "DTContainerForDoubleArray.h"

#define NVARSTOPLOT 50

NSDictionary *ComputeXYDataNumber(double start_time, double dt, int ndts)
{
    // What the heck is this doing here?  Why would we wait?  Is there something under the covers that I don't (or
    //shouldn't understand?)
    //[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    int i = 0;
    int j = 0;

    // These can totally be reused in the coming code abstractions.
    DTMutableDoubleArray all_data[NVARSTOPLOT];
    for (i = 0; i < NVARSTOPLOT; i++ )
    {
        DTMutableDoubleArray array(ndts);
        all_data[i] = array;
    }
    //DTMutableDoubleArray y1(ndts);
    //DTMutableDoubleArray y2(ndts);
    //DTMutableDoubleArray times(ndts);

    double freq = 1.0/30.343440;
    double time = start_time;
    //NSLog(@"time=%f", time);
    for ( i = 0; i < ndts; i++ ) 
    {
        time += dt;
        for ( j = 0; j < NVARSTOPLOT; j++ )
        {
            all_data[j](i) = sin(freq*2.0*M_PI*time) + 1.0*j;
            //((double)j)M_PI/(double)NVARSTOPLOT);
            //y1(i) = sin(freq*2.0*M_PI*time);
            //y2(i) = sin(freq*2.0*M_PI*time - M_PI/2.0);
        }
    }

    
    NSMutableDictionary *toReturn = [NSMutableDictionary dictionaryWithCapacity:4];

    for (i = 0; i < NVARSTOPLOT; i++ )
    {
        NSString * data_key = [NSString stringWithFormat:@"%y%i", i];
        [toReturn setObject:[DTContainerForDoubleArray createWithDoubleArray:all_data[i]] forKey:data_key];
    }
    //[toReturn setObject:[DTContainerForDoubleArray createWithDoubleArray:times] forKey:@"time"];
    
    return toReturn;
}

