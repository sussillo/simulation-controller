/* SimModel.m */

// adding plots before the error checking is wrong. Or is it? -DCS:2009/10/26

extern int SC_VARIABLE_LENGTH;

extern NSString * const SCWriteToControllerConsoleNotification; // for sending notes to the controller console
extern NSString * const SCWriteToControllerConsoleAttributedNotification; // for sending colored notes to the controller console
extern NSString * const SCSilentHistoryControllerName;

/* Notifications that SimModel handles. */
NSString * const SCNotifyModelOfButtonChange = @"SCNotifyModelOfButtonChange";
NSString * const SCNotifyModelOfParameterChange = @"SCNotifyModelOfParameterChange";

#import "SimModel.h"
#include "model.h"         /* declarations of model functions such as InitModel and RunModelOneStep. */
#include "SCPlotCommand.h"
#import "DebugLog.h"
#import "SCManagedColumn.h"
#import "SCColorScheme.h"

@implementation SimModel 

#define N_STEPS_IN_FULL_PLOT_INIT 1000
#define N_STEPS_BETWEEN_DRAWING_INIT 1
#define N_STEPS_BETWEEN_PLOTTING_INIT 1

BOOL SCDoDeleteMakeNowPlotsAfterDuration = YES;

- (id)init
{
    if ( self = [super init] )
    {
        SCPrivateSetSimModelPointer((void*)self);
        [self setNStepsInFullPlot:N_STEPS_IN_FULL_PLOT_INIT]; // pick a reasonable value
        [self setNStepsBetweenDrawing:N_STEPS_BETWEEN_DRAWING_INIT];
        [self setNStepsBetweenPlotting:N_STEPS_BETWEEN_PLOTTING_INIT];
        [self setDoRedrawBasedOnTimer:YES];
        [self setDoRunImmediatelyAfterInit:NO];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
            selector:@selector(handleButtonChange:)
            name:SCNotifyModelOfButtonChange
            object:nil];
        [nc addObserver:self
            selector:@selector(handleParameterChange:)
            name:SCNotifyModelOfParameterChange
            object:nil];        
        
        /* Allocate */
        variableNames = [[NSMutableSet alloc] init];
        variableArrayNames = [[NSMutableDictionary alloc] init];
        columnNames = [[NSMutableSet alloc] init];
        staticColumnNames = [[NSMutableSet alloc] init];
        staticColumns = [[NSMutableDictionary alloc] init];
        expressionNames = [[NSMutableSet alloc] init];
        //colorSchemeNames = [[NSMutableSet alloc] init];
        userVariablesByName = [[NSMutableDictionary alloc] init];
        watchedVariablesByName = [[NSMutableDictionary alloc] init];
        //colorSchemesByName = [[NSMutableDictionary alloc] init];
        managedColumnNames = [[NSMutableSet alloc] init];        
        managedColumns = [[NSMutableDictionary alloc] init];
    

        plotNames = [[NSMutableArray alloc] init];
        commandsByPlotName = [[NSMutableDictionary alloc] init];
        clearMakeNowPlotsByPlotName = [[NSMutableDictionary alloc] init];
        colorSchemesByPlotName = [[NSMutableDictionary alloc] init];
        windowParametersByPlotName = [[NSMutableDictionary alloc] init];
        axisParametersByPlotName = [[NSMutableDictionary alloc] initWithCapacity:[plotNames count]];
        simParameterModel = [[SimParameterModel alloc] init];

        plotNamesByWatchedVariableName = [[NSMutableDictionary alloc] init];

        doPlotInParallel = false;
        isPhaseOne = YES;       // initialition phase
        isPhaseTwo = NO;        // run phase

        nStepsStored = 64;       // Start with a largish guess.  used in runModelAmountOfTime:currentIteration; 
    }
    return self;
}


- (void)dealloc
{
    [variableNames release];
    [variableArrayNames release];
    [columnNames release];
    [staticColumnNames release];
    [staticColumns release];
    [expressionNames release];
    //[colorSchemeNames release];

    [userVariablesByName release];
    [watchedVariablesByName release];
    //[colorSchemesByName release];
    
    [plotNames release];
    [commandsByPlotName release];
    [colorSchemesByPlotName release];
    [windowParametersByPlotName release];
    [clearMakeNowPlotsByPlotName release];
    [axisParametersByPlotName release];
    [simParameterModel release];
    [managedColumns release];
    [managedColumnNames release];
    [plotNamesByWatchedVariableName release];

    [super dealloc];
}


@synthesize doPlotInParallel;
@synthesize computeLock;
@synthesize plotNames;
@synthesize variableNames;
@synthesize simParameterModel;
@synthesize nStepsInFullPlot;
@synthesize nStepsBetweenDrawing;
@synthesize doRedrawBasedOnTimer;
@synthesize nStepsBetweenPlotting; 
@synthesize windowParametersByPlotName;
@synthesize doRunImmediatelyAfterInit;
@synthesize doOpenInDemoMode;
@synthesize simController;


/* Should be run on separate thread so as not to hang the UI. */
/* Should happen for the run button also. */
- (void)handleButtonChangeInternal:(NSNotification*)note
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    [computeLock lock];
    NSString *button_name = [[note userInfo] objectForKey:@"buttonName"];
    BOOL button_value = NO;
    NSValue *wrapped_value = [[note userInfo] objectForKey:@"buttonValue"];
    [wrapped_value getValue:&button_value];
#ifndef _NO_USER_LIBRARY_       //This definition may be declared as -D_NO_USER_LIBRARY_=1 in other C flags, build information of Xcode. -SHH@7/15/09
    _ButtonAction([button_name UTF8String], button_value, modelData);
#else
    ButtonAction([button_name UTF8String], button_value, modelData);
#endif

    [computeLock unlock];
    
    [pool release];
}


/* Based on the notification, call the ButtonAction function of the model. */
- (void)handleButtonChange:(NSNotification*)note
{
    /* Need to detach a new thread so the GUI doesn't hang. */
    [NSThread detachNewThreadSelector:@selector(handleButtonChangeInternal:) toTarget:self withObject:note];
}


/* Should be run on separate thread so as not to hang the UI. */
-(void)handleParameterChangeInternal:(NSNotification*)note
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    [computeLock lock];
    NSString *parameter_name = [[note userInfo] objectForKey:@"parameterName"];
    double parameter_value = 0.0;
    NSValue *wrapped_value = [[note userInfo] objectForKey:@"parameterValue"];
    [wrapped_value getValue:&parameter_value];
#ifndef _NO_USER_LIBRARY_
    _ParameterAction([parameter_name UTF8String], parameter_value, modelData);
#else
    ParameterAction([parameter_name UTF8String], parameter_value, modelData);
#endif
    [computeLock unlock];

    [pool release];
}


/* Based on the notification, call the ParameterAction function of the model. */
- (void)handleParameterChange:(NSNotification*)note
{
    [NSThread detachNewThreadSelector:@selector(handleParameterChangeInternal:) toTarget:self withObject:note];
}


- (NSArray *)commandsByPlotName:(NSString *)plot_name
{
    assert ( commandsByPlotName != nil );
    assert ( plot_name != nil );

    return [commandsByPlotName objectForKey:plot_name]; // caller's responsibility to retain
}


- (DefaultAxisParameters *)axisParametersByPlotName:(NSString *)plot_name
{
    assert ( axisParametersByPlotName != nil );
    assert ( plot_name != nil );
    
    return [axisParametersByPlotName objectForKey:plot_name]; // caller's responsibility to retain
}

-(NSDictionary *)colorSchemesByPlotName:(NSString *)plot_name
{
    assert ( colorSchemesByPlotName != nil );
    assert ( plot_name != nil );
    
    return [colorSchemesByPlotName objectForKey:plot_name];
}



- (BOOL) getDoClearMakeNowPlotsByName:(NSString *)plot_name
{
    assert ( plot_name != nil );
    return [[clearMakeNowPlotsByPlotName objectForKey:plot_name] boolValue];
}


-(BOOL)assertPhaseOne:(NSString *)fun_name
{
    if (!isPhaseOne )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Function %@ can only be called during SC initialization.  SC initialization includes the functions:\n AddControllableParameter\n AddControllableButton\n AddPlotsAndRegisterWatchedVariables\n InitModel\n SetPlotParameters\n and AddWindowDataForPlots.\n", fun_name]];
        return NO;
    }
    return YES;
}


-(BOOL)assertPhaseTwo:(NSString *)fun_name
{
    if (!isPhaseTwo )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Function %@ can only be called during SC simulation.  SC simulation includes the functions:\n InitForRun\n InitForPlotDuration\n RunModelOneStep\n CleanupAfterPlotDuration\n and CleanupAfterRun.\n", fun_name]];
        return NO;
    }
    return YES;
}


-(void) setPlotName:(NSString *)plot_name forVariables:(NSArray *)var_names
{
    for ( NSString * var_name in var_names )
    {
        if ( [var_name length] == 0 )
            continue;
        
        NSMutableSet * plot_names = [plotNamesByWatchedVariableName objectForKey:var_name];
        if ( plot_names == nil )
            plot_names = [NSMutableSet set];
        [plot_names addObject:plot_name];
        [plotNamesByWatchedVariableName setObject:plot_names forKey:var_name];
    }    
}



