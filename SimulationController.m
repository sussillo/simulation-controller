/* Simple implementation of the hooks into the simulation controller.  */

/* Notes to myself since the .h file is meant to be read by users. */

// Should there be versions of these commands for expressons?  Versions that include expression columns are basically
// right out because of history.  Even if it were convenient to get the data out of DG (it's not, but it's doable), one
// would have to load the latest history into the DG view, since a user can be viewing any history at any given point in
// time.  This pretty much kills it right there. In fact, we should make sure that the user isn't trying to copy
// expression columns in the FMV make now calls. -DCS:2009/10/14



#import <Foundation/Foundation.h>

#import "SimulationController.h"
#import "SimController.h"
#import "SimModel.h"
#import "SimController.h"

SimModel * simModelInApplication; /* Used for getting parameter and button values, etc. */
SimController * simControllerInApplication; /* Used for stopping the simulation programmatically from user's model. */

/* If the user runs this code in a parallel fashion, then we need to protect the variable iterator counter. */
NSLock * varIteratorLock;
int PlotNowVarIterator = 0;

extern NSString * const SCWriteToControllerConsoleAttributedNotification; // for sending colored notes to the controller console

NSColor * NSColorFromName(char * color_name);


void writeWarningToConsole(NSString* text )
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
    [nc postNotificationName:SCWriteToControllerConsoleAttributedNotification object:nil userInfo:dictionary];
}


void SCPrivateSetSimModelPointer(void * sim_model_ptr)
{
    simModelInApplication = (SimModel *)sim_model_ptr;
}


 void SCPrivateSetSimControllerPointer(void * sim_controller_ptr)
{
    simControllerInApplication = (SimController *)sim_controller_ptr; 
}


void SCSetWindowData(const char * plot_name, double left, double bottom, double width, double height)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    double my_left, my_bottom, my_width, my_height;
    my_left = left;
    if ( my_left < 0.0 )
        my_left = 0.0;
    if ( my_left > 1.0 )
        my_left = 1.0;

    my_bottom = bottom;
    if ( my_bottom < 0.0 )
        my_bottom = 0.0;
    if ( my_bottom > 1.0 )
        my_bottom = 1.0;
    
    my_width = width;
    if ( my_width < 0.0 )
        my_width = 0.0;
    if ( my_width > 1.0 )
        my_width = 1.0;

    my_height = height;
    if ( my_height < 0.0 )
        my_height = 0.0;
    if ( my_height > 1.0 )
        my_height = 1.0;
    
    NSRect myRect = NSMakeRect(my_left, my_bottom, my_width, my_height);
    [simModelInApplication addWindowDataToPlotByName:[NSString stringWithUTF8String:plot_name] rect:myRect];

    [pool release];
}


void SCSetMaxHistoryCount(int max_history_count)
{
    if ( max_history_count >= 0 )
        [simControllerInApplication setMaxHistoryCount:max_history_count];
}


void SCStopRunning()
{
    [simControllerInApplication stopRunning];
}

void SCWriteText(const char * text)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    assert ( simModelInApplication != nil );
    NSString * string = [[NSString alloc] initWithFormat:@"   %s\n", text];
    [simModelInApplication writeTextToConsole:string];
    [string release];
    [pool release];
}


void SCWriteAttributedText(const char * text, char * text_color, int text_size)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    assert ( simModelInApplication != nil );

    NSString * string = [[NSString alloc] initWithFormat:@"   %s\n", text];
    
    NSColor * color = NSColorFromName(text_color);
    if ( !color )
    {
        color = [NSColor blackColor];
    }
    [simModelInApplication writeAttributedTextToConsole:string textColor:color textSize:text_size];
    [string release];

    [pool release];    
}


void SCWriteWarning(const char * warning)
{
    SCWriteAttributedText(warning, "maraschino", 14);
}


void SCWriteLine(const char * text, double value)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    assert ( simModelInApplication != nil );
    NSString * string = [[NSString alloc] initWithFormat:@"   %s    =    %.3lf\n", text, value];
    [simModelInApplication writeTextToConsole:string];
    [string release];
    [pool release];
}


void SCWriteLineDouble(const char * text, double value)
{
    SCWriteLine(text, value);
}


void SCWriteLineInt(const char * text, int value)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    assert ( simModelInApplication != nil );
    NSString * string = [[NSString alloc] initWithFormat:@"   %s    =    %i\n", text, value];
    [simModelInApplication writeTextToConsole:string];
    [string release];
    [pool release];
}


void SCStartRunImmediatelyAfterInit(bool do_start_run)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    assert ( simModelInApplication != nil );
    BOOL do_start_run_objc = NO;
    if ( do_start_run )
        do_start_run_objc = YES;
    
    [simModelInApplication setDoRunImmediatelyAfterInit:do_start_run_objc];
    [pool release];    
}


void SCOpenInDemoMode(bool do_open_in_demo_mode)
{
    [simModelInApplication setDoOpenInDemoMode:do_open_in_demo_mode];
}


void SCSetNStepsInFullPlot(int n_steps_in_full_plot)
{
    assert ( simModelInApplication != nil );
    [simModelInApplication setNStepsInFullPlot:n_steps_in_full_plot];
}

void SCDoRedrawBasedOnTimer(bool do_redraw_based_on_timer)
{
    assert ( simModelInApplication != nil);
    [simModelInApplication setDoRedrawBasedOnTimer:do_redraw_based_on_timer];
}

void SCSetNStepsBetweenDrawing(int n_steps_between_drawing)
{
    assert ( simModelInApplication != nil );
    [simModelInApplication setNStepsBetweenDrawing:n_steps_between_drawing];
}

void SCSetNStepsBetweenPlotting(int n_steps_between_plotting)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    assert ( simModelInApplication != nil );
    [simModelInApplication setNStepsBetweenPlotting:n_steps_between_plotting];
    [pool release];
}


void SCDoPlotInParallel(bool do_plot_in_parallel)
{
    assert ( simModelInApplication != nil );
    [simModelInApplication setDoPlotInParallel:do_plot_in_parallel];
}


void SCAddPlot(char * plot_name, bool do_delete_makenowplots_after_duration)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    if ( plot_name != NULL )
    {
        assert ( simModelInApplication != nil );
        [simModelInApplication addPlot:[NSString stringWithUTF8String:plot_name]  doDeleteMakeNowPlots: do_delete_makenowplots_after_duration];
    }
    [pool release]; 
}


void SCAddAxisToPlot(char * plot_name, SCAxisParameters * axis_parameters)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    if ( plot_name != NULL )
    {
        assert ( simModelInApplication != nil );
        [simModelInApplication addAxisToPlot:[NSString stringWithUTF8String:plot_name] axisParameters:axis_parameters];
    }
    [pool release];
}


