#import "HistoryController.h"

#import "DGControllerStateAddition.h"
#import "SCPlotCommand.h"
#import "DebugLog.h"
#import "SCManagedColumn.h"

// Is there an unnecessary redraw at the addOneToSliderMax, simply because we add one to the slider? -DCS:2009/11/04

// need to better understand the purpose and actual usage of the state lock around the slider value.  I tried adding
// more locks around reading the value and got deadlocks.  Doesn't the UI have to be updated from the main thread?
// -DCS:2009/10/27
//
// I commented out all references to the state lock because I realized that there is only one thread ever running in
// this code.   So no problems.  I'll leave it in case something changes, but it's probably so buggy
// anyways that I'd have to completely rewrite it. -DCS:2009/11/07

@implementation HistoryController


- (id)init
{
    if ( self = [super init] )
    {
        maxHistoryCount = 276447232;
        totalPlotCount = 0;
        isFirstPlot = YES;
        isPlottingHistoryController = YES;
        legendCommand = nil;
        magnifyCommands = nil;
        loupeIsOn = NO;
        lastPlotUpdateWasPlotted = YES;
        plotNowCommandData = [[NSMutableArray alloc] init];
        plotNowDGCommands = [[NSMutableArray alloc] init];
    }
    return self;
}
    

- (void)dealloc
{
    [historyPlotData release];
    //[stateLock release];
    [plotNowCommandData release];
    [plotNowDGCommands release];
    [super dealloc];
}


@synthesize maxHistoryCount;
@synthesize isPlottingHistoryController;


/* Used to initialize outlet values, etc.  */
// What about the windowDidLoad function? -DCS:2009/07/20 
- (void)awakeFromNib
{
    DebugNSLog(@"HistoryController awakeFromNib");
    //drawController = [[DGController alloc] init];
    [sliderValue setStringValue:@"1"];
    if ( [drawController scriptName] == nil ) 
    {
#ifndef _NO_USER_LIBRARY_
        //[drawController overwriteWithScriptFile:@"Real Time"];
#else
        //[drawController overwriteWithScriptFileInBundle:@"Real Time"];
#endif
    }

    // I'd be nice if this could be a common variable among all window, but I'm not sure how much work that would
    // be. -DCS:2009/06/14
    NSBundle *appBundle = [NSBundle mainBundle];
    NSString *appPath = [appBundle bundlePath];
    lastDirectory = [[NSMutableString alloc] initWithString:[appPath stringByDeletingLastPathComponent]];
}


- (void)buildPlotCommand
{
    DebugNSLog(@"HistoryController buildPlotCommand");
    if ( [self isPlottingHistoryController] )
        [super buildPlotCommand];

    // I tried to put these in the awakeFromNib and I guess it was too early because the computeLock was null (as set in
    // SimController) -DCS:2009/07/20
    // This stuff (UI control from history) could be separated to be a little cleaner. -DCS:2009/11/03
    [slider setLock:[self computeLock]];
    [sliderUp setLock:[self computeLock]];
    [sliderDown setLock:[self computeLock]];

    DebugNSLog(@"%@", variableNames);
    // Set the history specific stuff w.r.t. the slider.  This maybe should go elsewhere, but this is fine for
    // now. -DCS:2009/05/11
//     if ( stateLock == nil ) 
//         stateLock = [NSLock new];
    if ( historyPlotData == nil )
        historyPlotData = [[NSMutableArray alloc] init];
    else 
        [historyPlotData removeAllObjects];

    [slider setMinValue:1.0];
    [slider setMaxValue:1.0];
    [slider setDoubleValue:1.0];
    
    [slider setEnabled:NO];
    [sliderDown setEnabled:NO];
    [sliderUp setEnabled:NO];

    if ( maxHistoryCount == 0 )
    {
        [slider setHidden:YES];
        [sliderUp setHidden:YES];
        [sliderDown setHidden:YES];
        [sliderValue setHidden:YES];
    }

    /* The first addNewPlot command doesn't create the dictionary and array because we need to set them here in order
     * for make now commands in ParameterAction or ButtonAction to work. */
    totalPlotCount = 1;
    [historyPlotData addObject:[NSMutableDictionary dictionary]];        
    [plotNowCommandData addObject:[NSMutableArray array]]; /* For plotnow plotting. */

    /* Keep the last histories here. */
    historyOfLastPlot = [[NSMutableDictionary alloc] init];
    lastPlotNowData = [[NSMutableArray alloc] init];
}



// No lock, for now. -DCS:2009/11/04
/* This function should return an index that can be used in the historyPlotData, so the first index is 0. */
// Aren't these named exactly wrong?  The mapping is reversed from the name, right? -DCS:2010/01/21
-(int) historyToDisplayIdx
{    
    if ( maxHistoryCount == 0 )
        return 0;               // We save the history for the plotNowCommandData and optimizations on size of SCManagedColumns in plotData. 
    
    int slider_value = int(floor([slider doubleValue])); /* This is in units of 1..totalPlotCount */
    
    /* BP */
    assert ( slider_value > 0 );
    if ( slider_value >= [slider maxValue] )
        slider_value = int([slider maxValue]);   

    int hidx = 0;
    
    int n_from_last = totalPlotCount - slider_value;
    int history_count = [historyPlotData count];
    hidx = history_count - 1 - n_from_last;

    assert ( hidx >= 0 );
    assert ( hidx < [historyPlotData count] );

    //DebugNSLog(@"hidx: %i", hidx);
    return hidx;
}


/* Translate from what the user sees to what can be looked up in the history.  Returns -1 if things aren't kosher. */
// Aren't these named exactly wrong?  The mapping is reversed from the name, right? -DCS:2010/01/21
-(int) historyToDisplayIdx:(int)user_history_index
{    
    /* BP */
    if ( user_history_index < 1 ) /* The requested history can't be less than one (in human counting). */
        return -1;
    if ( user_history_index < totalPlotCount - maxHistoryCount ) /* The requested history can't be less than the number of saved histories. */
        return -1;
    if ( user_history_index > [slider maxValue] ) /* The requested history can't be more than the number of histories so far. */
        return -1;

    int hidx = 0;
    
    int n_from_last = totalPlotCount - user_history_index;
    int history_count = [historyPlotData count];
    hidx = history_count - 1 - n_from_last;

    assert ( hidx >= 0 );
    assert ( hidx < [historyPlotData count] );

    //DebugNSLog(@"hidx: %i", hidx);
    return hidx;
}


