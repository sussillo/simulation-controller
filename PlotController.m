#import "PlotController.h"
#import <DataGraph/DGFillSettings.h>
#import <DataGraph/DGHistogramCommand.h> // not in DataGraph.h, which is included from PlotController.h -DCS:2009/09/16
#import "DTContainerForDoubleArray.h"
#import "DGControllerStateAddition.h"
#import "SCPlotCommand.h"
#import "SCManagedColumn.h"
#import "SCColorScheme.h"
#import "DebugLog.h"

// historyplot addNewHistoryPlot

extern NSString * const SCWriteToControllerConsoleAttributedNotification; // for sending colored notes to the controller console


@implementation PlotController

- (id)init
{
    if ( self = [super init] )
    {
        doPlot = YES;
        doClearPlotNowCommandsAfterEachDuration = YES;
        doClearWatchedColumnsOnNextDraw = NO;
        columnsOfWatchedVarsByName = [[NSMutableDictionary alloc] init];
        plotNowDGColumns = [[NSMutableDictionary alloc] init];
        additionalXAxisParameters = [[NSMutableArray alloc] init];
        additionalYAxisParameters = [[NSMutableArray alloc] init];
        colorSchemesDGByName = [[NSMutableDictionary alloc] init];
        // Nothing yet to do.
    }
    return self;
}


- (void)dealloc
{
    int n_x_axis = [additionalXAxisParameters count] + 1;
    for ( int i = 0; i < n_x_axis; i++ )
    {
        free( magnifyCommands[i] ) ;
    }
    free ( magnifyCommands );

    [plotName release];
    [variableNames release];
    [watchedVariableNames release];
    [variableData release];
    [plotCommandDataList release];
    [colorSchemesByName release];
    [defaultAxisParameters release];
    [additionalXAxisParameters release];
    [additionalYAxisParameters release];
    [colorSchemesDGByName release];
    [columnsOfWatchedVarsByName release];
    [columnsAllVarsByName release];
    [plotNowDGColumns release];
    [super dealloc];
}

    

- (void)awakeFromNib
{
    assert ( 0 );
//     DebugNSLog(@"plotController awakeFromNib");
//     if ( [drawController scriptName] == nil ) 
//     {
//         [drawController overwriteWithScriptFileInBundle:@"Real Time"];
//     }
}


@synthesize nPointsToSave;
@synthesize computeLock;
@synthesize docWindow;
@synthesize defaultAxisParameters;
@synthesize plotName;
@synthesize doClearPlotNowCommandsAfterEachDuration;
@synthesize doPlotInMainThread;

-(void)writeWarningToConsole:(NSString*)text 
{
    NSColor *txtColor = [NSColor redColor];
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


- (void) setPlotCommandDataList:(NSArray *)plot_command_data_list
{
    [variableNames release];
    variableNames = [[NSMutableSet alloc] init];
    
    [watchedVariableNames autorelease];
    watchedVariableNames = [[NSMutableSet alloc] init];
    
    [variableData release];
    variableData = [[NSMutableDictionary alloc] init];
    
    [self getVariableInfoFromPlotCommand:plot_command_data_list
          variableNames:variableNames
          watchedVariableNames:watchedVariableNames 
          variableData:variableData];
    
    /* Now copy the plot command data list. */
    [plotCommandDataList release];
    plotCommandDataList = [plot_command_data_list retain];
}

-(void) setColorSchemes:(NSDictionary *)color_scheme_dict
{
    [colorSchemesByName release];
    colorSchemesByName = [color_scheme_dict retain];
}



/* Since the variables are associated to a given plot (DG drawing area) via the user's plot declaration commands, the
 * complete list of variables for a given DG drawing area has to be extracted from all the plot commands given to that
 * particular plot. It's either that or put ALL of the columns in ALL of the plots, even though they won't be used,
 * which is no good. The pointers to the sets and arrays had better already be allocated. */
- (void) getVariableInfoFromPlotCommand:(NSArray *)plot_command_list variableNames:(NSMutableSet *)variable_names 
                   watchedVariableNames:(NSMutableSet*)watched_variable_names variableData:(NSMutableDictionary *)variable_data
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];

    /* Plots can be empty initially because of makeXnowplots. */
    if ( !plot_command_list ) 
        return;

    assert ( variable_names );
    assert ( watched_variable_names );
    assert ( variable_data );

    // Doesn't this overwrite if the same variable is used in two separate commands in the same plot?  Is this a
    // problem. -DCS:2009/10/08
    /* Make a point of setting the variables names as well as saving the variable pairs. */
    for ( SCPlotCommand * plot_command in plot_command_list )
    {
        NSArray *all_names = [plot_command allNames];
        NSDictionary *all_variable_data = [plot_command allVariables]; // which one will be called here? -DCS:2009/10/08
        
        for ( NSString * var_name in all_names )
        {
            SCUserData * user_var = [all_variable_data objectForKey:var_name];
            [variable_names addObject:var_name];
            [variable_data setObject:user_var forKey:var_name];
            switch ( [user_var dataType] ) 
            {
            case SC_TIME_COLUMN:
            case SC_FIXED_SIZE_COLUMN:
            case SC_MANAGED_COLUMN:
                [watched_variable_names addObject:var_name];
                break;
            case SC_EXPRESSION_COLUMN:
            case SC_MAKE_NOW_COLUMN:
            case SC_STATIC_COLUMN:
                break;
            default:
                assert ( 0 );
            }
        }
    }

    [pool release];
}


/* already_added and the_columns are modified by this routine.  NOTE: This function must be called on the main thread
 * because DataGraph needs it to be so.  The reason that variable_data, already_added and the_columns are not class
 * variables is because these functions are also utilized by the makeXplotnow commands, which add things on the fly.  So
 * the function parameters are abstracted.  you'll find the internal calls to this function use the class variables as
 * parameters. 
 * 
 * This function must run in the main loop.  Other commands take care of it at the moment but it may make sense to
 * enforce it here -DCS:2009/11/03.  */
- (void)addDGColumn:(NSDictionary *)variable_data alreadyAdded:(NSMutableSet *)already_added theColumns:(NSMutableDictionary *)the_columns
{
    /* Have to loop through data twice to make sure that the expression columns are added after the data columns.  This
     * is important because the expression columns will have an error if the data columns to which they refer are not
     * defined.  We could separate the data for faster performance, but it surely doesn't matter.  */
    for ( NSString * var_name in variable_data )
    {
        SCUserData * user_data = [variable_data objectForKey:var_name];
        if ( [user_data isSilent] )
            continue;
        
        if ( ![already_added containsObject:var_name] )
        {
            NSString * type_string = nil;
            switch ( [user_data dataType ] )
            {
            case SC_TIME_COLUMN:
            case SC_FIXED_SIZE_COLUMN:
            case SC_MANAGED_COLUMN:
            case SC_MAKE_NOW_COLUMN:
            {
                type_string = @"Binary";
                DGBinaryDataColumn *c = (DGBinaryDataColumn*)[drawController addDataColumnWithName:var_name type:type_string];
                [the_columns setObject:c forKey:var_name];
                [already_added addObject:var_name];
            }
            break;
            case SC_STATIC_COLUMN: /* Static columns actually add the data when the column is created. */
            {
                type_string = @"Binary";
                DGBinaryDataColumn *c = (DGBinaryDataColumn*)[drawController addDataColumnWithName:var_name type:type_string];
                NSValue * sc_col_ptr = [user_data dataPtr];
                SCColumn * sc_column = (SCColumn *)[sc_col_ptr pointerValue];
                [c setDataFromPointer:[sc_column getData] length:[sc_column getDataLength]];

                [the_columns setObject:c forKey:var_name];
                [already_added addObject:var_name];
            }
            break;
            case SC_EXPRESSION_COLUMN:
                break;
            default:
                assert ( 0 );
            }
        }
    }
    for ( NSString * var_name in variable_data )
    {
        SCUserData * user_data = [variable_data objectForKey:var_name];
        if ( [user_data isSilent] )
            continue;
        
        if ( ![already_added containsObject:var_name] )
        {
            NSString * type_string = nil;
            switch ( [user_data dataType ] )
            {
            case SC_TIME_COLUMN:
            case SC_FIXED_SIZE_COLUMN:
            case SC_MANAGED_COLUMN:
            case SC_MAKE_NOW_COLUMN:
                break;
            case SC_EXPRESSION_COLUMN:
            {
                type_string = @"Expression";
                DGExpressionDataColumn *c = (DGExpressionDataColumn*)[drawController addDataColumnWithName:var_name type:type_string];
                [c setExpressionString:[user_data expression]];                
                NSString * error_string = [c errorString];
                if ( error_string != nil )
                    [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Expression %@ is formatted incorrectly with string \"%@\".  The error is \"%@\".\n", var_name, [user_data expression], error_string]];

                [the_columns setObject:c forKey:var_name];
                [already_added addObject:var_name];
            }
            break;
            default:
                assert ( 0 );
            }
        }
    }
}


