#import "LockingButton.h"
#import "LockingSlider.h"
#import "SimController.h"
#import "DrawingOperation.h"
#import "DGControllerStateAddition.h"
#import "SCPlotCommand.h"
#import "PlotController.h"
#import "MyDocumentWindowController.h" 
#import "model.h"
#import "DebugLog.h"

/* Should probably have a lock in the simIsRunning variable, but I don't think it matters too much because it's only
 * changed by the main thread (GUI) and the compute thread reads it.  The worst that could happen is that the compute
 * thread goes for one extra plot duration, in an extremely unlucky timing. -DCS:2009/10/24 */


extern NSString * const SCNotifyModelOfButtonChange;
extern NSString * const SCNotifyModelOfParameterChange;


/* Notifications that SimController handles. */
NSString * const SCWriteToControllerConsoleNotification = @"WriteToControllerConsole";
NSString * const SCWriteToControllerConsoleAttributedNotification = @"WriteToControllerConsoleAttributed";

NSString * const SCSilentHistoryControllerName = @"__SiLeNt_HiStOrY__"; // Chances are small. -DCS:2010/01/21


@implementation SimController

/* Shouldn't there be some constructor (or similar concept) here?  What happens if I want to initialize the values in
 * the GUI from loaded data, or from the SimModel or parameterModel or whatever?  One would think there should be a hook
 * before the application renders the window. I guess this is probably more complicated.  -DCS:2009/05/02 */
- (id)init
{
    if ( self = [super init] )
    {    
#ifndef _NO_USER_LIBRARY_       //This definition may be declared as -D_NO_USER_LIBRARY_=1 in other C flags, build information of Xcode. -SHH@7/15/09
        const char* scframepath = getenv("SC_FRAMEWORK_PATH");
        if ( !scframepath )
        {
            DebugNSLog(@"[%s] main: SC_USER_LIBRARY_PATH not set.  Aborting.\n", __FILE__);
            exit(EXIT_FAILURE);
        }
        NSString *framePath = [[NSString alloc] initWithUTF8String:scframepath];
        NSString* nibFilePath = [[NSString alloc] initWithString:@"/SimulationControllerFramework.framework/Versions/A/Resources"];
        framePath = [framePath stringByAppendingString:nibFilePath];
        NSBundle* aBundle = [NSBundle bundleWithPath:framePath];
#else
        NSBundle* aBundle = [NSBundle mainBundle];
#endif
        NSMutableArray *topLevelObjs = [NSMutableArray array]; 
        NSDictionary* nameTable = [NSDictionary dictionaryWithObjectsAndKeys:self, NSNibOwner, topLevelObjs, NSNibTopLevelObjects, nil]; 
        if (![aBundle loadNibFile:@"Simulation" externalNameTable:nameTable withZone:nil]) 
        { 
            DebugNSLog(@"Warning! Could not load myNib file.\n"); 
            return nil; 
        }

        //[self initWithWindowNibName:@"Simulation"];
        //simulationControllerWindow = [self window]; //[[NSWindow alloc] init];

        char * classname;
        int classname_length = 0;
        int i = 0;
        for (i = 0; i < [topLevelObjs count]; i++ )
        {
            classname = (char *)object_getClassName((id)[topLevelObjs objectAtIndex:i]);
            classname_length = 0;
            while ( classname[classname_length] != '\0' )
                classname_length++;

            if ( strcmp(classname, "NSWindow") == 0 )
            {
                DebugNSLog(@"SimController: init found window in top level");
                simulationControllerWindow = [topLevelObjs objectAtIndex:i];
                [self setWindow:simulationControllerWindow];
            }
            
        }

        doPlot = YES;
        simIsRunning = NO;
        fullPlotIter = 0;
        nHistories = 0;
        maxHistoryCount = 276447232;
        displayMode = SC_CONTROLLER_EXPERIMENTAL_MODE;
        
        SCPrivateSetSimControllerPointer((void*)self); /* Let the wrapper layer have a pointer so the user can stop the simulation. */

        scrollerLocation = 0.0;
        plotControllers = [[NSMutableDictionary alloc] init];
        
        
        self.simModel = [[SimModel alloc] init];
        computeLock = [[NSLock alloc] init];
        historySliderLock = [[NSLock alloc] init];
        
        [self windowDidLoad];       // Have to call this myself since I loaded the nib manually? -DCS:2009/05/24
        
        // This will come from somewhere else, but this is good for now. -DCS:2009/05/10
        
        // This will all come from the simulation model, but for the moment we leave it alone, because we build up from the
        // interface to the model. -DCS:2009/05/10    
        //nCores = 2;
        iterThroughCurrentPlot = 0;
        [runButton setTitle:@"Stop"];
    }
    
    return self;
}


- (void)dealloc
{
    DebugNSLog(@"SimController dealloc");
    [simModel release];
    [computeLock release];
    [plotControllers release];
    [super dealloc];
}


@synthesize buttonFontSize;
@synthesize fontSize;
@synthesize parametersController;
@synthesize screenWidth;
@synthesize simModel;
@synthesize doPlot;
@synthesize maxHistoryCount;
@synthesize computeLock;

@synthesize parameter1;
@synthesize parameter2;
@synthesize parameter3;
@synthesize parameter4;
@synthesize parameter5;
@synthesize parameter6;
@synthesize parameter7;
@synthesize parameter8;

@synthesize button1;
@synthesize button2;
@synthesize button3;
@synthesize button4;
@synthesize button5;
@synthesize button6;
@synthesize button7;
@synthesize button8;
@synthesize button9;
@synthesize button10;

/* Update the console by writing the attributed message to the bottom of the text storage. If the scroll bar is already
 * at the bottom, then keep it at the bottom. */
- (void)writeToControllerConsoleAttributedMT:(NSDictionary*)string_and_text_dict
{
    
    NSString * string = [string_and_text_dict objectForKey:@"message"];
    NSDictionary * txt_dict = [string_and_text_dict objectForKey:@"attributes"];

    if ( string == nil )
        return;

    [consoleLock lock];
    
    NSAttributedString *string_to_append = [[NSAttributedString alloc] initWithString:string attributes:txt_dict];
    NSTextStorage * text_storage = [controllerConsole textStorage];
    [text_storage appendAttributedString:string_to_append];
    [string_to_append release];

    NSPoint newScrollOrigin;
    NSRect frame = [[controllerConsoleScroller documentView] frame];
    NSRect bounds = [[controllerConsoleScroller contentView] bounds];
    NSScroller * vertical_scroller = [controllerConsoleScroller verticalScroller];
    scrollerLocation = [vertical_scroller floatValue];
    //NSLog(@"Location: %f\n", scrollerLocation);

    if ( scrollerLocation > 0.8 ) // this solution is a hack, but it should work for the moment. -DCS:2009/08/07
    {
        if ( [[controllerConsoleScroller documentView] isFlipped] ) 
        { 
            newScrollOrigin = NSMakePoint(0.0, NSMaxY(frame) - NSHeight(bounds)); 
        } 
        else 
        { 
            newScrollOrigin = NSMakePoint(0.0,0.0); 
        } 
        [[controllerConsoleScroller documentView] scrollPoint:newScrollOrigin]; 
    }

    [consoleLock unlock];

}


/* Update the console by writing the message to the bottom of the text storage. If the scroll bar is already at the
 * bottom, then keep it at the bottom. */
- (void)writeToControllerConsoleMT:(NSString *)string
{
    if ( string == nil )
        return;

    [consoleLock lock];
    
    NSAttributedString *string_to_append = [[NSAttributedString alloc] initWithString:string];
    NSTextStorage * text_storage = [controllerConsole textStorage];
    [text_storage appendAttributedString:string_to_append];
    [string_to_append release];

    NSPoint newScrollOrigin;
    NSRect frame = [[controllerConsoleScroller documentView] frame];
    NSRect bounds = [[controllerConsoleScroller contentView] bounds];
    NSScroller * vertical_scroller = [controllerConsoleScroller verticalScroller];
    scrollerLocation = [vertical_scroller floatValue];
    //NSLog(@"Location: %f\n", scrollerLocation);

    if ( scrollerLocation > 0.8 ) // this solution is a hack, but it should work for the moment. -DCS:2009/08/07
    {
        if ( [[controllerConsoleScroller documentView] isFlipped] ) 
        { 
            newScrollOrigin = NSMakePoint(0.0, NSMaxY(frame) - NSHeight(bounds)); 
        } 
        else 
        { 
            newScrollOrigin = NSMakePoint(0.0,0.0); 
        } 
        [[controllerConsoleScroller documentView] scrollPoint:newScrollOrigin]; 
    }

    [consoleLock unlock];

}