void SCClearMakeNowPlots(char * plot_name)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    if ( plot_name != NULL )
    {
        assert ( simModelInApplication != nil );
        [simModelInApplication clearMakeNowPlots:[NSString stringWithUTF8String:plot_name]];
    }
    [pool release];
}


void SCAddColorSchemeToPlot(char * plot_name, char * color_scheme_name, int nranges, SCColorRangeType * range_types, 
                      double * range_starts, double * range_stops, SCColor * colors)
{
    assert ( simModelInApplication != nil );

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableArray * range_types_ns = [NSMutableArray arrayWithCapacity:nranges];
    NSMutableArray * range_starts_ns = [NSMutableArray arrayWithCapacity:nranges];
    NSMutableArray * range_stops_ns = [NSMutableArray arrayWithCapacity:nranges];
    NSMutableArray * range_colors_ns = [NSMutableArray arrayWithCapacity:nranges];
    for ( int i = 0; i < nranges; i++ )
    {
        [range_types_ns addObject:[NSNumber numberWithInt:range_types[i]]];
        [range_starts_ns addObject:[NSNumber numberWithDouble:range_starts[i]]];
        [range_stops_ns addObject:[NSNumber numberWithDouble:range_stops[i]]];
        NSColor * color = [NSColor colorWithCalibratedRed:(CGFloat)colors[i].red 
                                   green:(CGFloat)colors[i].green 
                                   blue:(CGFloat)colors[i].blue 
                                   alpha:(CGFloat)colors[i].alpha];
        [range_colors_ns addObject:color];
    }
    
    [simModelInApplication addColorSchemeToPlot:[NSString stringWithUTF8String:plot_name]
                           colorSchemeName:[NSString stringWithUTF8String:color_scheme_name]
                           rangeTypes:range_types_ns
                           rangeStarts:range_starts_ns
                           rangeStops:range_stops_ns
                           rangeColors:range_colors_ns];

    [pool release];    
}


void SCAddStaticColumn(char * var_name, double * data_ptr, int length)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    if ( var_name != NULL && data_ptr != NULL && length > 0 )
    {
        assert ( simModelInApplication != nil );
        [simModelInApplication addStaticColumn:[NSString stringWithUTF8String:var_name] dataPtr:data_ptr length:length];
    }
    [pool release];
}


void SCAddWatchedTimeColumns(char * var_array_name, double * data_ptr, int length, SCDataHoldType data_hold_type)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    if ( var_array_name != NULL && data_ptr != NULL && length > 0 )
    {
        assert ( simModelInApplication != nil );
        [simModelInApplication addWatchedVariableArray:[NSString stringWithUTF8String:var_array_name] dataPtr:data_ptr length:length dataHoldType:data_hold_type];
    }
    [pool release];
}

void SCAddWatchedVariableArray(char * var_array_name, double * data_ptr, int length, SCDataHoldType data_hold_type)
{
    writeWarningToConsole([NSString stringWithFormat:@"SC Warning: SCAddWatchedVariableArray is obsolete.  Please use the function SCAddWatchedTimeColumns.\n"]);
    SCAddWatchedTimeColumns(var_array_name, data_ptr, length, data_hold_type);
}


void SCAddWatchedTimeColumn(char * var_name, double * data_ptr, SCDataHoldType data_hold_type)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    if ( var_name != NULL && data_ptr != NULL )
    {
        assert ( simModelInApplication != nil );
        [simModelInApplication addWatchedVariable:[NSString stringWithUTF8String:var_name] dataPtr:data_ptr dataHoldType:data_hold_type];
    }
    [pool release];
}

void SCAddWatchedVariable(char * var_name, double * data_ptr, SCDataHoldType data_hold_type)
{
    writeWarningToConsole([NSString stringWithFormat:@"SC Warning: SCAddWatchedVariable is obsolete.  Please use the function SCAddWatchedTimeColumn.\n"]);
    SCAddWatchedTimeColumn(var_name, data_ptr, data_hold_type);
}

/* Treat the whole array as a single variable.  This is useful for certain types of plots, such as the Barplot, here the
 * height of the bars is a single variable, as are the bar offsets. */

void SCAddWatchedFixedSizeColumn(char * var_name, double * data_ptr, int length)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    if ( var_name != NULL && data_ptr != NULL && length > 0 )
    {
        assert ( simModelInApplication != nil );
        [simModelInApplication addWatchedColumnVariable:[NSString stringWithUTF8String:var_name] dataPtr:data_ptr length:length];
    }
    [pool release];
}

void SCAddWatchedColumnVariable(char * var_name, double * data_ptr, int length)
{
    writeWarningToConsole([NSString stringWithFormat:@"SC Warning: SCAddWatchedColumnVariable is obsolete.  Please use the function SCAddWatchedFixedSizeColumn.\n"]);
    SCAddWatchedFixedSizeColumn(var_name, data_ptr, length);
}


void SCAddControllableParameter(char * param_name, double min_value, double max_value, double init_value)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    assert ( simModelInApplication != nil );
    [simModelInApplication addControllableParameter:[NSString stringWithUTF8String:param_name] 
                           minValue:min_value 
                           maxValue:max_value 
                           initValue:init_value];
    [pool release];
}


void SCCallParameterActionOnAll()
{
    SimParameterModel * sim_parameter_model = [simModelInApplication simParameterModel];
    [sim_parameter_model broadcastParameterValues];
}

// The implemenation of this function sucks because the paramters aren't a dictionary, but rather an array, because I
// set up the UI using an NSArrayController.  So something fundamental has to change, and I hope it isn't a big deal.
// -DCS:2009/05/21
double SCGetParameterValue(char * param_name)
{
    //NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    assert ( simModelInApplication != nil );
    SimParameterModel * sim_parameter_model = [simModelInApplication simParameterModel];
    
    NSString * param_name_string = [NSString stringWithUTF8String:param_name];
    double value = [sim_parameter_model valueForParameter:param_name_string];
    
    //[pool release];
    return value;
}


// This function should have the UI updated on the main thread! -DCS:2009/08/06
// Should be checked to be added in phase one. -DCS:2009/10/14
void SCSetParameterValue(char * param_name, double value)
{
    //NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    assert ( simModelInApplication != nil );
    SimParameterModel * sim_parameter_model = [simModelInApplication simParameterModel];
    
    NSString * param_name_string = [NSString stringWithUTF8String:param_name];
    [sim_parameter_model setValueForParameter:param_name_string value:value doBroadcast:YES]; // OK for recursion in parameters
    
    //[pool release];
}