/* The command pointers returned from DG are not saved.  */
-(void) addDefaultAxisAndCanvasSettings
{
    /* Access the canvas settings. */
    DGCanvasCommand *canvas_cmd = [drawController canvasSettings];
    if ( [defaultAxisParameters title] )
        [canvas_cmd setTitle:[defaultAxisParameters title]];
    [canvas_cmd setStacking:(DGCanvasCommandStacking)[defaultAxisParameters multiAxisStyle]];


    DGStylesCommand * styles_cmd = [drawController styleSettings]; // Style sheet
    [styles_cmd selectTag:[defaultAxisParameters gridType] forEntry:@"Grid X and/or Y"];
    [styles_cmd selectTag:[defaultAxisParameters boxStyle] forEntry:@"Box Style"];

    /* X Axis */
    DGXAxisCommand *xaxis_cmd = [drawController xAxisNumber:0]; // assume the base axis is already (always there)
    if ( [defaultAxisParameters xLabel] )
        [xaxis_cmd setAxisTitle:[defaultAxisParameters xLabel]];
    [xaxis_cmd setAxisType:(DGAxisTypeOptions)[defaultAxisParameters xAxisType]];
    [xaxis_cmd setInclude:[NSString stringWithFormat:@"%lf,%lf", [defaultAxisParameters xMin], [defaultAxisParameters xMax]]];
    [xaxis_cmd setPadding:(DGAxisPaddingOptions)DGAxisPaddingNone];

    if ( [defaultAxisParameters doCropWithXMinMax] )
    {
        DGRange xrange;
        xrange.minV = [defaultAxisParameters xMin];
        xrange.maxV = [defaultAxisParameters xMax];
        [xaxis_cmd setCropRange:xrange]; // useful even if data goes outside of defined ranges
    }
    
    if ( [defaultAxisParameters xTicks] > 0.0 )
    {
        [xaxis_cmd setTickMarks:(DGAxisTickMarkOptions)DGTickMarksUniform];
        [xaxis_cmd setStride:[NSString stringWithFormat:@"%lf", [defaultAxisParameters xTicks]]]; // option==DGTickMarksUniform
    }
    else
    {
        [xaxis_cmd setTickMarks:(DGAxisTickMarkOptions)DGTickMarksAutomatic];
    }
    
    [xaxis_cmd setDrawLabels:[defaultAxisParameters doDrawXAxis]];
    

    /* Y Axis */
    DGYAxisCommand *yaxis_cmd = [drawController yAxisNumber:0]; // assume the base axis is already (always there)               
    if ( [defaultAxisParameters yLabel] )
        [yaxis_cmd setAxisTitle:[defaultAxisParameters yLabel]];
    [yaxis_cmd setAxisType:(DGAxisTypeOptions)[defaultAxisParameters yAxisType]];
    [yaxis_cmd setPadding:(DGAxisPaddingOptions)DGAxisPaddingNone];
    [yaxis_cmd setInclude:[NSString stringWithFormat:@"%lf,%lf", [defaultAxisParameters yMin], [defaultAxisParameters yMax]]];

    if ( [defaultAxisParameters doCropWithYMinMax] )
    {
        DGRange yrange;
        yrange.minV = [defaultAxisParameters yMin];
        yrange.maxV = [defaultAxisParameters yMax];
        [yaxis_cmd setCropRange:yrange]; // useful even if data goes out of defined range.
    }

    if ( [defaultAxisParameters yTicks] > 0.0 )
    {
        [yaxis_cmd setTickMarks:(DGAxisTickMarkOptions)DGTickMarksUniform];
        [yaxis_cmd setStride:[NSString stringWithFormat:@"%lf", [defaultAxisParameters yTicks]]]; // option==DGTickMarksUniform
    }
    else
    {
        [yaxis_cmd setTickMarks:(DGAxisTickMarkOptions)DGTickMarksAutomatic];
    }
    [yaxis_cmd setDrawLabels:[defaultAxisParameters doDrawYAxis]];
    
    BOOL do_display_drawing_time = NO;
    [drawController setDisplayTimingResults:do_display_drawing_time];

    [drawController setDelegate:self];
    [DGController setErrorCallbackDelegate:self];

    //[drawController addDrawingCommandWithType:@"Legend"];
    //[drawController addDrawingCommandWithType:@"Magnify"];

}


/* The command pointers returned from DG are not saved here.  It's a one-off type thing. */
-(void) addAdditionalAxis
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];

    for (SCPlotCommand * sc_plot_cmd in plotCommandDataList )
    {
        SCPlotCommandType command_type = [sc_plot_cmd commandType];
        switch ( command_type )
        {
        case SC_AXIS_COMMAND:       /* Added earlier because other commands reference them. */
        {
            // Crop Y                      - Range                : 1,1000
            // Draw Y Labels               - Check box            : On
            // Include Y                   - List of numbers      : 1.000000,1000.000000
            // Pad Y Range                 - Menu                 : tag = 1
            // Relative Size               - Number input         : 1
            // Side                        - Menu                 : tag = 1
            // Space Before                - Menu                 : tag = 3
            // Space Before Pixels         - Number input         : 10
            // X Currency Negative         - Check box            : Off
            // X Currency Negative Red     - Check box            : Off
            // Y Categories                - Column selector      : # 
            // Y Currency                  - Menu                 : tag = 1
            // Y Degree/Radians            - Menu                 : tag = 1
            // Y Minor Ticks Values        - List of numbers      : 0.5,1.5
            // Y Prefix                    - Text field
            // Y Suffix                    - Text field
            // Y Tick Labels               - Column selector      : nothing selected
            // Y Tick Locations            - Column selector      : #
            // Y Ticks Choice              - Menu                 : tag = 2
            // Y Ticks Stride              - Number input         : 1
            // Y Ticks Values              - List of numbers      : 0,1,2
            // Y Title                     - Tokenized input
            // Y Type                      - Menu                 : tag = 3


            SCAxisCommandParameters * acp = (SCAxisCommandParameters *)[sc_plot_cmd commandParameters];
            DGAxisCommand *axis_cmd = nil;
            if ( [acp isXAxis] )
            {
                [additionalXAxisParameters addObject:sc_plot_cmd]; /* Hold onto this in PlotController. */
                axis_cmd = [drawController addXAxis]; 
            }
            else
            {
                [additionalYAxisParameters addObject:sc_plot_cmd]; /* Hold onto this in PlotController. */
                axis_cmd = [drawController addYAxis];
            }

            if ( [acp label] )
                [axis_cmd setAxisTitle:[acp label]];
            [axis_cmd setAxisType:(DGAxisTypeOptions)[acp axisType]];
            [axis_cmd setDrawLabels:[acp doDrawAxis]];
            [axis_cmd setPadding:(DGAxisPaddingOptions)DGAxisPaddingNone];
            [axis_cmd setInclude:[NSString stringWithFormat:@"%lf,%lf", [acp min], [acp max]]];

            if ( [acp doCropWithMinMax] )
            {
                DGRange range;
                range.minV = [acp min];
                range.maxV = [acp max];                
                [axis_cmd setCropRange:range]; // useful even if data goes out of defined range.
            }
            
            [axis_cmd setTickMarks:(DGAxisTickMarkOptions)DGTickMarksUniform];
            [axis_cmd setStride:[NSString stringWithFormat:@"%lf", [acp ticks]]]; // option==DGTickMarksUniform

            [axis_cmd setNumber:[NSNumber numberWithDouble:[acp axisRatio]] forEntry:@"Relative Size"];
            
            // 1 is None, 2 is small, 3 medium, 4 wide, 5 very wide, 6,7,8,9 medium (but looked bigger), 10 exactly
            [axis_cmd selectTag:10 forEntry:@"Space Before"];
            [axis_cmd setNumber:[NSNumber numberWithDouble:[acp axisToAxisSpacing]] forEntry:@"Space Before Pixels"];
        }
        break;
        }
    }
    

    [pool release];
}


