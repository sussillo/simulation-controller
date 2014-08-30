#import "ParametersController.h"
#import "DebugLog.h"

@implementation ParametersController

- (id)init
{
    if ( self = [super initWithWindowNibName:@"Parameters"] )
    {
        simParameterModel = [[SimParameterModel alloc] init];
    }
    return self;
}

- (void)dealloc
{
    DebugNSLog(@"ParametersController dealloc");
    [self setComputeLock:nil];
    [self setSimParameterModel:nil]; // just following from the cocoa book pg. 127 (how can this be correct?) -DCS:2009/05/13
    [super dealloc];
}


- (void)windowDidLoad
{
    DebugNSLog(@"Parameters Nib file is loaded");
}


- (void)alertEndedForParameterReset:(NSAlert *)alert code:(int)choice context:(void*)v
{
    DebugNSLog(@"Alert sheet ended");
    if ( choice == NSAlertDefaultReturn )
    {
        [simParameterModel resetParameterValuesToDefaults];
    }    
}


- (void)alertEndedForButtonReset:(NSAlert *)alert code:(int)choice context:(void*)v
{
    DebugNSLog(@"Alert sheet ended");
    if ( choice == NSAlertDefaultReturn )
    {
        [simParameterModel resetButtonValuesToDefaults];
    }    
}

-(IBAction) parameterValueChanged:(id)sender
{
    DebugNSLog(@"parameterValueChanged");
}



-(IBAction) pushResetParameterValuesToDefaults:(id)sender
{ 
    NSAlert *alert = [NSAlert alertWithMessageText:@"Reset?" 
                              defaultButton:@"Reset" 
                              alternateButton:@"Cancel" 
                              otherButton:nil
                              informativeTextWithFormat:@"Reset the parameters to their default values?"];
    
    DebugNSLog(@"Starting alert sheet for parameters reset.");
    [alert beginSheetModalForWindow:[self window]
           modalDelegate:self
           didEndSelector:@selector(alertEndedForParameterReset:code:context:)
           contextInfo:NULL];
}


-(IBAction) pushResetButtonValuesToDefaults:(id)sender
{ 
    NSAlert *alert = [NSAlert alertWithMessageText:@"Reset?" 
                              defaultButton:@"Reset" 
                              alternateButton:@"Cancel" 
                              otherButton:nil
                              informativeTextWithFormat:@"Reset the buttons to their default values?"];
    
    DebugNSLog(@"Starting alert sheet for buttons reset.");
    [alert beginSheetModalForWindow:[self window]
           modalDelegate:self
           didEndSelector:@selector(alertEndedForButtonReset:code:context:)
           contextInfo:NULL];
}


-(void) saveParameters:(NSOpenPanel *)panel returnCode:(int)return_code  contextInfo:(void  *)context_info
{
    DebugNSLog(@"saveParameters");

    if ( return_code !=  NSOKButton )
        return;
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSString * filename = [panel filename];
    NSArray * parameter_names = [simParameterModel parameterNames];
    NSDictionary * parameters_by_name = [simParameterModel parametersDict];

    /* Get a sorted version of the variable list, which is a set. */
    NSMutableArray * parameters_array = [NSMutableArray array];
    for ( NSString * parameter_name in parameter_names )
    {
        NSDictionary * parameter_as_dict = [[parameters_by_name objectForKey: parameter_name] asPropertyListDictionary];
        [parameters_array addObject:parameter_as_dict];
    }

    [parameters_array writeToFile:(NSString *)filename atomically:(BOOL)NO];

    [pool release];    
}


-(void) loadParameters:(NSOpenPanel *)panel returnCode:(int)return_code  contextInfo:(void  *)context_info
{
    DebugNSLog(@"loadParameters");

    if ( return_code !=  NSOKButton )
        return;
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSString * filename = [panel filename];
    /* Get a sorted version of the variable list, which is a set. */
    NSMutableArray * parameters_dict_array = [NSMutableArray arrayWithContentsOfFile:filename]; 

    for ( NSDictionary * parameter_dict in parameters_dict_array )
    {
        SimParameter * sp = [[SimParameter alloc] init];
        [sp fromPropertyListDictonary:parameter_dict];
        [simParameterModel addParameterAllowingOverwrite:sp];
        [sp release];
    }

    [pool release];    
}


-(void) saveButtons:(NSOpenPanel *)panel returnCode:(int)return_code contextInfo:(void  *)context_info
{
    DebugNSLog(@"saveButtons");

    if ( return_code !=  NSOKButton )
        return;
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSString * filename = [panel filename];
    NSArray * button_names = [simParameterModel buttonNames];
    NSDictionary * buttons_by_name = [simParameterModel buttonsDict];

    /* Get a sorted version of the variable list, which is a set. */
    NSMutableArray * buttons_array = [NSMutableArray array]; /* an array */
    for ( NSString * button_name in button_names )
    {
        NSDictionary * button_as_dict = [[buttons_by_name objectForKey: button_name] asPropertyListDictionary];
        [buttons_array addObject:button_as_dict];
    }

    [buttons_array writeToFile:(NSString *)filename atomically:(BOOL)NO];

    [pool release];    
}


// -  parameterscontroller -> simparametermodel -> buttonsDict
-(void) loadButtons:(NSOpenPanel *)panel returnCode:(int)return_code  contextInfo:(void  *)context_info
{
    DebugNSLog(@"loadButtons");

    if ( return_code !=  NSOKButton )
        return;
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSString * filename = [panel filename];
    /* Get a sorted version of the variable list, which is a set. */
    NSMutableArray * buttons_dict_array = [NSMutableArray arrayWithContentsOfFile:filename]; 

    for ( NSDictionary * button_dict in buttons_dict_array )
    {
        SimButton * sb = [[SimButton alloc] init];
        [sb fromPropertyListDictonary:button_dict];
        [simParameterModel addButtonAllowingOverwrite:sb];
        [sb release];
    }

    [pool release];    
}