// Should be checked to be added in phase one. -DCS:2009/10/14
// Should be checked to be added in phase one. -DCS:2009/10/14
bool SCGetButtonValue(char * button_name)
{
    //NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    assert ( simModelInApplication != nil );
    SimParameterModel * sim_parameter_model = [simModelInApplication simParameterModel];

    NSString * button_name_string = [NSString stringWithUTF8String:button_name];
    bool value = [sim_parameter_model valueForButton:button_name_string];
    
    //[pool release];
    return value;    
}

// This function should have the UI updated on the main thread! -DCS:2009/08/06
// Should be checked to be added in phase one. -DCS:2009/10/14
void SCSetButtonValue(char * button_name, bool value)
{
    //NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    assert ( simModelInApplication != nil );
    SimParameterModel * sim_parameter_model = [simModelInApplication simParameterModel];
    
    NSString * button_name_string = [NSString stringWithUTF8String:button_name];

    // no accidental infinite recursion in button callbacks. 
    [sim_parameter_model setValueForButton:button_name_string value:value doBroadcast:YES]; 
    
    //[pool release];    
}

 
void SCAddControllableButton(char * button_name, bool init_value, char * off_label, char * on_label)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    assert ( simModelInApplication != nil );
    [simModelInApplication addControllableButton:[NSString stringWithUTF8String:button_name] 
                           initValue:init_value // does this convert correctly -DCS:2009/05/22
                           offLabel:[NSString stringWithUTF8String:off_label]
                           onLabel:[NSString stringWithUTF8String:on_label]];    
    [pool release];
}



void SCAddVariablesToLinePlotByName(char * plot_name, char * x_var_name, char * y_var_name, SCPlotParameters * plot_parameters)
{
    // place an warning about the name here. 
    writeWarningToConsole([NSString stringWithFormat:@"SC Warning: SCAddVariablesToLinePlotByName is obsolete.  Please use the function SCAddVarsToPlot.\n"]);
    SCAddVarsToPlot(plot_name, x_var_name, y_var_name, plot_parameters);
}


/* New, shortened, more descriptive name. */
void SCAddVarsToPlot(char * plot_name, char * x_var_name, char * y_var_name, 
                     SCPlotParameters * plot_parameters)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    [simModelInApplication addVariablesToLinePlotByName:[NSString stringWithUTF8String:plot_name]
                           xVarName:[NSString stringWithUTF8String:x_var_name]
                           yVarName:[NSString stringWithUTF8String:y_var_name]
                           linePlotParameters:plot_parameters];
    
    [pool release];    
}



void SCAddVariablesToFastLinePlotByName(char * plot_name, char * x_var_name, char * y_var_name, SCTimePlotParameters * time_plot_parameters)
{
    writeWarningToConsole([NSString stringWithFormat:@"SC Warning: SCAddVariablesToFastLinePlotByName is obsolete.  Please use the function SCAddVarsToTimePlot.\n"]);

    SCAddVarsToTimePlot(plot_name, x_var_name, y_var_name, time_plot_parameters);
}


void SCAddVarsToTimePlot(char * plot_name, char * x_var_name, char * y_var_name, SCTimePlotParameters * time_plot_parameters)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    [simModelInApplication addVariablesToFastTimeLinePlotByName:[NSString stringWithUTF8String:plot_name]
                           xVarName:[NSString stringWithUTF8String:x_var_name]
                           yVarName:[NSString stringWithUTF8String:y_var_name]
                           fastLinePlotParameters:time_plot_parameters];

    [pool release];    
}


void SCAddVariablesToBarPlotByName(char * plot_name, char * var_name, SCBarPlotParameters * bar_plot_parameters)
{
    writeWarningToConsole([NSString stringWithFormat:@"SC Warning: SCAddVariablesToBarPlotByName is obsolete.  Please use the function SCAddVarsToBar.\n"]);

    SCAddVarsToBar(plot_name, var_name, bar_plot_parameters);
}


void SCAddVarsToBar(char * plot_name, char *var_name, SCBarPlotParameters * bar_plot_parameters)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    [simModelInApplication addVariablesToBarPlotByName:[NSString stringWithUTF8String:plot_name]
                           varName:[NSString stringWithUTF8String:var_name]
                           barPlotParameters:bar_plot_parameters];
    
    [pool release];
}


void SCAddVariablesToHistogramPlotByName(char * plot_name, char *var_name, SCHistogramPlotParameters * histogram_plot_parameters)
{
    writeWarningToConsole([NSString stringWithFormat:@"SC Warning: SCAddVariablesToHistogramPlotByName is obsolete.  Please use the function SCAddVarsToHistogram.\n"]);

    SCAddVarsToHistogram(plot_name, var_name, histogram_plot_parameters);
}

void SCAddVarsToHistogram(char * plot_name, char *var_name, SCHistogramPlotParameters * histogram_plot_parameters)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    [simModelInApplication addVariablesToHistogramPlotByName:[NSString stringWithUTF8String:plot_name]
                           varName:[NSString stringWithUTF8String:var_name]
                           histogramPlotParameters:histogram_plot_parameters];
    
    [pool release];
}


void SCAddVarsToFit(char * plot_name, char * x_var_name, char * y_var_name, 
                    SCFitPlotParameters * fit_plot_parameters, 
                    char * expression, int nparams, ...)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    va_list ap;
    va_start(ap, nparams);   // should change to function_approximation_plot_parameters -DCS:2009/10/12

    NSMutableArray * param_names = [NSMutableArray arrayWithCapacity:nparams];
    NSMutableArray * param_values = [NSMutableArray arrayWithCapacity:nparams];

    for ( int i = 0; i < nparams; i++ )
    {
        char * param_name = va_arg(ap, char *);
        if ( param_name )
        {
            //printf("string %s\n", param_name);
            double param_val = va_arg(ap, double);
            if ( param_val )
            {
                //printf("double %lf\n", param_val);
                [param_names addObject:[NSString stringWithUTF8String:param_name]];
                [param_values addObject:[NSString stringWithFormat:@"%lf", param_val]];
            }
            else
            {
                writeWarningToConsole([NSString stringWithFormat:@"SC Warning: SCAddVarsToFit: There are more parameter names than parameter values.  Not using parameter %s.\n", param_name]);
                break;
            }
        }
        else
        {
            break;
        }
    }    
    va_end(ap);

    [simModelInApplication addVarsToFit:[NSString stringWithUTF8String:plot_name]
                           xName:[NSString stringWithUTF8String:x_var_name]
                           yName:[NSString stringWithUTF8String:y_var_name]
                           expression:[NSString stringWithUTF8String:expression]
                           parameterNames:param_names
                           parameterValues:param_values
                           fitPlotParameters:fit_plot_parameters];
    
 
    [pool release];
}