-(void) addColorSchemes
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];

    for ( NSString * color_scheme_name in colorSchemesByName )
    {
        SCColorScheme * sc_color_scheme = [colorSchemesByName objectForKey: color_scheme_name];
        //DGColorScheme * dg_color_scheme = [drawController addColorSchemeWithName:[sc_color_scheme name]];
        DGColorScheme * dg_color_scheme = [drawController addColorSchemeWithName:color_scheme_name];
        [colorSchemesDGByName setObject:dg_color_scheme forKey:color_scheme_name];
        int nrange = [[sc_color_scheme rangeTypes] count];
        for ( int i = 0; i < nrange; i++ )
        {
            SCColorRangeType type = (SCColorRangeType)[[[sc_color_scheme rangeTypes] objectAtIndex:i] intValue];
            double range_start = [[[sc_color_scheme rangeStarts] objectAtIndex:i] doubleValue];
            double range_stop = [[[sc_color_scheme rangeStops] objectAtIndex:i] doubleValue];
            NSColor * c = [[sc_color_scheme rangeColors] objectAtIndex:i];
            
            NSString * content;
            switch ( type )
            {
            case SC_COLOR_RANGE_MATCH:
                content = [NSString stringWithFormat:@"%lf", range_start];
                break;
            case SC_COLOR_RANGE_LT_LT:
            case SC_COLOR_RANGE_LTE_LT:
            case SC_COLOR_RANGE_LT_LTE:
            case SC_COLOR_RANGE_LTE_LTE:
                content = [NSString stringWithFormat:@"%lf,%lf", range_start, range_stop];
                break;
            default:
                assert ( 0 );
            }
            [dg_color_scheme appendLineWithType:(DGColorSchemeMatchType)type value:content color:c title:[NSString string]];
        }        
        if ( [dg_color_scheme numberOfLines] ) // there's a spurious column added at the beginning, for some reason. -DCS:2009/10/30
            [dg_color_scheme removeLine:0];
    }
    


    [pool release];
}


/* Add the command to the DataGraph framework.  Note that this function needs to be run in the main thread because the
 * DataGraph framework requires it to be so. */