- (BOOL) copyDataForVariable:(NSString *)var_name 
                  historyIdx:(int)history_idx 
                 sampleEvery:(int)sample_every 
                  dataPtrPtr:(double**)data_ptr_ptr 
                  nValuesPtr:(int *)nvalues_ptr
{
    *data_ptr_ptr = NULL;
    *nvalues_ptr = 0;
    
    /* The history index given to this function is in user indices, so we need to translate. */
    int clean_hidx = [self historyToDisplayIdx:history_idx];

    if ( clean_hidx == -1 )
    {
        *nvalues_ptr = 0;
        *data_ptr_ptr = NULL;
        return NO;
    }
    
    NSDictionary * plot_data = [historyPlotData objectAtIndex:clean_hidx];    
    SCManagedColumn * history_column = [plot_data objectForKey:var_name];
    *nvalues_ptr  = [history_column getDataLength] / sample_every; /* Purposefully cuts off the remainder. */
    
    if ( *nvalues_ptr < 1 )     /* If the sample_every is greater than the history length. */
    {
        *nvalues_ptr = 0;
        *data_ptr_ptr = NULL;
        return NO;
    }    

    double *data_ptr = [history_column getData];

    *data_ptr_ptr = (double *)malloc(*nvalues_ptr * sizeof(double));
    for ( int i = 0; i < *nvalues_ptr; i++ )
        (*data_ptr_ptr)[i] = data_ptr[i*sample_every];

    return YES;
}


/* Copy inclusive from history_start_idx to history_stop_idx */
- (BOOL) copyFlatDataForVariable:(NSString *)var_name 
             historyStartIdx:(int)history_start_idx 
              historyStopIdx:(int)history_stop_idx
                     sampleEvery:(int)sample_every
                  dataPtrPtr:(double**)data_ptr_ptr 
                  nValuesPtr:(int *)nvalues_ptr
{
    *data_ptr_ptr = NULL;
    *nvalues_ptr = 0;    

    /* BP */
    /* The history indices given to this function is in user indices, so we need to translate to C indices. */
    int clean_history_start_idx = [self historyToDisplayIdx:history_start_idx];
    int clean_history_stop_idx = [self historyToDisplayIdx:history_stop_idx];
    if ( clean_history_start_idx == -1 || clean_history_stop_idx == -1)
        return NO;
 
    /* First get the total length of the data. */
    int data_length = 0;
    NSDictionary * plot_data;
    SCManagedColumn * history_column;
    for ( int i = clean_history_start_idx; i <= clean_history_stop_idx; i++)
    {
        plot_data = [historyPlotData objectAtIndex:i]; 
        history_column = [plot_data objectForKey:var_name];
        int sampled_length = [history_column getDataLength] / sample_every;  /* Purposefully cuts off any remainder. */
        if ( sampled_length < 1 )
            return NO;
        data_length += sampled_length; 
    }

    /* Now copy the data into one long array. */
    *nvalues_ptr = data_length;
    *data_ptr_ptr = (double *)malloc(*nvalues_ptr * sizeof(double));
    int index = 0;
    for ( int i = clean_history_start_idx; i <= clean_history_stop_idx; i++)
    {
        plot_data = [historyPlotData objectAtIndex:i]; 
        history_column = [plot_data objectForKey:var_name];
        double * data_ptr = [history_column getData];
        int sampled_history_length = [history_column getDataLength] / sample_every;
        for ( int j = 0; j < sampled_history_length; j++ )
        {
            (*data_ptr_ptr)[index] = data_ptr[j*sample_every];
            index++;
        }
    }
    assert ( index == *nvalues_ptr );
    
    return YES;
}


- (BOOL) copyStructuredDataForVariable:(NSString *)var_name                   
                       historyStartIdx:(int)history_start_idx 
                        historyStopIdx:(int)history_stop_idx
                           sampleEvery:(int)sample_every
                         dataPtrPtrPtr:(double ***)data_ptr_ptr_ptr 
                         nValuesPtrPtr:(int **)nvalues_ptr_ptr
{
    *data_ptr_ptr_ptr = NULL;
    *nvalues_ptr_ptr = 0;    

    /* The history indices given to this function is in user indices, so we need to translate to C indices. */
    int clean_history_start_idx = [self historyToDisplayIdx:history_start_idx];
    int clean_history_stop_idx = [self historyToDisplayIdx:history_stop_idx];
    if ( clean_history_start_idx == -1 || clean_history_stop_idx == -1)
        return NO;
    int history_count = history_stop_idx-history_start_idx+1;
    if ( history_count < 1 )
        return NO;

    /* Bullet proof to make sure all the histories, when downsampled, have at least one point. */
    for ( int i = clean_history_start_idx; i <= clean_history_stop_idx; i++)
    {
        NSDictionary * plot_data = [historyPlotData objectAtIndex:i]; 
        SCManagedColumn * history_column = [plot_data objectForKey:var_name];
        //double * history_ptr = [history_column getData];
        int sampled_history_length = [history_column getDataLength] / sample_every; /* Purposefully cuts off any remainder. */
        if ( sampled_history_length < 1 )
            return NO;
    }    

    /* Allocate the number of arrays we'll need. */
    *data_ptr_ptr_ptr = (double **)malloc(history_count * sizeof(double *));
    *nvalues_ptr_ptr = (int *)malloc(history_count * sizeof(int));

    /* Now copy the data into each array. */
    int index = 0;
    for ( int i = clean_history_start_idx; i <= clean_history_stop_idx; i++)
    {
        NSDictionary * plot_data = [historyPlotData objectAtIndex:i]; 
        SCManagedColumn * history_column = [plot_data objectForKey:var_name];
        double * history_ptr = [history_column getData];
        int history_length = [history_column getDataLength] / sample_every; /* Purposefully cuts off any remainder. */

        (*nvalues_ptr_ptr)[index] = history_length;
        (*data_ptr_ptr_ptr)[index] = (double *)malloc(history_length * sizeof(double));

        for ( int j = 0; j < history_length; j++ )
        {
            (*data_ptr_ptr_ptr)[index][j] = history_ptr[j*sample_every];
        }
        index++;
    }
    
    return YES;
}




