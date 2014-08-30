

#import "SCAppController.h"
#import "PreferenceController.h"
#import "ParametersController.h"
#import "SCDocumentController.h"
#import "SimController.h"
#import "DebugLog.h"

@implementation SCAppController

- (id)init
{
    if ( self = [super init] )
    {
        NSLog(@"SCAppController init");
#ifndef _NO_USER_LIBRARY_               //This definition may be declared as -D_NO_USER_LIBRARY_=1 in other C flags, build information of Xcode. -SHH@7/15/09
        openDynamicLibrary();          // load user model as dynamic library - SHH@7/7/09
#endif
        simController = [[SimController alloc] init];
    

/* When i pointed the SCApplicatoin to the correct version of the MainMenu.nib (for a long time it was just the vanilla
 * default), the system started calling this function twice.  Thus I can conclude that applicationWillFinishLaunching is
 * being called regardless of which setup is being used. -DCS:2010/03/10 */
// #ifndef _NO_USER_LIBRARY_    
//         [self applicationWillFinishLaunching:nil];      //call this function manually because SCAppController is not a
//                                                         //delegate of SCApplication but a delegation of
//                                                         //simulation_controller
// #endif
    }
    return self;
}


// Delegate method for the NSApplication instance.
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    // this creates our custom document controller. see
    // SCDocumentController.h for more details on how the
    // subclass is used.    
    NSLog(@"SCAppController applicationWillFinishLaunching");
    //[SCDocumentController sharedDocumentController];

    // So the question is how to place these documents according to some other application information.
    SCDocumentController *dc = [SCDocumentController sharedDocumentController];
    [simController setDocumentController:dc];
    [simController loadPlots];
}


- (IBAction)showPreferencePanel:(id)sender
{
    // Is preferenceController nil?
    if ( !preferenceController )
    {
        preferenceController = [[PreferenceController alloc] init];
    }
    DebugNSLog(@"SCAppController showing %@", preferenceController);
    [preferenceController showWindow:self];
}


- (IBAction)showSimPanel:(id)sender
{
    DebugNSLog(@"SCAppController showing %@", simController);
    [simController showWindow:self];
}


/* Implement the delegate for the main menu. */
- (void)menuDidClose:(NSMenu *)menu
{
    DebugNSLog(@"SCAppController: menuDidClose");
    //[computeLock unlock];
}


@end