/* NOTE: For all of these handlers that are responding to the users requests: (waitUntilDone:NO) is the right choice.
 * 
 * If the waitUntilDone is set to YES, then there are going to be mutex deadlocks.  This is because the compute lock is
 * shared between the main thread and the compute thread.  When the user requests a console write or a draw now command
 * (on the compute thread), the compute thread already has the compute lock.  The user's request is handled via the
 * notification system, which ultimately boils down to these handlers being executed.  Crucially, these handlers are
 * also executed in the compute thread, so if there is a waitUntilDone:YES, then the compute thread will wait until the
 * performSelectorOnMainThread selector is finished (obviously run in the main thread). So that's the compute thread
 * waiting on the main thread.  The problem is that the main thread is also what is used for handling all UI events.
 * Almost every button or slider in SC competes for the compute lock (so that's the main thread waiting on the compute
 * thread, potentially), so if these handlers wait, then the thread that holds the lock (compute) will be waiting for a
 * thread requesting the lock (main).  That's the definition of a dead-lock: waiting on a thread that's waiting for you.
 * 
 * Bad news bears.  -DCS:2009/08/22 */


/* Making any modifications to the UI have to be done in the main thread.  I keep forgetting this! -DCS:2009/08/06 */
- (void)writeToControllerConsole:(NSString *)string
{
    [self performSelectorOnMainThread:@selector(writeToControllerConsoleMT:) withObject:string waitUntilDone:NO];
}


/* Making any modifications to the UI have to be done in the main thread.  I keep forgetting this! -DCS:2009/08/06 */
- (void)writeToControllerConsoleAttributed:(NSString *)string attributes:(NSDictionary*)dict
{
    NSArray *keys = [NSArray arrayWithObjects:@"message", @"attributes", nil];
    NSArray *objects = [NSArray arrayWithObjects:string, dict, nil];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];

    [self performSelectorOnMainThread:@selector(writeToControllerConsoleAttributedMT:) withObject:dictionary waitUntilDone:NO];
}


-(void)drawMakeNowCommand:(SCPlotCommand *)plot_command 
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    NSString * plot_name = [plot_command plotName];
    HistoryController * hc = [plotControllers objectForKey:plot_name];
    
    [hc addMakePlotNowCommand:plot_command doPlot:doPlot];

    [pool release];
}


-(void) copyDataFromPlot:(NSString *)plot_name
             forVariable:(NSString *)var_name 
              historyIdx:(int)history_idx
             sampleEvery:(int)sample_every
              dataPtrPtr:(double**)data_ptr_ptr
              nValuesPtr:(int *)nvalues_ptr
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    HistoryController * hc = [plotControllers objectForKey:plot_name];

    BOOL copied_ok = [hc copyDataForVariable:var_name 
                         historyIdx:history_idx 
                         sampleEvery: sample_every
                         dataPtrPtr:data_ptr_ptr 
                         nValuesPtr:nvalues_ptr];
    
    if ( !copied_ok )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: SCCopyDataFromHistoryWithIndex function for variable %@ with history %i and downsample rate %i had an error.  Either the history index is out of bounds or the downsample rate resulted in saving 0 points.  Data not copied and the length was set to 0.\n", var_name, history_idx, sample_every]];        
    }

    [pool release];
}


-(void) copyFlatDataFromPlot:(NSString *)plot_name
                 forVariable:(NSString *)var_name 
             historyStartIdx:(int)history_start_idx 
              historyStopIdx:(int)history_stop_idx
                 sampleEvery:(int)sample_every
                  dataPtrPtr:(double **)data_ptr_ptr
                  nValuesPtr:(int *)nvalues_ptr
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    HistoryController * hc = [plotControllers objectForKey:plot_name];

    BOOL copied_ok = [hc copyFlatDataForVariable: var_name 
                         historyStartIdx: history_start_idx 
                         historyStopIdx: history_stop_idx 
                         sampleEvery: sample_every
                         dataPtrPtr: data_ptr_ptr 
                         nValuesPtr: nvalues_ptr];
    
    if ( !copied_ok )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: SCCopyFlatDataFromHistories function for variable %@ with histories indices [%i,%i] and downsample rate %i.  Either the indicies are out of bounds or the downsample rate resulted in saving 0 points.  Data not copied and the length was set to 0.\n", var_name, history_start_idx, history_stop_idx, sample_every]];        
    }

    [pool release];

}


-(void) copyStructuredDataFromPlot:(NSString *)plot_name
                       forVariable:(NSString *)var_name 
                   historyStartIdx:(int)history_start_idx 
                    historyStopIdx:(int)history_stop_idx
                       sampleEvery:(int)sample_every
                     dataPtrPtrPtr:(double ***)data_ptr_ptr_ptr
                     nValuesPtrPtr:(int **)nvalues_ptr_ptr
{

    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    HistoryController * hc = [plotControllers objectForKey:plot_name];

    BOOL copied_ok = [hc copyStructuredDataForVariable: var_name 
                         historyStartIdx: history_start_idx 
                         historyStopIdx: history_stop_idx 
                         sampleEvery: sample_every
                         dataPtrPtrPtr: data_ptr_ptr_ptr 
                         nValuesPtrPtr: nvalues_ptr_ptr];
    
    if ( !copied_ok )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: SCCopyStructuredDataFromHistories function for variable %@ with history indices [%i, %i] and downsample rate %i.  Either the indices are out of bounds or the downsample rate resulted in saving 0 points.  Data not copied and the length was set to 0.\n", var_name, history_start_idx, history_stop_idx, sample_every]];        
    }

    [pool release];
    
}



- (void)clearMakeNowPlots:(NSString *)plot_name
{
    HistoryController * hc = [plotControllers objectForKey:plot_name];
    [hc clearPlotOfMakeNowPlots];
}


-(void) clearAllPlotHistoriesOfVariable:(NSString *)var_name
{
    for ( NSString * plot_name in plotControllers )
    {
        HistoryController * hc = [plotControllers objectForKey:plot_name];
        [hc clearCurrentValuesForVariable:var_name];
    }
}

- (void)clearHistory:(NSString *)plot_name varName:(NSString *)var_name
{
    HistoryController * hc = [plotControllers objectForKey:plot_name];
    [hc clearCurrentValuesForVariable:var_name];
}



/* The hook that is called from the notification system. */
- (void)handleControllerConsole:(NSNotification*)note
{
    NSString *string = [[note userInfo] objectForKey:@"message"];
    [self writeToControllerConsole:string];
}


/* The hook that is called from the notification system. */
- (void)handleControllerConsoleAttributed:(NSNotification*)note
{
    NSString *string = [[note userInfo] objectForKey:@"message"];
    NSDictionary * dict = [[note userInfo] objectForKey:@"attributes"];
    [self writeToControllerConsoleAttributed:string attributes:dict];
}


/* These are local for the class, which still uses the notification system. I'm not sure if this is overblown or not. -DCS:2009/08/19 */
-(void)writeWarningToConsole:(NSString*)text 
{
    NSColor *txtColor = [NSColor redColor];
    NSFont *txtFont = [NSFont boldSystemFontOfSize:11];
    NSDictionary *txtDict = [NSDictionary
                                dictionaryWithObjectsAndKeys:txtFont,
                                NSFontAttributeName, txtColor, 
                                NSForegroundColorAttributeName, nil];


    NSArray *keys = [NSArray arrayWithObjects:@"message", @"attributes", nil];
    NSArray *objects = [NSArray arrayWithObjects:text, txtDict, nil];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:SCWriteToControllerConsoleAttributedNotification object:self userInfo:dictionary];
}