// Attempt to encapsulate all this nitty gritty.
-(BOOL) isViewedHistoryTheCurrentlyUpdatingHistory
{
    int hidx = [self historyToDisplayIdx];
    return ( hidx == [historyPlotData count]-1 );
}


- (void)addOneToSlider:(id)arg
{
    DebugNSLog(@"enableSlider\n");

    //[stateLock lock];

    /* Enable the slider if we've passed one history .*/
    if ( totalPlotCount < 2 ) 
    {
        [slider setMaxValue:1];
        [slider setEnabled:NO];
        [sliderDown setEnabled:NO];
        [sliderUp setEnabled:NO];
    }
    else 
    {
        [slider setEnabled:YES];
        [sliderDown setEnabled:YES];
        [sliderUp setEnabled:YES];
    }
        

    /* Update the maximum and minimum, the latter only if necessary. */
    [slider setMaxValue: totalPlotCount];

    /* If the user is currently watching the updating plot, then we need to add one to the current value of the slider,
     * so that the user can continue to watch the currently updating plot. */
    int was_displaying = int(round([slider doubleValue])); // 1 to totalPlotCount
    if ( was_displaying < 1 )                              // bp
        was_displaying = 1;    
    if ( was_displaying+1 == totalPlotCount ) // just updated, so add one
    {
        [slider setDoubleValue:totalPlotCount];
        [sliderValue setStringValue:[NSString stringWithFormat:@"%i", totalPlotCount]];
    }
    else if ( was_displaying <= totalPlotCount - maxHistoryCount )
    {
        // update the slider value by one so that the last history is followed
        [slider setDoubleValue:totalPlotCount-maxHistoryCount];
        [sliderValue setStringValue:[NSString stringWithFormat:@"%i", totalPlotCount-maxHistoryCount]];
    }

    /* Have to update the minimum after the doubleValue because if the double value is at the minimum and the min is
     * raised then the doublevalue will get pushed up one, too. */
    if (totalPlotCount > maxHistoryCount )
        [slider setMinValue: (totalPlotCount-maxHistoryCount)];


    //[stateLock unlock];
    
    /* Keep this clause after the state lock. */
    if ( doPlot && was_displaying <= totalPlotCount - maxHistoryCount )
        [self updateGraphic:YES];
}


- (void)sliderChanged:(id)arg
{
    //[stateLock lock];
    int currently_displaying_strval = int(round([slider doubleValue])); // what we should display is set by the user slider setting
    NSString * val_str = [NSString stringWithFormat:@"%i", currently_displaying_strval];
    [sliderValue setStringValue:val_str];
    //[stateLock unlock];
    
    [self updateGraphic:YES];
    [drawController redrawNow]; // need this to redraw when slider is moved, without depressing it. 
}


- (void)changeSliderToValue:(int)slider_value
{
    //[stateLock lock];
    int hidx = slider_value;
    if (hidx >= 0 )
        [slider setDoubleValue:double(hidx)];
    //[stateLock unlock];

    [self sliderChanged:nil];
}


- (void)sliderDownOne:(id)arg
{
    //[stateLock lock];
    int currently_displaying = int(round([slider doubleValue])); // what we should display is set by the user slider setting
    if (currently_displaying > 1 )
        [slider setDoubleValue:double(currently_displaying-1)];
    //[stateLock unlock];

    [self sliderChanged:arg];
}


- (void)sliderUpOne:(id)arg
{
    //[stateLock lock];

    int currently_displaying = int(round([slider doubleValue])); // what we should display is set by the user slider setting
    if (currently_displaying < [slider maxValue] )
        [slider setDoubleValue:double(currently_displaying+1)];
    //[stateLock unlock];

    [self sliderChanged:arg];
}


/* Used for the mass PDF save, so far. -DCS:2009/11/04 */
- (void)sliderSetValue:(int)hidx
{
    int currently_displaying = int(round([slider doubleValue])); // what we should display is set by the user slider setting
    DebugNSLog(@"sliderSetValue %lf %d %d\n",[slider doubleValue], currently_displaying, hidx);
    if (hidx <= [slider maxValue])
        [slider setDoubleValue:double(hidx)];

    [self sliderChanged:nil];
}


/* Time to display the plots on the screen.  This involves writing the correct information to the Datagraph binary
 * columns.  There are a couple of cases.  1) The user just scrolled to a history (not the currently updated plot ).
 * Then we need to figure out which history was scrolled to and rewrite the entire plot to the screen.  2) The user
 * scrolled to a completed history in a previous time step, so at this time step we do nothing.  3) The user just
 * scrolled to the currently updated plot.  In this case we also need to completely write the history into the DG and
 * perhaps the most recently updated chunk as well.  4) The user is watching the currently updating plot, in which case
 * we need to write only the new data in an incremental way to the DG columns.  */
- (void)updateGraphic:(BOOL)needs_complete_redraw
{
    //DebugNSLog(@"updateGraphic\n");
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    int hidx = [self historyToDisplayIdx];
    //DebugNSLog(@"hidx: %i\n", hidx);    

    /* Redraw everything to the screen in this case.  */
    if ( needs_complete_redraw ) 
    {
        NSDictionary * plot_data = [historyPlotData objectAtIndex:hidx];
        NSMutableArray * plot_now_commands_by_hidx = [plotNowCommandData objectAtIndex:hidx];
        [self drawCompletePlot:plot_data plotNowCommands:plot_now_commands_by_hidx];
    }
    else if ( hidx == [historyPlotData count]-1 )     /* Here we can use incremental update because the user is currently watching the updating plot. */
    {
        [self drawIncrementalPlot];
    }
    
    [pool release];
}