-(IBAction) pushSaveParameters:(id)sender
{
    NSSavePanel *spanel = [NSSavePanel savePanel];
    [spanel setPrompt:NSLocalizedString(@"Save",nil)];
    [spanel setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];
    [spanel beginSheetForDirectory:NSHomeDirectory()
            file:nil
            modalForWindow: [self window]
            modalDelegate: self
            didEndSelector: @selector(saveParameters: returnCode: contextInfo:)
            contextInfo:NULL];
}


-(IBAction) pushSaveButtons:(id)sender
{
    NSSavePanel *spanel = [NSSavePanel savePanel];
    [spanel setPrompt:NSLocalizedString(@"Save",nil)];
    [spanel setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];
    [spanel beginSheetForDirectory:NSHomeDirectory()
            file:nil
            modalForWindow: [self window]
            modalDelegate: self
            didEndSelector: @selector(saveButtons: returnCode: contextInfo:)
            contextInfo:NULL];
}


-(IBAction) pushLoadParameters:(id)sender
{
    NSArray *file_types = [NSArray arrayWithObject:@"txt"];
    NSOpenPanel *panel = [NSOpenPanel openPanel];

    [panel setAllowsMultipleSelection:YES];
    [panel beginSheetForDirectory: NSHomeDirectory()
           file: nil
           types: file_types
           modalForWindow: [self window]
           modalDelegate: self
           didEndSelector: @selector(loadParameters: returnCode: contextInfo:)
           contextInfo: NULL];
}


-(IBAction) pushLoadButtons:(id)sender
{
    NSArray *file_types = [NSArray arrayWithObject:@"txt"];
    NSOpenPanel *panel = [NSOpenPanel openPanel];

    [panel setAllowsMultipleSelection:YES];
    [panel beginSheetForDirectory: NSHomeDirectory()
           file: nil
           types: file_types
           modalForWindow: [self window]
           modalDelegate: self
           didEndSelector: @selector(loadButtons: returnCode: contextInfo:)
           contextInfo: NULL];
}


/* For the life of me, I can't figure out why these close commands don't close the window. So I'm resorting to releasing
 * self. 100% certain this is the wrong thing to do, but it meets my need and the console doesn't complain.  So
 * there. -DCS:2009/05/23 
 * 
 * In IB, I never connected the window as an outlet to the parameters controller, which is why it didn't work.  I
 * haven't changed anything about how the window closes (purposefully) but I understand why it wasn't working.
 * -DCS:2009/11/05 */
- (IBAction)closeWindow:(id)sender 
{
    DebugNSLog(@"ParametersController closeWindow");
    //DebugNSLog(@"thing %d", [self isWindowLoaded]);
    //DebugNSLog(@"window should close %d", [[self window] windowShouldClose:[self window]]);
    [computeLock unlock];
    //[[self window] performClose:sender];
    [self close];
    [self release];
}

    
- (SimParameterModel *)simParameterModel
{
    return simParameterModel;
}


- (void)setSimParameterModel:(SimParameterModel *)sim_parameter_model
{
    if ( simParameterModel == sim_parameter_model )
        return;
    
    [sim_parameter_model retain];
    [simParameterModel release];
    simParameterModel = sim_parameter_model;
}

-(void)setComputeLock:(NSLock *)compute_lock
{
    if ( computeLock == compute_lock )
        return;
    
    [compute_lock retain];
    [computeLock release];
    computeLock = compute_lock;
}


-(void)showWindow:(id)sender
{    
    /* The frame is set with four variables, which are defined in a rectangle.
     * 1. x - the x coordinate value of the bottom left corner
     * 2. y - the y coordinate value of the bottom left corner
     * 3. width - the width of the window
     * 4. height  - the height of the window
     *
     * So the window is defined by the bottom left point and the top right point. 
     *
     *  (x, y+height) --- (x+width,y+height)
     *    |                    |
     *  (x,y)    -----   (x+width,y)
     */
    NSRect screen_rect = [[NSScreen mainScreen] visibleFrame];    
    NSRect orig_param_frame = [[self window] frame];
    NSRect frame;
    
    frame.origin.x = orig_param_frame.origin.x;
    frame.size.width = orig_param_frame.size.width;
    frame.origin.y = orig_param_frame.origin.y;
    frame.size.height = orig_param_frame.size.height;

    /* Center the parameters window in the middle of the screen. */
    frame.origin.x = screen_rect.size.width/2.0 - frame.size.width/2.0;
    frame.origin.y = screen_rect.size.height/2.0 - frame.size.height/2.0;

    /* If the centereing pushed the parameters window off the screen, then put it back on the screen.  Won't help if the
     * parameters window is bigger than the screen altogether. */
    double full_right = frame.origin.x + frame.size.width;
    double full_up = frame.origin.y + frame.size.height;
    
    if ( full_right > screen_rect.size.width )
        frame.origin.x = frame.origin.x - (full_right - screen_rect.size.width);
    
    if ( full_up > screen_rect.size.height ) 
        frame.origin.y = frame.origin.y - (full_up - screen_rect.size.height);

    [[self window] setFrame:frame display:NO animate:NO];


    [computeLock lock];
    [super showWindow:sender];
    [NSApp runModalForWindow:[self window]];
}

@end