/* These are local for the class, which still uses the notification system. I'm not sure if this is overblown or not. -DCS:2009/08/19 */
-(void)writeStatusToConsole:(NSString*)text 
{
    NSColor *txtColor = [NSColor blackColor];
    NSFont *txtFont = [NSFont boldSystemFontOfSize:13];
    NSDictionary *txtDict = [NSDictionary
                                dictionaryWithObjectsAndKeys:txtFont,
                                NSFontAttributeName, txtColor, 
                                NSForegroundColorAttributeName, nil];


    NSArray *keys = [NSArray arrayWithObjects:@"message", @"attributes", nil];
    NSArray *objects = [NSArray arrayWithObjects:text, txtDict, nil];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:SCWriteToControllerConsoleAttributedNotification object:self userInfo:dictionary];
}


/* Used to let the user programmatically stop the simulation based on a condition. */
- (void)stopRunning
{
    simIsRunning = NO;
    [runButton setTitle:@"Stop"];
    [runButton setState:NSOffState];
    //[self writeStatusToConsole:@"Simulation stopped by model.\n"];
}

    
/* If the simulation controller window loaded then we go further with the initializations, including initializing the
 * simModel, which calls the users init functions. */
- (void)windowDidLoad
{
    DebugNSLog(@"SimController Nib file is loaded");

    /* Register the SimController as the observer for notifications related to printing to the controller console. */
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
        selector:@selector(handleControllerConsole:)
        name:SCWriteToControllerConsoleNotification
        object:nil];
    [nc addObserver:self
        selector:@selector(handleControllerConsoleAttributed:)
        name:SCWriteToControllerConsoleAttributedNotification
        object:nil];

    /* Share the compute lock with everybody and their mother. */
    [runButton setLock:[self computeLock]];
    [plotButton setLock:[self computeLock]];
    [parameter1 setLock:[self computeLock]];
    [parameter2 setLock:[self computeLock]];
    [parameter3 setLock:[self computeLock]];
    [parameter4 setLock:[self computeLock]];
    [parameter5 setLock:[self computeLock]];
    [parameter6 setLock:[self computeLock]];
    [parameter7 setLock:[self computeLock]];
    [parameter8 setLock:[self computeLock]];
    [button1 setLock:[self computeLock]];
    [button2 setLock:[self computeLock]];
    [button3 setLock:[self computeLock]];
    [button4 setLock:[self computeLock]];
    [button5 setLock:[self computeLock]];
    [button6 setLock:[self computeLock]];
    [button7 setLock:[self computeLock]];
    [button8 setLock:[self computeLock]];
    [button9 setLock:[self computeLock]];
    [button10 setLock:[self computeLock]];
    [buttonSliderUp1 setLock:[self computeLock]];
    [buttonSliderUp2 setLock:[self computeLock]];
    [buttonSliderUp3 setLock:[self computeLock]];
    [buttonSliderUp4 setLock:[self computeLock]];
    [buttonSliderUp5 setLock:[self computeLock]];
    [buttonSliderUp6 setLock:[self computeLock]];
    [buttonSliderUp7 setLock:[self computeLock]];
    [buttonSliderUp8 setLock:[self computeLock]];
    [buttonSliderDown1 setLock:[self computeLock]];
    [buttonSliderDown2 setLock:[self computeLock]];
    [buttonSliderDown3 setLock:[self computeLock]];
    [buttonSliderDown4 setLock:[self computeLock]];
    [buttonSliderDown5 setLock:[self computeLock]];
    [buttonSliderDown6 setLock:[self computeLock]];
    [buttonSliderDown7 setLock:[self computeLock]];
    [buttonSliderDown8 setLock:[self computeLock]];


    [buttonAllSlidersDown setLock:[self computeLock]];
    [buttonAllSlidersUp setLock:[self computeLock]];
    [sliderAllHistories setLock:[self computeLock]];

    [sliderAllHistories setDoubleValue:1.0];
    [sliderAllHistories setMaxValue:1.0];
    [sliderAllHistories setMinValue:1.0];
    [sliderAllHistories setEnabled:NO];
    [buttonAllSlidersUp setEnabled:NO];
    [buttonAllSlidersDown setEnabled:NO];

    
    [self.simModel setSimController:self];
    [self.simModel setComputeLock:[self computeLock]];
    
    /* Final details. */
    //NSString *string = @"Welcome to SimulationController!\n";
    //[self writeStatusToConsole:string];
//     NSString *string2 = @"Reading user's simulation info.\n";
//     [self writeStatusToConsole:string2];

    /* Get the plot parameters from the simmodel.  Don't erase the self references!  It's related to the KVC for the UI
     * bindings. Use the two printouts below and above to determine any possible errors in the user's init code. */
    [self.simModel initSimulation];

//     NSString *string3 = @"Finished user's init.\n";
//     [self writeStatusToConsole:string3];

    self.fontSize = [NSNumber numberWithInt:10];
    self.buttonFontSize = [NSNumber numberWithInt:10];
    [plotButton setState:NSOnState];
}


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
- (void) setControllerFrameInExperimentalMode
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];

    /* Set the location and scale the controller window to the screen size. */
    // Should probably register with some method to get notified of any screen changes, but I don't really care at this
    // point. -DCS:2009/05/12
    NSRect orig_sim_frame = [simulationControllerWindow frame];

    NSRect frame;
    frame.origin.x = screenWidth-orig_sim_frame.size.width;
    frame.origin.y = screenHeight; 
    frame.size.width = orig_sim_frame.size.width;
    frame.size.height = screenHeight;
    
    [simulationControllerWindow setFrame:frame display:YES animate:NO];
    [simulationControllerWindow orderFront:self];
    //[simulationControllerWindow deminiaturize:self];

    if ( !simModel )
    {
        [pool release];
        return;
    }
    
    NSRect sim_controller_frame = [simulationControllerWindow frame];    
    NSDictionary * window_parameters = [simModel windowParametersByPlotName];
    for ( NSString * plotname in plotControllers )
    {
        PlotController * pc = [plotControllers objectForKey:plotname];
        DefaultAxisParameters * axis_parameters_for_plot = [simModel axisParametersByPlotName:plotname];
        // Size and place the windows.
        // Get the plot controller
        NSWindow *w = [pc docWindow];
 
        if ( [plotname compare:SCSilentHistoryControllerName] == NSOrderedSame )
        {
            [w close];
        }
        else
        {
            NSRect window_parameter = [[window_parameters objectForKey:plotname] rectValue];
            // Not sure where the window data is going to come from, but we'll skip this for now.
            //NSRect frame;
            frame.origin.x = (screenWidth-sim_controller_frame.size.width)*window_parameter.origin.x;
            frame.origin.y = screenHeight*window_parameter.origin.y;
            frame.size.width = (screenWidth-sim_controller_frame.size.width)*window_parameter.size.width;
            frame.size.height = screenHeight*window_parameter.size.height;
            //[w setFrameOrigin:frame_origin];
            [w setFrame:frame display:YES animate:NO];
            if ( ![axis_parameters_for_plot isActive] )
            {
                [w orderOut:self];
                [w miniaturize:self];
            }
        }
    }

    [pool release];
}


- (void) setControllerFrameInDemoMode
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];

    /* Set the location and scale the controller window to the screen size. */
    // Should probably register with some method to get notified of any screen changes, but I don't really care at this
    // point. -DCS:2009/05/12
    NSRect orig_sim_frame = [simulationControllerWindow frame];
    NSRect screen_rect = [[NSScreen mainScreen] visibleFrame];    
    NSRect frame;
    frame.origin.x = screenWidth-orig_sim_frame.size.width;
    frame.origin.y = screenHeight; 
    frame.size.width = orig_sim_frame.size.width;
    frame.size.height = screenHeight;
    [simulationControllerWindow setFrame:frame display:NO animate:NO];
    [simulationControllerWindow orderBack:self];
//    [simulationControllerWindow miniaturize:self];

    if ( !simModel )
    {
        [pool release];
        return;
    }

    NSDictionary * window_parameters = [simModel windowParametersByPlotName];
    for ( NSString * plotname in plotControllers )
    {
        DefaultAxisParameters * axis_parameters_for_plot = [simModel axisParametersByPlotName:plotname];

        PlotController * pc = [plotControllers objectForKey:plotname];
        NSWindow *w = [pc docWindow];
        NSRect window_parameter = [[window_parameters objectForKey:plotname] rectValue];

        if ( [plotname compare:SCSilentHistoryControllerName] == NSOrderedSame )
        {
            [w close];
        }
        else
        {
            NSRect frame;
            frame.origin.x = screen_rect.size.width * window_parameter.origin.x;
            frame.origin.y = screenHeight * window_parameter.origin.y;
            frame.size.width = screen_rect.size.width * window_parameter.size.width;
            frame.size.height = screenHeight * window_parameter.size.height;
            
            [w setFrame:frame display:YES animate:NO];
            if ( ![axis_parameters_for_plot isActive] )
            {
                [w orderOut:self];        
                [w miniaturize:self];
            }
        }
    }

    [pool release];
}