- (void)addNewPlotFirstTime:(NSNumber *)do_plot_number
{
    DebugNSLog(@"HistoryController addNewPlotFirstTime");
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    int min_column_size = 1024;
    /* Allocate a new history dictionary. */
    NSMutableDictionary *plot_for_history = [historyPlotData objectAtIndex:0];
    for ( NSString * var_name in variableNames )
    {
        SCManagedColumn * history_column;
        SCUserData * user_data = [variableData objectForKey:var_name];
        /* Concatenate the same into the latest history dictionary.  */
        if ( [user_data dataHoldType] == SC_KEEP_DURATION ) // for time columns, we know beforehand how much data, so let's preallocate.
        {
            history_column = [[SCManagedColumn alloc] initColumnWithSize:nPointsToSave];
        }
        else
        {
            history_column = [[SCManagedColumn alloc] initColumnWithSize:min_column_size]; // doesn't matter because we can't predetermine the size, so use default
        }
        
        [plot_for_history setObject:history_column forKey:var_name];
        [history_column release];
    }

    [pool release];
}


/* Adds a new plot by managing the history slider. Doesn't clear the watched columns.  That's a separate function, which
 * used to be tied together.  */
- (void)addNewPlotAfterFirst:(NSNumber *)do_plot_number
{            
    DebugNSLog(@"HistoryController addNewPlot");    

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    /* Let the slider know there is a new history. */
    totalPlotCount++;

    /* Flicker optimization.  Cleared columns should happen here but that leads to flicker, so do right before next
     * draw. */
    doClearWatchedColumnsOnNextDraw = YES;
                  
    if ( !doClearPlotNowCommandsAfterEachDuration )
    {
        [lastPlotNowData release];
        int pnc_count = [plotNowCommandData count] ;
        lastPlotNowData = [[plotNowCommandData objectAtIndex:(pnc_count-1)] retain];
    }

    /* Allocate a new history dictionary. */
    int history_count = [historyPlotData count];
    [historyOfLastPlot release];
    historyOfLastPlot = [[historyPlotData objectAtIndex:(history_count-1)] retain];


    /* Get rid of any old histories, if there is a max. */        
    if ( [historyPlotData count] > maxHistoryCount )
        [historyPlotData removeObjectAtIndex:0];
    
    if ( [plotNowCommandData count] > maxHistoryCount )
        [plotNowCommandData removeObjectAtIndex:0];

    /* If the user doesn't want these cleared, then we should copy last histories plot now command into this histories
     * plot now commands structure.  Then when the user manually clears them, that will automatically transfer over to
     * the next history because the (now previous) history will have only the new plot now qcommands. */
    if ( doClearPlotNowCommandsAfterEachDuration ) 
        [plotNowCommandData addObject:[NSMutableArray array]]; 
    else    
        [plotNowCommandData addObject:[NSMutableArray arrayWithArray:lastPlotNowData]]; 

    NSMutableDictionary *plot_for_history = [NSMutableDictionary dictionary];
    /* Allocate the space for all the variables and their containers, to the degree we can.  Put the containers in the
     * dictionary. */
    /* Used the last history to make educated guesses about the size of the history. */
    for ( NSString * var_name in variableNames )
    {
        SCManagedColumn * history_column;
        SCUserData * user_data = [variableData objectForKey:var_name];
        /* Concatenate the same into the latest history dictionary.  */
        if ( [user_data dataHoldType] == SC_KEEP_DURATION ) // for time columns, we know beforehand how much data, so let's preallocate.
        {
            history_column = [[SCManagedColumn alloc] initColumnWithSize:nPointsToSave];
        }
        else /* We can take a guess based on the last history. */
        {
            SCManagedColumn *column_from_last_history = [historyOfLastPlot objectForKey:var_name]; 
            int last_column_size = [column_from_last_history getDataLength];
            history_column = [[SCManagedColumn alloc] initColumnWithSize:2*last_column_size]; 
        }
        
        [plot_for_history setObject:history_column forKey:var_name];
        [history_column release];
    }    
    [historyPlotData addObject:plot_for_history];

    /* We only remove the command from DG when the user wants them cleared or when the plotting button is off.  */
    [self addOneToSlider:nil];
    //[stateLock lock];

 
    BOOL do_plot = [do_plot_number boolValue]; /* This is used for the make now commands that need to be cleared. */
    if ( !do_plot || (doClearPlotNowCommandsAfterEachDuration && [self isViewedHistoryTheCurrentlyUpdatingHistory] ) )
    {
        [self removePlotNowDGColumnsAndCommands];
    }
    //[stateLock unlock];
    [pool release];
}



-(void) addNewPlot:(NSNumber *)do_plot_number
{
    if ( isFirstPlot )
    {
        [self addNewPlotFirstTime:do_plot_number];
        isFirstPlot = NO;
    }
    else
    {
        [self addNewPlotAfterFirst:do_plot_number];
    }
}
        

/* Add the new data to the current plot history.  Every history controller sees all the variables that were updated by
 * the simulation.  Each history controller only takes and copies the variables that are associated with its plot
 * commands.  That selection happens in this function. */
- (void)updateHistory:(NSDictionary*)latest_plot_chunk
{
    //DebugNSLog(@"HistoryController updateHistory");
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    latestPlotChunk = latest_plot_chunk;
    
    SCManagedColumn *current_history;
    SCColumn *new_plot_data;    /* Could be a SCColumn or SCManagedColumn, the runtime figures it out.  */
    NSMutableDictionary *plot_data_for_history;

    plot_data_for_history = [historyPlotData objectAtIndex:([historyPlotData count]-1)]; // get last plot? -DCS:2009/05/17
    for ( NSString * var_name in variableNames )
    {
        current_history = [plot_data_for_history objectForKey:var_name]; // current_history. haha. 
        new_plot_data = [latest_plot_chunk objectForKey:var_name];
        SCUserData *user_data = [variableData objectForKey:var_name];
        /* Concatenate the same into the latest history dictionary.  */
        switch ( [user_data dataHoldType] )
        {
        case SC_KEEP_DURATION:
        {
            [current_history addData:[new_plot_data getData] nData:[new_plot_data getDataLength]];
        }
        break;
        case SC_KEEP_EVERYTHING_GIVEN:
        {
            [current_history addData:[new_plot_data getData] nData:[new_plot_data getDataLength]];
        }
        break;
        case SC_KEEP_PLOT_POINT:
        case SC_KEEP_REDRAW:
        case SC_KEEP_COLUMN_AT_PLOT_TIME:
        {
            /* By definition these cases have no history between plot updates so we simply wipe out what was there and
             * replace it. */
            [current_history resetCurrentPosition];
            [current_history addData:[new_plot_data getData] nData:[new_plot_data getDataLength]];
        }        
        case SC_KEEP_NONE:
            break;
        default:
            assert ( 0 );
        }
    }

    [pool release];
}