void SCMakeLinePlotNow(char * plot_name, double * xdata, double * ydata, int data_length, SCPlotParameters * plot_parameters, int order)
{
    writeWarningToConsole([NSString stringWithFormat:@"SC Warning: SCMakeLinePlotNow is obsolete.  Please use the function SCMakePlotNow.\n"]);
    SCMakePlotNow(plot_name, xdata, ydata, data_length, plot_parameters, order);
}


void SCMakePlotNow(char * plot_name, double * xdata, double * ydata, int data_length, 
                   SCPlotParameters * plot_parameters, int order)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    [varIteratorLock lock];
    int x_val = PlotNowVarIterator++;
    int y_val = PlotNowVarIterator++;
    [varIteratorLock unlock];

    [simModelInApplication makeLinePlotNow:[NSString stringWithUTF8String:plot_name]
                           xName:[NSString stringWithFormat:@"UserPlottedX%i", x_val]
                           yName:[NSString stringWithFormat:@"UserPlottedY%i", y_val]
                           xData:xdata
                           yData:ydata
                           dataLength:data_length
                           linePlotParameters:plot_parameters
                           orderIndex:order];

    [pool release];    
}

void SCMakePlotNowFMC(char * plot_name, char * x_var_name, char * y_var_name, SCPlotParameters * pp, int order)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [varIteratorLock lock];
    int x_val = PlotNowVarIterator++;
    int y_val = PlotNowVarIterator++;
    [varIteratorLock unlock];

    [simModelInApplication makeLinePlotNowFMC:[NSString stringWithUTF8String:plot_name]
                           xName:[NSString stringWithFormat:@"UserPlottedX%i%s", x_val, x_var_name]
                           yName:[NSString stringWithFormat:@"UserPlottedY%i%s", y_val, y_var_name]
                           xMCName:[NSString stringWithUTF8String:x_var_name]
                           yMCName:[NSString stringWithUTF8String:y_var_name]
                           linePlotParameters:pp
                           orderIndex:order];
    
    [pool release];
}



void SCMakeBarPlotNow(char * plot_name, double * data, int data_length, SCBarPlotParameters * bar_plot_parameters, int order)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    writeWarningToConsole([NSString stringWithFormat:@"SC Warning: SCMakeBarPlotNow is obsolete.  Please use the function SCMakeBarNow.\n"]);
    SCMakeBarNow(plot_name, data, data_length, bar_plot_parameters, order);
    [pool release];
}


void SCMakeBarNow(char * plot_name, double * data, int data_length, 
                  SCBarPlotParameters * bar_plot_parameters, int order)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [varIteratorLock lock];
    int val = PlotNowVarIterator++;
    [varIteratorLock unlock];

    [simModelInApplication makeBarPlotNow:[NSString stringWithUTF8String:plot_name]
                           name:[NSString stringWithFormat:@"UserPlottedX%i", val]
                           data:data
                           dataLength:data_length
                           barPlotParameters:bar_plot_parameters
                           orderIndex:order];

    [pool release];
}


void SCMakeBarNowFMC(char * plot_name, char * var_name, SCBarPlotParameters * bpp, int order)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [varIteratorLock lock];
    int val = PlotNowVarIterator++;
    [varIteratorLock unlock];

    [simModelInApplication makeBarPlotNowFMC:[NSString stringWithUTF8String:plot_name]
                           name:[NSString stringWithFormat:@"UserPlottedX%i%s", val, var_name]
                           MCName:[NSString stringWithUTF8String:var_name]
                           barPlotParameters:bpp
                           orderIndex:order];

    [pool release];
}



void SCMakeHistogramPlotNow(char * plot_name, double * data, int data_length, 
                            SCHistogramPlotParameters * histogram_plot_parameters, int order)
{
    writeWarningToConsole([NSString stringWithFormat:@"SC Warning: SCHistogramPlotParameters is obsolete.  Please use the function SCMakeHistogramNow.\n"]);
    SCMakeHistogramNow(plot_name, data, data_length, histogram_plot_parameters, order);
}


void SCMakeHistogramNow(char * plot_name, double * data, int data_length, SCHistogramPlotParameters * hpp, int order)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [varIteratorLock lock];
    int val = PlotNowVarIterator++;
    [varIteratorLock unlock];

    [simModelInApplication makeHistogramPlotNow:[NSString stringWithUTF8String:plot_name]
                           name:[NSString stringWithFormat:@"UserPlottedX%i", val]
                           data:data
                           dataLength:data_length
                           histogramPlotParameters:hpp
                           orderIndex:order];

    [pool release];
}


void SCMakeHistogramNowFMC(char * plot_name, char * var_name, SCHistogramPlotParameters * hpp, int order)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    [varIteratorLock lock];
    int val = PlotNowVarIterator++;
    [varIteratorLock unlock];

    [simModelInApplication makeHistogramPlotNowFMC:[NSString stringWithUTF8String:plot_name]
                           name:[NSString stringWithFormat:@"UserPlottedX%i%s", val, var_name]
                           MCName:[NSString stringWithUTF8String:var_name]
                           histogramPlotParameters:hpp
                           orderIndex:order];

    [pool release];
}



/* Create a fit plot from data supplied to the function. */
void SCMakeFitNow(char * plot_name, double * xdata, double * ydata, int data_length, SCFitPlotParameters * fit_plot_parameters, int order, char * expression, int nparams, ...)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    va_list ap;
    va_start(ap, nparams);   // should change to function_approximation_plot_parameters -DCS:2009/10/12

    NSMutableArray * param_names = [NSMutableArray arrayWithCapacity:nparams];
    NSMutableArray * param_values = [NSMutableArray arrayWithCapacity:nparams];

    for ( int i = 0; i < nparams; i++ )
    {
        char * param_name = va_arg(ap, char *);
        if ( param_name )
        {
            //printf("string %s\n", param_name);
            double param_val = va_arg(ap, double);
            if ( param_val )
            {
                //printf("double %lf\n", param_val);
                [param_names addObject:[NSString stringWithUTF8String:param_name]];
                [param_values addObject:[NSString stringWithFormat:@"%lf", param_val]];
            }
            else
            {
                writeWarningToConsole([NSString stringWithFormat:@"SC Warning: SCMakeFitNow: There are more parameter names than parameter values.  Not using parameter %s.\n", param_name]);
                break;
            }
        }
        else
        {
            break;
        }
    }    
    va_end(ap);
    
    [varIteratorLock lock];
    int x_val = PlotNowVarIterator++;
    int y_val = PlotNowVarIterator++;
    [varIteratorLock unlock];

    [simModelInApplication makeFitNow:[NSString stringWithUTF8String:plot_name]
                           xName:[NSString stringWithFormat:@"UserPlottedX%i", x_val]
                           yName:[NSString stringWithFormat:@"UserPlottedY%i", y_val]
                           xData:xdata
                           yData:ydata
                           dataLength:data_length
                           expression:[NSString stringWithUTF8String:expression]
                           parameterNames:param_names
                           parameterValues:param_values                           
                           fitPlotParameters:fit_plot_parameters
                           orderIndex:order];

    [pool release];
}