- (IBAction) toggleDisplayMode:(id)sender
{
    switch ( displayMode )
    {
    case SC_CONTROLLER_EXPERIMENTAL_MODE:
        displayMode = SC_CONTROLLER_DEMONSTRATION_MODE;
        [self setControllerFrameInDemoMode];
        break;
    case SC_CONTROLLER_DEMONSTRATION_MODE:
        displayMode = SC_CONTROLLER_EXPERIMENTAL_MODE;
        [self setControllerFrameInExperimentalMode];
        break;
    default:
        assert ( 0 );
    }
}


- (void) buildPlots
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    DebugNSLog(@"SimController %i\n", maxHistoryCount);
    

    // call out to each plot to set these keys.  don't forget about the time, which is special.
    PlotController *pc;
    NSEnumerator *enumerator = [plotControllers keyEnumerator];
    NSString *plotname;
    while ( plotname = [enumerator nextObject] ) 
    {
        pc = [plotControllers objectForKey:plotname];
        [(HistoryController *)pc setMaxHistoryCount: maxHistoryCount];
        [pc setNPointsToSave:[simModel nStepsInFullPlot]];
        [pc setDoClearPlotNowCommandsAfterEachDuration:[simModel getDoClearMakeNowPlotsByName:plotname]];
        DefaultAxisParameters * axis_parameters_for_plot = [simModel axisParametersByPlotName:plotname];
        [pc setDefaultAxisParameters:axis_parameters_for_plot];

        NSArray * plot_commands_for_plot = [simModel commandsByPlotName:plotname];
        [pc setPlotCommandDataList:plot_commands_for_plot];
        [pc setDoPlotInMainThread:![simModel doPlotInParallel]];
        NSDictionary * color_schemes_for_plot = [simModel colorSchemesByPlotName:plotname];
        [pc setColorSchemes:color_schemes_for_plot];
        [pc buildPlotCommand];
    };

    /* Don't enable the sliders if the max history count is zero. */
    if ( maxHistoryCount == 0 )
    {
        [buttonAllSlidersDown setHidden:YES];
        [buttonAllSlidersUp setHidden:YES];
        [sliderAllHistories setHidden:YES];
        //[sliderAllHistoriesValue setHidden:YES];  // leave a marker of how many times the plot turns over. -DCS:2009/11/05
        [buttonAllSlidersDownValue setHidden:YES];
        [buttonAllSlidersUpValue setHidden:YES];
    }
    
    /* Now make the simulation controller window the main/key window, so that it's immediately responsive to the
     * user. */
    [self setControllerFrameInExperimentalMode];  // called here to correctly set the controller window size in the first place regardless of the mode initialized.
    [simulationControllerWindow makeMainWindow];
    [simulationControllerWindow makeKeyWindow];
    [pool release];
}    


- (void) loadPlots
{
    DebugNSLog(@"SimController loadPlots");
    NSAutoreleasePool *big_pool = [NSAutoreleasePool new];
    
    
#ifndef _NO_USER_LIBRARY_
    // DGFR-mdGHig-8xrru-H0k9k-wGG0R-6YNJJ-FgPc0-1eifn-90Tgj-tkJyx-nn7dp-wP4Fj-W1Xu7-hYmzd-YT
    char mungedRegistration[87] = {-73, 45, -97, 30, 108, 31, -119, -33, 83, -25, 88, -111, 15, -62, 47, -94, 24, 67, -47, 44, -38, 27, -64, -11, -78, -11, 104, -60, 89, -89, 35, -71, 33, -112, 3, 89, -27, 121, -43, 91, -101, 11, -126, 41, -96, 16, -117, -67, 60, -90, 61, -61, 57, 111, 41, -109, -27, -121, -7, 33, -43, 72, -124, 36, -93, -45, -112, -36, 51, -72, 79, -123, 34, 111, 9, -103, -50, 55, -27, 73, -48, 80, -83, -23, -120, -10, 0};
// sussillo@ee.columbia.edu
    char mungedEMail[25] = {-26, 91, -52, 63, -88, 30, -111, 7, 75, -29, 86, -110, 58, -71, 41, -91, 16, 120, -14, 93, -99, 71, -71, 61, 0};
    int charN;
    for (charN=0;charN<86;charN++) mungedRegistration[charN] -= ((charN+1)*731251)%256;
    for (charN=0;charN<24;charN++) mungedEMail[charN] -= ((charN+1)*731251)%256;
    NSString *registrationString = [NSString stringWithCString:mungedRegistration encoding:NSUTF8StringEncoding];
    NSString *emailString = [NSString stringWithCString:mungedEMail encoding:NSUTF8StringEncoding];
    // Enable the controller
    [DGController setFrameworkRegistrationEMail:emailString code:registrationString];

#else
    /* This is the registration code used to get rid of the watermark in SimulationConrtroller DG windows. */
    // DGFR-R97QGi-i7jCQ-xLk9k-wGG0R-NH54E-RapLi-FgGAK-280a7-yxhDx-nkCA9-wtJLJ-7GXu7-4HnPd-YT
    char mungedRegistration[87] = {-73, 45, -97, 30, 108, 4, 94, -49, 92, -59, 90, -111, 64, -127, 39, 115, -12, 67, 1, 72, -38, 27, -64, -11, -78, -11, 104, -60, 89, -89, 59, -88, 8, 122, -2, 89, -15, 115, -11, 68, -44, 11, -105, 43, 126, -21, 104, -67, 53, -82, 25, -67, 6, 111, 46, -96, 3, 82, -7, 33, -43, 69, -112, 1, 108, -45, -112, 0, 73, -66, 47, -123, 2, -123, 9, -103, -50, 55, -79, 56, -47, 38, -83, -23, -120, -10, 0};
    // sussillo@ee.columbia.edu
    char mungedEMail[25] = {-26, 91, -52, 63, -88, 30, -111, 7, 75, -29, 86, -110, 58, -71, 41, -91, 16, 120, -14, 93, -99, 71, -71, 61, 0};
    int charN;
    for (charN=0;charN<86;charN++) mungedRegistration[charN] -= ((charN+1)*731251)%256;
    for (charN=0;charN<24;charN++) mungedEMail[charN] -= ((charN+1)*731251)%256;
    NSString *registrationString = [NSString stringWithCString:mungedRegistration encoding:NSUTF8StringEncoding];
    NSString *emailString = [NSString stringWithCString:mungedEMail encoding:NSUTF8StringEncoding];
    // Enable the controller
    [DGController setFrameworkRegistrationEMail:emailString code:registrationString];
    /* Done with registration code. */
#endif    



    int n_plots = [[self.simModel plotNames] count];

    // Open empty plots
    int i = 0;
    for ( i = 0; i < n_plots+1; i++ ) // add one for the "__silent__" plot
    {
#ifndef _NO_USER_LIBRARY_
        [documentController addDocument:[documentController openUntitledDocumentAndDisplay:YES error:nil]];
#else
        [documentController openUntitledDocumentAndDisplay:YES error:nil];
#endif
    }
    
    // Start initalizing the plot with data from the simulation.  Probably can get the documents from the controller
    // right here and begin modifying the properties, like where the window is located.  Have to tell the plot
    // controllers what they are going to be expecting in terms of data and symbols and all that other mess, but for
    // now, we ignore it. -DCS:2009/05/10
    NSAutoreleasePool *pool;

    
    // Should probably register with some method to get notified of any screen changes, but I don't really care at this
    // point. -DCS:2009/05/12
    NSRect screen_rect = [[NSScreen mainScreen] visibleFrame];    
    screenHeight = screen_rect.size.height;
    screenWidth = screen_rect.size.width;


    // Initialize the plot controllers and arrays, etc.
    NSString *silent_plot_name = [NSString stringWithString:SCSilentHistoryControllerName];
    NSArray *user_plot_names = simModel.plotNames;
    NSMutableArray * plot_names = [NSMutableArray arrayWithArray:user_plot_names];
    [plot_names addObject:silent_plot_name];
    NSArray *documents = documentController.documents;         
    NSEnumerator * doc_enumerator = [documents objectEnumerator];
    id doc;
    MyDocumentWindowController *wc;
    PlotController *pc;
    int plot_number = 0;
    
    while ( doc = [doc_enumerator nextObject] )
    {
        pool = [NSAutoreleasePool new];

        // Size and place the windows.
        // Get the plot controller
        NSArray * wcs = [doc windowControllers];
        wc = [wcs objectAtIndex:0];
        NSWindow *w = [wc window];
        pc = [wc historyController];

        [doc setSimController:self]; /* This is the MyDocument class.  */
        [pc setDocWindow:w];
        DebugNSLog(@"PlotController showing %@", pc);                

        // Set the window name. 
        NSString *plot_name = [plot_names objectAtIndex:plot_number];
        [pc setPlotName:plot_name];
        [wc synchronizeWindowTitleWithDocumentName];
        [pc setComputeLock:[self computeLock]];           
        
        // Set the window size. 
        [plotControllers setObject:pc forKey:plot_name];
        plot_number++;
        [pool release];
    }

    /* Make sure the silent history isn't plotting. */
    doc_enumerator = [documents objectEnumerator];
    while ( doc = [doc_enumerator nextObject] )
    {
        NSArray * wcs = [doc windowControllers];
        wc = [wcs objectAtIndex:0];
        pc = [wc historyController];
        if ( [[pc plotName] compare:SCSilentHistoryControllerName] == NSOrderedSame )
            [(HistoryController *)pc setIsPlottingHistoryController:NO];    
    }
    
    [self buildPlots];

    DebugNSLog(@"%@", plotControllers);

    [big_pool release];

    /* Start the simulation immediately if the user requested it.  */
    // I'm not certain the end of the loadPlots function is the correct place for this, but it's either this or in
    // SCAppController, which seems way of. -DCS:2009/08/14
    if ( [simModel doRunImmediatelyAfterInit] )
    {
        [runButton setState:NSOnState];
        [self pushRun:nil];
    }

    if ( [simModel doOpenInDemoMode ] )
    {
        displayMode = SC_CONTROLLER_DEMONSTRATION_MODE;
        [self setControllerFrameInDemoMode];
    }
    else
    {
        displayMode = SC_CONTROLLER_EXPERIMENTAL_MODE;
        [self setControllerFrameInExperimentalMode];
    }

}