-(void) clearCurrentValuesForVariable:(NSString *)var_name
{
    if ( ![variableNames containsObject:var_name] )
        return;    
    
    NSMutableDictionary * plot_data_for_history = [historyPlotData objectAtIndex:([historyPlotData count]-1)]; // get last plot? -DCS:2009/05/17
    SCManagedColumn * current_history = [plot_data_for_history objectForKey:var_name];
    SCUserData *user_data = [variableData objectForKey:var_name];
    /* Concatenate the same into the latest history dictionary.  */
    switch ( [user_data dataHoldType] )
    {
    case SC_KEEP_EVERYTHING_GIVEN:
    {
        [current_history resetCurrentPosition];
    }
    break;
    default:
        assert ( 0 );
    }    
}


- (void)drawPlot:(NSDictionary *)plot_data_block_and_do_plot
{
    NSDictionary * plot_data_block = [plot_data_block_and_do_plot objectForKey:@"plotBlock"];
    BOOL do_plot  = [[plot_data_block_and_do_plot objectForKey:@"doPlot"] boolValue];

    // DebugNSLog(@"%@\n", [self plotName]);

    /* This is an optimization to avoid flicker.  I used to have clearing columns associated with adding new
     * plots. -DCS:2009/09/16 */
    if ( doClearWatchedColumnsOnNextDraw )
    {
        doClearWatchedColumnsOnNextDraw = NO;
        /* Clear the graphic if we are on the currently drawing graphic only. */
        if ( [self isViewedHistoryTheCurrentlyUpdatingHistory] )
        {
            [super clearWatchedColumnsFromDG:nil];
        }
    }

    /* Add the data to the history. */
    if ( plot_data_block )
        [self updateHistory:plot_data_block];

    if ( !isPlottingHistoryController ) /* Only case is that of the silent history controller. */
        return;
    
    /* Draw the plot if necessary. */
    if ( do_plot && !lastPlotUpdateWasPlotted )
    {
        lastPlotUpdateWasPlotted = YES;
        [self updateGraphic:YES];
    }
    else if ( do_plot && lastPlotUpdateWasPlotted )
    {
        [self updateGraphic:NO];
    }

    /* We need to make a note that the even if the history slider is maximal, there still needs to be a full redraw the
     * next time we plot. */
    if ( do_plot )
        doPlot = YES;
    if ( !do_plot )             
    {
        doPlot = NO;
        lastPlotUpdateWasPlotted = NO;
    }
}


/* External version, which needs to know if we're plotting and will deal with the history. */
- (void) addMakePlotNowCommand:(SCPlotCommand *)plot_command doPlot:(BOOL)do_plot
{
    /* Get the history idx that we're writing to right now. */
    int max_hidx = [historyPlotData count]-1;

    /* Add the plot command data to the current history. */
    NSMutableArray * plot_now_commands_by_hidx = [plotNowCommandData objectAtIndex:max_hidx];
    [plot_now_commands_by_hidx addObject:plot_command];

    /* Now we decide if the we have to draw at this moment or not.  Only if the history slider is at the max. */
    if ( do_plot ) 
    {
        //[stateLock lock];
        
        if ( [self isViewedHistoryTheCurrentlyUpdatingHistory] )
        {
            /* Now actually make the plot by adding the columns, adding the plot command and putting the data into the
             * columns. */
            [super addMakePlotNowCommand:plot_command];

        }
        //[stateLock unlock];
    }
}


/* This function actually clears out the parameters as well as the DGColumns and DGCommands.  This means the command
 * won't ever be reproduced. */
- (void) clearPlotOfMakeNowPlots
{
    /* Get the history idx that we're writing to right now. */
    int max_hidx = [historyPlotData count]-1;
    NSMutableArray * plot_now_commands_by_hidx = [plotNowCommandData objectAtIndex:max_hidx];
    [plot_now_commands_by_hidx removeAllObjects];

    /* Now delete the DGCommands if the history slider is at the max. */
    //[stateLock lock];    
    if ( [self isViewedHistoryTheCurrentlyUpdatingHistory] )
    {
        [self removePlotNowDGColumnsAndCommands];
    }
    //[stateLock unlock];
    
}