- (DGCommand *)addDGCommand:(SCPlotCommand *)sc_plot_cmd theColumns:(NSMutableDictionary *)the_columns
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    SCPlotCommandType command_type = [sc_plot_cmd commandType];
    DGCommand * command;
    switch ( command_type )
    {
    case SC_AXIS_COMMAND:       /* Added earlier because other commands reference them. */
        break;
    case SC_LINE_COMMAND: // use the DG plot command
    {
        SCLineCommand * line_command = (SCLineCommand*)sc_plot_cmd;
        NSString * x_var_name = [line_command xName];
        NSString * y_var_name = [line_command yName];
        DGDataColumn *x = [the_columns objectForKey:x_var_name];
        DGDataColumn *y = [the_columns objectForKey:y_var_name];

        DGPlotCommand * dg_plot_cmd = [drawController createPlotCommand];
        [dg_plot_cmd selectColumn:x forEntry:@"X"];
        [dg_plot_cmd selectColumn:y forEntry:@"Y"];
        
        /* Now configure the line plot command with properties that the user set. */
        SCPlotCommandParameters * lcp = (SCPlotCommandParameters *)[sc_plot_cmd commandParameters];            
        [dg_plot_cmd setLinePattern:(DGSimpleLineStyle)[lcp lineStyle]];
        [dg_plot_cmd setLineWidth: [lcp lineWidth]];
        [dg_plot_cmd setLineColorType:DGColorNumberSpecified]; 
        [dg_plot_cmd setColor:[lcp lineColor] forEntry:@"Line Style"]; 
        [dg_plot_cmd setMarkerFillType:DGColorNumberSpecified];
        [dg_plot_cmd setMarkerType: (DGSimplePointStyle)[lcp markerStyle]];
        [dg_plot_cmd setMarkerSize: [lcp markerSize]];
        [dg_plot_cmd setMarkerFill: [lcp markerColor]];
        [dg_plot_cmd setString:[NSString stringWithFormat:@"%lf,%lf", [lcp xOffset], [lcp yOffset]]  forEntry:@"Offset"];
        command = dg_plot_cmd;
    }
    break;
//     case SC_POINTS_COMMAND: // use the dg plot command
//     {
//         SCLineCommand * line_command = (SCLineCommand*)sc_plot_cmd;
//         NSString * x_var_name = [line_command xName];
//         NSString * y_var_name = [line_command yName];
//         DGDataColumn *x = [the_columns objectForKey:x_var_name];
//         DGDataColumn *y = [the_columns objectForKey:y_var_name];

//         DGPlotCommand * dg_plot_cmd = [drawController createPlotCommand];
//         [dg_plot_cmd selectColumn:x forEntry:@"X"];
//         [dg_plot_cmd selectColumn:y forEntry:@"Y"];
        
//         /* Now configure the line plot command with properties that the user set. */
//         PointsCommandParameters * pcp = (PointsCommandParameters *)[sc_plot_cmd commandParameters];
//         [dg_plot_cmd setLinePattern:DGEmptyLineStyle];
//         [dg_plot_cmd setLineWidth:1.0];
//         [dg_plot_cmd setMarkerType: [pcp markerStyle]];
//         [dg_plot_cmd setMarkerSize: [pcp markerSize]];
//         [dg_plot_cmd setLineColorType:DGColorNumberSpecified];
//         [dg_plot_cmd setMarkerFillType:DGColorNumberSpecified];
//         [dg_plot_cmd setMarkerFill: [pcp markerColor]];
//         [dg_plot_cmd setString:[NSString stringWithFormat:@"%lf,%lf", [pcp xOffset], [pcp yOffset]]  forEntry:@"Offset"];
//         command = dg_plot_cmd;
//     }
//     break;
    case SC_FAST_LINE_COMMAND:      /* Uses the DG plots command (not plot) */
    {
        SCFastLineCommand * fast_line_command = (SCFastLineCommand *)sc_plot_cmd;
        NSString * x_var_name = [fast_line_command xName];
        DGDataColumn *x = [the_columns objectForKey:x_var_name];
        NSMutableArray * y_columns = [[NSMutableArray alloc] init];
        
        NSArray * y_names = [fast_line_command yNames];
        for ( NSString * y_var_name in y_names )
        {
            DGDataColumn * y = [the_columns objectForKey:y_var_name];
            [y_columns addObject:y];
        }
        DGPlotsCommand * dg_plots_cmd = [drawController createPlotsCommand];
        [dg_plots_cmd setLocationColumn:x valueColumns:y_columns];
        [y_columns release];
        
        /* Now configure the fast line plot command with properties that the user set. */
        SCTimePlotCommandParameters * flcp = (SCTimePlotCommandParameters *)[fast_line_command commandParameters];
        
        [dg_plots_cmd setLineWidth:[flcp lineWidth]];
        [dg_plots_cmd setLineColor:[flcp lineColor]]; 
        [dg_plots_cmd setXOffset:[flcp xOffset]];
        [dg_plots_cmd setYOffset:[flcp yOffset]];            
        [dg_plots_cmd setLineStyle:(DGPlotsCommandLineType)[flcp lineType]];
        
        if ( [flcp markerStyle] == SC_POINT_STYLE_EMPTY )
            [dg_plots_cmd setPointStyle:DGPlotsCommandNoPoint];
        else
            [dg_plots_cmd setPointStyle:DGPlotsCommandSamePoint];
        
        [dg_plots_cmd setMarkerFillType:(DGColorNumber)DGColorNumberSpecified]; // not sure what this does! -DCS:2009/07/20
        [dg_plots_cmd setMarkerFill:[flcp markerColor]];
        [dg_plots_cmd setMarkerSize:[flcp markerSize]];
        [dg_plots_cmd setMarkerType:(DGSimplePointStyle)[flcp markerStyle]];
        command = dg_plots_cmd;
    }
    break;
//     case SC_FAST_POINTS_COMMAND: /* Uses the dg plots command (not plot) */
//     {
//         SCFastLineCommand * fast_points_command = (SCFastLineCommand *)sc_plot_cmd;
//         NSString * x_var_name = [fast_points_command xName];
//         DGDataColumn *x = [the_columns objectForKey:x_var_name];
//         NSMutableArray * y_columns = [[NSMutableArray alloc] init];
        
//         NSArray * y_names = [fast_points_command yNames];
//         for ( NSString * y_var_name in y_names )
//         {
//             DGDataColumn *y = [the_columns objectForKey:y_var_name];
//             [y_columns addObject:y];
//         }
//         DGPlotsCommand * dg_plots_cmd = [drawController createPlotsCommand];
//         [dg_plots_cmd setLocationColumn:x valueColumns:y_columns];
//         [y_columns release];
        
//         /* Now configure the fast points plot command with properties that the user set. */
//         FastPointsCommandParameters * fpcp = (FastPointsCommandParameters *)[fast_points_command commandParameters];
//         [dg_plots_cmd setXOffset:[fpcp xOffset]];
//         [dg_plots_cmd setYOffset:[fpcp yOffset]];            
//         [dg_plots_cmd setLineStyle:DGPlotsCommandNoLine];
//         [dg_plots_cmd setLineWidth:0]; // gets rid of the border around point  Could be nice to have that border. -DCS:2009/07/21
        
//         if ( [fpcp markerStyle] == DGEmptyPointStyle )
//             [dg_plots_cmd setPointStyle:DGPlotsCommandNoPoint];
//         else
//             [dg_plots_cmd setPointStyle:DGPlotsCommandSamePoint];
        
//         [dg_plots_cmd setMarkerFillType:(DGColorNumber)DGColorNumberSpecified]; // not sure what this does! -DCS:2009/07/20
//         [dg_plots_cmd setMarkerFill:[fpcp markerColor]];
//         [dg_plots_cmd setMarkerSize:[fpcp markerSize]];
//         [dg_plots_cmd setMarkerType:[fpcp markerStyle]];
//         command = dg_plots_cmd;
//     }
    break;
    case SC_BAR_COMMAND:
    {
        SCBarCommand * bar_command = (SCBarCommand *)sc_plot_cmd;
        NSString * var_name = [bar_command name];
        DGDataColumn *c = [the_columns objectForKey:var_name];
        DGBarsCommand *dg_bar_cmd = [drawController createBarsCommand];
        [dg_bar_cmd setColumns:[NSArray arrayWithObjects:c,nil]];
        
        SCBarCommandParameters * bcp = (SCBarCommandParameters *)[bar_command commandParameters];            
        //[dg_bar_cmd setString:[NSString stringWithFormat:@"%lf", x_offset] forEntry:@"Position Offset"];
        [dg_bar_cmd setColor:[bcp barColor] forEntry:@"Solid Color 1"];
        [dg_bar_cmd setPositionOffset:[bcp offset]];
        [dg_bar_cmd setBetweenBars:[bcp distanceBetweenBars]];
        if ( ![bcp barsAreVertical] )
        {
            [dg_bar_cmd selectTag:11 forEntry:@"Bar Type"];
        }
        else
        {
            [dg_bar_cmd selectTag:1 forEntry:@"Bar Type"];
        }
        
        //[dg_bar_cmd 
        /* Something like this would normally be used to set the labels of the categories for the simple bar plot. */
        ///[[myController xAxisNumber:0] setCategories:label];
        command = dg_bar_cmd;
    }
    break;
    case SC_HISTOGRAM_COMMAND:
    {
        SCHistogramCommand * histogram_command = (SCHistogramCommand *)sc_plot_cmd;
        NSString * var_name = [histogram_command name];
        DGDataColumn *c = [the_columns objectForKey:var_name];
        DGHistogramCommand *dg_histogram_cmd = [drawController createHistogramCommand];
        [dg_histogram_cmd selectColumn:c forEntry:@"Data"];
        
        SCHistogramCommandParameters * hppm = (SCHistogramCommandParameters *)[histogram_command commandParameters];
        if ( [hppm barsAreVertical] )
        {
            [dg_histogram_cmd setHistgramDirection:DGHistogramCommandXDirection];
        }
        else
        {
            [dg_histogram_cmd setHistgramDirection:DGHistogramCommandYDirection];
        }
        [dg_histogram_cmd setHistogramType:(DGHistogramCommandType)[hppm barType]];
        if ( [hppm barType] == SC_HISTOGRAM_BAR_SMOOTH )
        {
            [dg_histogram_cmd setSmoothGaussianType:DGHistogramCommandGaussianWidth]; // use percentage of width
            [dg_histogram_cmd setSmoothGaussianWidthValue:[hppm smoothValue]];
        }
        // 1 is counts, 2 is density, 3 is probability, 4 is % is bin
        [dg_histogram_cmd selectTag:[hppm units] forEntry:@"Units"];
        [dg_histogram_cmd selectTag:[hppm spacingType] forEntry:@"Spacing"];
        [dg_histogram_cmd setNumber:[NSNumber numberWithDouble:[hppm spacing]] forEntry:@"Step Size"];
        DGFillSettings * fill_settings = [dg_histogram_cmd fill]; // presumably I can modify these here. 
        [fill_settings setSolidColor:[hppm barColor]];
        if ( [hppm binRangeLow] != 0.0 || [hppm binRangeHigh] != 0.0 )
            [dg_histogram_cmd setString:[NSString stringWithFormat:@"%lf,%lf", [hppm binRangeLow], [hppm binRangeHigh]] forEntry:@"Crop Values"];
        command = dg_histogram_cmd;
    }
    break;
    case SC_FIT_COMMAND:
    {
        SCFitCommand * fit_command = (SCFitCommand*)sc_plot_cmd;
        NSString * x_var_name = [fit_command xName];
        NSString * y_var_name = [fit_command yName];
        NSString * expression = [fit_command expression];
        DGDataColumn *x = [the_columns objectForKey:x_var_name];
        DGDataColumn *y = [the_columns objectForKey:y_var_name];

        DGFitCommand *dg_fit_cmd = [drawController createFitCommand];
        //[dg_fit_cmd selectXColumn:x yColumn:y];        
        [dg_fit_cmd setXColumn:x];
        [dg_fit_cmd setYColumn:y];
        [dg_fit_cmd setFunctionType:DGFitCommandArbitrary];
        [dg_fit_cmd setArbitraryExpression:expression];
        
        NSArray * fit_parameter_names = [fit_command fitParameterNames];
        NSArray * fit_parameter_values = [fit_command fitParameterValues];
        
        int nparams = [fit_parameter_names count];
        //DebugNSLog(@"nparams %i", nparams);
        for ( int i = 0; i < nparams; i++ )
        {
            NSString *param_name = [fit_parameter_names objectAtIndex:i];
            NSString *param_value = [fit_parameter_values objectAtIndex:i];
            [dg_fit_cmd setInitialGuess:param_value forParameter:param_name];
            [dg_fit_cmd setOptimize:YES forParameter:param_name];
        }
        
        SCFitCommandParameters * fcp = (SCFitCommandParameters *)[sc_plot_cmd commandParameters];
        DGLineStyleSettings * line = [dg_fit_cmd line];
        [line setPattern:(DGSimpleLineStyle)[fcp lineStyle]];
        [line setColor:[fcp lineColor]];
        [line setWidth:[fcp lineWidth]];
        command = dg_fit_cmd; 
    }
    break;
    case SC_SMOOTH_COMMAND:     /* DG Fit command is used to do the smoothing. */
    {
        SCSmoothCommand * smooth_command = (SCSmoothCommand*)sc_plot_cmd;
        SCSmoothCommandParameters * scp = (SCSmoothCommandParameters *)[sc_plot_cmd commandParameters];

        NSString * x_var_name = [smooth_command xName];
        NSString * y_var_name = [smooth_command yName];
        double smoothness = [scp smoothness];
        DGDataColumn *x = [the_columns objectForKey:x_var_name];
        DGDataColumn *y = [the_columns objectForKey:y_var_name];

        DGFitCommand *dg_fit_cmd = [drawController createFitCommand];
        [dg_fit_cmd setXColumn:x];
        [dg_fit_cmd setYColumn:y];
        [dg_fit_cmd setFunctionType:DGFitCommandLOESS];
        [dg_fit_cmd selectTag:4 forEntry:@"LOESS Options"];
        // set the smoothness value 
        //LOESS Radius                - Number input         : 0.3width
        //[dg_fit_cmd setNumber:[NSNumber numberWithDouble:smoothness] forEntry:@"LOESS Radius"];
        [dg_fit_cmd setString:[NSString stringWithFormat:@"%lf width", smoothness] forEntry:@"LOESS Radius"];

        DGLineStyleSettings * line = [dg_fit_cmd line];
        [line setPattern:(DGSimpleLineStyle)[scp lineStyle]];
        [line setColor:[scp lineColor]];
        [line setWidth:[scp lineWidth]];
        command = dg_fit_cmd; 
    }
    break;
    case SC_MULTILINES_COMMAND:
    {
        SCMultiLinesCommand * multilines_command = (SCMultiLinesCommand*)sc_plot_cmd;
        SCMultiLinesCommandParameters * mlcp = (SCMultiLinesCommandParameters *)[sc_plot_cmd commandParameters];        
        DGLinesCommand * dg_lines_cmd = [drawController createLinesCommand];
        // Example values:
        // Crop With                   - Unknown
        // Exclude                     - Check box            : Off
        // Font Style                  - Font selector        : Label Font
        // From                        - Column selector      : nothing selected
        // From Value                  - Number input         : -
        // Hide                        - Check box            : Off
        // Label                       - Column selector      : nothing selected
        // Label Offset                - Point input          : 5,5
        // Label Position              - Menu                 : tag = 1
        // Legend                      - Tokenized input      : None
        // Line Style                  - Line style           : Solid
        // Line Type                   - Menu                 : tag = 1
        // Magnify Option              - Segmented input
        // Number List                 - List of numbers      : 0
        // To                          - Column selector      : nothing selected
        // To Value                    - Number input         : 
        // Values                      - Column selector      : nothing selected

        NSString * lines_name = [multilines_command linesName];
        DGDataColumn *lines_column = [the_columns objectForKey:lines_name];
        [dg_lines_cmd selectColumn:lines_column forEntry:@"Values"];

        NSString * lower_limits_name = [multilines_command lowerLimitsName];
        if ( [lower_limits_name length] > 0 )
        {
            DGDataColumn * lower_limits_column = [the_columns objectForKey:lower_limits_name];
            [dg_lines_cmd selectColumn:lower_limits_column forEntry:@"From"];
        }
        else
        {
            double fixed_lower_limit = [mlcp fixedLowerLimit];
            if ( fixed_lower_limit > -1.0e15 ) // hack, see SCPlotParameters.m
                [dg_lines_cmd setNumber:[NSNumber numberWithDouble:fixed_lower_limit] forEntry:@"From Value"];
        }        

        NSString * upper_limits_name = [multilines_command upperLimitsName];
        if ( [upper_limits_name length] > 0 )
        {
            DGDataColumn * upper_limits_column = [the_columns objectForKey:upper_limits_name];
            [dg_lines_cmd selectColumn:upper_limits_column forEntry:@"To"];
        }
        else
        {
            double fixed_upper_limit = [mlcp fixedUpperLimit];
            if ( fixed_upper_limit < 1.0e15 ) // hack, see SCPlotParameters.m
                [dg_lines_cmd setNumber:[NSNumber numberWithDouble:fixed_upper_limit] forEntry:@"To Value"];
        }        

        NSString * labels_name = [multilines_command labelsName];
        if ( [labels_name length] > 0 )
        {
            DGDataColumn * labels_column = [the_columns objectForKey:labels_name];
            [dg_lines_cmd selectColumn:labels_column forEntry:@"Label"];
        }

        if ( [mlcp labelAtTop] )
             [dg_lines_cmd selectTag:2 forEntry:@"Label Position"];        
        else
             [dg_lines_cmd selectTag:1 forEntry:@"Label Position"];        

        if ( [mlcp linesAreVertical] )
            [dg_lines_cmd selectTag:1 forEntry:@"Line Type"];
        else
            [dg_lines_cmd selectTag:2 forEntry:@"Line Type"];
        
        DGLineStyleSettings * line = [dg_lines_cmd line];
        [line setPattern:(DGSimpleLineStyle)[mlcp lineStyle]];
        [line setColor:[mlcp lineColor]];
        [line setWidth:[mlcp lineWidth]];
        command = dg_lines_cmd;        
    }
    break;
    case SC_RANGE_COMMAND:
    {
        SCRangeCommand * range_command = (SCRangeCommand*)sc_plot_cmd;
        SCRangeCommandParameters * rcp = (SCRangeCommandParameters *)[sc_plot_cmd commandParameters];        
        DGRangeCommand * dg_range_cmd = [drawController createRangeCommand];

        // Switching the interval types
        [dg_range_cmd setXIntervalType:(DGRangeCommandIntervalType)[rcp xRangeType]];
        switch ( [rcp xRangeType] )
        {
        case SC_RANGE_EVERYTHING:
            [dg_range_cmd setXEverythingOverlapAxisNumbers:NO];
            break;
        case SC_RANGE_INTERVAL:
        {
            DGRange range;
            range.minV = [rcp xMin];
            range.maxV = [rcp xMax];
            [dg_range_cmd setXInterval:range];
        }
        break;
        case SC_RANGE_ALTERNATES:
        {
            NSString * alternate_string = [NSString stringWithFormat:@"%lf,%lf", [rcp xMin], [rcp xStride]];
            [dg_range_cmd setXAlternatesString:alternate_string];
        }
        break;
        case SC_RANGE_COLUMNS:
        {
            NSString * x_min_var_name = [range_command xMinName];
            NSString * x_max_var_name = [range_command xMaxName];
            DGDataColumn *x_min_col = [the_columns objectForKey:x_min_var_name];
            DGDataColumn *x_max_col = [the_columns objectForKey:x_max_var_name];
            
            [dg_range_cmd setXColumnsStart: x_min_col];
            [dg_range_cmd setXColumnsEnd: x_max_col];
        }
        break;
        default:
            assert ( 0 );
        }

        [dg_range_cmd setYIntervalType:(DGRangeCommandIntervalType)[rcp yRangeType]];
        switch ( [rcp yRangeType] )
        {
        case SC_RANGE_EVERYTHING:
            [dg_range_cmd setYEverythingOverlapAxisNumbers:NO];
            break;
        case SC_RANGE_INTERVAL:
        {
            DGRange range;
            range.minV = [rcp yMin];
            range.maxV = [rcp yMax];
            [dg_range_cmd setYInterval:range];
        }
        break;
        case SC_RANGE_ALTERNATES:
        {
            NSString * alternate_string = [NSString stringWithFormat:@"%lf,%lf", [rcp yMin], [rcp yStride]];
            [dg_range_cmd setYAlternatesString:alternate_string];
        }
        break;
        case SC_RANGE_COLUMNS:
        {
            NSString * y_min_var_name = [range_command yMinName];
            NSString * y_max_var_name = [range_command yMaxName];
            DGDataColumn *y_min_col = [the_columns objectForKey:y_min_var_name];
            DGDataColumn *y_max_col = [the_columns objectForKey:y_max_var_name];
            
            [dg_range_cmd setYColumnsStart: y_min_col];
            [dg_range_cmd setYColumnsEnd: y_max_col];
        }
        break;
        default:
            assert ( 0 );
        }

        DGLineStyleSettings * line_style_settings = [dg_range_cmd line];
        [line_style_settings setPattern:(DGSimpleLineStyle)[rcp lineStyle]];
        [line_style_settings setColor:[rcp lineColor]];
        [line_style_settings setWidth:[rcp lineWidth]];

        
        NSString * range_color_name = [range_command rangeColorName];
        if ( [range_color_name length] > 0 )
        {
            DGDataColumn * range_color_col = [the_columns objectForKey:range_color_name];
            [dg_range_cmd setFillColorColumn:range_color_col];
            [dg_range_cmd setFillColorScheme:[colorSchemesDGByName objectForKey:[range_command colorSchemeName]]];
        }
        else
        {
            DGFillSettings * fill_settings = [dg_range_cmd fill];
            [fill_settings setSolidColor:[rcp fillColor]];
        }
        

        command = dg_range_cmd;
    }
    break;
    case SC_SCATTER_COMMAND:
    {
        SCScatterCommand * scatter_cmd = (SCScatterCommand*)sc_plot_cmd;
        SCScatterCommandParameters * scp = (SCScatterCommandParameters *)[sc_plot_cmd commandParameters];        
        DGPointsCommand * dg_scatter_cmd = [drawController createPointsCommand];
        
        /* X and Y Columns */
        NSString * x_name = [scatter_cmd xName];
        NSString * y_name = [scatter_cmd yName];
        DGDataColumn *x_col = [the_columns objectForKey:x_name];
        DGDataColumn *y_col = [the_columns objectForKey:y_name];

        [dg_scatter_cmd setXColumn:x_col];
        [dg_scatter_cmd setYColumn:y_col];

        [dg_scatter_cmd setLineWidth:[scp borderSize]];
        [dg_scatter_cmd setMarkerType:(DGSimplePointStyle)[scp markerStyle]];
        [dg_scatter_cmd setMarkerFill:[scp markerColor]];
        [dg_scatter_cmd setLineColor:[scp borderColor]];        

        /* Point size */
        NSString * point_size_name = [scatter_cmd pointSizeName];
        if ( [point_size_name length] > 0 )
        {
            DGDataColumn * point_size_col = [the_columns objectForKey:point_size_name];
            [dg_scatter_cmd setPointSizeColumn:point_size_col];
            [dg_scatter_cmd setScaleMethod:(DGPointsCommandScale)[scp scaleType]];
        }
        else
        {
            [dg_scatter_cmd setMarkerSize:[scp markerSize]];
        }        
        
        /* Point color */
        NSString * point_color_name = [scatter_cmd pointColorName];
        if ( [point_color_name length] > 0 )
        {
            DGDataColumn * point_color_col = [the_columns objectForKey:point_color_name];
            //[dg_scatter_cmd setPointColorColumn:point_color_col];
            [dg_scatter_cmd selectColumn:point_color_col forEntry:@"Point Color Variable"];
            [dg_scatter_cmd setPointColorScheme:[colorSchemesDGByName objectForKey:[scatter_cmd colorSchemeName]]];
            [dg_scatter_cmd setPointColorMethod:(DGPointsCommandColoring)[scp colorType]]; // Line or fill
        }

        command = dg_scatter_cmd;        
    }
    break;
    case SC_SILENT_COMMAND:
        break;
    default:
        assert ( 0 );
    }

    /* Get the axis correct. */
    if ( command_type != SC_AXIS_COMMAND && command_type != SC_SILENT_COMMAND)
    {
        SCCommandParameters * pcp = [sc_plot_cmd commandParameters];            
        [command setXAxis:[pcp xAxis] yAxis:[pcp yAxis]];
    }

    /* Command non-specific stuff. */
    int order = [sc_plot_cmd order];
    int num_commands = [drawController howManyDrawingCommands];
    if ( order >= num_commands )
    {
        order = num_commands - 1;
    }
    if ( order >= 0 )        // -1 value means put in last place  (i.e. leave it alone)
    {
        [drawController moveDrawingCommand:command toIndex:order];
    }
    
    [pool release];

    return command;
}