// - (void) setParametersController:(ParametersController *)pc
// {
//     parametersController = pc;
// }

- (void)setDocumentController:(SCDocumentController *)dc
{
    documentController = dc;
}


/* Send a message back to the model that a particular button has been pushed, and what the state of the button is. */
- (void)toggleButtonAbstract:(NSString *)button_id_string
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];    

    /* Take the lock because we are changing a model parameter value and the model could become inconsistent if we don't
     * wait for an interruption. Later, a lock is also set when the callback occurs, for similar considerations. */
    /* I don't know why this doesn't lock when putting a computeLock on the slider increment buttons does lock. They are
     * both locking buttons.  Further, there isn'ts any sort of update mechanism for the sliders, which are bound to the
     * values.  So there is a danger of mixing up values there, I guess.  In both cases, the parameter action and button
     * action is launched in a separate thread, both a compute lock, so that's safe.  -DCS:2010/02/01 */
    [computeLock lock];         

    NSButton * button = [self valueForKey:button_id_string]; /* KVC */
    NSInteger state = [button state];
    if ( state == NSOnState )
        [button setState:NSOffState];
    else
        [button setState:NSOnState];

    SimParameterModel * sim_parameter_model = [self.simModel simParameterModel];
    SimButton * sim_button = [sim_parameter_model valueForKey:button_id_string];    /* KVC */
    
    double value = [sim_button value];
    [sim_button setValue:!value];

    [computeLock unlock];
    [pool release];
}


/* These are used to notify the model that a button has been pushed in the ButtonAction function. */
- (IBAction) pushButton1:(id)sender 
{    
    DebugNSLog(@"pushButton1\n");
}

- (IBAction) toggleButton1:(id)sender 
{
    [self toggleButtonAbstract:@"button1"];
}


- (IBAction)pushButton2:(id)sender 
{
}
- (IBAction) toggleButton2:(id)sender 
{
    [self toggleButtonAbstract:@"button2"];
}


- (IBAction)pushButton3:(id)sender 
{
}

- (IBAction) toggleButton3:(id)sender 
{
    [self toggleButtonAbstract:@"button3"];
}


- (IBAction)pushButton4:(id)sender 
{
}
- (IBAction) toggleButton4:(id)sender 
{
    [self toggleButtonAbstract:@"button4"];
}

- (IBAction)pushButton5:(id)sender 
{
}
- (IBAction) toggleButton5:(id)sender 
{
    [self toggleButtonAbstract:@"button5"];
}

- (IBAction)pushButton6:(id)sender 
{
}
- (IBAction) toggleButton6:(id)sender 
{
    [self toggleButtonAbstract:@"button6"];
}

- (IBAction)pushButton7:(id)sender 
{
}
- (IBAction) toggleButton7:(id)sender 
{
    [self toggleButtonAbstract:@"button7"];
}

- (IBAction)pushButton8:(id)sender 
{
}
- (IBAction) toggleButton8:(id)sender 
{
    [self toggleButtonAbstract:@"button8"];
}

- (IBAction)pushButton9:(id)sender 
{
}
- (IBAction) toggleButton9:(id)sender 
{
    [self toggleButtonAbstract:@"button9"];
}

- (IBAction)pushButton10:(id)sender 
{
}
- (IBAction) toggleButton10:(id)sender 
{
    [self toggleButtonAbstract:@"button10"];
}


/* Send a message back to the model that a particular parameter has been changed, and what the value of the parameter
 * is. */
- (void)touchedSliderAbstract:(NSString *)slider_id_string
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

//     SimParameterModel * sim_parameter_model = [self.simModel simParameterModel];
//     SimParameter * parameter = [sim_parameter_model valueForKey:slider_id_string];    /* KVC */
    
//     double value = [parameter value];
//     NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//     NSValue *wrappedValue = [NSValue valueWithBytes:&value objCType:@encode(double)];

//     NSArray *keys = [NSArray arrayWithObjects:@"parameterName", @"parameterValue", nil];
//     NSArray *objects = [NSArray arrayWithObjects:[parameter name], wrappedValue, nil];
//     NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];

//     [nc postNotificationName:SCNotifyModelOfParameterChange object:self userInfo:dictionary];

    [pool release];
}

- (IBAction)touchedSlider1:(id)sender 
{
    [self touchedSliderAbstract:@"parameter1"];
}

- (IBAction)touchedSlider2:(id)sender 
{
    [self touchedSliderAbstract:@"parameter2"];
}

- (IBAction)touchedSlider3:(id)sender 
{
    [self touchedSliderAbstract:@"parameter3"];
}

- (IBAction)touchedSlider4:(id)sender 
{
    [self touchedSliderAbstract:@"parameter4"];
}

- (IBAction)touchedSlider5:(id)sender 
{
    [self touchedSliderAbstract:@"parameter5"];
}

- (IBAction)touchedSlider6:(id)sender 
{
    [self touchedSliderAbstract:@"parameter6"];
}

- (IBAction)touchedSlider7:(id)sender 
{
    [self touchedSliderAbstract:@"parameter7"];
}

- (IBAction)touchedSlider8:(id)sender 
{
    [self touchedSliderAbstract:@"parameter8"];
}

#define SLIDER_INCREMENT 50.0