-(void) saveHistoryAsTextFiles: (NSOpenPanel *)panel returnCode:(int)return_code  contextInfo:(void  *)context_info
{
    DebugNSLog(@"saveHistoryAsTextFiles");

    if ( return_code ==  NSOKButton )
    {
        
        NSFormCell * start_idx_cell = [saveIndicesView cellAtIndex:0];
        NSFormCell * stop_idx_cell = [saveIndicesView cellAtIndex:1];
        NSFormCell * multiple_files_cell = [saveIndicesView cellAtIndex:2];

        DebugNSLog(@"start: %@", [NSString stringWithFormat:@"%d", [start_idx_cell intValue]]);
        DebugNSLog(@"stop: %@", [NSString stringWithFormat:@"%d", [stop_idx_cell intValue]]);
        

        NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
        /* In plot number reference. */
        int plot_start_idx = [start_idx_cell intValue]; /* The user sees numbers starting at 1, but of course we offset from zero. */
        int plot_stop_idx = [stop_idx_cell intValue];

        int n_from_last_start_idx = totalPlotCount - plot_start_idx;
        int n_from_last_stop_idx = totalPlotCount - plot_stop_idx;        
        int history_count = [historyPlotData count];

        int start_idx = history_count - 1 - n_from_last_start_idx;
        int stop_idx =  history_count - 1 - n_from_last_stop_idx;
        
        /* In history reference. */
        if ( maxHistoryCount == 0 )
        {
            start_idx = 0;
            stop_idx = 0;
        }


        NSString * do_save_to_multiple_files_string = [multiple_files_cell stringValue];
        BOOL do_save_to_multiple_files = YES;
        if ( [do_save_to_multiple_files_string caseInsensitiveCompare:@"no"] == NSOrderedSame )
        {
            do_save_to_multiple_files = NO;
        }

        int i = 0;
        int j = 0;
        NSDictionary * plot_data;
        NSString *directory_name = [panel filename];
        NSString *file_name_part = [plotName stringByReplacingOccurrencesOfString:@" " withString:@"_"];

        /* Get a sorted version of the variable list, which is a set. */
        NSMutableArray * variable_names_array = [[NSMutableArray alloc] init]; /* an array */
        for ( NSString * var_name in variableNames )
        {
            [variable_names_array addObject:var_name];
        }
        NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:nil ascending:YES selector:@selector(localizedCompare:)];
        // Should sorted_variable_names be released afterwards? -DCS:2009/07/21 
        NSArray *sorted_variable_names = [variable_names_array sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];

        if ( do_save_to_multiple_files )
        {
            /* Iterate through all the plots in the history. */
            int plot_iter_idx = plot_start_idx;
            for ( i = start_idx; i <= stop_idx; i++ ) /* inclusive from 18..28 (that's 11), for example.  */
            {
                /* Save with plot_start_idx cause that's what the user see's in the history controller. */
                NSMutableString *complete_file_name = [NSString stringWithFormat:@"%@/%@_%d.txt", directory_name, file_name_part, plot_iter_idx];
                FILE * fp = fopen([complete_file_name UTF8String], "w");
                if ( fp == NULL )
                    assert ( 0 );   // handle this better. -DCS:2009/06/14
                
                plot_data = [historyPlotData objectAtIndex:i];
                
                /* Iterate through all the variables in the plot */
                for ( NSString *var_name in sorted_variable_names )
                {
                    /* The var_name might have white spaces in it, so let's turn those into underscores to make the lives of the
                     * users easier. */
                    NSString *printed_var_name = [var_name stringByReplacingOccurrencesOfString:@" " withString:@"_"];
                    fprintf(fp, "%s\t", [printed_var_name UTF8String]); /* save the name of the variable. */
                    
                    SCManagedColumn *plot_data_for_variable = [plot_data objectForKey:var_name];
                    /* Now we have the variable name, and we have the data.  Now it's time to save. */
                    /* For the time indices selected */
                    double * data = [plot_data_for_variable getData];
                    int length = [plot_data_for_variable getDataLength];
                    for ( j = 0; j < length; j++ )
                    {
                        fprintf(fp, "%1.10e\t", data[j]);
                    }                
                    fprintf(fp, "\n");
                }
                plot_iter_idx++;
                
                //NSBeep();
                fclose(fp);
                fp = NULL;
            }
        }
        else                    /* Save all the data to one file. */
        {
            /* Open the file. */
            NSMutableString *complete_file_name = [NSString stringWithFormat:@"%@/%@_all.txt", directory_name, file_name_part];
            FILE * fp = fopen([complete_file_name UTF8String], "w");
            if ( fp == NULL )
                assert ( 0 );   // handle this better. -DCS:2009/06/14

            /* Iterate through all the variables in the plot */
            for ( NSString *var_name in sorted_variable_names )
            {
                /* The var_name might have white spaces in it, so let's turn those into underscores to make the lives of the
                 * users easier. */
                NSString *printed_var_name = [var_name stringByReplacingOccurrencesOfString:@" " withString:@"_"];
                fprintf(fp, "%s\t", [printed_var_name UTF8String]); /* save the name of the variable. */
                
                for ( i = start_idx; i <= stop_idx; i++ ) /* inclusive from 18..28 (that's 11), for example. */
                {
                    plot_data = [historyPlotData objectAtIndex:i];
                    SCManagedColumn *plot_data_for_variable = [plot_data objectForKey:var_name];
                    double *data = [plot_data_for_variable getData];
                    int length = [plot_data_for_variable getDataLength];
                    /* Now we have the variable name, and we have the data.  Now it's time to save. */
                    /* For the time indices selected */
                    for ( j = 0; j < length; j++ )
                    {
                        fprintf(fp, "%1.10e\t", data[j]);
                    }                
                }

                fprintf(fp, "\n");
            }    
            //NSBeep();
            fclose(fp);
            fp = NULL;
        }
        
        [desc release];
        [variable_names_array release];
        [pool release];
    }
}