- (void)buildPlotCommand
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    //NSString * plot_name = [defaultAxisParameters title];

    DebugNSLog(@"PlotController buildPlotCommand for %@", plotName);
    
    /* Set up the variables and variable specific configurations to the plot. */
    NSMutableDictionary *the_columns = [NSMutableDictionary dictionaryWithCapacity:[variableNames count]];

    /* For each variable (pair) that has been assigned to a plot, we create a DG data column, and configure the plot
     * command according to the user's specifications. The way things are set up, the same variable can have a data
     * column in multiple plots, and can be configured differently in those plots as well. */
    NSMutableSet * did_add_to_data_graph = [[NSMutableSet alloc] init]; // this is to determine whether columns were already added.

    [self addDGColumn:variableData alreadyAdded:did_add_to_data_graph theColumns:the_columns];
    DGCommand * command;

    // These next commands should probably be in there own function. -DCS:2009/10/06
    /* Now add all the other parts of the plot, such as the axis, etc. */
    [self addDefaultAxisAndCanvasSettings];
    [self addAdditionalAxis];
    [self addColorSchemes];
    
    for (SCPlotCommand * plot_command_data in plotCommandDataList )
    {
        command = [self addDGCommand:plot_command_data theColumns:the_columns]; // command is not saved cuz it's never referenced again
    }

    [did_add_to_data_graph release];
    columnsAllVarsByName = [the_columns retain];
    //columnsOfWatchedVarsByName = [NSMutableDictionary dictionaryWithCapacity:[watchedVariableNames count]];
    for ( NSString * watched_var in watchedVariableNames ) // presumably one can do fast iteration through a NSSET.
    {
        [columnsOfWatchedVarsByName setObject:[columnsAllVarsByName objectForKey:watched_var] forKey:watched_var];
    }    

    /* Set up the magnifyCommand matrix, which is used to keep track of all the magnify commands. */
    int n_x_axis = [additionalXAxisParameters count] + 1;
    int n_y_axis = [additionalYAxisParameters count] + 1;
    magnifyCommands = (DGMagnifyCommand ***)malloc(sizeof(DGMagnifyCommand**)*n_x_axis);
    for ( int i = 0; i < n_x_axis; i++ )
    {
        magnifyCommands[i] = (DGMagnifyCommand **)malloc(sizeof(DGMagnifyCommand*)*n_y_axis);
        for ( int j = 0; j < n_y_axis; j++ )
            magnifyCommands[i][j] = nil;
    }
    
    [pool release];
}