- (void)pushedSliderIncrementAbstract:(NSString *)slider_id_string wasUp:(BOOL)was_up
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    /* Update the SimParameterModel class. */
    SimParameterModel * sim_parameter_model = [self.simModel simParameterModel];
    SimParameter * parameter = [sim_parameter_model valueForKey:slider_id_string];    /* KVC */

    double max_value = [parameter maxValue];
    double min_value = [parameter minValue];
    double value = [parameter value];
    double new_value = 0.0;
    if ( was_up )
        new_value = value + (max_value - min_value)/SLIDER_INCREMENT;
    else
        new_value = value - (max_value - min_value)/SLIDER_INCREMENT;

    if ( new_value < min_value )
        new_value = min_value;
    if ( new_value > max_value )
        new_value = max_value;
    
    [parameter setValue:new_value];

    [pool release];
}

- (IBAction)pushSliderUp1:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter1" wasUp:YES];
}

- (IBAction)pushSliderUp2:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter2" wasUp:YES];
}

- (IBAction)pushSliderUp3:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter3" wasUp:YES];
}

- (IBAction)pushSliderUp4:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter4" wasUp:YES];
}

- (IBAction)pushSliderUp5:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter5" wasUp:YES];
}

- (IBAction)pushSliderUp6:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter6" wasUp:YES];
}

- (IBAction)pushSliderUp7:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter7" wasUp:YES];
}

- (IBAction)pushSliderUp8:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter8" wasUp:YES];
}


- (IBAction)pushSliderDown1:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter1" wasUp:NO];
}

- (IBAction)pushSliderDown2:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter2" wasUp:NO];
}

- (IBAction)pushSliderDown3:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter3" wasUp:NO];
}

- (IBAction)pushSliderDown4:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter4" wasUp:NO];
}

- (IBAction)pushSliderDown5:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter5" wasUp:NO];
}

- (IBAction)pushSliderDown6:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter6" wasUp:NO];
}

- (IBAction)pushSliderDown7:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter7" wasUp:NO];
}

- (IBAction)pushSliderDown8:(id)sender
{
    [self pushedSliderIncrementAbstract:@"parameter8" wasUp:NO];
}




- (void)alertEnded:(NSAlert *)alert code:(int)choice context:(void*)v
{
    DebugNSLog(@"Alert sheet ended");
    if ( choice == NSAlertDefaultReturn )
    {
        //[[controllerConsole textStorage] setAttributedString:@""];
        [consoleLock lock];
        [controllerConsole setString:@""];
        [consoleLock unlock];
    }    
}

- (IBAction)pushClearConsole:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Delete?" 
                              defaultButton:@"Delete" 
                              alternateButton:@"Cancel" 
                              otherButton:nil
                              informativeTextWithFormat:@"Do you really want to delete the text in the console?"];
    
    DebugNSLog(@"Starting alert sheet");
    [alert beginSheetModalForWindow:[self window]
           modalDelegate:self
           didEndSelector:@selector(alertEnded:code:context:)
           contextInfo:NULL];
}


/* The notification only seems to be received when the upper left red button is hit, not the OK button, which was
 * connected to my closeWindow method in ParametersController. So for the time being I'm just going to disable that Ok
 * button. */
-(void)handleParametersWindow:(NSNotification *)note
{
    DebugNSLog(@"Received notification");
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    // This is a little better than removing the object for notifications without any qualifications.  I'd really like
    // to remove the notifications about the parametercontorller window that just went away, but I don't feel like
    // saving that id as part of the class, for some reason. -DCS:2009/05/23
    //NSDictionary *stuff = [note userInfo];
    //DebugNSLog(stuff);

    NSWindow * w = [[self parametersController] window];
    [NSApp stopModal];

    [nc removeObserver:self name:NSWindowWillCloseNotification object:w];
    [[self parametersController] release];
    [self setParametersController:nil];

    if ( nHistories < 2 )       // Don't know where else to put this, but it seems hacky here. -DCS:2009/10/29
    {
        [sliderAllHistories setEnabled:NO];
        [buttonAllSlidersUp setEnabled:NO];
        [buttonAllSlidersDown setEnabled:NO];
    }

    [computeLock unlock];
}


// This function is hacked. How does the sim parameter panel get released? -DCS:2009/05/24

// KSingleItemSelectorController *newSelector = [[self alloc] initWithWindowNibName:@"SingleItemSelector"];
// [NSBundle loadNibNamed:[newSelector windowNibName] owner:newSelector];
// [NSApp runModalForWindow:[newSelector window]];

// 	id keepThis = newSelector.returnValue;
// 	[newSelector release];	


// 	return keepThis;


- (IBAction)showParametersPanel:(id)sender
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    if (!parametersController )
        [parametersController release];
    
    self.parametersController = [[ParametersController alloc] init];

    NSWindow *w = [self.parametersController window];
     
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
        selector:@selector(handleParametersWindow:)
        name:NSWindowWillCloseNotification
        object:w];

    
    // If the Parameter can send out a notification, we can keep the compute lock in the family. -DCS:2009/05/23
    [self.parametersController setSimParameterModel:[simModel simParameterModel]];
    [self.parametersController setComputeLock:[self computeLock]];
    DebugNSLog(@"showing %@", parametersController);    

    [self.parametersController showWindow:sender];
    


    //[self setParametersController:nil];
    [pool release];
}


- (IBAction)pushParameters:(id)sender 
{
    // The NIB is already loaded, so all we have to do is get the window to show.  It's connected via IB
    DebugNSLog(@"pushParameters");

    //[plotButton setState:NSOffState];
    if ( self.parametersController == nil )
    {
        [self showParametersPanel:sender];
        //[[self.simModel simParameterModel] notifyUserOfChanges];
    }
    DebugNSLog(@"end pushParameters");
}


/* This is used when the user actually presses the button. */
- (IBAction)pushRun:(id)sender 
{
    NSInteger state = [runButton state];
    DebugNSLog(@"rb state: %d", [runButton state]);
    if ( state == NSOnState )
    {
        //[self writeStatusToConsole:@"Start computational thread.\n"];
        simIsRunning = YES;
        [runButton setTitle:@"Run"];
        if ( [simModel doRedrawBasedOnTimer] )
            [NSThread detachNewThreadSelector:@selector(computeBasedOnTiming:) toTarget:self withObject:nil];
        else
            [NSThread detachNewThreadSelector:@selector(computeBasedOnNSteps:) toTarget:self withObject:nil];
    }
    else
    {
        simIsRunning = NO;
        [runButton setTitle:@"Stop"];
        //[self writeStatusToConsole:@"Stop computational thread.\n"];
        //[runButton setState:NSOnState];
    }
}

/* This is used when the user turns toggles the button from the menu, so we have to update the button state manually. */
- (IBAction) toggleRun:(id)sender 
{
    NSInteger state = [runButton state];
    DebugNSLog(@"rb state: %d", [runButton state]);
    if ( state == NSOffState )
    {
        [runButton setState:NSOnState];
        //[self writeStatusToConsole:@"Start computational thread.\n"];
        simIsRunning = YES;
        [runButton setTitle:@"Run"];
        if ( [simModel doRedrawBasedOnTimer] )
            [NSThread detachNewThreadSelector:@selector(computeBasedOnTiming:) toTarget:self withObject:nil];
        else
            [NSThread detachNewThreadSelector:@selector(computeBasedOnNSteps:) toTarget:self withObject:nil];
    }
    else
    {
        [runButton setState:NSOffState];
        simIsRunning = NO;
        [runButton setTitle:@"Stop"];
        //[self writeStatusToConsole:@"Stop computational thread.\n"];
        //[runButton setState:NSOnState];
    }
}


-(void)didEndSaveSheet:(NSSavePanel*)sheet returnCode:(int)code contextInfo:(void *)contextInfo
{
    if ( code != NSOKButton )
        return;
    
    NSString * path = [sheet filename];
    NSError * error;
    [consoleLock lock];
    NSString * string = [[controllerConsole textStorage] string];
    [consoleLock unlock];
    NSData * data = [string dataUsingEncoding:NSASCIIStringEncoding];

    BOOL successful = [data writeToFile:path options:0 error:&error];
    if ( !successful )
    {
        NSAlert *a = [NSAlert alertWithError:error];
        [a runModal];
    }
}


- (IBAction)pushSaveConsole:(id)sender 
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setRequiredFileType:@"txt"];
    [panel beginSheetForDirectory:@""
           file:@"console"
           modalForWindow:[self window]
           modalDelegate:self
           didEndSelector:@selector(didEndSaveSheet:returnCode:contextInfo:)
           contextInfo:NULL];

}


