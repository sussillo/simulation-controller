#import <Cocoa/Cocoa.h>

/* These subclasses are necessary because we need the computation thread to block whenever the user makes a change to
 * the parameters or buttons.  This same lock surrounds the call to RunModelOneStep in SimModel.m.  */
@interface LockingButton : NSButton
{
    NSLock * lock;
}

@property(retain) NSLock * lock;

@end