- (void) drawMakeNowCommand:(SCPlotCommand *)plot_command
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    /* Draw the data immediately. */
    NSArray *all_names = [plot_command allNames];
    NSDictionary *all_variable_data = [plot_command allVariables]; // which one will be called here? -DCS:2009/10/08
    
    for ( NSString * var_name in all_names )
    {
        SCUserData *var_data = [all_variable_data objectForKey:var_name];
        DGBinaryDataColumn *column = [plotNowDGColumns objectForKey:var_name];
        if ( column != nil ) 
        {
            int data_length = [var_data dim1];
            double * x_data = (double *)[[var_data makePlotNowData] bytes];
            [column setDataFromPointer:x_data length:data_length];
        }        
    }
    
    //[drawController sync];
    //[drawController redrawNow];
    [drawController sync];
    //[[drawController fullySyncAndCallForTarget:drawController] redrawNow];
    
    [pool release];
}



- (void) addMakePlotNowCommandInternal:(SCPlotCommand *)plot_command
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    /* Create the current plot now command. */
    NSMutableSet * already_added = [NSMutableSet setWithCapacity:1]; /* This isn't really used, but the function requires it. */

    /* The plotNowDGColumns are updated by this function and the array of columns is used later to delete the columns
     * for the next history. */
    NSMutableSet * plot_now_variable_names = [[NSMutableSet alloc] init];
    NSMutableSet * plot_now_watched_variable_names = [[NSMutableSet alloc] init]; /* not used */
    NSMutableDictionary * plot_now_variable_data = [[NSMutableDictionary alloc] init];
    
    NSArray * plot_command_data_one_element_list = [NSArray arrayWithObjects:plot_command,nil];
    [self getVariableInfoFromPlotCommand: plot_command_data_one_element_list
          variableNames: plot_now_variable_names
          watchedVariableNames: plot_now_watched_variable_names 
          variableData: plot_now_variable_data];

    DGCommand * command;
    for ( NSString * var_name in plot_now_variable_names )
    {
        [self addDGColumn:plot_now_variable_data alreadyAdded:already_added theColumns:plotNowDGColumns];
    }
    command = [self addDGCommand:plot_command theColumns:plotNowDGColumns];
    [plotNowDGCommands addObject:command]; /* Used to delete it later. */

    /* Draw the data immediately. */
    [self drawMakeNowCommand:plot_command];

    [plot_now_variable_names release];
    [plot_now_watched_variable_names release];
    [plot_now_variable_data release];
 
    [pool release];
}


