
#import "SCUserVariable.h"

int SC_VARIABLE_LENGTH;

@implementation SCUserData

- (id)init
{
    if ( self = [super init] )
    {
        isSilent = NO;
    }
    return self;
}


- (void)dealloc
{
    [dataName release];
    [dataPtr release];
    [expression release];
    [makePlotNowData release];  /* Don't need to deallocate the internal data, because it's managed by SimModel (managedColumns or staticColumns). */
    [varNameToCopy release];
    [super dealloc];
}

@synthesize dataName;
@synthesize dataType;
@synthesize dataHoldType;
@synthesize dataPtr;
@synthesize expression;
@synthesize makePlotNowData;
@synthesize dim1;
@synthesize varNameToCopy;
@synthesize isSilent;

@end

