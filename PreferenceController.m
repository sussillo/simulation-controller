#import "PreferenceController.h"
#import "DebugLog.h"

@implementation PreferenceController

- (id)init
{
    if ( ![super initWithWindowNibName:@"Preferences"] )
        return nil;
    
    return self;
}

- (void)windowDidLoad
{
    DebugNSLog(@"Nib file is loaded");
}

- (IBAction)changeBackgroundColor: (id)sender
{
    NSColor *color = [colorWell color];
    DebugNSLog(@"Color changed: %@", color);
}


- (IBAction)changeNewEmptyDoc: (id)sender
{
    int state = [checkbox state];
    DebugNSLog(@"Checkbox changed %d", state);
}


@end