/* Used for making plot commands on the fly, not part of the variable watching system, which firsts add the plots and
 * the adds the data as the simulation goes forward.  In this case, the plots and data are added at the same time.  This
 * allows the user to add plot command while the simulation is running, if that is really what they are into. */
- (void)addMakePlotNowCommand:(SCPlotCommand*)plot_command;
{
    [self performSelectorOnMainThread:@selector(addMakePlotNowCommandInternal:) withObject:plot_command waitUntilDone:YES];
}


- (void)removePlotNowDGColumns
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    /* Only the plot now commands that had data were added toe plotNowDGColumns, so we don't have to be selective about
     * deleting the columns. The worry is that we may erase a watched variable column. */
    for (NSString * name in plotNowDGColumns ) 
    {
        [drawController removeDataColumn:[plotNowDGColumns objectForKey:name]];
    }
    [plotNowDGColumns removeAllObjects];

    [pool release];
}


- (void)removePlotNowDGCommands
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    for (DGCommand * command in plotNowDGCommands ) 
    {
        [drawController removeDrawingCommand:command];
    }
    [plotNowDGCommands removeAllObjects];

    [pool release];
}


- (void)removePlotNowDGColumnsAndCommandsInternal
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    [self removePlotNowDGCommands];
    [self removePlotNowDGColumns];

    [pool release];
}


/* A little optimization to avoid unnecessary calls on the main thread. */

/* Previously I had waitUntilDone:YES here.  I'm not sure why.  This leads to a deadlock on the computeLock if someone
 * calls SCClearMakeNowPlots from the computeLock and then does something on the UI that takes the computeLock.  I'm not
 * sure if this logic is sound, but I think so.  Search for 'deadlock' in SimController and read that comment.  It
 * should apply to the same thing here.  The only question is whether or not there are other considerations.  -DCS:2010/02/01*/
- (void)removePlotNowDGColumnsAndCommands
{
    int plot_now_command_count = [plotNowDGCommands count];
    int plot_now_column_count = [plotNowDGColumns count];
    
    if ( plot_now_column_count > 0 && plot_now_command_count > 0 )
        [self performSelectorOnMainThread:@selector(removePlotNowDGColumnsAndCommandsInternal) withObject:nil waitUntilDone:NO];
    else if ( plot_now_column_count > 0 )
        [self performSelectorOnMainThread:@selector(removePlotNowDGColumns) withObject:nil waitUntilDone:NO];
    else if ( plot_now_command_count > 0 )
        [self performSelectorOnMainThread:@selector(removePlotNowDGCommands) withObject:nil waitUntilDone:NO];    
}



/* Draw a complete plot based on the data provided in the parameters. */
-(void) drawCompletePlotInternal:(NSDictionary *)plot_data_and_plot_now_commands
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    NSDictionary * plot_data = [plot_data_and_plot_now_commands objectForKey:@"plotData"];
    NSArray * plot_now_commands = [plot_data_and_plot_now_commands objectForKey:@"plotNowCommands"];

    /* For each column of data in the current plot. */
    SCManagedColumn* array;
    DGBinaryDataColumn *column;

    for (NSString * var_name in plot_data) 
    {
        array = [plot_data objectForKey:var_name];
        int length = [array getDataLength];
        double * data = [array getData];

        column = [columnsOfWatchedVarsByName objectForKey:var_name];
        if ( column == nil ) 
            continue;
        
        if ( length == 0 )      // could have no data for a managed column
            [column removeAllEntries];
        else
            [column setDataFromPointer:data length:length];
    }
    
    /* Now handle the plotnow stuff. */
    [self removePlotNowDGColumnsAndCommands];
    for ( SCPlotCommand * plot_command in plot_now_commands )
    {
        [self addMakePlotNowCommandInternal:plot_command];
    }
    
    //[drawController sync];
    //[drawController redrawNow];
    [drawController sync];
    //[[drawController fullySyncAndCallForTarget:drawController] redrawNow];
    [pool release];
}


/* This function is plotting only the latest plot chunk. */
- (void) drawIncrementalPlotInternal
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    SCManagedColumn *array;
    DGBinaryDataColumn *column;
    
    /* For each column of data in the current plot. */
    //DebugNSLog(@"partial");
    for (NSString * var_name in variableNames) 
    {
        array = [latestPlotChunk objectForKey:var_name];
        column = [columnsOfWatchedVarsByName objectForKey:var_name];
        if ( column == nil ) 
            continue;
        
        SCUserData *user_data = [variableData objectForKey:var_name];
        int length = [array getDataLength];
        double * data = [array getData];
        
        /* Concatenate the same into the latest history dictionary.  */
        if ( [user_data dataType] != SC_MANAGED_COLUMN )
        {
            if ( [user_data dataHoldType] == SC_KEEP_DURATION )
            {
                [column appendValuesFromPointer:data length:length];
            }
            else
            {
                [column setDataFromPointer:data length:length];
            }
        }
        else                    /* SC_MANAGED_COLUMN */
        {
            /* The user can clear the data from the column in the middle of the plot duration.  If they do this then we
             * need to clear the data from the DG column.  Before this would happen automatically since there would be a
             * complete rewrite of the data every time the column was written to DG via setDataFromPointer.  Now that we
             * allow for an append, we need to also be careful to clear the DG column (implictly by using
             * setDataFromPointer) whenever the SC managed column is cleared. */
            NSValue * mc_ptr = [user_data dataPtr];
            SCManagedPlotColumn * managed_column = (SCManagedPlotColumn *)[mc_ptr pointerValue];
            BOOL data_was_cleared = [managed_column dataWasClearedSinceLastPlot];
            if ( data_was_cleared )
            {
                [column setDataFromPointer:data length:length];
            }
            else
            {
                [column appendValuesFromPointer:data length:length];
            }
        }
    }
    //[drawController sync]; // intentionally put into the loop to see if the flicker is reduced.
    //[drawController redrawNow];

    [drawController sync];
    //[[drawController fullySyncAndCallForTarget:drawController] redrawNow];
    latestPlotChunk = nil;  /* We've used it (and we don't own it), so let's not fool ourselves later. */
 
   [pool release];
}


