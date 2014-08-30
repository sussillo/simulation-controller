


#import <Cocoa/Cocoa.h>
#import "DynamicLibraryLoader.h" 

@class PreferenceController;
@class SimController;
@class ParametersController;

/* This is a delegate for the File's owner in the NIB.  The NIB is mainMenu.xib and the File's Owner is
 * NSApplication. */

@interface SCAppController : NSObject 
{
    ParametersController *parametersController;
    PreferenceController *preferenceController;
    SimController *simController;
}

- (IBAction)showPreferencePanel:(id)sender;
//- (IBAction)initParametersPanel:(id)sender;
- (IBAction)showSimPanel:(id)sender;

@end