void SCMakeFitNowFMC(char * plot_name, char * x_var_name, char * y_var_name, SCFitPlotParameters * fpp, int order, char * expression, int nparams, ...)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    va_list ap;
    va_start(ap, nparams);   // should change to function_approximation_plot_parameters -DCS:2009/10/12

    NSMutableArray * param_names = [NSMutableArray arrayWithCapacity:nparams];
    NSMutableArray * param_values = [NSMutableArray arrayWithCapacity:nparams];

    for ( int i = 0; i < nparams; i++ )
    {
        char * param_name = va_arg(ap, char *);
        if ( param_name )
        {
            //printf("string %s\n", param_name);
            double param_val = va_arg(ap, double);
            if ( param_val )
            {
                //printf("double %lf\n", param_val);
                [param_names addObject:[NSString stringWithUTF8String:param_name]];
                [param_values addObject:[NSString stringWithFormat:@"%lf", param_val]];
            }
            else
            {
                writeWarningToConsole([NSString stringWithFormat:@"SC Warning: SCMakeFitNowFMC: There are more parameter names than parameter values.  Not using parameter %s.\n", param_name]);
                break;
            }
        }
        else
        {
            break;
        }
    }    
    va_end(ap);
    
    [varIteratorLock lock];
    int x_val = PlotNowVarIterator++;
    int y_val = PlotNowVarIterator++;
    [varIteratorLock unlock];

    [simModelInApplication makeFitNowFMC:[NSString stringWithUTF8String:plot_name]
                           xName:[NSString stringWithFormat:@"UserPlottedX%i%s", x_val, x_var_name]
                           yName:[NSString stringWithFormat:@"UserPlottedY%i%s", y_val, y_var_name]
                           xMCName:[NSString stringWithUTF8String:x_var_name]
                           yMCName:[NSString stringWithUTF8String:y_var_name]
                           expression:[NSString stringWithUTF8String:expression]
                           parameterNames:param_names
                           parameterValues:param_values                           
                           fitPlotParameters:fpp
                           orderIndex:order];

    [pool release];    
}



void SCAddVarsToSmooth(char * plot_name, char * x_var_name, char * y_var_name, SCSmoothPlotParameters * smooth_plot_parameters)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [simModelInApplication addVarsToSmooth:[NSString stringWithUTF8String:plot_name]
                           xName:[NSString stringWithUTF8String:x_var_name]
                           yName:[NSString stringWithUTF8String:y_var_name]
                           smoothPlotParameters:smooth_plot_parameters];
    
    [pool release];
}


void SCMakeSmoothNow(char * plot_name, double * xdata, double * ydata, int data_length, SCSmoothPlotParameters * smooth_plot_parameters, int order)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [varIteratorLock lock];
    int x_val = PlotNowVarIterator++;
    int y_val = PlotNowVarIterator++;
    [varIteratorLock unlock];

    [simModelInApplication makeSmoothNow:[NSString stringWithUTF8String:plot_name]
                           xName:[NSString stringWithFormat:@"UserPlottedX%i", x_val]
                           yName:[NSString stringWithFormat:@"UserPlottedY%i", y_val]
                           xData:xdata
                           yData:ydata
                           dataLength:data_length
                           smoothPlotParameters:smooth_plot_parameters
                           orderIndex:order];

    [pool release];
}


void SCMakeSmoothNowFMC(char * plot_name, char * x_var_name, char * y_var_name, SCSmoothPlotParameters * spp, int order)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [varIteratorLock lock];
    int x_val = PlotNowVarIterator++;
    int y_val = PlotNowVarIterator++;
    [varIteratorLock unlock];

    [simModelInApplication makeSmoothNowFMC:[NSString stringWithUTF8String:plot_name]
                           xName:[NSString stringWithFormat:@"UserPlottedX%i%s", x_val, x_var_name]
                           yName:[NSString stringWithFormat:@"UserPlottedY%i%s", y_val, x_var_name]
                           xMCName:[NSString stringWithUTF8String:x_var_name]
                           yMCName:[NSString stringWithUTF8String:y_var_name]
                           smoothPlotParameters:spp
                           orderIndex:order];

    [pool release];    
}


void SCAddVarsToMultiLines(char * plot_name, char * lines_var_name, char * lower_limits_var_name, char * upper_limits_var_name, 
                           char * labels_var_name, SCMultiLinesPlotParameters * multi_lines_plot_parameters)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSString * lower_limits_var_name_ns = nil;
    if ( !lower_limits_var_name )
        lower_limits_var_name_ns = [NSString string];
    else
        lower_limits_var_name_ns = [NSString stringWithUTF8String:lower_limits_var_name];
    
    NSString * upper_limits_var_name_ns = nil;
    if ( !upper_limits_var_name )
        upper_limits_var_name_ns = [NSString string];
    else
        upper_limits_var_name_ns = [NSString stringWithUTF8String:upper_limits_var_name];

    NSString * labels_var_name_ns = nil;
    if ( !labels_var_name )
        labels_var_name_ns = [NSString string];
    else
        labels_var_name_ns = [NSString stringWithUTF8String:labels_var_name];

    [simModelInApplication addVarsToMultiLines:[NSString stringWithUTF8String:plot_name]
                           linesVarName:[NSString stringWithUTF8String:lines_var_name]
                           lowerLimitsVarName:lower_limits_var_name_ns
                           upperLimitsVarName:upper_limits_var_name_ns
                           labelsVarName:labels_var_name_ns
                           multiLinesPlotParameters:multi_lines_plot_parameters];
    
    [pool release];
}


