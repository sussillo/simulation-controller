
#import "LockingSlider.h"
#import "DebugLog.h"

@implementation LockingSlider

- (void)dealloc
{
    [lock release];
    [super dealloc];
}

@synthesize lock;


// - (void)setLock:(NSLock*)compute_lock
// {
//     if ( lock == compute_lock )
//         return;
    
//     [compute_lock retain];
//     [lock release];
//     lock = compute_lock; 
// }


-(void)mouseDown:(NSEvent *)event
{
    if ( ![self isEnabled] )
        return;
    
    [lock lock];
    DebugNSLog(@"Locking lock");
    [super mouseDown:event];
    DebugNSLog(@"Unlocking lock");    
    [lock unlock];
}

    
@end
