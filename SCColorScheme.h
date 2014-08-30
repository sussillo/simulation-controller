#ifndef __SC_COLOR_SCHEME_H__
#define __SC_COLOR_SCHEME_H__

#import <Foundation/Foundation.h>

@interface SCColorScheme : NSObject
{
    NSString * name;
    NSArray * rangeTypes;
    NSArray * rangeStarts;
    NSArray * rangeStops;
    NSArray * rangeColors;
}

@property(copy) NSString * name;
@property(retain) NSArray * rangeTypes;
@property(retain) NSArray * rangeStarts;
@property(retain) NSArray * rangeStops;
@property(retain) NSArray * rangeColors;


@end


#endif