void SCMakeMultiLinesNow(char * plot_name, double * lines_data, double * lower_limits_data, double * upper_limits_data, 
                         double * labels_data, int data_length, SCMultiLinesPlotParameters * mlpp, int order)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [varIteratorLock lock];
    
    int lines_val = 0;
    if ( lines_data )
        lines_val = PlotNowVarIterator++;

    int lower_limits_val = 0; 
    if ( lower_limits_data ) 
        lower_limits_val = PlotNowVarIterator++;

    int upper_limits_val = 0;
    if ( upper_limits_data )
        upper_limits_val = PlotNowVarIterator++;

    int labels_val = 0;
    if ( labels_data )
         labels_val = PlotNowVarIterator++;

    [varIteratorLock unlock];

    NSString *lines_name = nil;
    if ( !lines_data )
        lines_name = [NSString string];
    else
        lines_name = [NSString stringWithFormat:@"UserPlottedLines%i", lines_val];

    NSString *lower_limits_name = nil;
    if ( !lower_limits_data )
        lower_limits_name = [NSString string];
    else
        lower_limits_name = [NSString stringWithFormat:@"UserPlottedLowerLimits%i", lower_limits_val];

    NSString *upper_limits_name = nil;
    if ( !upper_limits_data )
        upper_limits_name = [NSString string];
    else
        upper_limits_name = [NSString stringWithFormat:@"UserPlottedYMin%i", upper_limits_val];

    NSString *labels_name = nil;
    if ( !labels_data )
        labels_name = [NSString string];
    else
        labels_name = [NSString stringWithFormat:@"UserPlottedLabels%i", labels_val];


    [simModelInApplication makeMultLinesNow:[NSString stringWithUTF8String:plot_name]
                           linesVarName:lines_name
                           lowerLimitsVarName:lower_limits_name
                           upperLimitsVarName:upper_limits_name
                           labelsVarName:labels_name
                           linesData:lines_data
                           lowerLimitsData:lower_limits_data
                           upperLimitsData:upper_limits_data
                           labelsData:labels_data
                           dataLength:data_length
                           multiLinesPlotParameters:mlpp
                           orderIndex:order];

    [pool release];
}



void SCAddVarsToRange(char * plot_name, char * x_min_var_name, char * x_max_var_name, char * y_min_var_name, char * y_max_var_name, 
                      char * range_color_var_name, char * color_scheme_name, SCRangePlotParameters * range_plot_parameters)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSString * x_min_var_name_ns = nil;
    if ( !x_min_var_name )
        x_min_var_name_ns = [NSString string];
    else
        x_min_var_name_ns = [NSString stringWithUTF8String:x_min_var_name];

    NSString * x_max_var_name_ns = nil;
    if ( !x_max_var_name )
        x_max_var_name_ns = [NSString string];
    else
        x_max_var_name_ns = [NSString stringWithUTF8String:x_max_var_name];

    NSString * y_min_var_name_ns = nil;
    if ( !y_min_var_name )
        y_min_var_name_ns = [NSString string];
    else
        y_min_var_name_ns = [NSString stringWithUTF8String:y_min_var_name];

    NSString * y_max_var_name_ns = nil;
    if ( !y_max_var_name )
        y_max_var_name_ns = [NSString string];
    else
        y_max_var_name_ns = [NSString stringWithUTF8String:y_max_var_name];


    NSString * range_color_var_name_ns = nil;
    if ( !range_color_var_name )
        range_color_var_name_ns = [NSString string];
    else
        range_color_var_name_ns = [NSString stringWithUTF8String:range_color_var_name];


    NSString * color_scheme_name_ns = nil;
    if ( !color_scheme_name )
        color_scheme_name_ns = [NSString string];
    else
        color_scheme_name_ns = [NSString stringWithUTF8String:color_scheme_name];
    

    [simModelInApplication addVarsToRange:[NSString stringWithUTF8String:plot_name]
                           xMinVarName:x_min_var_name_ns
                           xMaxVarName:x_max_var_name_ns
                           yMinVarName:y_min_var_name_ns
                           yMaxVarName:y_max_var_name_ns
                           rangeColorVarName:range_color_var_name_ns
                           colorSchemeName:color_scheme_name_ns
                           rangePlotParameters:range_plot_parameters];
    
    [pool release];    
}


void SCMakeRangeNow(char * plot_name, double * x_min_data, double * x_max_data, double * y_min_data, double * y_max_data, double * range_color_data, int data_length,
                    char *color_scheme_name, SCRangePlotParameters * rpp, int order)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [varIteratorLock lock];
    
    int x_min_val = 0;
    if ( x_min_data )
        x_min_val = PlotNowVarIterator++;

    int x_max_val = 0; 
    if ( x_max_data ) 
        x_max_val = PlotNowVarIterator++;

    int y_min_val = 0;
    if ( y_min_data )
        y_min_val = PlotNowVarIterator++;

    int y_max_val = 0;
    if ( y_max_data )
         y_max_val = PlotNowVarIterator++;

    int range_color_val = 0;
    if ( range_color_data )
        range_color_val = PlotNowVarIterator++;
    
    [varIteratorLock unlock];

    NSString *x_min_name = nil;
    if ( !x_min_data )
        x_min_name = [NSString string];
    else
        x_min_name = [NSString stringWithFormat:@"UserPlottedXMin%i", x_min_val];

    NSString *x_max_name = nil;
    if ( !x_max_data )
        x_max_name = [NSString string];
    else
        x_max_name = [NSString stringWithFormat:@"UserPlottedXMax%i", x_max_val];

    NSString *y_min_name = nil;
    if ( !y_min_data )
        y_min_name = [NSString string];
    else
        y_min_name = [NSString stringWithFormat:@"UserPlottedYMin%i", y_min_val];

    NSString *y_max_name = nil;
    if ( !y_max_data )
        y_max_name = [NSString string];
    else
        y_max_name = [NSString stringWithFormat:@"UserPlottedYMax%i", y_max_val];

    NSString * range_color_name = nil;
    if ( !range_color_data )
        range_color_name = [NSString string];
    else
        range_color_name = [NSString stringWithFormat:@"UserPlottedRangeColor%i", range_color_val];

    NSString * color_scheme_name_ns = nil;
    if ( !color_scheme_name )
        color_scheme_name_ns = [NSString string];
    else
        color_scheme_name_ns = [NSString stringWithUTF8String:color_scheme_name];

    [simModelInApplication makeRangeNow:[NSString stringWithUTF8String:plot_name]
                           xMinName:x_min_name
                           xMaxName:x_max_name
                           yMinName:y_min_name
                           yMaxName:y_max_name
                           rangeColorName:range_color_name
                           xMinData:x_min_data
                           xMaxData:x_max_data
                           yMinData:y_min_data
                           yMaxData:y_max_data
                           rangeColorData:range_color_data
                           dataLength:data_length
                           colorSchemeName:color_scheme_name_ns
                           rangePlotParameters:rpp
                           orderIndex:order];
                           
    [pool release];
}