- (void) checkSimModel 
{
    @try {
        if (simModel == nil) {
            simModel = [[SimModel alloc] init];
        }
    }
    @catch (NSException *ex) {
        DebugNSLog(@"check_simModel: Caught %@: %@", [ex name], [ex reason]);
    }
}


- (void)threadStopped:(id)arg
{
    simIsRunning = NO;
}


- (void)addOneToHistorySlider:(id)arg
{
    DebugNSLog(@"enableSlider\n");

    [historySliderLock lock];

    /* Enable the slider if we've passed one history .*/
    if ( nHistories < 2 ) 
    {
        [sliderAllHistories setMaxValue:1];
        [sliderAllHistories setEnabled:NO];
        [buttonAllSlidersUp setEnabled:NO];
        [buttonAllSlidersDown setEnabled:NO];
    }
    else 
    {
        [sliderAllHistories setEnabled:YES];
        [buttonAllSlidersUp setEnabled:YES];
        [buttonAllSlidersDown setEnabled:YES];
    }

    [sliderAllHistories setMaxValue:nHistories];
    if ( nHistories > maxHistoryCount ) 
        [sliderAllHistories setMinValue: (nHistories - maxHistoryCount)];
    
    /* If the user is currently watching the updating plot, then we need to add one to the current value of the slider,
     * so that the user can continue to watch the currently updating plot. */
    int was_displaying = (int)(round([sliderAllHistories doubleValue]));
    if ( was_displaying < 1 ) 
        was_displaying = 1;
    if ( was_displaying+1 == nHistories )
    {
        [sliderAllHistories setDoubleValue: nHistories];
        [sliderAllHistoriesValue setStringValue:[NSString stringWithFormat:@"%i", nHistories]];
    }
    else if ( was_displaying <= nHistories - maxHistoryCount )
    {
        [sliderAllHistoriesValue setDoubleValue:nHistories-maxHistoryCount];
        [sliderAllHistoriesValue setStringValue:[NSString stringWithFormat:@"%i", nHistories-maxHistoryCount]];
    }   

    [historySliderLock unlock];
}


- (void)addNewPlots
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    PlotController *pc;
    NSEnumerator *enumerator = [plotControllers keyEnumerator];
    NSString *plotname;
    nHistories++;

    [self addOneToHistorySlider:nil];
    while (plotname = [enumerator nextObject]) 
    {
        pc = [plotControllers objectForKey:plotname];
        [pc addNewPlot:[NSNumber numberWithBool:doPlot]];
    }
    [pool release];
}


/* Th PlotController and HistoryController handle anything that needs to be done on the main thread themselves.  This
 * means that drawPlots should always be called from a secondary thread. */ 
- (void)drawPlots:(NSDictionary *) plot_block_from_sim doInParallel:(BOOL)do_multithreaded
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    PlotController *pc;
    
    if ( do_multithreaded )
    {
        /* If we do a multithreaded drawing operation, then we cannot add columns in the draw commands. */
        NSOperationQueue *draw_queue = [NSOperationQueue new];
        DrawingOperation * drawing_op = nil;
        for ( NSString * plot_name in plotControllers )
        {      
            pc = [plotControllers objectForKey:plot_name];
            drawing_op = [[DrawingOperation alloc] init];
                [drawing_op setDoPlot:doPlot];
                [drawing_op setPlotController:pc];
                [drawing_op setPlotBlock:plot_block_from_sim];
                [draw_queue addOperation:drawing_op];
                [drawing_op release];   // draw_queue retained the object, so we can release it here without having to store it.
        }
        [draw_queue waitUntilAllOperationsAreFinished];
        //DebugNSLog(@"Waiting for Godot.\n");
        [draw_queue release];
    }
    else
    {
        for ( NSString * plot_name in plotControllers )
        {        
            //DebugNSLog(@"\t %@", plot_name);
            pc = [plotControllers objectForKey:plot_name];

            NSArray *keys = [NSArray arrayWithObjects:@"plotBlock", @"doPlot", nil];
            NSArray *objects = [NSArray arrayWithObjects:plot_block_from_sim, [NSNumber numberWithBool:doPlot], nil];
            NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            [pc drawPlot:dictionary];
        }
    }

    [pool release];
}


/* Simple helper function. */
-(void) drawPlotsOffMainThread:(NSDictionary*)parameter_dict
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSDictionary * plot_block = [parameter_dict objectForKey:@"plotBlock"];
    BOOL do_plot_in_parallel = [[parameter_dict objectForKey:@"doPlotInParallel"] boolValue];
    [self drawPlots:plot_block doInParallel:do_plot_in_parallel];
    [pool release];
}


/* Since this is an action, it's called from the main thread if the user hits the appropriate UI. */
/* I think with the additional logic of the History and Plot Controllers knowing how to redraw themselves completely,
 * the call to redraw in the pushPlot is unnecessary assuming the plot is actually running. If it's not running, then we
 * can replot. -DCS:2009/11/10 */
/* This is used when the user presses the plot button. */
- (IBAction)pushPlot:(id)sender
{
    NSInteger state = [plotButton state];
    DebugNSLog(@"plot state: %d", state);
    if ( state == NSOffState )
    {
        // Since the button is in the "Toggle" mode, the state is automatically changed. -DCS:2009/08/14
        [plotButton setTitle:@"Not Plotting"];
        doPlot = NO;
    }
    else
    {
        [plotButton setTitle:@"Plotting"];
        doPlot = YES;
        if ( !simIsRunning )
        {
            [self drawPlots:(NSDictionary *)[NSDictionary dictionary] doInParallel:[simModel doPlotInParallel]];
            NSArray *keys = [NSArray arrayWithObjects:@"plotBlock", @"doPlotInParallel", nil];
            NSArray *objects = [NSArray arrayWithObjects:[NSDictionary dictionary], [NSNumber numberWithBool:[simModel doPlotInParallel]], nil];
            NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            [NSThread detachNewThreadSelector:@selector(drawPlotsOffMainThread:) toTarget:self withObject:dictionary];
        }
    }
}


/* This is used when the user turns toggles the button from the menu, so we have to update the button state manually. */
- (IBAction)togglePlot:(id)sender
{
    NSInteger state = [plotButton state];
    DebugNSLog(@"plot state: %d", state);
    if ( state == NSOnState )
    {
        [plotButton setState:NSOffState];
        // Since the button is in the "Toggle" mode, the state is automatically changed. -DCS:2009/08/14
        [plotButton setTitle:@"Not Plotting"];
        doPlot = NO;
    }
    else
    {
        [plotButton setState:NSOnState];
        [plotButton setTitle:@"Plotting"];
        doPlot = YES;
        if ( !simIsRunning )
        {
            [self drawPlots:(NSDictionary *)[NSDictionary dictionary] doInParallel:[simModel doPlotInParallel]];
            NSArray *keys = [NSArray arrayWithObjects:@"plotBlock", @"doPlotInParallel", nil];
            NSArray *objects = [NSArray arrayWithObjects:[NSDictionary dictionary], [NSNumber numberWithBool:[simModel doPlotInParallel]], nil];
            NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            [NSThread detachNewThreadSelector:@selector(drawPlotsOffMainThread:) toTarget:self withObject:dictionary];
        }
    }
}



/* These refer to the history sliderss, not the parameter sliders.  Should probably tighten up the function names do get
 * this clear. -DCS:2009/09/30*/
- (void)historySliderChanged:(id)arg
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    PlotController *pc;
    NSEnumerator *enumerator = [plotControllers keyEnumerator];
    NSString *plotname;

    DebugNSLog(@"historySliderChanged\n");
    [historySliderLock lock];
    int currently_displaying_strval = (int)(round([sliderAllHistories doubleValue])); // what we should display is set by the user slider setting
    NSString * val_str = [NSString stringWithFormat:@"%i", currently_displaying_strval];
    [sliderAllHistoriesValue setStringValue:val_str];
    [historySliderLock unlock];
    
    int slider_value = (int)(round([sliderAllHistories doubleValue])); 
    while ( plotname = [enumerator nextObject] ) 
    {        
        pc = [plotControllers objectForKey:plotname];
        [(HistoryController *)pc changeSliderToValue:slider_value];
    }

    [pool release];
}