- (void) saveHistoryAsPDFs:(NSOpenPanel *)panel returnCode:(int)return_code  contextInfo:(void  *)context_info
{
    DebugNSLog(@"saveHistoryAsPDFs");

    if ( return_code ==  NSOKButton )
    {
        NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
        
        NSFormCell * start_idx_cell = [saveIndicesView cellAtIndex:0];
        NSFormCell * stop_idx_cell = [saveIndicesView cellAtIndex:1];
        
        DebugNSLog(@"start: %@", [NSString stringWithFormat:@"%d", [start_idx_cell intValue]]);
        DebugNSLog(@"stop: %@", [NSString stringWithFormat:@"%d", [stop_idx_cell intValue]]);
    
        /* In plot number reference. */
        int plot_start_idx = [start_idx_cell intValue]; /* The user sees numbers starting at 1, but of course we offset from zero. */
        int plot_stop_idx = [stop_idx_cell intValue];

//         int n_from_last_start_idx = totalPlotCount - plot_start_idx;
//         int n_from_last_stop_idx = totalPlotCount - plot_stop_idx;        
//         int history_count = [historyPlotData count];

//         /* In history reference. */
//         int start_idx = history_count - 1 - n_from_last_start_idx;
//         int stop_idx =  history_count - 1 - n_from_last_stop_idx;
        
        if ( maxHistoryCount > 0 )
        {
            if ( plot_stop_idx > totalPlotCount )
                plot_stop_idx = totalPlotCount;
            if ( plot_start_idx < totalPlotCount - maxHistoryCount)
                plot_start_idx = totalPlotCount - maxHistoryCount;
        }
        
        int i = 0;
        NSString *directory_name = [panel filename];
        NSString *file_name_part = [plotName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        for ( i = plot_start_idx; i <= plot_stop_idx; i++ ) /* i in plot indices, since we are manipulating the slider. */
        {
            if ( maxHistoryCount > 0 )
                [self sliderSetValue:i];
            NSMutableString *complete_file_name = [NSString stringWithFormat:@"%@/%@_%d.pdf", directory_name, file_name_part, i];
            Boolean did_save =  [drawController writePDF:complete_file_name];
            if ( did_save ) 
                DebugNSLog(@"Ok!");
            else
                assert( 0 );      // handle this better. -DCS:2009/06/14
        }

        [pool release];
    }    
}


-(void) saveHistoryAsTextFilesSheet:(id)sender
{
    DebugNSLog(@"saveHistoryAsTextFilesSheet");

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSFormCell * history_start_idx_cell = [saveIndicesView cellAtIndex:0];
    NSFormCell * history_stop_idx_cell = [saveIndicesView cellAtIndex:1];
    NSFormCell * history_multiple_files_cell = [saveIndicesView cellAtIndex:2];

    //iint history_count_minus_one = [historyPlotData count]-1;
    //[history_start_idx_cell setIntValue:(totalPlotCount - history_count_minus_one)];
    //[history_stop_idx_cell setIntValue:totalPlotCount];

    /* Safer to select only the current history. */
    int slider_value = int(floor([slider doubleValue])); /* This is in units of 1..totalPlotCount */
    [history_start_idx_cell setIntValue:slider_value];
    [history_stop_idx_cell setIntValue:slider_value];

    [history_multiple_files_cell setStringValue:@"NO"];
    [history_multiple_files_cell setEnabled:YES];
    if ( [historyPlotData count] < 2 )
    {
        [history_multiple_files_cell setStringValue:@"NO"];
        [history_multiple_files_cell setEnabled:NO];
    }    
    
    [panel setCanChooseDirectories: YES];
    [panel setCanChooseFiles: NO];
    [panel setPrompt: @"Choose Directory"];
    [panel setMessage: @"Choose Directory for Text File Data"];
    [panel setAccessoryView:saveIndicesView];
    [panel _setIncludeNewFolderButton:YES]; // undocumented goodness 
    [panel beginSheetForDirectory: lastDirectory
           file: nil
           types: nil
           modalForWindow: docWindow
           modalDelegate: self
           didEndSelector: @selector(saveHistoryAsTextFiles: returnCode: contextInfo:)
           contextInfo: NULL];

}


- (void) saveHistoryAsPDFsSheet:(id)sender
{
    DebugNSLog(@"saveHistoryAsPDFsSheet");

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSFormCell * history_start_idx_cell = [saveIndicesView cellAtIndex:0];
    NSFormCell * history_stop_idx_cell = [saveIndicesView cellAtIndex:1];
    NSFormCell * history_multiple_files_cell = [saveIndicesView cellAtIndex:2];

    //int history_count_minus_one = [historyPlotData count]-1;
    //[history_start_idx_cell setIntValue:(totalPlotCount - history_count_minus_one)];
    //[history_stop_idx_cell setIntValue:totalPlotCount];

    /* Safer the have the default be the history that the user is looking at. */
    int slider_value = int(floor([slider doubleValue])); /* This is in units of 1..totalPlotCount */
    [history_start_idx_cell setIntValue:slider_value];
    [history_stop_idx_cell setIntValue:slider_value];

    [history_multiple_files_cell setEnabled:NO];
    [panel setCanChooseDirectories: YES];
    [panel setCanChooseFiles: NO];
    [panel setPrompt: @"Choose Directory"];
    [panel setMessage: @"Choose Directory for PDF Data"];
    [panel setAccessoryView:saveIndicesView];
    [panel _setIncludeNewFolderButton:YES]; // undocumented goodness 
    [panel beginSheetForDirectory: lastDirectory
           file: nil
           types: nil
           modalForWindow: docWindow
           modalDelegate: self
           didEndSelector: @selector(saveHistoryAsPDFs: returnCode: contextInfo:)
           contextInfo: NULL];
}



- (void)copyDataBoth:(BOOL)do_matlab_style
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];

    NSMutableString * string_for_pasteboard = [NSMutableString string];
    int hidx = [self historyToDisplayIdx];
    NSDictionary * plot_data = [historyPlotData objectAtIndex:hidx];
    
    for ( NSString * var_name in variableNames )
    {
        /* spaces are treated as seperators in matlab, and so don't work in variable names. */
        NSString * clean_var_name = [var_name stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        SCUserData * var_data = [variableData objectForKey:var_name];
        switch ( [var_data dataType] )
        {
        case SC_TIME_COLUMN:
        case SC_FIXED_SIZE_COLUMN:
        case SC_MANAGED_COLUMN:
        {
            SCManagedColumn * col = [plot_data objectForKey:var_name];

            if ( do_matlab_style )
            {
                [string_for_pasteboard appendString: clean_var_name];
                [string_for_pasteboard appendString: @" = "];
                [string_for_pasteboard appendString: [col matlabStringRepresentation]];
                [string_for_pasteboard appendString: @";\n"];
            }
            else
            {
                [string_for_pasteboard appendString: clean_var_name];
                [string_for_pasteboard appendString: @"    "];
                [string_for_pasteboard appendString: [col stringRepresentation]];
                [string_for_pasteboard appendString: @"\n"];
            }
        }
        break;
        case SC_EXPRESSION_COLUMN:
        case SC_MAKE_NOW_COLUMN:
        case SC_STATIC_COLUMN:
        {
            DGDataColumn * dg_column = [drawController columnWithName:var_name]; // First column with that name
            if ( dg_column != nil )
            {                
                int length = [dg_column numberOfRows];
                double * data = (double*)malloc(length*sizeof(double));
                [dg_column copyNumbersIntoPointer:data length:length]; // len<=numberOfRows.  Underlying numbers.
                SCColumn * col = [[SCColumn alloc] initColumnWithDataCopy:data length:length];

                if ( do_matlab_style )
                {
                    [string_for_pasteboard appendString: clean_var_name];
                    [string_for_pasteboard appendString: @" = "];
                    [string_for_pasteboard appendString: [col matlabStringRepresentation]];
                    [string_for_pasteboard appendString: @";\n"];
                }
                else
                {
                    [string_for_pasteboard appendString: clean_var_name];
                    [string_for_pasteboard appendString: @"    "];
                    [string_for_pasteboard appendString: [col stringRepresentation]];
                    [string_for_pasteboard appendString: @"\n"];
                }
                
                [col release];
                free( data );
                data = NULL;
            }
        }
        break;
        default:
            assert ( 0 );       // case not implemented yet. 
        }
    }

    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
    [pasteBoard setString:string_for_pasteboard forType:NSStringPboardType];
    
    [pool release];
}