void SCAddVarsToScatter(char * plot_name, char * x_var_name, char * y_var_name, 
                        char * point_size_name, char * point_color_name, char * color_scheme_name, 
                        SCScatterPlotParameters *spp)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSString * point_size_name_ns = nil;
    if ( !point_size_name )
        point_size_name_ns = [NSString string];
    else
        point_size_name_ns = [NSString stringWithUTF8String:point_size_name];

    NSString * point_color_name_ns = nil;
    if ( !point_color_name )
        point_color_name_ns = [NSString string];
    else
        point_color_name_ns = [NSString stringWithUTF8String:point_color_name];

    NSString * color_scheme_name_ns = nil;
    if ( !color_scheme_name )
        color_scheme_name_ns = [NSString string];
    else
        color_scheme_name_ns = [NSString stringWithUTF8String:color_scheme_name];

    
    [simModelInApplication addVarsToScatter:[NSString stringWithUTF8String:plot_name]
                           xVarName:[NSString stringWithUTF8String:x_var_name]
                           yVarName:[NSString stringWithUTF8String:y_var_name]
                           pointSizeName:point_size_name_ns
                           pointColorName:point_color_name_ns
                           colorSchemeName:color_scheme_name_ns
                           scatterPlotParameters:spp];

    [pool release];
}


void SCMakeScatterNow(char * plot_name, double * x_data, double * y_data, double * point_size_data, double * point_color_data, int data_length,
                      char * color_scheme_name, SCScatterPlotParameters *spp, int order)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [varIteratorLock lock];
    int x_val = PlotNowVarIterator++;
    int y_val = PlotNowVarIterator++;
    int psd_val = 0;
    if ( point_size_data )
        psd_val = PlotNowVarIterator++;
    int pcd_val = 0;
    if ( point_color_data )
        pcd_val = PlotNowVarIterator++;
    [varIteratorLock unlock];

    NSString *point_size_name = nil;
    if ( !point_size_data )
        point_size_name = [NSString string];
    else
        point_size_name = [NSString stringWithFormat:@"UserPlottedPSD%i", psd_val];
    
    NSString *point_color_name = nil;
    if ( !point_color_data )
        point_color_name = [NSString string];
    else
        point_color_name = [NSString stringWithFormat:@"UserPlottedPCD%i", pcd_val];

    NSString * color_scheme_name_ns = nil;
    if ( !color_scheme_name )
        color_scheme_name_ns = [NSString string];
    else
        color_scheme_name_ns = [NSString stringWithUTF8String:color_scheme_name];
    
    [simModelInApplication makeScatterNow:[NSString stringWithUTF8String:plot_name]
                           xVarName:[NSString stringWithFormat:@"UserPlottedX%i", x_val]
                           yVarName:[NSString stringWithFormat:@"UserPlottedY%i", y_val]
                           pointSizeName:point_size_name
                           pointColorName:point_color_name
                           xData:x_data
                           yData:y_data
                           pointSizeData:point_size_data
                           pointColorData:point_color_data
                           dataLength:data_length
                           colorSchemeName:color_scheme_name_ns
                           scatterPlotParameters:spp
                           orderIndex:order];

    [pool release];
}



void SCCopyDataFromHistoryWithIndex(char * var_name, int history_index, int sample_every, double **data_ptr_ptr, int * nvalues_ptr)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSString * var_name_ns = nil;
    if ( !var_name )
        var_name_ns = [NSString string];
    else
        var_name_ns = [NSString stringWithUTF8String:var_name];
    
    [simModelInApplication copyDataFromHistoryWithIndex:var_name_ns historyIdx:history_index sampleEvery:sample_every dataPtrPtr:data_ptr_ptr nValuesPtr:nvalues_ptr];

    [pool release];
}


void SCCopyFlatDataFromHistories(char * var_name, int history_start_idx, int history_stop_idx, int sample_every, double ** data_ptr_ptr, int * nvalues_ptr)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSString * var_name_ns = nil;
    if ( !var_name )
        var_name_ns = [NSString string];
    else
        var_name_ns = [NSString stringWithUTF8String:var_name];
    
    [simModelInApplication copyFlatDataFromHistories: var_name_ns 
                           historyStartIdx: history_start_idx 
                           historyStopIdx: history_stop_idx 
                           sampleEvery: sample_every
                           dataPtrPtr: data_ptr_ptr 
                           nValuesPtr: nvalues_ptr];

    [pool release];    
}


void SCCopyFlatDataFromHistoriesForColumns(char * var_name_prefix, int var_start_idx, int var_stop_idx, 
                                           int history_start_idx, int history_stop_idx, int sample_every,
                                           double *** data_ptr_ptr_ptr, int ** nvalues_ptr_ptr)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSString * var_name_prefix_ns = nil;
    if ( !var_name_prefix )
        var_name_prefix_ns = [NSString string];
    else
        var_name_prefix_ns = [NSString stringWithUTF8String:var_name_prefix];
    
    [simModelInApplication copyFlatDataFromHistoriesForColumns: var_name_prefix_ns 
                           varStartIdx: var_start_idx
                           varStopIdx: var_stop_idx
                           historyStartIdx: history_start_idx
                           historyStopIdx: history_stop_idx 
                           sampleEvery: sample_every
                           dataPtrPtrPtr: data_ptr_ptr_ptr 
                           nValuesPtrPtr: nvalues_ptr_ptr];

    [pool release];
}




void SCCopyStructuredDataFromHistories(char * var_name, int history_start_idx, int history_stop_idx, int sample_every, double *** data_ptr_ptr_ptr, int ** nvalues_ptr_ptr)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSString * var_name_ns = nil;
    if ( !var_name )
        var_name_ns = [NSString string];
    else
        var_name_ns = [NSString stringWithUTF8String:var_name];
    
    [simModelInApplication copyStructuredDataFromHistories: var_name_ns 
                           historyStartIdx: history_start_idx
                           historyStopIdx: history_stop_idx 
                           sampleEvery: sample_every
                           dataPtrPtrPtr: data_ptr_ptr_ptr 
                           nValuesPtrPtr: nvalues_ptr_ptr];

    [pool release];

}



void SCAddManagedColumn(char * var_name, bool do_clear_after_plot_duration)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [simModelInApplication addManagedColumnVariable:[NSString stringWithUTF8String:var_name] 
                           doClearAfterPlotDuration:do_clear_after_plot_duration sizeHint:0];

    [pool release];    
}


void SCAddManagedColumnWithSize(char * var_name, bool do_clear_after_plot_duration, int size_hint)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [simModelInApplication addManagedColumnVariable:[NSString stringWithUTF8String:var_name] 
                           doClearAfterPlotDuration:do_clear_after_plot_duration sizeHint:size_hint];

    [pool release];    

}