-(void)addControllableParameter:(NSString*)param_name minValue:(double)min_value maxValue:(double)max_value initValue:(double)init_value
{
    if ( ![self assertPhaseOne:@"SCAddControllableParameter"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Parameter %@ not added.\n", param_name]];
        return;
    }
              
    DebugNSLog(@"SimModel addControllableParameter");
    SimParameter * sim_parameter = [[SimParameter alloc] init];
    [sim_parameter setName:param_name];
    [sim_parameter setMinValue:min_value];
    [sim_parameter setMaxValue:max_value];
    [sim_parameter initValue:init_value];
    [sim_parameter setDefaultValue:init_value];
    [simParameterModel addParameter:sim_parameter];
    [sim_parameter release];
}

-(void)addControllableButton:(NSString*)button_name initValue:(BOOL)init_value offLabel:(NSString*)off_label onLabel:(NSString *)on_label
{
    if ( ![self assertPhaseOne:@"SCAddControllableButton"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Button %@ not added.\n", button_name]];
        return;
    }

    DebugNSLog(@"SimModel addControllableButton");
    SimButton * sim_button = [[SimButton alloc] init];
    [sim_button setName:button_name];
    [sim_button initValue:init_value];
    [sim_button setDefaultValue:init_value];
    [sim_button setOnLabel:on_label];
    [sim_button setOffLabel:off_label];
    [simParameterModel addButton:sim_button];
    [sim_button release];
}


-(void) addStaticColumn:(NSString *)col_name dataPtr:(double *)data_ptr length:(int)length
{
    if ( ![self assertPhaseOne:@"SCAddStaticColumn"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Static column %@ not added.\n", col_name]];
        return;
    }
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    BOOL was_error = NO;
    if ( [staticColumnNames containsObject:col_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Static column %@ already exists.  Not adding again. \n", col_name]];
        was_error = YES;
    }
    if ( was_error )
    {
        [pool release];
        return;
    }

    DebugNSLog(@"SimModel: Registering static column: %@", col_name);
    [staticColumnNames addObject:col_name];
    [columnNames addObject:col_name];

    SCColumn * sc_column = [[SCColumn alloc] initColumnWithDataCopy:data_ptr length:length];
    [staticColumns setObject:sc_column forKey:col_name];

    NSValue * object_pointer_val;
    object_pointer_val = [NSValue valueWithPointer:sc_column];

    SCUserData * user_data = [[SCUserData alloc] init];
    [user_data setDataName:col_name];
    [user_data setDataType:SC_STATIC_COLUMN];
    [user_data setDataHoldType:SC_KEEP_NONE]; /* no need to get data, since it's not watched.  */
    [user_data setDataPtr:object_pointer_val];
    [user_data setDim1:SC_VARIABLE_LENGTH];
    [user_data setDim1:length];
    
    [userVariablesByName setObject:user_data forKey:col_name];
    [user_data release];
    
    [pool release];
}


-(void) addWatchedVariable:(NSString *)var_name dataPtr:(double *)data_ptr dataHoldType:(SCDataHoldType)data_hold_type
{
    if ( ![self assertPhaseOne:@"SCAddWatchedVariable"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Variable %@ not added.\n", var_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL was_error = NO;
    if ( [variableNames containsObject:var_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ already exists.  Not adding again. \n", var_name]];
        was_error = YES;
    }
    if ( was_error )
    {
        [pool release];
        return;
    }

    NSValue * double_pointer_val;
    double_pointer_val = [NSValue valueWithPointer:data_ptr];
    // Don't want to have the zeros, except on variable arrays. -DCS:2009/06/28
    //var_name = [NSString stringWithFormat:@"%@0", var_name];               // autoreleased
    DebugNSLog(@"SimModel: Registering variable: %@", var_name);
    [variableNames addObject:var_name];

    SCUserData * user_data = [[SCUserData alloc] init];
    [user_data setDataName:var_name];
    [user_data setDataType:SC_TIME_COLUMN];
    [user_data setDataHoldType:data_hold_type];
    [user_data setDataPtr:double_pointer_val];
    [user_data setDim1:1];
    
    [userVariablesByName setObject:user_data forKey:var_name]; // will overwrite if duplicate value.

    [user_data release];
    
    [pool release];    
}


/* The watchedData is an array of double pointers, each one pointing to the relevant data.  Each element in the data
 * pointer is treated as a conceptually different variable.  E.g.  the firing rates of neurons are often kept in the
 * same double array, but they are often printed as line plots, where each neuron is plotted against time, therefore,
 * the variables are conceptually different.  But writing down the pointers to the data isn't helpful at all without
 * being able to associate a name to the data.  Otherwise, how will we know what to print?  So we require a name from
 * the simulation writer whenever he asks for a variable to be watched. */
-(void)addWatchedVariableArray:(NSString *)var_array_name dataPtr:(double *)data_ptr  length:(int)length dataHoldType:(SCDataHoldType)data_hold_type
{
    if ( ![self assertPhaseOne:@"SCAddWatchedVariableArray"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Variable array %@ not added.\n", var_array_name]];
        return;
    }
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    int i = 0;
    NSValue * double_pointer_val;

    BOOL was_error = NO;
    if ( [variableArrayNames objectForKey:var_array_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable array %@ already exists.  Not adding again. \n", var_array_name]];
        was_error = YES;
    }
    if ( was_error )
    {
        [pool release];
        return;
    }

    /* Keep track of the variable arrays because the names are different and sometimes the user may refert to the entire
     * array. */
    [variableArrayNames setObject:[NSNumber numberWithInt:length] forKey:var_array_name]; 

    for ( i = 0; i < length; i++ )
    {
        double_pointer_val = [NSValue valueWithPointer:(&data_ptr[i])];
        NSString * var_name = [NSString stringWithFormat:@"%@%i", var_array_name, i]; // autoreleased, start names with 0 index.
        DebugNSLog(@"SimModel: Registering variable: %@", var_name);
        [variableNames addObject:var_name];                                         // does this matter that I'm adding at end? -DCS:2009/05/19

        SCUserData * user_data = [[SCUserData alloc] init];
        [user_data setDataName:var_name];
        [user_data setDataType:SC_TIME_COLUMN];
        [user_data setDataHoldType:data_hold_type];
        [user_data setDataPtr:double_pointer_val];
        [user_data setDim1:1];

        [userVariablesByName setObject:user_data forKey:var_name];            
        [user_data release];
    }

    [pool release];
}


-(void)addWatchedColumnVariable:(NSString*)var_name dataPtr:(double *)data_ptr length:(int)length
{
    if ( ![self assertPhaseOne:@"SCAddWatchedColumnVariable"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Column variable array %@ not added.\n", var_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL was_error = NO;
    if ( [variableNames containsObject:var_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ already exists.  Not adding again. \n", var_name]];
        was_error = YES;
    }
    if ( was_error )
    {
        [pool release];
        return;
    }
    
    NSValue * double_pointer_val;
    double_pointer_val = [NSValue valueWithPointer:data_ptr];
    // Don't want to have the zeros except on variable arrays. -DCS:2009/06/28
    //var_name = [NSString stringWithFormat:@"%@0", var_name];               // autoreleased
    DebugNSLog(@"SimModel: Registering variable: %@", var_name);
    [variableNames addObject:var_name];
    [columnNames addObject:var_name];

    SCUserData * user_data = [[SCUserData alloc] init];
    [user_data setDataName:var_name];
    [user_data setDataType:SC_FIXED_SIZE_COLUMN];
    [user_data setDataHoldType:SC_KEEP_COLUMN_AT_PLOT_TIME];  // was SC_KEEP_PLOT_POINT
    [user_data setDataPtr:double_pointer_val];
    [user_data setDim1:length];
    
    [userVariablesByName setObject:user_data forKey:var_name]; // will overwrite if duplicate value.

    [user_data release];
    
    [pool release];    
}


-(void)addManagedColumnVariable:(NSString*)var_name doClearAfterPlotDuration:(BOOL)do_clear_after_plot_duration sizeHint:(int)size_hint
{
    if ( ![self assertPhaseOne:@"SCAddManagedColumnVariable"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Managed column variable %@ not added.\n", var_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL was_error = NO;
    if ( [variableNames containsObject:var_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ already exists.  Not adding again. \n", var_name]];
        was_error = YES;
    }
    if ( was_error )
    {
        [pool release];
        return;
    }    

    [variableNames addObject:var_name];
    [columnNames addObject:var_name];
    [managedColumnNames addObject:var_name];
    
    SCManagedPlotColumn * managed_column;
    if ( size_hint > [SCManagedPlotColumn defaultLength] )
        managed_column = [[SCManagedPlotColumn alloc] initColumnWithSize:size_hint];
    else
        managed_column = [[SCManagedPlotColumn alloc] init];
    [managed_column setDoClearAfterPlotDuration:do_clear_after_plot_duration];

    [managedColumns setObject:managed_column forKey:var_name];
    NSValue * object_pointer_val;
    object_pointer_val = [NSValue valueWithPointer:managed_column];

    SCUserData * user_data = [[SCUserData alloc] init];
    [user_data setDataName:var_name];
    [user_data setDataType:SC_MANAGED_COLUMN];
    [user_data setDataHoldType:SC_KEEP_EVERYTHING_GIVEN]; 
    [user_data setDataPtr:object_pointer_val];
    [user_data setDim1:SC_VARIABLE_LENGTH];
    
    [userVariablesByName setObject:user_data forKey:var_name]; // will overwrite if duplicate value.

    [managed_column release];
    [user_data release];

    [pool release];
}


-(void)addManagedColumnVariables:(NSString*)var_name_prefix nColumns:(int)ncolumns doClearAfterPlotDuration:(BOOL)do_clear_after_plot_duration sizeHint:(int)size_hint
{
    if ( ![self assertPhaseOne:@"SCAddManagedColumnVariables"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Managed column variables %@ not added.\n", var_name_prefix]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    for ( int i = 0; i < ncolumns; i++ )
    {
        [self addManagedColumnVariable:[NSString stringWithFormat:@"%@%i",var_name_prefix, i] doClearAfterPlotDuration:do_clear_after_plot_duration sizeHint:size_hint];
    }
    
    [pool release];
}


-(void)addDataToManagedColumn:(NSString *)var_name newData:(double*)new_data length:(int)length
{
    if ( ![self assertPhaseTwo:@"SCAddDataToManagedColumn"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Data not added to %@.\n", var_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    SCManagedPlotColumn * managed_column = [managedColumns objectForKey:var_name];
    if ( managed_column == nil )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Managed column %@ doesn't exists.  Can't add data. \n", var_name]];
        [pool release];
        return;
    }
    
    [managed_column addData:new_data nData:(int)length];
    [pool release];
}


-(void) copyDataFromManagedColumn:(NSString *)var_name 
                       dataPtrPtr:(double **)data_ptr_ptr 
                       nValuesPtr:(int *)nvalues_ptr
{
    if ( ![self assertPhaseTwo:@"SCCopyDataFromManagedColumn"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Data not copied from %@.\n", var_name]];
        return;
    }
    
    SCManagedPlotColumn * managed_column = [managedColumns objectForKey:var_name];
    if ( managed_column == nil )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Managed column %@ doesn't exists.  Can't copy data. \n", var_name]];
        return;
    }
    
    *nvalues_ptr  = [managed_column getDataLength]; 
    double *data_ptr = [managed_column getData];

    *data_ptr_ptr = (double *)malloc(*nvalues_ptr * sizeof(double));
    for ( int i = 0; i < *nvalues_ptr; i++ )
        (*data_ptr_ptr)[i] = data_ptr[i];
}


/* In this case we have to go to the HistoryController to satisfy the request for the information. */
-(void) copyDataFromHistoryWithIndex:(NSString *)var_name 
                          historyIdx:(int)history_idx 
                         sampleEvery:(int)sample_every
                          dataPtrPtr:(double **)data_ptr_ptr 
                          nValuesPtr:(int *)nvalues_ptr
{
    if ( ![self assertPhaseTwo:@"SCCopyDataFromHistoryWithIndex"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Data not copied from %@.\n", var_name]];
        return;
    }
    
    NSSet * plot_names = [plotNamesByWatchedVariableName objectForKey:var_name];
    if ( plot_names == nil || [plot_names count] == 0 ) // should have a short circuit, right? -DCS:2010/01/20
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: SCCopyDataFromHistoryWithIndex: Can't find a plot that uses variable: %@.  Not copying data.\n", var_name]];
        return;
    }
    
    NSString * plot_name = [plot_names anyObject];
    
    int safe_sample_every = sample_every;
    if ( safe_sample_every < 1 )
    {
        safe_sample_every = 1;
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Warning: SCCopyDataFromHistoryWithIndex: The downsample parameter was %i.  Setting to 1 and continuing.\n", sample_every]];
    }
    
    
    /* Now that we have a plot where the data is being stored, we can query that specific HistoryController for the
     * data. */
    [simController copyDataFromPlot: plot_name
                   forVariable: var_name 
                   historyIdx: history_idx
                   sampleEvery: safe_sample_every
                   dataPtrPtr: data_ptr_ptr
                   nValuesPtr: nvalues_ptr];
    
}


-(void) copyFlatDataFromHistories:(NSString *)var_name 
                  historyStartIdx:(int)history_start_idx 
                   historyStopIdx:(int)history_stop_idx
                      sampleEvery:(int)sample_every
                      dataPtrPtr:(double **)data_ptr_ptr 
                      nValuesPtr:(int *)nvalues_ptr
{
    if ( ![self assertPhaseTwo:@"SCCopyFlatDataFromHistories"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Data not copied from %@.\n", var_name]];
        return;
    }
    
    NSSet * plot_names = [plotNamesByWatchedVariableName objectForKey:var_name];
    if ( plot_names == nil || [plot_names count] == 0 ) // should have a short circuit, right? -DCS:2010/01/20
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: SCCopyFlatDataFromHistories: Can't find a plot that uses variable: %@.  Not copying data.\n", var_name]];
        return;
    }
    
    NSString * plot_name = [plot_names anyObject];

    int safe_sample_every = sample_every;
    if ( safe_sample_every < 1 )
    {
        safe_sample_every = 1;
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Warning: SCCopyFlatDataFromHistories: The downsample parameter was %i.  Setting to 1 and continuing.\n", sample_every]];
    }
    
    
    /* Now that we have a plot where the data is being stored, we can query that specific HistoryController for the
     * data. */
    [simController copyFlatDataFromPlot: plot_name
                   forVariable: var_name
                   historyStartIdx: history_start_idx 
                   historyStopIdx: history_stop_idx
                   sampleEvery: safe_sample_every
                   dataPtrPtr: data_ptr_ptr
                   nValuesPtr: nvalues_ptr];    
}


-(void) copyFlatDataFromHistoriesForColumns:(NSString *)var_name_prefix_ns 
                                varStartIdx:(int)var_start_idx
                                 varStopIdx:(int)var_stop_idx
                            historyStartIdx:(int)history_start_idx
                             historyStopIdx:(int)history_stop_idx 
                                sampleEvery:(int)sample_every
                              dataPtrPtrPtr:(double ***)data_ptr_ptr_ptr 
                              nValuesPtrPtr:(int **)nvalues_ptr_ptr
{
    /* BP */
    *data_ptr_ptr_ptr = NULL;
    *nvalues_ptr_ptr = 0;
    
    if ( ![self assertPhaseTwo:@"SCCopyFlatDataFromHistoriesForColumns"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Data not copied from variables with prefix %@.\n", var_name_prefix_ns]];
        return;
    }
    
    if ( (var_stop_idx < var_start_idx) || (var_start_idx < 0) || (var_stop_idx < 0 ) || ([var_name_prefix_ns length] == 0) )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: SCCopyFlatDataFromHistoriesForColumns: Data not copied from variables with prefix \"%@\" and variable indices [%i, %i].\n", var_name_prefix_ns, var_start_idx, var_stop_idx]];
        return;
    }

    /* Have to do some BP on the history indices here since we do some allocation at this higher level. */
    if ( (history_stop_idx < history_start_idx) || (history_start_idx < 1) || (history_stop_idx < 1) )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: SCCopyFlatDataFromHistoriesForColumns: Data not copied from variables with prefix \"%@\" and history indices [%i, %i].\n", var_name_prefix_ns, history_start_idx, history_stop_idx]];
        return;
    }
    
    /* Make sure all the variables have histories to which they have been saved. */
    for (int i = var_start_idx; i <= var_stop_idx; i++ )
    {
        NSString * var_name = [NSString stringWithFormat:@"%@%i", var_name_prefix_ns, i];
        NSSet * plot_names = [plotNamesByWatchedVariableName objectForKey:var_name];
        if ( plot_names == nil || [plot_names count] == 0 ) // should have a short circuit, right? -DCS:2010/01/20
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: SCCopyStructuredDataFromHistories: Can't find a plot that uses variable: %@.  Not copying data.\n", var_name]];
            return;
        }
    }

    int safe_sample_every = sample_every;
    if ( safe_sample_every < 1 )
    {
        safe_sample_every = 1;
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Warning: SCCopyStructuredDataFromHistories: The downsample parameter was %i.  Setting to 1 and continuing.\n", sample_every]];
    }
    

    int nvariables = var_stop_idx - var_start_idx + 1;
    
    /* Allocate the number of arrays we'll need. */
    *data_ptr_ptr_ptr = (double **)malloc(nvariables * sizeof(double *));
    *nvalues_ptr_ptr = (int *)malloc(nvariables * sizeof(int));
    
    for (int i = var_start_idx; i <= var_stop_idx; i++ )
    {
        NSString * var_name = [NSString stringWithFormat:@"%@%i", var_name_prefix_ns, i];
        NSSet * plot_names = [plotNamesByWatchedVariableName objectForKey:var_name];
        NSString * plot_name = [plot_names anyObject];
        
        //double * data_ptr = (*data_ptr_ptr_ptr)[i];
        //int nvalues = (*nvalues_ptr_ptr)[i];

        [simController copyFlatDataFromPlot: plot_name
                       forVariable: var_name
                       historyStartIdx: history_start_idx 
                       historyStopIdx: history_stop_idx
                       sampleEvery: safe_sample_every
                       dataPtrPtr: &(*data_ptr_ptr_ptr)[i]
                       nValuesPtr: &(*nvalues_ptr_ptr)[i] ];
    }
}


-(void) copyStructuredDataFromHistories:(NSString *)var_name 
                        historyStartIdx:(int)history_start_idx 
                         historyStopIdx:(int)history_stop_idx
                            sampleEvery:(int)sample_every
                             dataPtrPtrPtr:(double ***)data_ptr_ptr_ptr 
                             nValuesPtrPtr:(int **)nvalues_ptr_ptr
{
    if ( ![self assertPhaseTwo:@"SCCopyStructuredDataFromHistories"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Data not copied from %@.\n", var_name]];
        return;
    }
    
    NSSet * plot_names = [plotNamesByWatchedVariableName objectForKey:var_name];
    if ( plot_names == nil || [plot_names count] == 0 ) // should have a short circuit, right? -DCS:2010/01/20
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: SCCopyStructuredDataFromHistories: Can't find a plot that uses variable: %@.  Not copying data.\n", var_name]];
        return;
    }
    
    NSString * plot_name = [plot_names anyObject];

    int safe_sample_every = sample_every;
    if ( safe_sample_every < 1 )
        safe_sample_every = 1;
    
    /* Now that we have a plot where the data is being stored, we can query that specific HistoryController for the
     * data. */
    [simController copyStructuredDataFromPlot: plot_name
                   forVariable: var_name 
                   historyStartIdx: history_start_idx 
                   historyStopIdx: history_stop_idx
                   sampleEvery: safe_sample_every
                   dataPtrPtrPtr: data_ptr_ptr_ptr
                   nValuesPtrPtr: nvalues_ptr_ptr];    
}



 /* Called from user side. */
-(void)clearDataInManagedColumn:(NSString *)var_name
{
    if ( ![self assertPhaseTwo:@"SCClearManagedColumn"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Data not cleared in %@.\n", var_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    SCManagedPlotColumn * managed_column = [managedColumns objectForKey:var_name];
    if ( managed_column )
    {
        /* This will handle the plotting because the SCManagedPlotColumn is smart. */
        [managed_column resetCurrentPosition]; 
        /* But we still need to manually clear out the history. */
        [[self simController] clearAllPlotHistoriesOfVariable:var_name];
    }
    else
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Managed variable %@ doesn't exist.  Not clearing column. \n", var_name]];
    }
    [pool release];
}

/* Called from user side. */
-(void) clearDataInManagedColumnsWithVarNamePrefix:(NSString *)var_name_prefix nColumns:(int)ncolumns
{
    if ( ![self assertPhaseTwo:@"SCClearManagedColumns"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Data not cleared.\n"]];
        return;
    }
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    for ( int i = 0; i < ncolumns; i++ )
    {
        [self clearDataInManagedColumn:[NSString stringWithFormat:@"%@%i", var_name_prefix, i]];
    }

    [pool release];
}



/* Sent from SimController. */
-(void)clearDataInManagedColumns:(BOOL)is_end_of_plot_duration
{
    if ( ![self assertPhaseTwo:@"SCClearManagedColumnVariables"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Data not cleared.\n"]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    for ( NSString * var_name in managedColumns )
    {
        SCManagedPlotColumn * managed_column = [managedColumns objectForKey:var_name];
        if ( is_end_of_plot_duration  )
            [managed_column resetCurrentPositionAfterPlot]; // could zero if we wanted to. -DCS:2009/08/27
        else
            [managed_column resetCurrentPosition];
    }
    [pool release];
}


-(void)addExpressionVariable:(NSString *)var_name expression:(NSString *)expression
{
    if ( ![self assertPhaseOne:@"SCAddExpressionVariable"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Expression variable %@ not added.", var_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL was_error = NO;
    if ( [variableNames containsObject:var_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Expression variable %@ already exists.  Not adding again. \n", var_name]];
        was_error = YES;
    }
    if ( was_error )
    {
        [pool release];
        return;
    }

    DebugNSLog(@"SimModel: Registering variable: %@", var_name);
    [variableNames addObject:var_name];
    [expressionNames addObject:var_name];

    SCUserData * user_data = [[SCUserData alloc] init];
    [user_data setDataName:var_name];
    [user_data setDataType:SC_EXPRESSION_COLUMN];
    [user_data setDataHoldType:SC_KEEP_NONE];
    [user_data setExpression:expression];
    [user_data setDim1:1];
    
    [userVariablesByName setObject:user_data forKey:var_name]; // will overwrite if duplicate value.

    [user_data release];
    
    [pool release];
}



- (void)drawMakeNowCommand:(SCPlotCommand *)make_now_command
{
    [computeLock unlock];
    [[self simController] drawMakeNowCommand:make_now_command];    
    [computeLock lock];
}



- (void)makeLinePlotNow:(NSString *)plot_name xName:(NSString *)x_var_name yName:(NSString *)y_var_name xData:(double *)x_data yData:(double *)y_data dataLength:(int)data_length linePlotParameters:(SCPlotParameters*)line_plot_parameters orderIndex:(int)order
{
    if ( ![self assertPhaseTwo:@"SCMakePlotNow"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Plot command with variables %@ and %@ not created.\n", x_var_name, y_var_name]];
        return;
    }
    
    if ( ![plotNames containsObject:plot_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Plot %@ doesn't exist.  The plot needs to exist when SCMakePlotNow is called.\n  Plot command not created.\n", plot_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    /* It is necessary to copy this data because we keep a history of everything. */
    NSData * data_for_x = [NSData dataWithBytes:(const void *)x_data length:(sizeof(double)*data_length)];
    NSData * data_for_y = [NSData dataWithBytes:(const void *)y_data length:(sizeof(double)*data_length)];

    SCUserData * x_user_data = [[SCUserData alloc] init]; // where does this ever get cleared correctly?  Does it matter cuz of history?
    [x_user_data setDataName:x_var_name];
    [x_user_data setDataType:SC_MAKE_NOW_COLUMN];
    [x_user_data setDataHoldType:SC_KEEP_NONE]; 
    [x_user_data setDataPtr:nil];
    [x_user_data setMakePlotNowData:data_for_x];
    [x_user_data setDim1:data_length];

    SCUserData * y_user_data = [[SCUserData alloc] init]; // where does this ever get cleared correctly?  Does it matter cuz of history?
    [y_user_data setDataName:y_var_name];
    [y_user_data setDataType:SC_MAKE_NOW_COLUMN];
    [y_user_data setDataHoldType:SC_KEEP_NONE]; 
    [y_user_data setDataPtr:nil]; 
    [y_user_data setMakePlotNowData:data_for_y];
    [y_user_data setDim1:data_length];

    SCLineCommand * make_line_now_command = [[SCLineCommand alloc] init];
    [make_line_now_command setPlotName:plot_name];
    [make_line_now_command setXName:x_var_name];
    [make_line_now_command setYName:y_var_name];
    [make_line_now_command setXVariable:x_user_data];
    [make_line_now_command setYVariable:y_user_data];
    [make_line_now_command setOrder:order];
    SCPlotCommandParameters * lcp = [SCPlotCommandParameters copyFromCStruct:line_plot_parameters];
    [make_line_now_command setCommandParameters:lcp];
    [lcp release];
    [x_user_data release];
    [y_user_data release];


    [self drawMakeNowCommand:make_line_now_command];

    [pool release];
}


-(void) makeLinePlotNowFMC:(NSString *)plot_name
                     xName:(NSString *)x_var_name
                     yName:(NSString *)y_var_name
                  xMCName:(NSString *)x_mc_name
                  yMCName:(NSString *)y_mc_name
        linePlotParameters:(SCPlotParameters *)line_plot_parameters
                orderIndex:(int)order;
{
    if ( ![self assertPhaseTwo:@"SCMakePlotNowFMC"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Plot command with variables %@ and %@ not created.\n", x_var_name, y_var_name]];
        return;
    }
    
    BOOL was_error = NO;
    if ( ![managedColumnNames containsObject:x_mc_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"Variable %@ is not a managed column.  The makeLinePlotNowFMC command wasn't not created.\n", x_mc_name]];
        was_error = YES;
    }
    if ( ![managedColumnNames containsObject:y_mc_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"Variable %@ is not a managed column.  The makeLinePlotNowFMC command wasn't not created.\n", y_mc_name]];
        was_error = YES;
    }

    if ( was_error )
    {
        return;
    }
    
    SCManagedPlotColumn * x_mpc = [managedColumns objectForKey:x_mc_name];
    double * x_data = [x_mpc getData];
    int x_data_length = [x_mpc getDataLength];
    
    SCManagedPlotColumn * y_mpc = [managedColumns objectForKey:y_mc_name];
    double * y_data = [y_mpc getData];
    int y_data_length = [y_mpc getDataLength];

    int data_length = 0;
    if ( x_data_length <= y_data_length )
        data_length = x_data_length;
    else
        data_length = y_data_length;

    [self makeLinePlotNow:plot_name xName:x_var_name yName:y_var_name xData:x_data yData:y_data dataLength:data_length linePlotParameters:line_plot_parameters orderIndex:order];
    
}



- (void)makeBarPlotNow:(NSString *)plot_name name:(NSString *)var_name data:(double *)data dataLength:(int)data_length barPlotParameters:(SCBarPlotParameters*)bar_plot_parameters orderIndex:(int)order
{
    if ( ![self assertPhaseTwo:@"SCMakeBarNow"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Bar command with variables %@.\n", var_name]];
        return;
    }

    if ( ![plotNames containsObject:plot_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Plot %@ doesn't exist.  The plot needs to exist when SCMakeBarNow is called.\n  Plot command not created.\n", plot_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    /* It is necessary to copy this data because we keep a history of everything. */
    NSData * data_for_bars = [NSData dataWithBytes:(const void *)data length:(sizeof(double)*data_length)];

    SCUserData * var_data = [[SCUserData alloc] init]; // where does this ever get cleared correctly?  Does it matter cuz of history?
    [var_data setDataName:var_name];
    [var_data setDataType:SC_MAKE_NOW_COLUMN];
    [var_data setDataHoldType:SC_KEEP_NONE]; 
    [var_data setDataPtr:nil];
    [var_data setMakePlotNowData:data_for_bars];
    [var_data setDim1:data_length];

    SCBarCommand * make_bar_now_command = [[SCBarCommand alloc] init]; 
    [make_bar_now_command setPlotName:plot_name];
    [make_bar_now_command setName:var_name];
    [make_bar_now_command setVariable:var_data];
    [make_bar_now_command setOrder:order];
    SCBarCommandParameters * bcp = [SCBarCommandParameters copyFromCStruct:bar_plot_parameters];
    [make_bar_now_command setCommandParameters:bcp];
    [bcp release];
    [var_data release];
 
    [self drawMakeNowCommand:make_bar_now_command];
    [make_bar_now_command release];

    [pool release];
}


-(void) makeBarPlotNowFMC:(NSString *)plot_name
                     name:(NSString *)var_name
                   MCName:(NSString *)mc_name
        barPlotParameters:(SCBarPlotParameters *)bar_plot_parameters
               orderIndex:(int)order
{
    if ( ![self assertPhaseTwo:@"SCMakeBarNowFMC"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Bar command with variable %@ not created.\n", var_name]];
        return;
    }
    
    BOOL was_error = NO;
    if ( ![managedColumnNames containsObject:mc_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"Variable %@ is not a managed column.  Not creating the makeBarPlotNowFMC command.\n", mc_name]];
        was_error = YES;
    }
    if ( was_error )
    {
        return;
    }
    
    SCManagedPlotColumn * mpc = [managedColumns objectForKey:mc_name];
    double * data = [mpc getData];
    int data_length = [mpc getDataLength];
    
    [self makeBarPlotNow:plot_name name:var_name data:data dataLength:data_length barPlotParameters:bar_plot_parameters orderIndex:order];
}



-(void)makeHistogramPlotNow:(NSString *)plot_name name:(NSString *)var_name data:(double *)data dataLength:(int)data_length histogramPlotParameters:(SCHistogramPlotParameters*)histogram_plot_parameters orderIndex:(int)order
{
    if ( ![self assertPhaseTwo:@"SCMakeHistogramNow"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Histogram command with variables %@.\n", var_name]];
        return;
    }

    if ( ![plotNames containsObject:plot_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Plot %@ doesn't exist.  The plot needs to exist when SCMakeHistogramNow is called.\n  Plot command not created.\n", plot_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    /* It is necessary to copy this data because we keep a history of everything. */
    NSData * data_for_histogram = [NSData dataWithBytes:(const void *)data length:(sizeof(double)*data_length)];

    SCUserData * var_data = [[SCUserData alloc] init]; // where does this ever get cleared correctly?  Does it matter cuz of history?
    [var_data setDataName:var_name];
    [var_data setDataType:SC_MAKE_NOW_COLUMN];
    [var_data setDataHoldType:SC_KEEP_NONE]; 
    [var_data setDataPtr:nil];
    [var_data setMakePlotNowData:data_for_histogram];
    [var_data setDim1:data_length];

    SCHistogramCommand * make_histogram_now_command = [[SCHistogramCommand alloc] init];
    [make_histogram_now_command setPlotName:plot_name];
    [make_histogram_now_command setName:var_name];
    [make_histogram_now_command setVariable:var_data];
    [make_histogram_now_command setOrder:order];
    SCHistogramCommandParameters * hcp = [SCHistogramCommandParameters copyFromCStruct:histogram_plot_parameters];
    [make_histogram_now_command setCommandParameters:hcp];
    [hcp release];
    [var_data release]; 

    [self drawMakeNowCommand:make_histogram_now_command];
    [make_histogram_now_command release];
   
    [pool release];
}


-(void) makeHistogramPlotNowFMC:(NSString *)plot_name
                           name:(NSString *)var_name
                         MCName:(NSString *)mc_name
        histogramPlotParameters:(SCHistogramPlotParameters*)hpp
                     orderIndex:(int)order
{
    if ( ![self assertPhaseTwo:@"SCMakeHistogramNowFMC"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Histogram command with variable %@ not created.\n", var_name]];
        return;
    }
    
    BOOL was_error = NO;
    if ( ![managedColumnNames containsObject:mc_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"Variable %@ is not a managed column.  Not creating the SCMakeHistogramNowFMC command.\n", mc_name]];
        was_error = YES;
    }
    if ( was_error )
    {
        return;
    }
    
    SCManagedPlotColumn * mpc = [managedColumns objectForKey:mc_name];
    double * data = [mpc getData];
    int data_length = [mpc getDataLength];
    
    [self makeHistogramPlotNow:plot_name name:var_name data:data dataLength:data_length histogramPlotParameters:hpp orderIndex:order];
}


-(void) makeFitNow:(NSString *)plot_name
             xName:(NSString *)x_var_name
             yName:(NSString *)y_var_name
             xData:(double *)x_data
             yData:(double *)y_data
        dataLength:(int)data_length
        expression:(NSString *)expression
    parameterNames:(NSArray *)param_names
   parameterValues:(NSArray *)param_values                           
 fitPlotParameters:(SCFitPlotParameters*)fit_plot_parameters
        orderIndex:(int)order
{
    if ( ![self assertPhaseTwo:@"SCMakeFitNow"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Fit command with variables %@ and %@ not created.\n", x_var_name, y_var_name]];
        return;
    }

    if ( ![plotNames containsObject:plot_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Plot %@ doesn't exist.  The plot needs to exist when SCMakeFitNow is called.\n  Plot command not created.\n", plot_name]];
        return;
    }
    

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    /* It is necessary to copy this data because we keep a history of everything. */
    NSData * data_for_x = [NSData dataWithBytes:(const void *)x_data length:(sizeof(double)*data_length)];
    NSData * data_for_y = [NSData dataWithBytes:(const void *)y_data length:(sizeof(double)*data_length)];

    SCUserData * x_user_data = [[SCUserData alloc] init]; // where does this ever get cleared correctly?  Does it matter cuz of history?
    [x_user_data setDataName:x_var_name];
    [x_user_data setDataType:SC_MAKE_NOW_COLUMN];
    [x_user_data setDataHoldType:SC_KEEP_NONE]; 
    [x_user_data setDataPtr:nil];
    [x_user_data setMakePlotNowData:data_for_x];
    [x_user_data setDim1:data_length];

    SCUserData * y_user_data = [[SCUserData alloc] init]; // where does this ever get cleared correctly?  Does it matter cuz of history?
    [y_user_data setDataName:y_var_name];
    [y_user_data setDataType:SC_MAKE_NOW_COLUMN];
    [y_user_data setDataHoldType:SC_KEEP_NONE]; 
    [y_user_data setDataPtr:nil]; 
    [y_user_data setMakePlotNowData:data_for_y];
    [y_user_data setDim1:data_length];

    SCFitCommand * make_fit_now_command = [[SCFitCommand alloc] init];
    [make_fit_now_command setPlotName:plot_name];
    [make_fit_now_command setXName:x_var_name];
    [make_fit_now_command setYName:y_var_name];
    [make_fit_now_command setXVariable:x_user_data];
    [make_fit_now_command setYVariable:y_user_data];
    [make_fit_now_command setExpression:expression];
    [make_fit_now_command setFitParameterNames:param_names];
    [make_fit_now_command setFitParameterValues:param_values];
    [make_fit_now_command setOrder:order];
    SCFitCommandParameters * fcp = [SCFitCommandParameters copyFromCStruct:fit_plot_parameters];
    [make_fit_now_command setCommandParameters:fcp];
    [fcp release];
    [x_user_data release];
    [y_user_data release];

    [self drawMakeNowCommand:make_fit_now_command];
    [make_fit_now_command release];

    [pool release];
}


-(void) makeFitNowFMC:(NSString *)plot_name
                xName:(NSString *)x_var_name
                yName:(NSString *)y_var_name
              xMCName:(NSString *)x_mc_name
              yMCName:(NSString *)y_mc_name
           expression:(NSString *)expression
       parameterNames:(NSArray *)param_names
      parameterValues:(NSArray *)param_values                           
    fitPlotParameters:(SCFitPlotParameters*)fit_plot_parameters
           orderIndex:(int)order
{
    if ( ![self assertPhaseTwo:@"SCMakeFitNowFMC"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Fit command with variables %@ and %@ not created.\n", x_var_name, y_var_name]];
        return;
    }
    
    BOOL was_error = NO;
    if ( ![managedColumnNames containsObject:x_mc_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"Variable %@ is not a managed column.  The SCMakeFitNowFMC command wasn't not created.\n", x_mc_name]];
        was_error = YES;
    }
    if ( ![managedColumnNames containsObject:y_mc_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"Variable %@ is not a managed column.  The SCMakeFitNowFMC command wasn't not created.\n", y_mc_name]];
        was_error = YES;
    }

    if ( was_error )
    {
        return;
    }
    
    SCManagedPlotColumn * x_mpc = [managedColumns objectForKey:x_mc_name];
    double * x_data = [x_mpc getData];
    int x_data_length = [x_mpc getDataLength];
    
    SCManagedPlotColumn * y_mpc = [managedColumns objectForKey:y_mc_name];
    double * y_data = [y_mpc getData];
    int y_data_length = [y_mpc getDataLength];

    int data_length = 0;
    if ( x_data_length <= y_data_length )
        data_length = x_data_length;
    else
        data_length = y_data_length;

    [self makeFitNow:plot_name xName:x_var_name yName:y_var_name xData:x_data yData:y_data dataLength:data_length
          expression:expression parameterNames:param_names parameterValues:param_values                           
          fitPlotParameters:fit_plot_parameters orderIndex:(int)order];
}


-(void)makeSmoothNow:(NSString *)plot_name
               xName:(NSString *)x_var_name
               yName:(NSString *)y_var_name
               xData:(double *)x_data
               yData:(double *)y_data
          dataLength:(int)data_length
smoothPlotParameters:(SCSmoothPlotParameters*)smooth_plot_parameters
          orderIndex:(int)order
{
    if ( ![self assertPhaseTwo:@"SCMakeSmoothNow"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Smooth command with variables %@ and %@ not created.\n", x_var_name, y_var_name]];
        return;
    }

    if ( ![plotNames containsObject:plot_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Plot %@ doesn't exist.  The plot needs to exist when SCMakeSmoothNow is called.\n  Plot command not created.\n", plot_name]];
        return;
    }
    

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    /* It is necessary to copy this data because we keep a history of everything. */
    NSData * data_for_x = [NSData dataWithBytes:(const void *)x_data length:(sizeof(double)*data_length)];
    NSData * data_for_y = [NSData dataWithBytes:(const void *)y_data length:(sizeof(double)*data_length)];

    SCUserData * x_user_data = [[SCUserData alloc] init]; // where does this ever get cleared correctly?  Does it matter cuz of history?
    [x_user_data setDataName:x_var_name];
    [x_user_data setDataType:SC_MAKE_NOW_COLUMN];
    [x_user_data setDataHoldType:SC_KEEP_NONE]; 
    [x_user_data setDataPtr:nil];
    [x_user_data setMakePlotNowData:data_for_x];
    [x_user_data setDim1:data_length];

    SCUserData * y_user_data = [[SCUserData alloc] init]; // where does this ever get cleared correctly?  Does it matter cuz of history?
    [y_user_data setDataName:y_var_name];
    [y_user_data setDataType:SC_MAKE_NOW_COLUMN];
    [y_user_data setDataHoldType:SC_KEEP_NONE]; 
    [y_user_data setDataPtr:nil]; 
    [y_user_data setMakePlotNowData:data_for_y];
    [y_user_data setDim1:data_length];

    SCSmoothCommand * make_smooth_now_command = [[SCSmoothCommand alloc] init];
    [make_smooth_now_command setPlotName:plot_name];
    [make_smooth_now_command setXName:x_var_name];
    [make_smooth_now_command setYName:y_var_name];
    [make_smooth_now_command setXVariable:x_user_data];
    [make_smooth_now_command setYVariable:y_user_data];
    [make_smooth_now_command setOrder:order];
    SCSmoothCommandParameters * scp = [SCSmoothCommandParameters copyFromCStruct:smooth_plot_parameters];
    [make_smooth_now_command setCommandParameters:scp];
    [scp release];
    [x_user_data release];
    [y_user_data release];

    [self drawMakeNowCommand:make_smooth_now_command];
    [make_smooth_now_command release];

    [pool release];
}


-(void) makeSmoothNowFMC:(NSString *)plot_name
                   xName:(NSString *)x_var_name
                   yName:(NSString *)y_var_name
                 xMCName:(NSString *)x_mc_name
                 yMCName:(NSString *)y_mc_name
    smoothPlotParameters:(SCSmoothPlotParameters *)spp
              orderIndex:(int)order
{
    if ( ![self assertPhaseTwo:@"SCMakeSmoothNowFMC"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Smooth command with variables %@ and %@ not created.\n", x_var_name, y_var_name]];
        return;
    }
    
    BOOL was_error = NO;
    if ( ![managedColumnNames containsObject:x_mc_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"Variable %@ is not a managed column.  The SCMakeSmoothNowFMC command wasn't not created.\n", x_mc_name]];
        was_error = YES;
    }
    if ( ![managedColumnNames containsObject:y_mc_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"Variable %@ is not a managed column.  The SCMakeSmoothNowFMC command wasn't not created.\n", y_mc_name]];
        was_error = YES;
    }

    if ( was_error )
    {
        return;
    }
    
    SCManagedPlotColumn * x_mpc = [managedColumns objectForKey:x_mc_name];
    double * x_data = [x_mpc getData];
    int x_data_length = [x_mpc getDataLength];
    
    SCManagedPlotColumn * y_mpc = [managedColumns objectForKey:y_mc_name];
    double * y_data = [y_mpc getData];
    int y_data_length = [y_mpc getDataLength];

    int data_length = 0;
    if ( x_data_length <= y_data_length )
        data_length = x_data_length;
    else
        data_length = y_data_length;

    [self makeSmoothNow:plot_name xName:x_var_name yName:y_var_name xData:x_data yData:y_data dataLength:data_length 
          smoothPlotParameters:spp orderIndex:order];
}




/* Responds to the user's request to clear out the make now plots for a given plot. */
-(void)clearMakeNowPlots:(NSString *)plot_name
{
    if ( ![self assertPhaseTwo:@"SCClearMakeNowPlots"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Make now commands in plot %@ not cleared.\n", plot_name]];
        return;
    }

    if ( ![plotNames containsObject:plot_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Plot %@ doesn't exist.  The plot needs to exist when SCClearPlot is called.\n", plot_name]];
        return;
    }


    [[self simController] clearMakeNowPlots:plot_name];
}


-(void)addPlot:(NSString *)plot_name doDeleteMakeNowPlots:(BOOL)do_delete_makenowplots_after_duration
{
    if ( ![self assertPhaseOne:@"SCAddPlot"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Plot %@ not added.\n", plot_name]];
        return;
    }

   NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    /* First check to add the plot if the name doesn't exist. */
    if ( ![plotNames containsObject:plot_name] )
    {
        DebugNSLog(@"SimModel: addPlot: Adding plot with name %@", plot_name);
        [plotNames addObject:plot_name];
        [clearMakeNowPlotsByPlotName setObject:[NSNumber numberWithBool:do_delete_makenowplots_after_duration] forKey:plot_name];
    }
    else
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Plot %@ already exists. Not adding plot again.\n", plot_name]];
    }

    [pool release];
}


/* One place to put this hook with the built-in parameter. */
-(void)addPlot:(NSString *)plot_name
{
    [self addPlot:plot_name doDeleteMakeNowPlots:SCDoDeleteMakeNowPlotsAfterDuration];
}



-(void)addAxisToPlot:(NSString *)plot_name axisParameters:(SCAxisParameters *)axis_parameters
{
    if ( ![self assertPhaseOne:@"SCAddAxisToPlot"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Axis not added to plot %@.\n", plot_name]];
        return;
    }
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    /* First check to add the plot if the name doesn't exist. */
    if ( ![plotNames containsObject:plot_name] )
    {
        DebugNSLog(@"SimModel: addAxisToPlot: Adding plot with name %@", plot_name);
        [self addPlot:plot_name];
    }

    NSMutableArray *commands_per_plot = [commandsByPlotName objectForKey:plot_name];
    if ( commands_per_plot == nil )
    {
        DebugNSLog(@"SimModel: addAxisToPlot: Adding axis to plot with name %@", plot_name);
        commands_per_plot = [[NSMutableArray alloc] init];    
    }

    SCAxisCommand * axis_command = [[SCAxisCommand alloc] init];
    [axis_command setPlotName:plot_name];
    SCAxisCommandParameters * acp = [SCAxisCommandParameters copyFromCStruct:axis_parameters];
    [axis_command setCommandParameters:acp];
    [acp release];
    [commands_per_plot addObject:axis_command];
    [axis_command release];
    [commandsByPlotName setObject:commands_per_plot forKey:plot_name];


    
    [pool release];    
}



-(void) addColorSchemeToPlot:(NSString *)plot_name
             colorSchemeName:(NSString *)color_scheme_name
                  rangeTypes:(NSArray *)range_types
                 rangeStarts:(NSArray *)range_starts
                  rangeStops:(NSArray *)range_stops
                 rangeColors:(NSArray *)range_colors
{
    if ( ![self assertPhaseOne:@"SCAddColorScheme"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Color scheme  %@ not added.", color_scheme_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL was_error = NO;
//     if ( [colorSchemeNames containsObject:color_scheme_name] )
//     {
//         [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Color scheme %@ already exists.  Not adding again. \n", color_scheme_name]];
//         was_error = YES;
//     }
    BOOL color_scheme_is_defined = [color_scheme_name length] > 0;
    if ( !color_scheme_is_defined )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: The color scheme with no name i.e. \"\" was added to plot %@. Color scheme not created.  \n", plot_name]];
        was_error = YES;
    }    
                
    if ( was_error )
    {
        [pool release];
        return;
    }

    NSMutableDictionary *color_schemes_per_plot = [colorSchemesByPlotName objectForKey:plot_name];
    if ( color_schemes_per_plot == nil )
    {
        DebugNSLog(@"SimModel: addColorSchemeToPlot: Adding color scheme %@ for plot with name %@\n", color_scheme_name, plot_name);
        color_schemes_per_plot = [NSMutableDictionary dictionary];
    }

    SCColorScheme * color_scheme = [[SCColorScheme alloc] init];
    [color_scheme setName:color_scheme_name];
    [color_scheme setRangeTypes:range_types];
    [color_scheme setRangeStarts:range_starts];
    [color_scheme setRangeStops:range_stops];
    [color_scheme setRangeColors:range_colors];

    [color_schemes_per_plot setObject: color_scheme forKey: color_scheme_name];
    [colorSchemesByPlotName setObject: color_schemes_per_plot forKey: plot_name];
    
    //[colorSchemesByName setObject:color_scheme forKey:color_scheme_name]; // will overwrite if duplicate value.
    [color_scheme release];
    
    [pool release];
}


-(void)addVariablesToFastTimeLinePlotByName:(NSString *)plot_name xVarName:(NSString *)x_var_name yVarName:(NSString*)y_var_name 
                     fastLinePlotParameters:(SCTimePlotParameters*)fast_line_plot_parameters
{
    if ( ![self assertPhaseOne:@"SCAddVarsToFastTimeLine"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Fast time line command with vars %@ and %@ not added.\n", x_var_name, y_var_name]];
        return;
    }


    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL was_error = NO;

    if ( [variableArrayNames objectForKey:x_var_name] ) // the NSNumber is nill, then the var isn't there. 
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ is variable array, which is an inappropriate x variable for fast line plot.\n  Plot command not created.\n", x_var_name]];
        was_error = YES;
    }
    if ( was_error )
    {
        [pool release];
        return;
    }

    SCUserData * x_user_data = [userVariablesByName objectForKey:x_var_name];
    if ( !x_user_data )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Plot command not created.\n", x_var_name]];
        was_error = YES;
    }

    SCUserData * y_user_data = nil;
    bool is_var_array = NO;
    int var_array_length = 1;   // we'll use this var in the case it's a scalar. 
    if ( [variableArrayNames objectForKey:y_var_name] )
    {
        is_var_array = YES;
        var_array_length = [[variableArrayNames objectForKey:y_var_name] intValue];
        //[self writeWarningToConsole:[NSString stringWithFormat:@"Variable %@ has %i entries.\n", y_var_name, var_array_length]];
    }
    else
    {
        y_user_data = [userVariablesByName objectForKey:y_var_name];
        if ( !y_user_data )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Plot command not created.\n", y_var_name]];
            was_error = YES;
        }
    }
    
    if ( was_error )
    {
        [pool release];
        return;
    }
    
    /* First check to add the plot if the name doesn't exist. */
    if ( ![plotNames containsObject:plot_name] )
    {
        DebugNSLog(@"SimModel: addVariablesToFastTimeLinePlotByName: Adding plot with name %@", plot_name);
        [self addPlot:plot_name];
    }

    /* Get the variables names for the plot.  If this is the first pair, then we make it. */
    NSMutableArray *commands_per_plot = [commandsByPlotName objectForKey:plot_name];
    if ( commands_per_plot == nil )
    {
        DebugNSLog(@"SimModel: addVariablesToFastTimeLinePlotByName: Adding variable array for plot with name %@", plot_name);
        commands_per_plot = [[NSMutableArray alloc] init];    
    }


    SCFastLineCommand * fast_line_command = [[SCFastLineCommand alloc] init]; 
    [fast_line_command setPlotName:plot_name];
    [fast_line_command setXName:x_var_name];
    [fast_line_command setXVariable:[userVariablesByName objectForKey:x_var_name]];
    [fast_line_command setNLines:var_array_length];
    NSMutableArray *y_names = [NSMutableArray arrayWithCapacity:var_array_length];
    NSMutableDictionary *y_variables = [NSMutableDictionary dictionaryWithCapacity:var_array_length];
    for ( int i = 0; i < var_array_length; i++ )
    {
        NSString * yname = nil;
        if ( is_var_array )     /* We still respect the name of the variable, so if it's part of an array it has a 0, otherwise just the name.  */
            yname = [NSString stringWithFormat:@"%@%i", y_var_name, i];
        else
            yname = y_var_name;
        
        [y_names addObject:yname];
        [y_variables setObject:[userVariablesByName objectForKey:yname] forKey:yname];
    }
    [fast_line_command setYNames:y_names];
    [fast_line_command setYVariables:y_variables];
    SCTimePlotCommandParameters * flpp = [SCTimePlotCommandParameters copyFromCStruct:fast_line_plot_parameters];
    [fast_line_command setCommandParameters:flpp];
    [flpp release];
    [commands_per_plot addObject:fast_line_command];
    [fast_line_command release];
    [commandsByPlotName setObject:commands_per_plot forKey:plot_name];

    /* Make a note of the plot that the variables have gone into. */
    [self setPlotName:plot_name forVariables:[NSArray arrayWithObjects:x_var_name, nil]];
    [self setPlotName:plot_name forVariables:y_names];

    [pool release]; 
}


-(void)addVariablesToLinePlotByName:(NSString *)plot_name xVarName:(NSString *)x_var_name yVarName:(NSString *)y_var_name
                 linePlotParameters:(SCPlotParameters*)line_plot_parameters
{
    if ( ![self assertPhaseOne:@"SCAddVarsToLine"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Line command with vars %@ and %@ not added.\n", x_var_name, y_var_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL was_error = NO;
    /* First check to add the plot if the name doesn't exist. */
    if ( ![plotNames containsObject:plot_name] )
    {
        DebugNSLog(@"SimModel: addVariablesToLinelotByName: Adding plot with name %@", plot_name);
        [self addPlot:plot_name];
    }

    SCUserData * x_user_data = [userVariablesByName objectForKey:x_var_name];
    if ( !x_user_data )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Plot command not created.\n", x_var_name]];
        was_error = YES;
    }
    SCUserData * y_user_data = [userVariablesByName objectForKey:y_var_name];
    if ( !y_user_data )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Line plot command not created.\n", x_var_name]];
        was_error = YES;
    }
 
    if ( was_error )
    {
        [pool release];
        return;
    }

    /* Get the variable names for the plot.  If this is the first pair, then we make it. */
    NSMutableArray *commands_per_plot = [commandsByPlotName objectForKey:plot_name];
    if ( commands_per_plot == nil )
    {
        DebugNSLog(@"SimModel: addVariablesToLinePlotByName: Adding column for plot with name %@", plot_name);
        commands_per_plot = [[NSMutableArray alloc] init];    
    }

    SCLineCommand * line_command = [[SCLineCommand alloc] init]; 
    [line_command setPlotName:plot_name];
    [line_command setXName:x_var_name];
    [line_command setXVariable:[userVariablesByName objectForKey:x_var_name]];
    [line_command setYName:y_var_name];
    [line_command setYVariable:[userVariablesByName objectForKey:y_var_name]];
    SCPlotCommandParameters * lcp = [SCPlotCommandParameters copyFromCStruct:line_plot_parameters];
    [line_command setCommandParameters:lcp];
    [commands_per_plot addObject:line_command];
    [lcp release];
    [line_command release];
    [commandsByPlotName setObject:commands_per_plot forKey:plot_name];

    /* Make a note of the plot that the variables have gone into. */
    [self setPlotName:plot_name forVariables:[NSArray arrayWithObjects:x_var_name, y_var_name, nil]];

    [pool release];    
}


-(void)addVariablesToBarPlotByName:(NSString *)plot_name varName:(NSString *)var_name                  
                barPlotParameters:(SCBarPlotParameters*)bar_plot_parameters
{
    if ( ![self assertPhaseOne:@"SCAddVarsToBar"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Bar command with vars %@ not added.\n", var_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL was_error = NO;
    /* First check to add the plot if the name doesn't exist. */
    if ( ![plotNames containsObject:plot_name] )
    {
        DebugNSLog(@"SimModel: addVariablesToBarPlotByName: Adding plot with name %@", plot_name);
        [self addPlot:plot_name];
    }

    SCUserData * user_data = [userVariablesByName objectForKey:var_name];
    if ( !user_data )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Plot command not created.\n", var_name]];
        was_error = YES;
    }
    if ( ![columnNames containsObject:var_name] && ![expressionNames containsObject:var_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ is not a column or expression.  Bar plots require either.  Not adding. \n", var_name]];
        was_error = YES;
    }
 
    if ( was_error )
    {
        [pool release];
        return;
    }

    /* Get the variables names for the plot.  If this is the first pair, then we make it. */

    /* These bar plots don't have a pairing of variables because the axis on which the bars are aligned is set up from
     * the offset and distanceBetweenBars parameters. But since the other plot types follow this structure, we'll just
     * hack it for now. -DCS:2009/06/28 */
    NSMutableArray *commands_per_plot = [commandsByPlotName objectForKey:plot_name];
    if ( commands_per_plot == nil )
    {
        DebugNSLog(@"SimModel: addVariablesToBarPlotByName: Adding column for plot with name %@", plot_name);
        commands_per_plot = [[NSMutableArray alloc] init];    
    }

    SCBarCommand * bar_command = [[SCBarCommand alloc] init]; /* Points and lines are the same except for a couple of parameters. */
    [bar_command setPlotName:plot_name];
    [bar_command setName:var_name];
    [bar_command setVariable:[userVariablesByName objectForKey:var_name]];
    SCBarCommandParameters * bcp = [SCBarCommandParameters copyFromCStruct:bar_plot_parameters];
    [bar_command setCommandParameters:bcp];
    [commands_per_plot addObject:bar_command];
    [bcp release];
    [bar_command release];
    [commandsByPlotName setObject:commands_per_plot forKey:plot_name];

    /* Make a note of the plot that the variables have gone into. */
    [self setPlotName:plot_name forVariables:[NSArray arrayWithObjects:var_name, nil]];

    [pool release]; 
}


-(void)addVariablesToHistogramPlotByName:(NSString *)plot_name varName:(NSString *)var_name                  
                 histogramPlotParameters:(SCHistogramPlotParameters*)histogram_plot_parameters
{
    if ( ![self assertPhaseOne:@"SCAddVarsToHistogram"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Histogram command with vars %@ not added.\n", var_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL was_error = NO;
    /* First check to add the plot if the name doesn't exist. */
    if ( ![plotNames containsObject:plot_name] )
    {
        DebugNSLog(@"SimModel: addVariablesToHistogramPlotByName: Adding plot with name %@", plot_name);
        [self addPlot:plot_name];
    }

    SCUserData * user_data = [userVariablesByName objectForKey:var_name];
    if ( !user_data )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Histogram plot command not created.\n", var_name]];
        was_error = YES;
    }
    if ( ![columnNames containsObject:var_name] && ![expressionNames containsObject:var_name] && ![variableNames containsObject:var_name])
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ is not a column or an expression.  Histogram plots require either.  Not adding. \n", var_name]];
        was_error = YES;
    }
 
    if ( was_error )
    {
        [pool release];
        return;
    }

    /* Get the variables names for the plot.  If this is the first pair, then we make it. */
    NSMutableArray *commands_per_plot = [commandsByPlotName objectForKey:plot_name];
    if ( commands_per_plot == nil )
    {
        DebugNSLog(@"SimModel: addVariablesToHistogramPlotByName: Adding column for plot with name %@", plot_name);
        commands_per_plot = [[NSMutableArray alloc] init];    
    }

    SCHistogramCommand * histogram_command = [[SCHistogramCommand alloc] init]; /* Points and lines are the same except for a couple of parameters. */
    [histogram_command setPlotName:plot_name];
    [histogram_command setName:var_name];
    [histogram_command setVariable:[userVariablesByName objectForKey:var_name]];
    SCHistogramCommandParameters * hcp = [SCHistogramCommandParameters copyFromCStruct:histogram_plot_parameters];
    [histogram_command setCommandParameters:hcp];
    [commands_per_plot addObject:histogram_command];
    [hcp release];
    [histogram_command release];
    [commandsByPlotName setObject:commands_per_plot forKey:plot_name];

    /* Make a note of the plot that the variables have gone into. */
    [self setPlotName:plot_name forVariables:[NSArray arrayWithObjects:var_name, nil]];

    [pool release]; 
}


-(void)addVarsToFit:(NSString *)plot_name
              xName:(NSString *)x_var_name
              yName:(NSString *)y_var_name
         expression:(NSString *)expression
     parameterNames:(NSArray *)param_names
    parameterValues:(NSArray *)param_values
  fitPlotParameters:(SCFitPlotParameters *)fpp
{
    if ( ![self assertPhaseOne:@"SCAddVarsToFit"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Fit command with vars %@ and %@ not added.\n", x_var_name, y_var_name]];
        return;
    }


    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL was_error = NO;
    /* First check to add the plot if the name doesn't exist. */
    if ( ![plotNames containsObject:plot_name] )
    {
        DebugNSLog(@"SimModel: addVarsToFit: Adding plot with name %@", plot_name);
        [self addPlot:plot_name];
    }

    SCUserData * x_user_data = [userVariablesByName objectForKey:x_var_name];
    if ( !x_user_data )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Fit command not created.\n", x_var_name]];
        was_error = YES;
    }
    if ( ![columnNames containsObject:x_var_name] && ![expressionNames containsObject:x_var_name])
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ is not a column or an expression.  Fits require either.  Not adding. \n", x_var_name]];
        was_error = YES;
    }
    SCUserData * y_user_data = [userVariablesByName objectForKey:y_var_name];
    if ( !y_user_data )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Fit command not created.\n", x_var_name]];
        was_error = YES;
    }
    if ( ![columnNames containsObject:y_var_name] && ![expressionNames containsObject:y_var_name])
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ is not a column or an expression.  Line plots require either.  Not adding. \n", y_var_name]];
        was_error = YES;
    }
 
    if ( was_error )
    {
        [pool release];
        return;
    }

    /* Get the variable names for the plot.  If this is the first pair, then we make it. */
    NSMutableArray *commands_per_plot = [commandsByPlotName objectForKey:plot_name];
    if ( commands_per_plot == nil )
    {
        DebugNSLog(@"SimModel: addVarsToFit: Adding commands for plot with name %@", plot_name);
        commands_per_plot = [[NSMutableArray alloc] init];    
    }

    SCFitCommand * fit_command = [[SCFitCommand alloc] init]; 
    [fit_command setPlotName:plot_name];
    [fit_command setXName:x_var_name];
    [fit_command setXVariable:[userVariablesByName objectForKey:x_var_name]];
    [fit_command setYName:y_var_name];
    [fit_command setYVariable:[userVariablesByName objectForKey:y_var_name]];
    [fit_command setExpression:expression];
    [fit_command setFitParameterNames:param_names];
    [fit_command setFitParameterValues:param_values];
    SCFitCommandParameters * fcp = [SCFitCommandParameters copyFromCStruct:fpp];
    [fit_command setCommandParameters:fcp];
    [commands_per_plot addObject:fit_command];
    [fcp release];
    [fit_command release];
    [commandsByPlotName setObject:commands_per_plot forKey:plot_name];

    /* Make a note of the plot that the variables have gone into. */
    [self setPlotName:plot_name forVariables:[NSArray arrayWithObjects:x_var_name, y_var_name, nil]];

    [pool release];
}


-(void)addVarsToSmooth:(NSString *)plot_name
                 xName:(NSString *)x_var_name
                 yName:(NSString *)y_var_name
  smoothPlotParameters:(SCSmoothPlotParameters*)smooth_plot_parameters
{
    if ( ![self assertPhaseOne:@"SCAddVarsToSmooth"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Smooth command with vars %@ and %@ not added.\n", x_var_name, y_var_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL was_error = NO;
    /* First check to add the plot if the name doesn't exist. */
    if ( ![plotNames containsObject:plot_name] )
    {
        DebugNSLog(@"SimModel: addVarsToSmooth: Adding plot with name %@", plot_name);
        [self addPlot:plot_name];
    }

    SCUserData * x_user_data = [userVariablesByName objectForKey:x_var_name];
    if ( !x_user_data )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Smooth command not created.\n", x_var_name]];
        was_error = YES;
    }
    if ( ![columnNames containsObject:x_var_name] && ![expressionNames containsObject:x_var_name])
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ is not a column or an expression.  Smooths require either.  Not adding. \n", x_var_name]];
        was_error = YES;
    }
    SCUserData * y_user_data = [userVariablesByName objectForKey:y_var_name];
    if ( !y_user_data )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Smooth command not created.\n", y_var_name]];
        was_error = YES;
    }
    if ( ![columnNames containsObject:y_var_name] && ![expressionNames containsObject:y_var_name])
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ is not a column or an expression.  Smooths require either.  Not adding. \n", y_var_name]];
        was_error = YES;
    }
 
    if ( was_error )
    {
        [pool release];
        return;
    }

    /* Get the variable names for the plot.  If this is the first pair, then we make it. */
    NSMutableArray *commands_per_plot = [commandsByPlotName objectForKey:plot_name];
    if ( commands_per_plot == nil )
    {
        DebugNSLog(@"SimModel: addVarsToSmooth: Adding columns for plot with name %@", plot_name);
        commands_per_plot = [[NSMutableArray alloc] init];    
    }

    SCSmoothCommand * smooth_command = [[SCSmoothCommand alloc] init]; 
    [smooth_command setPlotName:plot_name];
    [smooth_command setXName:x_var_name];
    [smooth_command setXVariable:[userVariablesByName objectForKey:x_var_name]];
    [smooth_command setYName:y_var_name];
    [smooth_command setYVariable:[userVariablesByName objectForKey:y_var_name]];
    SCSmoothCommandParameters * scp = [SCSmoothCommandParameters copyFromCStruct:smooth_plot_parameters];
    [smooth_command setCommandParameters:scp];
    [commands_per_plot addObject:smooth_command];
    [scp release];
    [smooth_command release];
    [commandsByPlotName setObject:commands_per_plot forKey:plot_name];

    /* Make a note of the plot that the variables have gone into. */
    [self setPlotName:plot_name forVariables:[NSArray arrayWithObjects:x_var_name, y_var_name, nil]];

    [pool release];
}


-(void) addVarsToMultiLines:(NSString *)plot_name
               linesVarName:(NSString *)lines_var_name
         lowerLimitsVarName:(NSString *)lower_limits_var_name
         upperLimitsVarName:(NSString *)upper_limits_var_name
              labelsVarName:(NSString *)labels_var_name
   multiLinesPlotParameters:(SCMultiLinesPlotParameters*)multi_lines_plot_parameters
{
    if ( ![self assertPhaseOne:@"SCAddVarsToMultiLines"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Multiline command with vars %@ not added.\n", lines_var_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL was_error = NO;
    /* First check to add the plot if the name doesn't exist. */
    if ( ![plotNames containsObject:plot_name] )
    {
        DebugNSLog(@"SimModel: addVarsToMultiLines: Adding plot with name %@", plot_name);
        [self addPlot:plot_name];
    }

    SCUserData * lines_user_data = [userVariablesByName objectForKey:lines_var_name];
    if ( !lines_user_data )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Multiline command not created.\n", lines_var_name]];
        was_error = YES;
    }
    if ( ![columnNames containsObject:lines_var_name] && ![expressionNames containsObject:lines_var_name])
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ is not a column or an expression.  Multilines require either.  Not adding. \n", lines_var_name]];
        was_error = YES;
    }

    SCUserData * lower_limits_user_data = nil;
    if ( [lower_limits_var_name length] > 0 )
    {
        lower_limits_user_data = [userVariablesByName objectForKey:lower_limits_var_name];
        if ( !lower_limits_user_data )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Multilines command not created.\n", lower_limits_var_name]];
            was_error = YES;
        }
    }

    SCUserData * upper_limits_user_data = nil;
    if ( [upper_limits_var_name length] > 0 )
    {
         upper_limits_user_data = [userVariablesByName objectForKey:upper_limits_var_name];
        if ( !upper_limits_user_data )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Multilines command not created.\n", upper_limits_var_name]];
            was_error = YES;
        }
    }

    SCUserData * labels_user_data = nil;
    if ( [labels_var_name length] > 0 )
    {
        labels_user_data = [userVariablesByName objectForKey:labels_var_name];
        if ( !labels_user_data )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Multilines command not created.\n", labels_var_name]];
            was_error = YES;
        }
    }
    
    if ( was_error )
    {
        [pool release];
        return;
    }

    /* Get the variable names for the plot.  If this is the first pair, then we make it. */
    NSMutableArray *commands_per_plot = [commandsByPlotName objectForKey:plot_name];
    if ( commands_per_plot == nil )
    {
        DebugNSLog(@"SimModel: addVarsToMultiLines: Adding columns for plot with name %@", plot_name);
        commands_per_plot = [[NSMutableArray alloc] init];    
    }
    
    SCMultiLinesCommand * multilines_command = [[SCMultiLinesCommand alloc] init]; 
    [multilines_command setPlotName: plot_name];
    [multilines_command setLinesName: lines_var_name];
    [multilines_command setLinesVariable: lines_user_data];
    [multilines_command setLowerLimitsName: lower_limits_var_name];
    if ( [lower_limits_var_name length] > 0 )
        [multilines_command setLowerLimitsVariable: lower_limits_user_data];

    [multilines_command setUpperLimitsName: upper_limits_var_name];
    if ( [upper_limits_var_name length] > 0 )
        [multilines_command setUpperLimitsVariable: upper_limits_user_data];
                                                                       
    [multilines_command setLabelsName: labels_var_name];
    if ( [labels_var_name length] > 0 )
        [multilines_command setLabelsVariable: labels_user_data];

    SCMultiLinesCommandParameters * mlcp = [SCMultiLinesCommandParameters copyFromCStruct: multi_lines_plot_parameters];
    [multilines_command setCommandParameters: mlcp];
    [commands_per_plot addObject: multilines_command];
    [mlcp release];
    [multilines_command release];
    [commandsByPlotName setObject: commands_per_plot forKey: plot_name];

    /* Make a note of the plot that the variables have gone into. */
    [self setPlotName:plot_name forVariables:[NSArray arrayWithObjects:lines_var_name, upper_limits_var_name, lower_limits_var_name, labels_var_name, nil]];

    [pool release];
}


-(void) makeMultLinesNow:(NSString *)plot_name
            linesVarName:(NSString *)lines_var_name
      lowerLimitsVarName:(NSString *)lower_limits_var_name
      upperLimitsVarName:(NSString *)upper_limits_var_name
           labelsVarName:(NSString *)labels_var_name
               linesData:(double *)lines_data
         lowerLimitsData:(double *)lower_limits_data
         upperLimitsData:(double *)upper_limits_data
              labelsData:(double *)labels_data
              dataLength:(int)data_length
multiLinesPlotParameters:(SCMultiLinesPlotParameters*)mlpp
              orderIndex:(int)order
{

    if ( ![self assertPhaseTwo:@"SCMakeMultiLinesNow"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" MultLines command for plot %@.\n", plot_name]];
        return;
    }

    if ( ![plotNames containsObject:plot_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Plot %@ doesn't exist.  The plot needs to exist when SCMakeMultiLinesNow is called.\n", plot_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];


    NSData * data_for_lines = [NSData dataWithBytes:(const void *)lines_data length:(sizeof(double)*data_length)];
    SCUserData * lines_user_data = [[SCUserData alloc] init]; 
    [lines_user_data setDataName:lines_var_name];
    [lines_user_data setDataType:SC_MAKE_NOW_COLUMN];
    [lines_user_data setDataHoldType:SC_KEEP_NONE]; 
    [lines_user_data setDataPtr:nil];
    [lines_user_data setMakePlotNowData:data_for_lines];
    [lines_user_data setDim1:data_length];    

    SCUserData * lower_limits_user_data = nil;
    if ( [lower_limits_var_name length] > 0 )
    {
        NSData * data_for_lower_limits = [NSData dataWithBytes:(const void *)lower_limits_data length:(sizeof(double)*data_length)];
        lower_limits_user_data = [[SCUserData alloc] init];
        [lower_limits_user_data setDataName:lower_limits_var_name];
        [lower_limits_user_data setDataType:SC_MAKE_NOW_COLUMN];
        [lower_limits_user_data setDataHoldType:SC_KEEP_NONE]; 
        [lower_limits_user_data setDataPtr:nil];
        [lower_limits_user_data setMakePlotNowData:data_for_lower_limits];
        [lower_limits_user_data setDim1:data_length];
    }

    SCUserData * upper_limits_user_data = nil;
    if ( [upper_limits_var_name length] > 0 )
    {
        NSData * data_for_upper_limits = [NSData dataWithBytes:(const void *)upper_limits_data length:(sizeof(double)*data_length)];
        upper_limits_user_data = [[SCUserData alloc] init];
        [upper_limits_user_data setDataName:upper_limits_var_name];
        [upper_limits_user_data setDataType:SC_MAKE_NOW_COLUMN];
        [upper_limits_user_data setDataHoldType:SC_KEEP_NONE]; 
        [upper_limits_user_data setDataPtr:nil];
        [upper_limits_user_data setMakePlotNowData:data_for_upper_limits];
        [upper_limits_user_data setDim1:data_length];
    }

    SCUserData * labels_user_data = nil;
    if ( [labels_var_name length] > 0 )
    {
        NSData * data_for_labels = [NSData dataWithBytes:(const void *)labels_data length:(sizeof(double)*data_length)];
        labels_user_data = [[SCUserData alloc] init];
        [labels_user_data setDataName:labels_var_name];
        [labels_user_data setDataType:SC_MAKE_NOW_COLUMN];
        [labels_user_data setDataHoldType:SC_KEEP_NONE]; 
        [labels_user_data setDataPtr:nil];
        [labels_user_data setMakePlotNowData:data_for_labels];
        [labels_user_data setDim1:data_length];
    }

    SCMultiLinesCommand * multilines_command = [[SCMultiLinesCommand alloc] init]; 
    [multilines_command setPlotName: plot_name];
    [multilines_command setLinesName: lines_var_name];
    [multilines_command setLinesVariable: lines_user_data];
    [multilines_command setLowerLimitsName: lower_limits_var_name];
    if ( [lower_limits_var_name length] > 0 )
    {
        [multilines_command setLowerLimitsVariable: lower_limits_user_data];
        [lower_limits_user_data release];
    }

    [multilines_command setUpperLimitsName: upper_limits_var_name];
    if ( [upper_limits_var_name length] > 0 )
    {
        [multilines_command setUpperLimitsVariable: upper_limits_user_data];
        [upper_limits_user_data release];
    }                                    
                              
    [multilines_command setLabelsName: labels_var_name];
    if ( [labels_var_name length] > 0 )
    {
        [multilines_command setLabelsVariable: labels_user_data];
        [labels_user_data release];
    }

    SCMultiLinesCommandParameters * mlcp = [SCMultiLinesCommandParameters copyFromCStruct: mlpp];
    [multilines_command setCommandParameters: mlcp];
    [multilines_command setOrder:order];
    [mlcp release];

    [self drawMakeNowCommand:multilines_command];
    [multilines_command release];

    [pool release];
}


-(void) addVarsToRange:(NSString *)plot_name
           xMinVarName:(NSString *)x_min_var_name
           xMaxVarName:(NSString *)x_max_var_name
           yMinVarName:(NSString *)y_min_var_name
           yMaxVarName:(NSString *)y_max_var_name
     rangeColorVarName:(NSString *)range_color_var_name
       colorSchemeName:(NSString *)color_scheme_name
   rangePlotParameters:(SCRangePlotParameters *)rpp
{
    if ( ![self assertPhaseOne:@"SCAddVarsToRange"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Range command with for plot %@.\n", plot_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL was_error = NO;
    /* First check to add the plot if the name doesn't exist. */
    if ( ![plotNames containsObject:plot_name] )
    {
        DebugNSLog(@"SimModel: addVarsToRange: Adding plot with name %@", plot_name);
        [self addPlot:plot_name];
    }

    SCUserData * x_min_user_data = nil;
    BOOL x_min_is_defined = [x_min_var_name length] > 0;
    if ( x_min_is_defined )
    {
        x_min_user_data = [userVariablesByName objectForKey:x_min_var_name];
        if ( !x_min_user_data )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: x min variable %@ not found.\n  Range command not created.\n", x_min_var_name]];
            was_error = YES;
        }
    }
    SCUserData * x_max_user_data = nil;
    BOOL x_max_is_defined = [x_max_var_name length] > 0;
    if ( x_max_is_defined )
    {
        x_max_user_data = [userVariablesByName objectForKey:x_max_var_name];
        if ( !x_max_user_data )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: x max variable %@ not found.\n  Range command not created.\n", x_max_var_name]];
            was_error = YES;
        }
    }
    SCUserData * y_min_user_data = nil;
    BOOL y_min_is_defined = [y_min_var_name length] > 0;
    if ( y_min_is_defined )
    {
        y_min_user_data = [userVariablesByName objectForKey:y_min_var_name];
        if ( !y_min_user_data )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: y min variable %@ not found.\n  Range command not created.\n", y_min_var_name]];
            was_error = YES;
        }
    }
    SCUserData * y_max_user_data = nil;
    BOOL y_max_is_defined = [y_max_var_name length] > 0;
    if ( y_max_is_defined )
    {
        y_max_user_data = [userVariablesByName objectForKey:y_max_var_name];
        if ( !y_max_user_data )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: y max variable %@ not found.\n  Range command not created.\n", y_max_var_name]];
            was_error = YES;
        }
    }
    SCUserData * range_color_user_data = nil;
    BOOL range_color_is_defined = [range_color_var_name length] > 0;
    if ( range_color_is_defined )
    {
        range_color_user_data = [userVariablesByName objectForKey:range_color_var_name];
        if ( !range_color_user_data )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: range color variable %@ not found.\n  Range command not created.\n", range_color_var_name]];
            was_error = YES;
        }
    }


    if ( (!x_min_is_defined && x_max_is_defined) || (x_min_is_defined && !x_max_is_defined) )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Range command requires both x min and x max to be columns if one of them is.  Range command for plot %@ not created.\n", plot_name]];
        was_error = YES;
    }
    if ( (!y_min_is_defined && y_max_is_defined) || (y_min_is_defined && !y_max_is_defined) )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Range command requires both y min and y max to be columns if one of them is.  Range command for plot %@ not created.\n", plot_name]];
        was_error = YES;
    }
    if ( !x_min_is_defined && !x_max_is_defined && !y_min_is_defined && !y_max_is_defined )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: SCAddVarsToRange command requires at least one of the x or y variable to be defined as watched columns.  Range command for plot %@ not created.\n", plot_name]];
        was_error = YES;
    }

    if ( rpp->xRangeType == SC_RANGE_COLUMNS && (!x_min_is_defined || !x_max_is_defined ))
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: SCAddVarsToRange command requires the x min and x max columns to be defined if the xRangeType is SC_RANGE_COLUMNS.  Range command for plot %@ not created.\n", plot_name]];
        was_error = YES;
    }
    if ( rpp->yRangeType == SC_RANGE_COLUMNS && (!y_min_is_defined || !y_max_is_defined ))
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: SCAddVarsToRange command requires the y min and y max columns to be defined if the yRangeType is SC_RANGE_COLUMNS.  Range command for plot %@ not created.\n", plot_name]];
        was_error = YES;
    }


    BOOL color_scheme_is_defined = [color_scheme_name length] > 0;
    if ( color_scheme_is_defined )
    {
        NSDictionary * color_schemes = [colorSchemesByPlotName objectForKey:plot_name];
        if ( color_schemes == nil )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: The color scheme %@ in the range command hasn't been added to the plot %@. Not adding range command.  \n", color_scheme_name, plot_name]];
            was_error = YES;
        }
        else 
        {
            if ( [color_schemes objectForKey:color_scheme_name] == nil )
            {
                [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: The color scheme %@ in the range command hasn't been added to the plot %@. Not adding range command.  \n", color_scheme_name, plot_name]];                
                was_error = YES;
            }
        }
    }

    if ( was_error )
    {
        [pool release];
        return;
    }


    /* Get the variable names for the plot.  If this is the first pair, then we make it. */
    NSMutableArray *commands_per_plot = [commandsByPlotName objectForKey:plot_name];
    if ( commands_per_plot == nil )
    {
        DebugNSLog(@"SimModel: addVarsToRange: Adding command for plot with name %@", plot_name);
        commands_per_plot = [[NSMutableArray alloc] init];    
    }

    SCRangeCommand * range_command = [[SCRangeCommand alloc] init]; 
    [range_command setPlotName:plot_name];
    [range_command setXMinName:x_min_var_name];
    if ( x_min_is_defined )
        [range_command setXMinVariable:[userVariablesByName objectForKey:x_min_var_name]];

    [range_command setXMaxName:x_max_var_name];
    if ( x_max_is_defined )
        [range_command setXMaxVariable:[userVariablesByName objectForKey:x_max_var_name]];

    [range_command setYMinName:y_min_var_name];
    if ( y_min_is_defined )
        [range_command setYMinVariable:[userVariablesByName objectForKey:y_min_var_name]];

    [range_command setYMaxName:y_max_var_name];
    if ( y_max_is_defined )
        [range_command setYMaxVariable:[userVariablesByName objectForKey:y_max_var_name]];

    [range_command setRangeColorName:range_color_var_name];
    if ( range_color_is_defined )
        [range_command setRangeColorVariable:[userVariablesByName objectForKey:range_color_var_name]];

    if ( [color_scheme_name length] > 0 )
        [range_command setColorSchemeName: color_scheme_name];

    SCRangeCommandParameters * rcp = [SCRangeCommandParameters copyFromCStruct:rpp];
    [range_command setCommandParameters:rcp];
    [commands_per_plot addObject:range_command];
    [rcp release];
    [range_command release];
    [commandsByPlotName setObject:commands_per_plot forKey:plot_name];

    /* Make a note of the plot that the variables have gone into. */
    [self setPlotName:plot_name forVariables:[NSArray arrayWithObjects:x_min_var_name, x_max_var_name, y_min_var_name, y_max_var_name, range_color_var_name, nil]];

    [pool release];
}


-(void) makeRangeNow:(NSString *)plot_name
            xMinName:(NSString *)x_min_var_name
            xMaxName:(NSString *)x_max_var_name
            yMinName:(NSString *)y_min_var_name
            yMaxName:(NSString *)y_max_var_name
      rangeColorName:(NSString *)range_color_name
            xMinData:(double *)x_min_data
            xMaxData:(double *)x_max_data
            yMinData:(double *)y_min_data
            yMaxData:(double *)y_max_data
      rangeColorData:(double *)range_color_data
          dataLength:(int)data_length
     colorSchemeName:(NSString *)color_scheme_name
 rangePlotParameters:(SCRangePlotParameters *)rpp
          orderIndex:(int)order;
{
    if ( ![self assertPhaseTwo:@"SCMakeRangeNow"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Range command for plot %@.\n", plot_name]];
        return;
    }
    if ( ![plotNames containsObject:plot_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Plot %@ doesn't exist.  The plot needs to exist when SCMakeRangeNow is called.\n", plot_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];


    BOOL was_error = NO;

    BOOL x_min_is_defined = [x_min_var_name length] > 0;
    BOOL x_max_is_defined = [x_max_var_name length] > 0;
    BOOL y_min_is_defined = [y_min_var_name length] > 0;
    BOOL y_max_is_defined = [y_max_var_name length] > 0;
    BOOL range_color_is_defined = [range_color_name length] > 0;

    if ( (!x_min_is_defined && x_max_is_defined) || (x_min_is_defined && !x_max_is_defined) )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Range command requires both x min and x max to be columns if one of them is.  Range command for plot %@ not created.\n", plot_name]];
        was_error = YES;
    }
    if ( (!y_min_is_defined && y_max_is_defined) || (y_min_is_defined && !y_max_is_defined) )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Range command requires both y min and y max to be columns if one of them is.  Range command for plot %@ not created.\n", plot_name]];
        was_error = YES;
    }

    if ( rpp->xRangeType == SC_RANGE_COLUMNS && (!x_min_is_defined || !x_max_is_defined ))
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: SCMakeRangeNow command requires the x min and x max data to be supplied if the xRangeType is SC_RANGE_COLUMNS.  Range command for plot %@ not created.\n", plot_name]];
        was_error = YES;
    }
    if ( rpp->yRangeType == SC_RANGE_COLUMNS && (!y_min_is_defined || !y_max_is_defined ))
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: SCMakeRangeNow command requires the y min and y max data to be supplied if the yRangeType is SC_RANGE_COLUMNS.  Range command for plot %@ not created.\n", plot_name]];
        was_error = YES;
    }    

    BOOL color_scheme_is_defined = [color_scheme_name length] > 0;
    if ( color_scheme_is_defined )
    {
        NSDictionary * color_schemes = [colorSchemesByPlotName objectForKey:plot_name];
        if ( color_schemes == nil )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: The color scheme %@ in the SCMakeRangeNow command hasn't been added to the plot %@. Not adding range command.  \n", color_scheme_name, plot_name]];
            was_error = YES;
        }
        else 
        {
            if ( [color_schemes objectForKey:color_scheme_name] == nil )
            {
                [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: The color scheme %@ in the SCMakeRangeNow command hasn't been added to the plot %@. Not adding range command.  \n", color_scheme_name, plot_name]];                
                was_error = YES;
            }
        }
    }

    if ( was_error )
    {
        [pool release];
        return;
    }

    SCUserData * x_min_user_data = nil;
    if ( x_min_is_defined )
    {
        NSData * data_for_x_min = [NSData dataWithBytes:(const void *)x_min_data length:(sizeof(double)*data_length)];
        x_min_user_data = [[SCUserData alloc] init]; 
        [x_min_user_data setDataName:x_min_var_name];
        [x_min_user_data setDataType:SC_MAKE_NOW_COLUMN];
        [x_min_user_data setDataHoldType:SC_KEEP_NONE]; 
        [x_min_user_data setDataPtr:nil];
        [x_min_user_data setMakePlotNowData:data_for_x_min];
        [x_min_user_data setDim1:data_length];
    }
    SCUserData * x_max_user_data = nil;
    if ( x_max_is_defined )
    {
        NSData * data_for_x_max = [NSData dataWithBytes:(const void *)x_max_data length:(sizeof(double)*data_length)];
        x_max_user_data = [[SCUserData alloc] init]; 
        [x_max_user_data setDataName:x_max_var_name];
        [x_max_user_data setDataType:SC_MAKE_NOW_COLUMN];
        [x_max_user_data setDataHoldType:SC_KEEP_NONE]; 
        [x_max_user_data setDataPtr:nil];
        [x_max_user_data setMakePlotNowData:data_for_x_max];
        [x_max_user_data setDim1:data_length];
    }
    SCUserData * y_min_user_data = nil;
    if ( y_min_is_defined )
    {
        NSData * data_for_y_min = [NSData dataWithBytes:(const void *)y_min_data length:(sizeof(double)*data_length)];
        y_min_user_data = [[SCUserData alloc] init]; 
        [y_min_user_data setDataName:y_min_var_name];
        [y_min_user_data setDataType:SC_MAKE_NOW_COLUMN];
        [y_min_user_data setDataHoldType:SC_KEEP_NONE]; 
        [y_min_user_data setDataPtr:nil];
        [y_min_user_data setMakePlotNowData:data_for_y_min];
        [y_min_user_data setDim1:data_length];
    }
    SCUserData * y_max_user_data = nil;
    if ( y_max_is_defined )
    {
        NSData * data_for_y_max = [NSData dataWithBytes:(const void *)y_max_data length:(sizeof(double)*data_length)];
        y_max_user_data = [[SCUserData alloc] init]; 
        [y_max_user_data setDataName:y_max_var_name];
        [y_max_user_data setDataType:SC_MAKE_NOW_COLUMN];
        [y_max_user_data setDataHoldType:SC_KEEP_NONE]; 
        [y_max_user_data setDataPtr:nil];
        [y_max_user_data setMakePlotNowData:data_for_y_max];
        [y_max_user_data setDim1:data_length];
    }
    SCUserData * range_color_user_data = nil;
    if ( range_color_is_defined )
    {
        NSData * data_for_range_color = [NSData dataWithBytes:(const void*)range_color_data length:(sizeof(double)*data_length)];
        range_color_user_data = [[SCUserData alloc] init];
        [range_color_user_data setDataName:range_color_name];
        [range_color_user_data setDataType:SC_MAKE_NOW_COLUMN];
        [range_color_user_data setDataHoldType:SC_KEEP_NONE];
        [range_color_user_data setDataPtr:nil];
        [range_color_user_data setMakePlotNowData:data_for_range_color];
        [range_color_user_data setDim1:data_length];
    }
    

    SCRangeCommand * range_command = [[SCRangeCommand alloc] init]; 
    [range_command setPlotName:plot_name];

    [range_command setXMinName:x_min_var_name];
    if ( x_min_is_defined )
    {
        [range_command setXMinVariable:x_min_user_data];
        [x_min_user_data release];
    }

    [range_command setXMaxName:x_max_var_name];
    if ( x_max_is_defined )
    {
        [range_command setXMaxVariable:x_max_user_data];
        [x_max_user_data release];
    }

    [range_command setYMinName:y_min_var_name];
    if ( y_min_is_defined )
    {
        [range_command setYMinVariable:y_min_user_data];
        [y_min_user_data release];
    }

    [range_command setYMaxName:y_max_var_name];
    if ( y_max_is_defined )
    {
        [range_command setYMaxVariable:y_max_user_data];
        [y_max_user_data release];
    }

    [range_command setRangeColorName:range_color_name];
    if ( range_color_is_defined )
    {
        [range_command setRangeColorVariable:range_color_user_data];
        [range_color_user_data release];
    }
    
    if ( [color_scheme_name length] > 0 )
        [range_command setColorSchemeName: color_scheme_name];

    [range_command setOrder:order];
    SCRangeCommandParameters * rcp = [SCRangeCommandParameters copyFromCStruct:rpp];
    [range_command setCommandParameters:rcp];
    [rcp release];

    [self drawMakeNowCommand:range_command];
    [range_command release];

    [pool release];
}


-(void) addVarsToScatter:(NSString *)plot_name
                xVarName:(NSString *)x_var_name
                yVarName:(NSString *)y_var_name
           pointSizeName:(NSString *)point_size_var_name
          pointColorName:(NSString *)point_color_var_name
         colorSchemeName:(NSString *)color_scheme_name
   scatterPlotParameters:(SCScatterPlotParameters *)spp
{

    if ( ![self assertPhaseOne:@"SCAddVarsToScatter"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Scatter command with vars %@, %@ not added.\n", x_var_name, y_var_name]];
        return;
    }

    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL was_error = NO;
    
    /* First check to add the plot if the name doesn't exist. */
    if ( ![plotNames containsObject:plot_name] )
    {
        DebugNSLog(@"SimModel: addVarsToScatter: Adding plot with name %@", plot_name);
        [self addPlot:plot_name];
    }

    SCUserData * x_user_data = [userVariablesByName objectForKey:x_var_name];
    if ( !x_user_data )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Scatter command not created.\n", x_var_name]];
        was_error = YES;
    }
    SCUserData * y_user_data = [userVariablesByName objectForKey:y_var_name];
    if ( !y_user_data )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Scatter command not created.\n", y_var_name]];
        was_error = YES;
    }

    SCUserData * point_size_user_data = nil;
    if ( [point_size_var_name length] > 0 )
    {
        point_size_user_data = [userVariablesByName objectForKey:point_size_var_name];
        if ( !point_size_user_data )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Scatter command not created.\n", point_size_var_name]];
            was_error = YES;
        }
    }

    SCUserData * point_color_user_data = nil;
    if ( [point_color_var_name length] > 0 )
    {
        point_color_user_data = [userVariablesByName objectForKey:point_color_var_name];
        if ( !point_color_user_data )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Variable %@ not found.\n  Scatter command not created.\n", point_color_var_name]];
            was_error = YES;
        }
    }


    BOOL color_scheme_is_defined = [color_scheme_name length] > 0;
    if ( color_scheme_is_defined )
    {
        NSDictionary * color_schemes = [colorSchemesByPlotName objectForKey:plot_name];
        if ( color_schemes == nil )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: The color scheme %@ in the scatter command hasn't been added to the plot %@. Not adding scatter command.  \n", color_scheme_name, plot_name]];
            was_error = YES;
        }
        else 
        {
            if ( [color_schemes objectForKey:color_scheme_name] == nil )
            {
                [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: The color scheme %@ in the scatter command hasn't been added to the plot %@. Not adding scatter command.  \n", color_scheme_name, plot_name]];                
            }
        }
    }
    
    if ( was_error )
    {
        [pool release];
        return;
    }

    /* Get the variable names for the plot.  If this is the first pair, then we make it. */
    NSMutableArray *commands_per_plot = [commandsByPlotName objectForKey:plot_name];
    if ( commands_per_plot == nil )
    {
        DebugNSLog(@"SimModel: addVarsToScatter: Adding command for plot with name %@", plot_name);
        commands_per_plot = [[NSMutableArray alloc] init];    
    }

    SCScatterCommand * scatter_command =  [[SCScatterCommand alloc] init];
    [scatter_command setPlotName: plot_name];
    [scatter_command setXName: x_var_name];
    [scatter_command setXVariable: x_user_data];
    [scatter_command setYName: y_var_name];
    [scatter_command setYVariable: y_user_data];
    [scatter_command setPointSizeName: point_size_var_name];
    if ( [point_size_var_name length] > 0 )
        [scatter_command setPointSizeVariable: point_size_user_data];

    [scatter_command setPointColorName: point_color_var_name];
    if ( [point_color_var_name length] > 0 )
        [scatter_command setPointColorVariable: point_color_user_data];
    
    if ( [color_scheme_name length] > 0 )
        [scatter_command setColorSchemeName: color_scheme_name];

    SCScatterCommandParameters * scp = [SCScatterCommandParameters copyFromCStruct: spp];
    [scatter_command setCommandParameters: scp];
    [commands_per_plot addObject: scatter_command];
    [scp release];
    [scatter_command release];
    [commandsByPlotName setObject: commands_per_plot forKey: plot_name];

    /* Make a note of the plot that the variables have gone into. */
    [self setPlotName:plot_name forVariables:[NSArray arrayWithObjects:x_var_name, y_var_name, point_size_var_name, point_color_var_name, nil]];

    [pool release];    
}


-(void) makeScatterNow:(NSString *)plot_name
                 xVarName:(NSString *)x_var_name
                 yVarName:(NSString *)y_var_name
         pointSizeName:(NSString *)point_size_var_name
        pointColorName:(NSString *)point_color_var_name
                 xData:(double *)x_data
                 yData:(double *)y_data
         pointSizeData:(double *)point_size_data
        pointColorData:(double *)point_color_data
            dataLength:(int)data_length
       colorSchemeName:(NSString *)color_scheme_name
 scatterPlotParameters:(SCScatterPlotParameters *)spp
            orderIndex:(int)order;
{

    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    BOOL was_error = NO;
    if ( ![self assertPhaseTwo:@"SCMakeScatterNow"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Scatter command with variables %@ and %@ not created.\n", x_var_name, y_var_name]];
        was_error = YES;
    }
    
    if ( ![plotNames containsObject:plot_name] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Plot %@ doesn't exist.  The plot needs to exist when SCMakeScatterNow is called.\n  Plot command not created.\n", plot_name]];
        was_error = YES;
    }

    BOOL color_scheme_is_defined = [color_scheme_name length] > 0;
    if ( color_scheme_is_defined )
    {
        NSDictionary * color_schemes = [colorSchemesByPlotName objectForKey:plot_name];
        if ( color_schemes == nil )
        {
            [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: The color scheme %@ in the scatter command hasn't been added to the plot %@. Not adding scatter command.  \n", color_scheme_name, plot_name]];
            was_error = YES;
        }
        else 
        {
            if ( [color_schemes objectForKey:color_scheme_name] == nil )
            {
                [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: The color scheme %@ in the scatter command hasn't been added to the plot %@. Not adding scatter command.  \n", color_scheme_name, plot_name]];                
                was_error = YES;
            }
        }
    }

    if ( was_error )
    {
        [pool release];
        return;
    }

    /* It is necessary to copy this data because we keep a history of everything. */
    NSData * data_for_x = [NSData dataWithBytes:(const void *)x_data length:(sizeof(double)*data_length)];
    NSData * data_for_y = [NSData dataWithBytes:(const void *)y_data length:(sizeof(double)*data_length)];

    SCUserData * x_user_data = [[SCUserData alloc] init]; 
    [x_user_data setDataName:x_var_name];
    [x_user_data setDataType:SC_MAKE_NOW_COLUMN];
    [x_user_data setDataHoldType:SC_KEEP_NONE]; 
    [x_user_data setDataPtr:nil];
    [x_user_data setMakePlotNowData:data_for_x];
    [x_user_data setDim1:data_length];

    SCUserData * y_user_data = [[SCUserData alloc] init];
    [y_user_data setDataName:y_var_name];
    [y_user_data setDataType:SC_MAKE_NOW_COLUMN];
    [y_user_data setDataHoldType:SC_KEEP_NONE]; 
    [y_user_data setDataPtr:nil]; 
    [y_user_data setMakePlotNowData:data_for_y];
    [y_user_data setDim1:data_length];

    SCUserData *point_size_user_data = nil;
    if ( [point_size_var_name length] > 0 )
    {
        NSData * data_for_point_size = [NSData dataWithBytes:(const void *)point_size_data length:(sizeof(double)*data_length)];
        point_size_user_data = [[SCUserData alloc] init];
        [point_size_user_data setDataName:point_size_var_name];
        [point_size_user_data setDataType:SC_MAKE_NOW_COLUMN];
        [point_size_user_data setDataHoldType:SC_KEEP_NONE]; 
        [point_size_user_data setDataPtr:nil]; 
        [point_size_user_data setMakePlotNowData:data_for_point_size];
        [point_size_user_data setDim1:data_length];
    }

    SCUserData *point_color_user_data = nil;
    if ( [point_color_var_name length] > 0 )
    {
        NSData * data_for_point_color = [NSData dataWithBytes:(const void *)point_color_data length:(sizeof(double)*data_length)];
        point_color_user_data = [[SCUserData alloc] init];
        [point_color_user_data setDataName:point_color_var_name];
        [point_color_user_data setDataType:SC_MAKE_NOW_COLUMN];
        [point_color_user_data setDataHoldType:SC_KEEP_NONE]; 
        [point_color_user_data setDataPtr:nil]; 
        [point_color_user_data setMakePlotNowData:data_for_point_color];
        [point_color_user_data setDim1:data_length];
    }   

    SCScatterCommand * scatter_command =  [[SCScatterCommand alloc] init];
    [scatter_command setPlotName: plot_name];
    [scatter_command setXName: x_var_name];
    [scatter_command setXVariable: x_user_data];
    [x_user_data release];
    [scatter_command setYName: y_var_name];
    [scatter_command setYVariable: y_user_data];
    [y_user_data release];
    [scatter_command setPointSizeName: point_size_var_name];
    if ( [point_size_var_name length] > 0 )
    {
        [scatter_command setPointSizeVariable: point_size_user_data];
        [point_size_user_data release];
    }
    
    [scatter_command setPointColorName: point_color_var_name];
    if ( [point_color_var_name length] > 0 )
    {
        [scatter_command setPointColorVariable: point_color_user_data];
        [point_color_user_data release];
    }
    if ( [color_scheme_name length] > 0 )
        [scatter_command setColorSchemeName: color_scheme_name];

    [scatter_command setOrder:order];
    SCScatterCommandParameters * scp = [SCScatterCommandParameters copyFromCStruct: spp];
    [scatter_command setCommandParameters: scp];
    [scp release];

    [self drawMakeNowCommand:scatter_command];
    [scatter_command release];
    
    [pool release];
}



-(void)addWindowDataToPlotByName:(NSString *)plot_name rect:(NSRect)rect_
{
    if ( ![self assertPhaseOne:@"SCSetWindowData"] )
    {
        [self writeWarningToConsole:[NSString stringWithFormat:@" Window data for plot %@ not added.\n", plot_name]];
        return;
    }

    NSValue *myRectValue = [NSValue valueWithRect:rect_];
    [windowParametersByPlotName setObject:myRectValue forKey:plot_name];
}


/* Convert from the C structure plot parameters pStruct to the objective C class call CommandParameters. */
//         //[self setPlotParametersFromSimulation:pData plotName:plot_name];
// - (void)setPlotParametersFromSimulation:(pStruct * )pdata plotName:(NSString *)plot_name
// {
//     CommandParameters *ppm = [CommandParameters copyFromPStruct:pdata];    
//     [axisParametersByPlotName setObject:ppm forKey:plot_name];
//     [ppm release];
// }



/* Hook into the models initialization routine. All of the data structures utilized in this routine are set in the
 * classes init method, so there should be nothing to worry about.  But if it's called twice, it'll leak all thos
 * variables. */
- (void)initSimulation
{
    /* User initialization of their model. */

#ifndef _NO_USER_LIBRARY_    
    _AddControllableParameters();
    _AddControllableButtons();
#else
    AddControllableParameters();
    AddControllableButtons();
#endif

    DebugNSLog(@"InitModel start");

#ifndef _NO_USER_LIBRARY_
    modelData = _InitModel();   // _ means comes from the dynamic library and _NOT_ from the .o file.
#else
    modelData = InitModel();   
#endif
    DebugNSLog(@"InitModel end");

    /* Define the plots and the variables associated with those plots. */
#ifndef _NO_USER_LIBRARY_    
    _AddPlotsAndRegisterWatchedVariables(modelData);
#else
    AddPlotsAndRegisterWatchedVariables(modelData);
#endif

    /* Get the window data for each plot. */
    for ( NSString * plot_name in plotNames )
    {
#ifndef _NO_USER_LIBRARY_   
        _AddWindowDataForPlots([plot_name UTF8String], modelData);
#else
        AddWindowDataForPlots([plot_name UTF8String], modelData);
#endif
    }
    
    /* Set the plot parameters from the model. This comes after the initialization function so that the most of the
     * model can be setup and made use of for making the plots prettier. */ 
    pStruct * pData = NULL;
    
    /* Can't use fast enumeration here because the plotTypes needs to be simultaneously accessed. */
    //for ( NSString * plot_name in plotNames )
    int i = 0;
    for ( i = 0; i < [plotNames count]; i++ )
    {
        NSString * plot_name = [plotNames objectAtIndex:i];
        pData = (pStruct *)malloc(sizeof(pStruct));
        SCInitPStruct(pData);
        SCInitPStructWithSensibleValues(pData);       // should have pNumber set.
#ifndef _NO_USER_LIBRARY_
        _SetPlotParameters(pData, [plot_name UTF8String], modelData); // command in user's model definition
#else
        SetPlotParameters(pData, [plot_name UTF8String], modelData); // command in user's model definition
#endif
        DefaultAxisParameters *apm = [DefaultAxisParameters copyFromPStruct:pData]; // now turn into ObjC class.
        [axisParametersByPlotName setObject:apm forKey:plot_name];       // store in right variable
        [apm release];
        SCDeallocPStruct(pData);  // dealloc the struct, including the members (so it's deep).
        pData = NULL;
    }
    isPhaseOne = NO;
    isPhaseTwo = YES;

    NSString *error_string;
    if ( !doRedrawBasedOnTimer && nStepsBetweenDrawing <= 0 )
    {
        nStepsBetweenDrawing = 1;
        error_string = @"SC Error: The number of steps between redraws must be greater than 0.  Setting to 1.\n";
        [self writeWarningToConsole:error_string];
    }
    if ( nStepsBetweenPlotting <= 0 )
    {
        nStepsBetweenPlotting = 1;
        error_string = @"SC Error: The number of steps between plotting must be greater than 0.  Setting to 1.\n";
        [self writeWarningToConsole:error_string];
    }
    if ( nStepsInFullPlot <= 0 )
    {
        nStepsInFullPlot = 1;
        error_string = @"SC Error: The number of steps between in a full plot duration must be greater than 0.  Setting to 1.\n";
        [self writeWarningToConsole:error_string];
    }
    if ( !doRedrawBasedOnTimer && nStepsBetweenPlotting > nStepsBetweenDrawing )
    {
        nStepsBetweenPlotting = nStepsBetweenDrawing;
        error_string = [NSString stringWithFormat:@"SC Error: The number of steps between plotting must be less than the number of steps between redrawing.  Setting the number of steps between plotting to %i.\n", nStepsBetweenDrawing];
        [self writeWarningToConsole:error_string];
    }
    if ( !doRedrawBasedOnTimer && nStepsBetweenDrawing % nStepsBetweenPlotting )
    {
        int rem = nStepsBetweenDrawing % nStepsBetweenPlotting;
        nStepsBetweenDrawing -= rem;
        error_string = [NSString stringWithFormat:@"SC Error: The number of steps between plotting must evenly divide the number of steps between drawing.  Setting the number of steps between drawing to %i.\n", nStepsBetweenDrawing];
        [self writeWarningToConsole:error_string];
    }
    if ( !doRedrawBasedOnTimer && nStepsInFullPlot < nStepsBetweenDrawing )
    {
        nStepsInFullPlot = nStepsBetweenDrawing;
        error_string = [NSString stringWithFormat:@"SC Error: The number of steps in a full plot duration must be greater than or equal to the number of steps between drawing.  Setting the number of steps in a full plot duration to %i.\n", nStepsBetweenDrawing];
        [self writeWarningToConsole:error_string];
    }
    if ( nStepsInFullPlot < nStepsBetweenPlotting )
    {
        nStepsInFullPlot = nStepsBetweenPlotting;
        error_string = [NSString stringWithFormat:@"SC Error: The number of steps in a full plot duration must be greater than or equal to the number of steps between plottin.  Setting the number of steps in a full plot duration to %i.\n", nStepsBetweenPlotting];
        [self writeWarningToConsole:error_string];        
    }
    if ( nStepsInFullPlot % nStepsBetweenPlotting )
    {
        int rem = nStepsInFullPlot % nStepsBetweenPlotting;
        nStepsInFullPlot -= rem;
        error_string = [NSString stringWithFormat:@"SC Error: The number of steps between plotting must evenly divide the number of steps in a full plot duration.  Setting the number of steps in a full plot duration to %i.\n", nStepsInFullPlot];
        [self writeWarningToConsole:error_string];
    }
    if ( !doRedrawBasedOnTimer && nStepsInFullPlot % nStepsBetweenDrawing )
    {
        int rem = nStepsInFullPlot % nStepsBetweenDrawing;
        nStepsInFullPlot -= rem;
        error_string = [NSString stringWithFormat:@"SC Error: The number of steps between drawing must evenly divide the number of steps in a full plot duration.  Setting the number of steps in a full plot duration to %i.\n", nStepsInFullPlot];
        [self writeWarningToConsole:error_string];
    }    
    

    /* Now set the watched variable data list, which is used when we actually collect data after every plot point.  We
     * take out anything that doesn't collect data, such as the static columns and the expressions.  Since we allow the
     * history for watched variables that aren't being plotted, we make sure that every watched variable has a plot
     * assocaited with it (from a plot command) and if it doesn't we assign the variable to the "silent" plot. */ 


    NSMutableArray *var_names_for_silent_history = [NSMutableArray array];
    NSMutableDictionary *variables_for_silent_history = [NSMutableDictionary dictionary];


    for ( NSString * var_name in userVariablesByName )
    {
        SCUserData * user_data = [userVariablesByName objectForKey:var_name];
        switch ( [user_data dataType] )
        {
        case SC_TIME_COLUMN:
        case SC_FIXED_SIZE_COLUMN:
        case SC_MANAGED_COLUMN:
        case SC_MAKE_NOW_COLUMN: 
        {
            [watchedVariablesByName setObject:user_data forKey:var_name];
            NSMutableSet * plots_for_variable = [plotNamesByWatchedVariableName objectForKey:var_name];
            if ( plots_for_variable == nil )
            {
                plots_for_variable = [NSMutableSet setWithObject:SCSilentHistoryControllerName];
                /* Can be referenced for lookup when copying data.*/
                [plotNamesByWatchedVariableName setObject:plots_for_variable forKey:var_name]; 

                /* Put into the silent plot */
                [user_data setIsSilent:YES];
                [var_names_for_silent_history addObject:var_name];
                [variables_for_silent_history setObject:user_data forKey:var_name];

            }
        }
        break;
        case SC_EXPRESSION_COLUMN:
        case SC_STATIC_COLUMN:
            break;
        default:
            assert ( 0 ); /* Case not implemented yet. */
        }
    }

    SCSilentCommand * silent_command = [[SCSilentCommand alloc] init]; 
    [silent_command setPlotName:SCSilentHistoryControllerName];
    [silent_command setNames:var_names_for_silent_history];
    [silent_command setVariables:variables_for_silent_history];

    NSMutableArray * commands_per_plot = [[NSMutableArray alloc] init];    
    [commands_per_plot addObject:silent_command];
    [silent_command release];
    [commandsByPlotName setObject:commands_per_plot forKey:SCSilentHistoryControllerName];
    //[commands_per_plot release];
}


/* I don't think the pool is necessary because the NC doesn't go away, the dictionary is initially autoreleased, but
 * probably retained by the NC, so I don't have anything to worry about. -DCS:2009/05/27 */
-(void)writeTextToConsole:(NSString*)text
{
    //NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    //DebugNSLog(@"Sending Notification.");
    NSDictionary *d = [NSDictionary dictionaryWithObject:text forKey:@"message"];
    [nc postNotificationName:SCWriteToControllerConsoleNotification object:self userInfo:d];
    //[pool release];
}


-(void)writeAttributedTextToConsole:(NSString*)text textColor:(NSColor *)color textSize:(int)size
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];    

    NSFont *text_font = [NSFont systemFontOfSize:size];
    NSDictionary *text_dict = [NSDictionary dictionaryWithObjectsAndKeys:text_font, NSFontAttributeName, color, NSForegroundColorAttributeName, nil];
    
    NSArray *keys = [NSArray arrayWithObjects:@"message", @"attributes", nil];
    NSArray *objects = [NSArray arrayWithObjects:text, text_dict, nil];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:SCWriteToControllerConsoleAttributedNotification object:self userInfo:dictionary];

    [pool release];    
}


-(void)writeWarningToConsole:(NSString*)text 
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];    

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

    [pool release];
}



- (void)callInitForRun
{
    DebugNSLog(@"InitForRun start");
    [computeLock lock];
#ifndef _NO_USER_LIBRARY_
    _InitForRun(modelData);
#else
    InitForRun(modelData);
#endif
    [computeLock unlock];
    DebugNSLog(@"InitForRun end");
}


- (void)callInitForPlotDuration
{
    DebugNSLog(@"InitForPlotDuration start");
    [computeLock lock];
#ifndef _NO_USER_LIBRARY_
    _InitForPlotDuration(modelData);
#else
    InitForPlotDuration(modelData);
#endif
    [computeLock unlock];
    DebugNSLog(@"InitForPlotDuration end");
}


/* SCColumn and SCManagedColumn and SCManagedPlotColumn are used in three contexts.  The user defined managed columns
 * are SCManagedPlotColumn because there is an optimization that we only need to append the latest information, since
 * the last plot update, to the DG controller and not the entire thing.  The SCColumn and SCManagedColumn are used to
 * move the data from the user level down to the history level, so you'll see those used just below as temporary
 * objects.  The SCColumn is used when the data doesn't have to be accumulated (not a time column) while the SCManaged
 * column is used for the time column because it has to grow since user variables are being watched.  Finally, the
 * SCManagedColumn is used as the permanent storage for the history (See the dictionaries of plot data in
 * HistoryController.  It's robust for variable sized data as well as fixed size data.
 */
- (NSDictionary*) runModelForNSteps:(int)nsteps_to_simulate
{
    /* Now the SimModel class makes everything nice for the system to read effectively. */
    int n_vars_to_plot = [watchedVariablesByName count];
    int nsteps_to_store = (int)(nsteps_to_simulate/[self nStepsBetweenPlotting]);
    
    /* An array here for the sake of speed.  It makes the code much uglier, but that's the way it is. */ 
    SCColumn *all_data[n_vars_to_plot]; /* Used the (managed) columns for passing data around as well as a specific user data type */

    /*** PREALLOCATE DUE TO TIME VARIABLES ***/
    /* If we are dealing with scalars, then we'll save the value at each plot time, regardless of the number of plot
     * times per redraw.  If the variable is an array, then we only save the array once per redraw.  This means that the
     * array size for scalars will be nsteps_to_store ( the number of plot times per redraw) and for columns it will be
     * the length of the column.  Perhaps down the road it may make sense to copy the array entire array for each time
     * step but our first use of the column data type is to fill in a bar plot, which only needs to updated once per
     * redraw.  Making this change should be only as hard as adding another flag to the SCUserData structure that
     * indicates whether to save multiple values or not.  */
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    int aidx = 0;
    for ( NSString * var_name in watchedVariablesByName )
    {
        SCUserData * user_data = [watchedVariablesByName objectForKey:var_name];
        SCDataHoldType var_hold_type = [user_data dataHoldType];
        SCUserDataType user_data_type = [user_data dataType];

        /* The responsibility for the difference between saving for the redraw duration vs. the plot duration is shared
         * between this function and the updateHistory function of HistoryController.  That's because this class doesn't
         * know anything about the duration length and can only distinguish between the plot point and redraw cases.  */
        /* Allocating space for variables is done for most variables beforehand because we the space requirements.
         * However, for a managed column, we have to do it after the calls to RunModelOneStep because that's when we
         * know the space we'll need. */
        switch ( user_data_type )
        {
        case SC_FIXED_SIZE_COLUMN: // based on the assumption that all columns saved only for the current point -DCS:2009/06/29
        case SC_MANAGED_COLUMN:
            all_data[aidx] = nil; /* Do nothing, taken care of below. */
            break;
        case SC_TIME_COLUMN:
        {
            switch ( var_hold_type )
            {
            case SC_KEEP_REDRAW:
            case SC_KEEP_DURATION:
            {
                assert ( user_data_type == SC_TIME_COLUMN );
                SCManagedColumn * sc_column = [[SCManagedColumn alloc] initColumnWithSize:nsteps_to_store];
                all_data[aidx] = sc_column;
            }
            break;
            case SC_KEEP_PLOT_POINT:
            {
                assert ( user_data_type == SC_TIME_COLUMN );
                SCManagedColumn * sc_column = [[SCManagedColumn alloc] initColumnWithSize:1];
                all_data[aidx] = sc_column;
            }
            break;
            default:
                assert ( 0 );       // case not implemented 
            }
        }
        break;
        case SC_EXPRESSION_COLUMN:
        case SC_STATIC_COLUMN:
            assert ( 0 );       /* These types should not come up here.  */
            break;
        default:
            assert(0);
        }        
        aidx++;
    }
    assert ( aidx == n_vars_to_plot );

    /* For each variable, we want to store nsteps_to_store worth of values.  These values are acquired by looking up the
     * values pointed to by the dictionary of value name to value pointer.  So we can presumably enumerate the
     * dictionary without regard to key name, so long as the order is preserved later when we store the variables. */
    int var_idx = 0;
    double * data_ptr;
    int nsteps_stored = 0;
    BOOL is_plot_iter = NO;
    int n_steps_between_plotting = [self nStepsBetweenPlotting];
    for ( int i = 0; i < nsteps_to_simulate; i++ ) 
    {        
        /* Get the simulation result for the next step. */
        is_plot_iter = i % n_steps_between_plotting == (n_steps_between_plotting-1); /* Store a value every nStepsBetweenPlotting */

        [computeLock lock];
#ifndef _NO_USER_LIBRARY_        
        _RunModelOneStep(modelData, is_plot_iter);
#else
        RunModelOneStep(modelData, is_plot_iter);
#endif
        [computeLock unlock];

        /*** NOW COLLECT THE DATA ***/
        /* Get the data from the watched variable in the simulation for the time step just computed. */
        if ( is_plot_iter && nsteps_stored < nsteps_to_store )
        {
            var_idx = 0;
            for ( NSString * var_name in watchedVariablesByName )
            {
                SCUserData * user_data = [watchedVariablesByName objectForKey:var_name];
                SCDataHoldType var_hold_type = [user_data dataHoldType];
                switch ( var_hold_type )
                {
                case SC_KEEP_NONE:
                    assert ( 0 ); /* Variables with this data hold type shouldn't be here in the first place. */
                    break;
                case SC_KEEP_DURATION:
                case SC_KEEP_REDRAW:
                {
                    SCUserDataType user_data_type = [user_data dataType];
                    assert ( user_data_type != SC_FIXED_SIZE_COLUMN );
                    NSValue * data = [user_data dataPtr];
                    data_ptr = (double *)[data pointerValue];
                    [(SCManagedColumn *)all_data[var_idx] addData:data_ptr nData:1];
                }
                break;
                case SC_KEEP_PLOT_POINT:
                case SC_KEEP_COLUMN_AT_PLOT_TIME:
                    /* If this is the last plot for the redraw, then we'll copy the values. */
                    if ( nsteps_stored == nsteps_to_store-1 )
                    {
                        int sc_column_dim = [user_data dim1];
                        NSValue * data = [user_data dataPtr];
                        data_ptr = (double *)[data pointerValue];
                        SCColumn * sc_column = [[SCColumn alloc] initColumnWithDataPtr:data_ptr length:sc_column_dim]; // doesn't copy as optimization! :)
                        all_data[var_idx] = sc_column;
                    }
                    break;
                case SC_KEEP_EVERYTHING_GIVEN: /* currently used for managed columns, where the history should save everything. */
                {
                    /* Take only the data since the last plot, unless the managed column was cleared, then we
                     * need to start over. */
                    if ( nsteps_stored == nsteps_to_store-1 )
                    {
                        NSValue * data = [user_data dataPtr];
                        SCManagedPlotColumn * managed_column = (SCManagedPlotColumn *)[data pointerValue];
                        int sc_column_dim = [managed_column getDataLengthSinceLastPlot]; 
                        data_ptr = [managed_column getDataSinceLastPlot];
                        SCColumn * sc_column = [[SCColumn alloc] initColumnWithDataPtr:data_ptr length:sc_column_dim]; // doesn't copy as optimization! :)
                        all_data[var_idx] = sc_column;
                    }
                }
                break;
                default:
                    assert ( 0 );  // case not implemented yet 
                }
                var_idx++;    
            }
            nsteps_stored++;
        }
    }

    /* Now set the nsteps_to_simulate worth of data values into the dictionaries to be used by the plotting
     * routines.  */
    NSMutableDictionary *plot_data_block = [[NSMutableDictionary alloc] initWithCapacity:n_vars_to_plot]; /* Auto released, by caller's pool. */

    var_idx = 0;
    for ( NSString * var_name in watchedVariablesByName )
    {
        [plot_data_block setObject:all_data[var_idx] forKey:var_name];
        [all_data[var_idx] release];
        var_idx++;
    }
    
    [pool release];

    return plot_data_block;
}


-(NSDictionary*) runModelAmountOfTime:(double)time_in_ms currentIteration:(int*)current_iteration
{
    struct timeval start_time; 
    struct timeval end_time;
    
    gettimeofday(&start_time, NULL);

    /* Now the SimModel class makes everything nice for the system to read effectively. */
    int n_vars_to_plot = [watchedVariablesByName count];
    //int max_steps_to_store = (nStepsInFullPlot / nStepsBetweenPlotting) - (*current_iteration)/nStepsBetweenPlotting + 1;
    int max_steps_to_store = 2*nStepsStored;
    if ( max_steps_to_store < 64 )
        max_steps_to_store = 64;

    
    /* An array here for the sake of speed.  It makes the code much uglier, but that's the way it is. */ 
    /* Used the (managed) columns for passing data around as well as a specific user data type */
    SCColumn **all_data = (SCColumn **)malloc(n_vars_to_plot*sizeof(SCColumn*));

    /*** PREALLOCATE DUE TO TIME VARIABLES ***/
    /* If we are dealing with scalars, then we'll save the value at each plot time, regardless of the number of plot
     * times per redraw.  If the variable is an array, then we only save the array once per redraw.  This means that the
     * array size for scalars will be max_steps_to_store ( the number of plot times per number of steps in full plot)
     * and for columns it will be the length of the column.  Perhaps down the road it may make sense to copy the array
     * entire array for each time step but our first use of the column data type is to fill in a bar plot, which only
     * needs to updated once per redraw.  Making this change should be only as hard as adding another flag to the
     * SCUserData structure that indicates whether to save multiple values or not.  */
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    int aidx = 0;
    for ( NSString * var_name in watchedVariablesByName )
    {
        SCUserData * user_data = [watchedVariablesByName objectForKey:var_name];
        SCDataHoldType var_hold_type = [user_data dataHoldType];
        SCUserDataType user_data_type = [user_data dataType];

        /* The responsibility for the difference between saving for the redraw duration vs. the plot duration is shared
         * between this function and the updateHistory function of HistoryController.  That's because this class doesn't
         * know anything about the duration length and can only distinguish between the plot point and redraw cases.  */
        /* Allocating space for variables is done for most variables beforehand because we the space requirements.
         * However, for a managed column, we have to do it after the calls to RunModelOneStep because that's when we
         * know the space we'll need. */
        switch ( user_data_type )
        {
        case SC_FIXED_SIZE_COLUMN: // based on the assumption that all columns saved only for the current point -DCS:2009/06/29
        case SC_MANAGED_COLUMN:
            all_data[aidx] = nil; /* Do nothing, taken care of below. */
            break;
        case SC_TIME_COLUMN:
        {
            switch ( var_hold_type )
            {
            case SC_KEEP_REDRAW:
            case SC_KEEP_DURATION:
            {
                assert ( user_data_type == SC_TIME_COLUMN );
                SCManagedColumn * sc_column = [[SCManagedColumn alloc] initColumnWithSize:max_steps_to_store];
                all_data[aidx] = sc_column;
            }
            break;
            case SC_KEEP_PLOT_POINT:
            {
                assert ( user_data_type == SC_TIME_COLUMN );
                SCManagedColumn * sc_column = [[SCManagedColumn alloc] initColumnWithSize:1];
                all_data[aidx] = sc_column;
            }
            break;
            default:
                assert ( 0 );       // case not implemented 
            }
        }
        break;
        case SC_EXPRESSION_COLUMN:
        case SC_STATIC_COLUMN:
            assert ( 0 );       /* These types should not come up here.  */
            break;
        default:
            assert(0);
        }        
        aidx++;
    }
    assert ( aidx == n_vars_to_plot );

    /* For each variable, we want to store up to max_steps_to_store worth of values.  These values are acquired by looking up the
     * values pointed to by the dictionary of value name to value pointer.  So we can presumably enumerate the
     * dictionary without regard to key name, so long as the order is preserved later when we store the variables. */
    int var_idx = 0;
    double * data_ptr;
    BOOL is_plot_iter = NO;
    int n_steps_between_plotting = [self nStepsBetweenPlotting];
    double milliseconds_elapsed = 0.0;

    nStepsStored = 0;
    while ( milliseconds_elapsed < time_in_ms && *current_iteration < nStepsInFullPlot )  
    {        
        (*current_iteration)++;
        /* Get the simulation result for the next step. */
        is_plot_iter = *current_iteration % n_steps_between_plotting == (n_steps_between_plotting-1); /* Store a value every nStepsBetweenPlotting */

        [computeLock lock];
#ifndef _NO_USER_LIBRARY_        
        _RunModelOneStep(modelData, is_plot_iter);
#else
        RunModelOneStep(modelData, is_plot_iter);
#endif
        [computeLock unlock];

        /*** NOW COLLECT THE DATA for the time columns ***/
        /* Get the data from the watched variable in the simulation for the time step just computed. */
        if ( is_plot_iter )
        {
            nStepsStored++;
            var_idx = 0;
            for ( NSString * var_name in watchedVariablesByName ) // xxx could have a separate list for time variables to shorten this loop. -DCS:2009/11/12
            {
                SCUserData * user_data = [watchedVariablesByName objectForKey:var_name];
                SCDataHoldType var_hold_type = [user_data dataHoldType];
                switch ( var_hold_type )
                {
                case SC_KEEP_NONE:
                    assert ( 0 ); /* Variables with this data hold type shouldn't be here in the first place. */
                    break;
                case SC_KEEP_DURATION:
                case SC_KEEP_REDRAW:
                {
                    SCUserDataType user_data_type = [user_data dataType];
                    assert ( user_data_type != SC_FIXED_SIZE_COLUMN );
                    NSValue * data = [user_data dataPtr];
                    data_ptr = (double *)[data pointerValue];
                    [(SCManagedColumn *)all_data[var_idx] addData:data_ptr nData:1];
                }
                break;
                case SC_KEEP_PLOT_POINT:
                {
                    /* If this is the last plot for the redraw, then we'll copy the values. */
                    int sc_column_dim = [user_data dim1];
                    NSValue * data = [user_data dataPtr];
                    data_ptr = (double *)[data pointerValue];
                    SCColumn * sc_column = [[SCColumn alloc] initColumnWithDataPtr:data_ptr length:sc_column_dim]; // doesn't copy as optimization! :)
                    all_data[var_idx] = sc_column;
                }
                break;                
                case SC_KEEP_COLUMN_AT_PLOT_TIME:
                case SC_KEEP_EVERYTHING_GIVEN: 
                    break;
                default:
                    assert ( 0 );  // case not implemented yet 
                }
                var_idx++;    
            }
        }
        gettimeofday(&end_time, NULL);
        milliseconds_elapsed = (end_time.tv_sec - start_time.tv_sec)*1000.0 + (end_time.tv_usec - start_time.tv_usec)/1000.0;
    }

    /* Now get the data from the non time columns. */
    var_idx = 0;
    for ( NSString * var_name in watchedVariablesByName ) // xxx could have a separate list for non-time variables to shorten this loop, then var_idx whould have to change. . -DCS:2009/11/12
    {
        SCUserData * user_data = [watchedVariablesByName objectForKey:var_name];
        SCDataHoldType var_hold_type = [user_data dataHoldType];
        switch ( var_hold_type )
        {
        case SC_KEEP_NONE:
            assert ( 0 ); /* Variables with this data hold type shouldn't be here in the first place. */
            break;
        case SC_KEEP_DURATION:
        case SC_KEEP_REDRAW:
        case SC_KEEP_PLOT_POINT:
            break;
        case SC_KEEP_COLUMN_AT_PLOT_TIME:
        {
            /* If this is the last plot for the redraw, then we'll copy the values. */
            int sc_column_dim = [user_data dim1];
            NSValue * data = [user_data dataPtr];
            data_ptr = (double *)[data pointerValue];
            SCColumn * sc_column = [[SCColumn alloc] initColumnWithDataPtr:data_ptr length:sc_column_dim]; // doesn't copy as optimization! :)
            all_data[var_idx] = sc_column;
        }
        break;
        case SC_KEEP_EVERYTHING_GIVEN: /* currently used for managed columns, where the history should save everything. */
        {
            NSValue * data = [user_data dataPtr];
            SCManagedPlotColumn * managed_column = (SCManagedPlotColumn *)[data pointerValue];
            int sc_column_dim = [managed_column getDataLengthSinceLastPlot]; 
            data_ptr = [managed_column getDataSinceLastPlot];
            SCColumn * sc_column = [[SCColumn alloc] initColumnWithDataPtr:data_ptr length:sc_column_dim]; // doesn't copy as optimization! :)
            all_data[var_idx] = sc_column;
        }
        break;
        default:
            assert ( 0 );       /* Case not implemented yet. */
        }
        var_idx++;
    }

    
    /* Now set the nsteps_to_simulate worth of data values into the dictionaries to be used by the plotting
     * routines.  */
    NSMutableDictionary *plot_data_block = [[NSMutableDictionary alloc] initWithCapacity:n_vars_to_plot]; /* Auto released, by caller's pool. */

    var_idx = 0;
    for ( NSString * var_name in watchedVariablesByName )
    {
        [plot_data_block setObject:all_data[var_idx] forKey:var_name];
        [all_data[var_idx] release];
        var_idx++;
    }
    
    [pool release];
    
    free ( all_data );
    DebugNSLog(@"max_steps_to_store: %i\n", max_steps_to_store);
    DebugNSLog(@"nStepsStored: %i\n", nStepsStored);
    
    return plot_data_block;
}


- (void) aPlotHappened
{
    for ( NSString * var_name in managedColumnNames )
    {
        SCManagedPlotColumn * managed_column = [managedColumns objectForKey:var_name];
        [managed_column aPlotHappened];
    }
}


- (void)callCleanupAfterPlotDuration
{
    DebugNSLog(@"CleanupAfterPlotDuration start");
    [computeLock lock];
#ifndef _NO_USER_LIBRARY_  
    _CleanupAfterPlotDuration(modelData);
#else
    CleanupAfterPlotDuration(modelData);
#endif
    [computeLock unlock];
    DebugNSLog(@"CleanupAfterPlotDuration end");
}


- (void)callCleanupAfterRun
{
    DebugNSLog(@"CleanupAfterRun start");
    [computeLock lock];
#ifndef _NO_USER_LIBRARY_
    _CleanupAfterRun(modelData);
#else
    CleanupAfterRun(modelData);
#endif
    [computeLock unlock];
    DebugNSLog(@"CleanupAfterRun end");
}


/* Hook into the model's cleanup routine. */
- (void)cleanupSimulation
{
    DebugNSLog(@"cleanupSimulation start");
    [computeLock lock];
#ifndef _NO_USER_LIBRARY_
    _CleanupModel(modelData);
#else
    CleanupModel(modelData);
#endif
    [computeLock unlock];
    DebugNSLog(@"cleanupSimulation start");
}

@end
