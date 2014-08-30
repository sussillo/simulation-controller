#import "SCColorScheme.h"

@implementation SCColorScheme

- (id)init
{
    if ( self = [super init] )
    {
    }
    return self;
}


- (void)dealloc
{
    [name release];
    [rangeTypes release];
    [rangeStarts release];
    [rangeStops release];
    [rangeColors release];
    [super dealloc];
}


@synthesize name;
@synthesize rangeTypes;
@synthesize rangeStarts;
@synthesize rangeStops;
@synthesize rangeColors;


@end