/* Put all the sliders up by one. Usually the button would take the compute lock, but these actions are called from
 * other parts of the program.  I'm starting to wonder whether making locking buttons and sliders was actually a good
 * idea since I have to program around it in many cases. -DCS:2009/12/14*/
-(void) pushAllSlidersDownExternal:(id)arg
{
    [computeLock lock];
    [self pushAllSlidersDown:arg];
    [computeLock unlock];
}

-(void) pushAllSlidersUpExternal:(id)arg
{
    [computeLock lock];
    [self pushAllSlidersUp:arg];
    [computeLock unlock];
}

    

-(void) pushAllSlidersDown:(id)arg
{    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    [historySliderLock lock];
    int currently_displaying = (int)(round([sliderAllHistories doubleValue])); // what we should display is set by the user slider setting
    if ( currently_displaying >= 0 )
        [sliderAllHistories setDoubleValue: (double)(currently_displaying-1)];
    [historySliderLock unlock];

    [self historySliderChanged:arg];

    [pool release];
}


-(void) pushAllSlidersUp:(id)arg
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    [historySliderLock lock];
    int currently_displaying = (int)(round([sliderAllHistories doubleValue])); // what we should display is set by the user slider setting
    if ( currently_displaying < [sliderAllHistories maxValue] )
        [sliderAllHistories setDoubleValue: (double)(currently_displaying+1)];
    [historySliderLock unlock];

    [self historySliderChanged:arg];

    [pool release];
}


/* This function (and obviously the functions it calls, all run in the "compute" thread. */
- (void)computeBasedOnNSteps:(id)arg
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    // Running in a separate thread    
    // Run the compute loop, and save the state after each iteration.
    int n_draw_iters = simModel.nStepsInFullPlot / simModel.nStepsBetweenDrawing;
    int nsteps_to_simulate = simModel.nStepsBetweenDrawing;
    BOOL going = YES;

    DebugNSLog(@"n_draw_iters=%f", (double)n_draw_iters);
    DebugNSLog(@"nsteps_to_simulate=%f", (double)nsteps_to_simulate);
    
    [self.simModel callInitForRun];
    
    while (going)
    {
        if ( iterThroughCurrentPlot == 0 )
        {
            [self addNewPlots]; 
            BOOL is_end_of_plot_duration = YES;
            [simModel clearDataInManagedColumns:is_end_of_plot_duration];
            // should this be called if we just started the run, even if the plotDuration isn't zero? -DCS:2009/05/26
            [self.simModel callInitForPlotDuration]; 
            fullPlotIter++;
        }
            
        for ( ; iterThroughCurrentPlot < n_draw_iters; iterThroughCurrentPlot++ ) 
        {
            NSDictionary * plot_block_from_sim = [simModel runModelForNSteps:nsteps_to_simulate]; // a dictionary of SCManagedColumns and SCColumns.
            
            /* Update the plots, now that we've finished computing. Now the plotting data for this last plot is full, so
             * we convert it to the correct data type and put it into the plots storage NSMutableArray. */
            if ( [plot_block_from_sim count] > 0 ) // is there any point in plotting if there's no data? -DCS:2009/11/03
            {
                [self drawPlots:plot_block_from_sim doInParallel:[simModel doPlotInParallel]];
            }
            [plot_block_from_sim release];

            /* Write here we have to tell the managed columns that there was a plot that just finished. */
            [simModel aPlotHappened];

            if ( !simIsRunning )
            {
                iterThroughCurrentPlot++;
                going = NO;
                break;          // out of for loop... probably should make sure this cleans up nice. -DCS:2009/05/10
            }
        }
        
        if ( iterThroughCurrentPlot == n_draw_iters )
        {
            [self.simModel callCleanupAfterPlotDuration]; /* user could stop run here, so have to check. */
            if ( !simIsRunning )
                going = NO;
            iterThroughCurrentPlot = 0;
        }
    }
    
    // Should callCleanupAfterPlotDuration be called here because we may have stopped outside a complete loop? -DCS:2009/05/26
    [self.simModel callCleanupAfterRun];

    // Tell the main thread that things have stopped.
    [self performSelectorOnMainThread:@selector(threadStopped:) withObject:nil waitUntilDone:YES];

    [pool release];
}


- (void)computeBasedOnTiming:(id)arg
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    // Running in a separate thread    
    // Run the compute loop, and save the state after each iteration.
    int n_draw_iters = simModel.nStepsInFullPlot / simModel.nStepsBetweenDrawing;
    int nsteps_to_simulate = simModel.nStepsBetweenDrawing;
    BOOL going = YES;

    DebugNSLog(@"n_draw_iters=%f", (double)n_draw_iters);
    DebugNSLog(@"nsteps_to_simulate=%f", (double)nsteps_to_simulate);
    
    [self.simModel callInitForRun];

    int nsteps_in_full_plot = [simModel nStepsInFullPlot];

    struct timeval start_time; 
    struct timeval end_time;
    struct timeval plot_time;
    
    double total_ms = 30.0;
    double time_in_loop_ms = 0.0;
    double time_plotting_ms = 30.0;
    double time_for_computing_ms = 30.0;
    
    while ( going )
    {
        if ( iterThroughCurrentPlot == 0 )
        {
            [self addNewPlots]; 
            BOOL is_end_of_plot_duration = YES;
            [simModel clearDataInManagedColumns:is_end_of_plot_duration];
            // should this be called if we just started the run, even if the plotDuration isn't zero? -DCS:2009/05/26
            [self.simModel callInitForPlotDuration]; 
            fullPlotIter++;
        }

        while ( iterThroughCurrentPlot < nsteps_in_full_plot ) 
        {
            gettimeofday(&start_time, NULL);

            time_for_computing_ms = total_ms - time_plotting_ms;
            if ( time_for_computing_ms < total_ms / 2.0 ) /* let the plotting only eat half of the processor, even if we slow for it. */
                time_for_computing_ms = time_plotting_ms;

            /* a dictionary of SCManagedColumns and SCColumns. */
            NSDictionary * plot_block_from_sim = [simModel runModelAmountOfTime:time_for_computing_ms currentIteration:&iterThroughCurrentPlot]; 
            
            gettimeofday(&plot_time, NULL);

            /* Update the plots, now that we've finished computing. Now the plotting data for this last plot is full, so
             * we convert it to the correct data type and put it into the plots storage NSMutableArray. */
            if ( [plot_block_from_sim count] > 0 ) // is there any point in plotting if there's no data? -DCS:2009/11/03
            {
                [self drawPlots:plot_block_from_sim doInParallel:[simModel doPlotInParallel]];
            }
            [plot_block_from_sim release];

            /* Here we have to tell the managed columns that there was a plot that just finished. */
            [simModel aPlotHappened];

            gettimeofday(&end_time, NULL);
            time_plotting_ms = (end_time.tv_sec - plot_time.tv_sec)*1000.0 + (end_time.tv_usec - plot_time.tv_usec)/1000.0;
            time_in_loop_ms = (end_time.tv_sec - start_time.tv_sec)*1000.0 + (end_time.tv_usec - start_time.tv_usec)/1000.0;
            //[self writeStatusToConsole:[NSString stringWithFormat:@"%lf\n \t%lf\n \t%lf\n", time_in_loop_ms, time_for_computing_ms, time_plotting_ms]];

            if ( !simIsRunning )
            {
                going = NO;
                break;          // out of for loop... probably should make sure this cleans up nice. -DCS:2009/05/10
            }
        }
        
        if ( iterThroughCurrentPlot == nsteps_in_full_plot )
        {
            [self.simModel callCleanupAfterPlotDuration]; /* user could stop run here, so have to check. */
            if ( !simIsRunning )
                going = NO;
            iterThroughCurrentPlot = 0;
        }
        if ( iterThroughCurrentPlot > nsteps_in_full_plot )
            assert ( 0 );       // something wrong -DCS:2009/11/12
    }
    
    // Should callCleanupAfterPlotDuration be called here because we may have stopped outside a complete loop? -DCS:2009/05/26
    [self.simModel callCleanupAfterRun];

    // Tell the main thread that things have stopped.
    [self performSelectorOnMainThread:@selector(threadStopped:) withObject:nil waitUntilDone:YES];
    
    [pool release];
}


@end