-(void) copyData:(id)sender
{
    [self copyDataBoth:NO];
}


-(void) copyDataMatlab:(id)sender
{
    [self copyDataBoth:YES];
}


- (void)dataGraph:(DGController *)controller modifyContextMenu:(NSMenu *)menu
{ 
    DebugNSLog(@"datGraph:controller modifiyContextmenu:menu");
    [menu setDelegate:self];
    if ( [historyPlotData count] > 0 )
    {
        
        NSMenuItem *newItem1 = [[NSMenuItem alloc] initWithTitle:@"Save as Text" action:@selector(saveHistoryAsTextFilesSheet:) keyEquivalent:@""];
        [newItem1 setTarget:self];
        [menu addItem:newItem1];

        NSMenuItem *newItem2 = [[NSMenuItem alloc] initWithTitle:@"Save as PDF" action:@selector(saveHistoryAsPDFsSheet:) keyEquivalent:@""];
        [newItem2 setTarget:self];
        [menu addItem:newItem2]; 

        NSMenuItem * separator = [NSMenuItem separatorItem];
        [menu addItem:separator];


        NSMenuItem *newItem0 = [[NSMenuItem alloc] initWithTitle:@"Copy Data" action:@selector(copyData:) keyEquivalent:@""];
        [newItem0 setTarget:self];
        [menu addItem:newItem0];

        NSMenuItem *newItem01 = [[NSMenuItem alloc] initWithTitle:@"Copy Data (Matlab)" action:@selector(copyDataMatlab:) keyEquivalent:@""];
        [newItem01 setTarget:self];
        [menu addItem:newItem01];


        NSMenuItem * separator0 = [NSMenuItem separatorItem];
        [menu addItem:separator0];


        NSMenuItem * newItem3;
        if ( !loupeIsOn )
            newItem3 = [[NSMenuItem alloc] initWithTitle:@"Add Loupe Tool" action:@selector(setLoupeTool:) keyEquivalent:@""];
        else
            newItem3 = [[NSMenuItem alloc] initWithTitle:@"Remove Loupe Tool" action:@selector(setLoupeTool:) keyEquivalent:@""];
        [newItem3 setTarget:self];
        [menu addItem:newItem3];

        if ( [self isPlottingHistoryController] ) /* Hack because a history controller is both a UI concept and a model.
                                                   * i.e. I shouldn't need to have this peicemeal logic all over the
                                                   * place. YUCK.  -DCS:2010/01/21 */
        {
            NSMenuItem * newItem31;
            int n_x_axis = [additionalXAxisParameters count] + 1;
            int n_y_axis = [additionalYAxisParameters count] + 1;
            if ( n_x_axis + n_y_axis <= 2 )
            {
                if ( magnifyCommands[0][0] == nil )
                    newItem31 = [[NSMenuItem alloc] initWithTitle:@"Add Magnify Tool" action:@selector(setMagnifyTool:) keyEquivalent:@""];
                else
                    newItem31 = [[NSMenuItem alloc] initWithTitle:@"Remove Magnify Tool" action:@selector(setMagnifyTool:) keyEquivalent:@""];
                [newItem31 setTarget:self];
                [menu addItem:newItem31];
            }
            else
            {
                newItem31 = [[NSMenuItem alloc] initWithTitle:@"Magnify Tool" action:@selector(setMagnifyTool:) keyEquivalent:@""];
                [newItem31 setTarget:self];
                [menu addItem:newItem31];
                NSMenu * magnifySubmenu = [[NSMenu alloc] initWithTitle:@"Magnify Submenu"];
                for ( int i = 0; i < n_x_axis; i++ )
                {
                    for ( int j = 0; j < n_y_axis; j++ )
                    {
                        NSMenuItem * menu_item;
                        if ( magnifyCommands[i][j] == nil ) 
                            menu_item  = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Add Magnify Axis (%i,%i)", i, j] action:@selector(setMagnifyTool:) keyEquivalent:@""];
                        else
                            menu_item  = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Remove Magnify Axis (%i,%i)", i, j] action:@selector(setMagnifyTool:) keyEquivalent:@""];
                        [menu_item setTarget:self];
                        [menu_item setRepresentedObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:i],[NSNumber numberWithInt:j], nil]];
                        [magnifySubmenu addItem:menu_item];
                    }
                }
                [menu setSubmenu:magnifySubmenu forItem:newItem31];
            }
        }
        


        NSMenuItem *newItem4;
        if ( legendCommand == nil )
            newItem4 = [[NSMenuItem alloc] initWithTitle:@"Add Legend" action:@selector(addLegend:) keyEquivalent:@""];
        else
            newItem4 = [[NSMenuItem alloc] initWithTitle:@"Remove Legend" action:@selector(addLegend:) keyEquivalent:@""];
        [newItem4 setTarget:self];
        [menu addItem:newItem4];

        // Problems because they can't be deleted and they respect axis boundaries, which means I would have to test to
        // see which axis the user was mousing over. -DCS:2009/10/29
//         NSMenuItem *newItem5 = [[NSMenuItem alloc] initWithTitle:@"Add Label" action:@selector(addLabel:) keyEquivalent:@""];
//         [newItem5 setTarget:self];
//         [menu addItem:newItem5];
        
        [computeLock lock];
    }
}


- (void)menuDidClose:(NSMenu *)menu
{
    DebugNSLog(@"HistoryController: menuDidClose");
    [computeLock unlock];
}


@end