// These waitUntilDone must be YES, so I assume they are already run on the main thread, in which case, I don't see why
// there is a performSelectorOnMainThread here ,other than to be entirely safe.  -DCS:2010/02/02
-(void) drawCompletePlot:(NSDictionary *)plot_data plotNowCommands:(NSArray*)plot_now_commands
{
    NSDictionary * plot_data_and_plot_now_commands = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:plot_data,plot_now_commands,nil] 
                                                                   forKeys:[NSArray arrayWithObjects:@"plotData",@"plotNowCommands", nil]];
    
    if ( [plot_now_commands count] == 0  ) /* Can run outside of main thread because there are no plot now commands. */
    {
        [self drawCompletePlotInternal: plot_data_and_plot_now_commands];
    }
    else                        /* Plot now commands must add columns, which can be done only in the main thread, so we do the whole thing in the main thread. */
    {
        [self performSelectorOnMainThread:@selector(drawCompletePlotInternal:) withObject:plot_data_and_plot_now_commands waitUntilDone:YES];
    }
}


/* Put a thread control layer here. */
// These waitUntilDone must be YES, so I assume they are already run on the main thread, in which case, I don't see why
// there is a performSelectorOnMainThread here ,other than to be entirely safe.  -DCS:2010/02/02
- (void) drawIncrementalPlot
{
    /* It shouldn't be necessary to update the columns in the main thread, but things seem choppy when I don't. -DCS:2009/11/03 */
    if ( doPlotInMainThread )
        [self performSelectorOnMainThread:@selector(drawIncrementalPlotInternal) withObject:nil waitUntilDone:YES];
    else
        [self drawIncrementalPlotInternal]; 
}


/* Clear all the DGColumns that aren't plot now commands or expression columns.  This can be distinguished because the watched variables are
 * in the variableNames variable. */
- (void) clearWatchedColumnsFromDG:(id)arg
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    for ( NSString * var_name in watchedVariableNames ) 
    {
        DGBinaryDataColumn *column = [columnsOfWatchedVarsByName objectForKey:var_name];
        if ( column != nil )    
            [column removeAllEntries]; /* Probably need this for append data, as opposed to the whole rewrite at each time step. */
    }

    [drawController sync];
    //[[drawController fullySyncAndCallForTarget:drawController] redrawNow];
    
    //[drawController sync];
    //[drawController redrawNow];
    [pool release];
}




// These should all be filled in for drawing a simple plot without any history.  But until I implement the UI choice to
// disable the history, I'll keep these blank. -DCS:2009/05/10
- (void)prepPlotForRun:(id)arg
{}

- (void)addNewPlot:(id)arg
{}


- (void)drawPlot:(NSDictionary *)arg
{
    assert ( 0 );
}

// - (void)drawPlot:(NSDictionary *)arg doPlot:(BOOL)do_plot
// {
//     assert( 0 );                // not implemented yet.
// }

- (void)plotDurationFinished:(id)arg
{}

- (void)simulationStopped:(id)arg
{}

-(void) clearCurrentValuesForVariable:(NSString *)var_name
{}


- (void) clearPlotOfMakeNowPlots
{}

- (void)setLoupeTool:(id)sender
{
    loupeIsOn = !loupeIsOn;
    DebugNSLog(@"HistoryController setLoupeTool %i", loupeIsOn);
    [drawController setDisplayLoupe:loupeIsOn];
    DebugNSLog(@"DG Loop variable: %i", [drawController displayLoupe]);
}


- (void)addLegend:(id)sender
{
    DebugNSLog(@"HistoryController addLegend");
    if ( legendCommand == nil )
        legendCommand = [drawController addDrawingCommandWithType:@"Legend"];
    else
    {
        [drawController removeDrawingCommand:legendCommand];
        legendCommand = nil;
    }
}


- (void)setMagnifyTool:(NSMenuItem *)sender
{
    DebugNSLog(@"HistoryController setMagnifyTool");
    
    NSArray * coordinates = [sender representedObject];
    int x_axis_number = 0;
    int y_axis_number = 0;
    if ( coordinates == nil )
    {
        x_axis_number = 0;
        y_axis_number = 0;
    }
    else
    {
        x_axis_number = [[coordinates objectAtIndex:0] intValue];
        y_axis_number = [[coordinates objectAtIndex:1] intValue];
    }
    
    if ( magnifyCommands[x_axis_number][y_axis_number] == nil )
    {
        DGMagnifyCommand * magnify_command = [drawController createMagnifyCommand];

        NSPoint point; 
        point = [NSEvent mouseLocation]; //get current mouse position
        
        //CGEventRef ourEvent = CGEventCreate(NULL);
        //NSPoint point = CGEventGetLocation(ourEvent);
        DebugNSLog(@"Location? x= %f, y = %f", (float)point.x, (float)point.y);


        DGRange xrange;
        {
            double xmin;
            double xmax;
            if ( x_axis_number == 0 )
            {
                xmin = [defaultAxisParameters xMin];
                xmax = [defaultAxisParameters xMax];
            }
            else
            {
                xmin = [(SCAxisCommandParameters*)[[additionalXAxisParameters objectAtIndex:(x_axis_number-1)] commandParameters] min];
                xmax = [(SCAxisCommandParameters*)[[additionalXAxisParameters objectAtIndex:(x_axis_number-1)] commandParameters] max];
            }
            
            double axis_width = xmax-xmin;
            xrange.minV = xmin + axis_width/10.0;
            xrange.maxV = xmin + 2*axis_width/10.0;
        }
        
        DGRange yrange;
        {
            double ymin;
            double ymax;
            if ( y_axis_number == 0 )
            {                
                ymin = [defaultAxisParameters yMin];
                ymax = [defaultAxisParameters yMax];
            }
            else
            {
                ymin = [(SCAxisCommandParameters*)[[additionalYAxisParameters objectAtIndex:(y_axis_number-1)] commandParameters] min];
                ymax = [(SCAxisCommandParameters*)[[additionalYAxisParameters objectAtIndex:(y_axis_number-1)] commandParameters] max];
            }
            
            double axis_height = ymax-ymin;
            yrange.minV = ymin + axis_height/10.0;
            yrange.maxV = ymin + 2*axis_height/10.0;
        }
        
        [magnify_command setXRange:(DGRange)xrange];
        [magnify_command setYRange:(DGRange)yrange];
        DGFillSettings *fill_settings = [magnify_command backgroundFill];
        [fill_settings setSolidColor:[defaultAxisParameters backColor]];
        [magnify_command setXAxis:x_axis_number yAxis:y_axis_number];
        
        magnifyCommands[x_axis_number][y_axis_number] = magnify_command;
    }
    else
    {
        [drawController removeDrawingCommand:magnifyCommands[x_axis_number][y_axis_number]];
        magnifyCommands[x_axis_number][y_axis_number] = nil;
    }
}


- (void)addLabel:(id)sender
{
    DGCommand *label_command = [drawController createLabelCommand];
    [label_command selectTag:2 forEntry:@"End Type"];
}


- (void)DGerrorCallback:(NSString *)error_string
{
    DebugNSLog(@"DG error: %@.\n", error_string);
}


@end