void SCAddManagedColumns(char * var_name_prefix, int ncolumns, bool do_clear_after_plot_duration)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [simModelInApplication addManagedColumnVariables:[NSString stringWithUTF8String:var_name_prefix] nColumns:ncolumns 
                           doClearAfterPlotDuration:do_clear_after_plot_duration sizeHint:0];

    [pool release];
}


void SCAddManagedColumnsWithSize(char * var_name_prefix, int ncolumns, bool do_clear_after_plot_duration, int size_hint)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [simModelInApplication addManagedColumnVariables:[NSString stringWithUTF8String:var_name_prefix] nColumns:ncolumns 
                           doClearAfterPlotDuration:do_clear_after_plot_duration sizeHint:size_hint];

    [pool release];
}


void SCAddDataToManagedColumn(char * var_name, double * new_data, int length)
{
    [simModelInApplication addDataToManagedColumn:[NSString stringWithUTF8String:var_name] newData:new_data length:length];
}

void SCAddOneValueToManagedColumn(char * var_name, double value)
{
    double dvalue = value;
    SCAddDataToManagedColumn(var_name, &dvalue, 1);
}

void SCAddManyValuesToManagedColumn(char * var_name, int nvalues, ...)
{
    double dvalues[nvalues];
    
    va_list ap;
    va_start(ap, nvalues);   // should change to function_approximation_plot_parameters -DCS:2009/10/12    
    for ( int i = 0; i < nvalues; i++ )
    {
        double val = va_arg(ap, double);
        dvalues[i] = val;
    }    
    va_end(ap);

    SCAddDataToManagedColumn(var_name, dvalues, nvalues);
}


void SCCopyDataFromManagedColumn(char * var_name, double ** data_ptr_ptr, int * nvalues_ptr)
{
    [simModelInApplication copyDataFromManagedColumn:[NSString stringWithUTF8String:var_name] dataPtrPtr:data_ptr_ptr nValuesPtr:nvalues_ptr];
}


void SCClearManagedColumn(char * var_name)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [simModelInApplication clearDataInManagedColumn:[NSString stringWithUTF8String:var_name]];

    [pool release];
}

void SCClearManagedColumnsWithPrefix(char * var_name_prefix, int ncolumns)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    [simModelInApplication clearDataInManagedColumnsWithVarNamePrefix:[NSString stringWithUTF8String:var_name_prefix] nColumns:ncolumns];

    [pool release];    
}


void SCAddExpressionColumn(char * var_name, char * expression)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [simModelInApplication addExpressionVariable:[NSString stringWithUTF8String:var_name] expression:[NSString stringWithUTF8String:expression]];

    [pool release];
}


void SCAddExpressionVariable(char * var_name, char * expression)
{
    writeWarningToConsole([NSString stringWithFormat:@"SC Warning: SCAddExpressionVariable is obsolete.  Please use the function SCAddExpressionColumn.\n"]);
    SCAddExpressionColumn(var_name, expression);
}


void SCTextCopy(char * label, char ** dest)
{
    if ( dest != NULL )
    {
        free ( *dest );
        *dest = NULL;
    }
    int string_length = strlen(label);
    
    if ( string_length > 0 )
    {
        *dest = (char *)malloc((string_length+1)*sizeof(char));
        strncpy(*dest, label, string_length+1);
    }
}


void SCColorCopy(SCColor *src, SCColor *dest)
{
    if ( dest == NULL || src == NULL )
        return;

    dest->red = src->red;
    dest->green = src->green;
    dest->blue = src->blue;
    dest->alpha = src->alpha;
}


NSColor * NSColorFromName(char * color_name)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSString * clean_color_name = [NSString stringWithUTF8String:color_name];    
    NSArray *all_color_lists = [NSColorList availableColorLists];
    NSColor * color = nil;
    for ( NSColorList *color_list in all_color_lists ) 
    {
        if ( color )
            break;
        
        for ( NSString * key in [color_list allKeys] )
        {
            NSRange where_found = [key rangeOfString:clean_color_name options:NSCaseInsensitiveSearch];
            if (( where_found.location == 0 ) && (where_found.length > 0 ))
            {
                color = [[color_list colorWithKey:key] retain]; 
                break;
            }
        }
    }    
    // The retain count of the color from the color list is -1. I don't fully understand this.  I didn't request a new
    // color or anything, so I'm not really sure what should happen here.  Even after a retain, the retain count was
    // still -1.  -DCS:2009/10/23
    
    [pool release];

    return color;
}


int SCColorFromName(char * color_name, SCColor * cs)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSColor * color = NSColorFromName(color_name);
    if ( color )
    {
        [color getRed:(CGFloat*)&cs->red green:(CGFloat *)&cs->green blue:(CGFloat *)&cs->blue alpha:(CGFloat *)&cs->alpha];
        [pool release];
        return 1;
    }
    else
    {
        cs->red = 0.0;
        cs->green = 0.0;
        cs->blue = 0.0;
        cs->alpha = 1.0;
        writeWarningToConsole([NSString stringWithFormat:@"SC Warning: Could not find color %s, using black.\n", color_name]);
        [pool release];
        return 0;
    }
}


int SCColorRangeFromNames(char * color_name_1, char * color_name_2, int ncolors, SCColor * cs, float alpha)
{
    assert ( color_name_1 );
    assert ( color_name_2 );
    assert ( cs );

    SCColor cs1;
    SCColor cs2;

    SCColorFromName(color_name_1, &cs1);
    SCColorFromName(color_name_2, &cs2);

    SCColorCopy(&cs1, &cs[0]);
    cs[0].alpha = alpha;
    

    SCColorCopy(&cs2, &cs[ncolors-1]);
    cs[ncolors-1].alpha = alpha;

    if ( ncolors > 2 )
    {
        float denom = (float)(ncolors - 1);
        float rd = fabs((cs1.red - cs2.red) / denom);
        float gd = fabs((cs1.green - cs2.green) / denom);
        float bd = fabs((cs1.blue - cs2.blue) / denom);
        
        SCColor c;
        SCColorCopy(&cs1, &c);
        for ( int i = 1; i < ncolors-1; i++ )
        {
            if ( cs1.red < cs2.red )
                c.red += rd;
            else
                c.red -= rd;
            
            if ( cs1.green < cs2.green )
                c.green += gd;
            else
                c.green -= gd;
            
            if ( cs1.blue < cs2.blue )
                c.blue += bd;
            else
                c.blue -= bd;
            
            SCColorCopy(&c, &cs[i]);
            cs[i].alpha = alpha;
        }
    }
    return 1;
}
