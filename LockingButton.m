
#import "LockingButton.h"
#import "DebugLog.h"

@implementation LockingButton

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

- (BOOL)performKeyEquivalent:(NSEvent *)event
{
    BOOL is_this_object =  NO;
    NSString * event_characters = [event characters];
    NSString * key_equivalent = [super keyEquivalent];
    if ( [key_equivalent compare:event_characters] == NSOrderedSame )
        is_this_object = YES;

    /* Should be 
       1. performKeyEquivalent before
       2. button callback
       3. performKeyEquivalent after
    */
    if ( is_this_object )
    {
        //DebugNSLog(@"performKeyEquivalent before\n");
        [lock lock];
        [super performKeyEquivalent:event];
        [lock unlock];
        //DebugNSLog(@"performKeyEquivalent after\n");
    }
    
    return is_this_object;
}

-(void) mouseDown:(NSEvent *)event
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
