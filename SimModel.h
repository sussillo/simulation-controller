#import <Foundation/Foundation.h>
#include <sys/time.h>
#import "PlotParameterModel.h"
#import "SimParameterModel.h"
#import "SCUserVariable.h"
#import "SCManagedColumn.h"
#import "SimController.h"

/* Nothing in this file should know anything about simulation controller or plotting in general.  That way, one could
 * potentially dispatch a simulation on a cluster (with some additional controller code) and not have to worry about
 * ripping out all of the plotting routines. */

extern NSString * const SCNotifyModelOfButtonChange;
extern NSString * const SCNotifyModelOfParameterChange;

typedef enum 
{
    SIM_RUNNING = 0,
    SIM_PAUSED,
    SIM_FINISHED
} SimulationStatus;


@class SimController;

@interface SimModel : NSObject 
{
    int nStepsInFullPlot;       /* How many model steps in a full plot? e.g. 500 or 5000? */
    int nStepsBetweenPlotting;   /* How many model steps between storing a plotting point? 5 10 */
    int nStepsBetweenDrawing;   /* How many model steps between drawing steps?  e.g. 5, 10, 50 */
    BOOL doRedrawBasedOnTimer;  /* Let SC figure how often to redraw, or the user? */
    BOOL doRunImmediatelyAfterInit; /* Start without a user press of "Run"? */
    BOOL doOpenInDemoMode;          /* Start with SC in demo mode? the controller panel minimized?  */

    NSLock *computeLock;         // Test to see if this is fast enough.
    SimParameterModel *simParameterModel; /* Hold the parameters that a user may want to a vary as the simulation goes forward. */
    void * modelData;

    NSMutableArray *plotNames;                /* names of all the plots the user wants plotted. */
    NSMutableDictionary *axisParametersByPlotName; /* AxisParameterModels indexed by plot name. */
    NSMutableDictionary *windowParametersByPlotName;
    NSMutableDictionary *commandsByPlotName; /* contains arrays of variable names & parameters for plot commands, indexed by plotname */
    NSMutableDictionary *clearMakeNowPlotsByPlotName; // potentially starting a new class data type regarding per-plot SC configuration (not DG). 
    NSMutableDictionary *colorSchemesByPlotName;      /* A dictionary (keyed by plotname) of dictionaries (keyed by color scheme name). */

    NSMutableSet * variableNames;               /* all variable names used in the simulation */
    NSMutableDictionary * variableArrayNames;            /* since we have arrays as var0... var9, but the user specifies var, we need to keep track */
    NSMutableSet * columnNames;                          /* Keep a set of the column variable names for error checking. */
    NSMutableSet * staticColumnNames;                    /* A list of all the static / nonwatched columns. */
    NSMutableDictionary * staticColumns;                 /* The actual SCColumns for the static data storage. */
    NSMutableSet * expressionNames;                      /* Keep a s set of all the expressions. */
    NSMutableSet * managedColumnNames;                   /* Keep a set of the managed column variables names. */
    NSMutableDictionary * managedColumns;                /* The actual SCManagedColumsn for the managed data storage. */
    NSMutableSet * colorSchemeNames; /* Keep a list of all the color schemes that are added to the mix. */

    /* pointers to the variable info (SCUserData), including the watched values (double*) indexed by variable name (for
     * all plots) */
    NSMutableDictionary *userVariablesByName; /* All user data for all user defined columns. */
    NSMutableDictionary *watchedVariablesByName; /* All user data for only watched columns. */
    //NSMutableDictionary *colorSchemesByName;

    NSMutableDictionary *plotNamesByWatchedVariableName; /* A dictionary of sets used to keep track of which plots a watched variable ended up in. */
    
    BOOL isPhaseOne;            /* This is the phase when users can add addwatchedvarible type commands.  */
    BOOL isPhaseTwo;            /* This is the phase when the simulation is running.  No more configuration type commands */
    BOOL doPlotInParallel;

    int nStepsStored;             /* When running in timing mode, used to allocated memory based on the last compute. */
    SimController *simController; /* For the make now plots. */
}


-(NSArray *)commandsByPlotName:(NSString *)plot_name;
-(NSDictionary *)colorSchemesByPlotName:(NSString *)plot_name;
-(DefaultAxisParameters *)axisParametersByPlotName:(NSString *)plot_name;

-(BOOL)getDoClearMakeNowPlotsByName:(NSString *)plot_name;

- (void)initSimulation;
- (void)cleanupSimulation;

-(void)addPlot:(NSString *)plot_name doDeleteMakeNowPlots:(BOOL)do_delete_makenowplots_after_duration;
-(void)addAxisToPlot:(NSString *)plot_name axisParameters:(SCAxisParameters *)axis_parameters;
-(void)clearMakeNowPlots:(NSString *)plot_name;

-(void) addStaticColumn:(NSString *)col_name dataPtr:(double *)data_ptr length:(int)length;
-(void) addWatchedVariable:(NSString *)var_name dataPtr:(double *)data_ptr dataHoldType:(SCDataHoldType)data_hold_type;
-(void) addWatchedVariableArray:(NSString *)var_array_name dataPtr:(double *)data_ptr length:(int)length 
                  dataHoldType:(SCDataHoldType)data_hold_type;
-(void) addWatchedColumnVariable:(NSString*)var_name dataPtr:(double *)data_ptr length:(int)length;


-(void) addColorSchemeToPlot:(NSString *)plot_name
             colorSchemeName:(NSString *)color_scheme_name
                  rangeTypes:(NSArray *)range_types
                 rangeStarts:(NSArray *)range_starts
                  rangeStops:(NSArray *)range_stops
                 rangeColors:(NSArray *)range_colors;

-(void) addManagedColumnVariable:(NSString*)var_name 
        doClearAfterPlotDuration:(BOOL)do_clear_after_plot_duration 
                        sizeHint:(int)size_hint;

-(void) addManagedColumnVariables:(NSString*)var_name_prefix 
                         nColumns:(int)ncolumns 
         doClearAfterPlotDuration:(BOOL)do_clear_after_plot_duration 
                         sizeHint:(int)size_hint;

-(void) addDataToManagedColumn:(NSString *)var_name newData:(double*)new_data length:(int)length;

-(void) copyDataFromManagedColumn:(NSString *)var_name 
                       dataPtrPtr:(double **)data_ptr_ptr 
                       nValuesPtr:(int *)nvalues_ptr;


-(void) copyDataFromHistoryWithIndex:(NSString *)var_name 
                          historyIdx:(int)history_idx 
                         sampleEvery:(int)sample_every
                          dataPtrPtr:(double **)data_ptr_ptr 
                          nValuesPtr:(int *)nvalues_ptr;

-(void) copyFlatDataFromHistories:(NSString *)var_name
                  historyStartIdx:(int)history_start_idx 
                   historyStopIdx:(int)history_stop_idx
                      sampleEvery:(int)sample_every
                      dataPtrPtr:(double **)data_ptr_ptr 
                      nValuesPtr:(int *)nvalues_ptr;

-(void) copyFlatDataFromHistoriesForColumns:(NSString *)var_name_prefix_ns 
                                varStartIdx:(int)var_start_idx
                                 varStopIdx:(int)var_stop_idx
                            historyStartIdx:(int)history_start_idx
                             historyStopIdx:(int)history_stop_idx 
                                sampleEvery:(int)sample_every
                              dataPtrPtrPtr:(double ***)data_ptr_ptr_ptr 
                              nValuesPtrPtr:(int **)nvalues_ptr_ptr;

-(void) copyStructuredDataFromHistories:(NSString *)var_name 
                        historyStartIdx:(int)history_start_idx 
                         historyStopIdx:(int)history_stop_idx
                           sampleEvery:(int)sample_every
                             dataPtrPtrPtr:(double ***)data_ptr_ptr_ptr
                             nValuesPtrPtr:(int **)nvalues_ptr_ptr;

-(void) clearDataInManagedColumn:(NSString *)var_name; /* Called from user side. */
-(void) clearDataInManagedColumnsWithVarNamePrefix:(NSString *)var_name_prefix nColumns:(int)ncolumns; /* Called from user side. */
-(void) clearDataInManagedColumns:(BOOL)is_end_of_plot_duration; /* All columns, called from SimController. */

-(void) addExpressionVariable:(NSString *)var_name 
                   expression:(NSString *)expression;


-(void)addVariablesToFastTimeLinePlotByName:(NSString *)plot_name 
                                   xVarName:(NSString *)x_var_name 
                                   yVarName:(NSString*)y_var_name 
                     fastLinePlotParameters:(SCTimePlotParameters*)fast_line_plot_parameters;


-(void)addVariablesToLinePlotByName:(NSString *)plot_name 
                           xVarName:(NSString *)x_var_name 
                           yVarName:(NSString *)y_var_name
                 linePlotParameters:(SCPlotParameters*)line_plot_parameters;

-(void)addVariablesToBarPlotByName:(NSString *)plot_name 
                           varName:(NSString *)var_name                  
                 barPlotParameters:(SCBarPlotParameters*)bar_plot_parameters;

-(void)addVariablesToHistogramPlotByName:(NSString *)plot_name 
                                 varName:(NSString *)var_name                  
                 histogramPlotParameters:(SCHistogramPlotParameters*)histogram_plot_parameters;

-(void)addVarsToFit:(NSString *)plot_name
              xName:(NSString *)x_var_name
              yName:(NSString *)y_var_name
         expression:(NSString *)expression
     parameterNames:(NSArray *)param_names
    parameterValues:(NSArray *)param_values
  fitPlotParameters:(SCFitPlotParameters *)fpp;


-(void)addVarsToSmooth:(NSString *)plot_name
                 xName:(NSString *)x_var_name
                 yName:(NSString *)y_var_name
  smoothPlotParameters:(SCSmoothPlotParameters*)smooth_plot_parameters;

-(void)makeLinePlotNow:(NSString *)plot_name 
                 xName:(NSString *)x_name 
                 yName:(NSString *)y_var_name 
                 xData:(double *)x_var_data 
                 yData:(double *)y_data 
            dataLength:(int)data_length 
    linePlotParameters:(SCPlotParameters*)line_plot_parameters 
            orderIndex:(int)order_index;

-(void) makeLinePlotNowFMC:(NSString *)plot_name
                     xName:(NSString *)x_var_name
                     yName:(NSString *)y_var_name
                  xMCName:(NSString *)x_mc_name
                  yMCName:(NSString *)y_mc_name
        linePlotParameters:(SCPlotParameters *)line_plot_parameters
                orderIndex:(int)order;

-(void) makeBarPlotNow:(NSString *)plot_name 
                  name:(NSString *)var_name 
                  data:(double *)data 
            dataLength:(int)data_length 
     barPlotParameters:(SCBarPlotParameters*)bar_plot_parameters 
            orderIndex:(int)order_index;

-(void) makeBarPlotNowFMC:(NSString *)plot_name
                     name:(NSString *)var_name
                   MCName:(NSString *)mc_name
        barPlotParameters:(SCBarPlotParameters *)bar_plot_parameters
               orderIndex:(int)order;

-(void) makeHistogramPlotNow:(NSString *)plot_name 
                       name:(NSString *)var_name 
                       data:(double *)data dataLength:(int)data_length 
    histogramPlotParameters:(SCHistogramPlotParameters*)histogram_plot_parameters 
                 orderIndex:(int)order_index;

-(void) makeHistogramPlotNowFMC:(NSString *)plot_name
                           name:(NSString *)var_name
                         MCName:(NSString *)mc_name
        histogramPlotParameters:(SCHistogramPlotParameters*)hpp
                     orderIndex:(int)order;

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
        orderIndex:(int)order_index;

-(void) makeFitNowFMC:(NSString *)plot_name
                xName:(NSString *)x_var_name
                yName:(NSString *)y_var_name
              xMCName:(NSString *)x_mc_name
              yMCName:(NSString *)y_mc_name
           expression:(NSString *)expression
       parameterNames:(NSArray *)param_names
      parameterValues:(NSArray *)param_values                           
    fitPlotParameters:(SCFitPlotParameters*)fit_plot_parameters
           orderIndex:(int)order;


-(void) makeSmoothNow:(NSString *)plot_name
                xName:(NSString *)x_var_name
                yName:(NSString *)y_var_name
                xData:(double *)x_data
                yData:(double *)y_data
           dataLength:(int)data_length
 smoothPlotParameters:(SCSmoothPlotParameters*)smooth_plot_parameters
           orderIndex:(int)order;

-(void) makeSmoothNowFMC:(NSString *)plot_name
                   xName:(NSString *)x_var_name
                   yName:(NSString *)y_var_name
                 xMCName:(NSString *)x_mc_name
                 yMCName:(NSString *)y_mc_name
    smoothPlotParameters:(SCSmoothPlotParameters *)spp
              orderIndex:(int)order;



-(void) addVarsToMultiLines:(NSString *)plot_name
               linesVarName:(NSString *)lines_var_name
         lowerLimitsVarName:(NSString *)lower_limits_var_name
         upperLimitsVarName:(NSString *)upper_limits_var_name
              labelsVarName:(NSString *)labels_var_name
   multiLinesPlotParameters:(SCMultiLinesPlotParameters*)mlpp;


-(void) makeMultLinesNow:(NSString *)plot_name
            linesVarName:(NSString *)lines_var_name
      lowerLimitsVarName:(NSString *)lower_limits_name
      upperLimitsVarName:(NSString *)upper_limits_name
           labelsVarName:(NSString *)labels_name
               linesData:(double *)lines_data
         lowerLimitsData:(double *)lower_limits_data
         upperLimitsData:(double *)upper_limits_data
              labelsData:(double *)labels_data
              dataLength:(int)data_length
multiLinesPlotParameters:(SCMultiLinesPlotParameters*)mlpp
              orderIndex:(int)order;


-(void) makeRangeNow:(NSString *)plot_name
            xMinName:(NSString *)x_min_name
            xMaxName:(NSString *)x_max_name
            yMinName:(NSString *)y_min_name
            yMaxName:(NSString *)y_max_name
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

-(void) addVarsToRange:(NSString *)plot_name
           xMinVarName:(NSString *)x_min_var_name
           xMaxVarName:(NSString *)x_max_var_name
           yMinVarName:(NSString *)y_min_var_name
           yMaxVarName:(NSString *)y_max_var_name
     rangeColorVarName:(NSString *)range_color_var_name
       colorSchemeName:(NSString *)color_scheme_name
   rangePlotParameters:(SCRangePlotParameters *)rpp;


-(void) addVarsToScatter:(NSString *)plot_name
                xVarName:(NSString *)x_var_name
                yVarName:(NSString *)y_var_name
           pointSizeName:(NSString *)point_size_var_name
          pointColorName:(NSString *)point_color_var_name
         colorSchemeName:(NSString *)color_scheme_name
   scatterPlotParameters:(SCScatterPlotParameters *)spp;


-(void) makeScatterNow:(NSString *)plot_name
                 xVarName:(NSString *)x_var_name
                 yVarName:(NSString *)y_var_name
         pointSizeName:(NSString *)point_size_name
        pointColorName:(NSString *)point_color_name
                 xData:(double *)x_data
                 yData:(double *)y_data
         pointSizeData:(double *)point_size_data
        pointColorData:(double *)point_color_data
            dataLength:(int)data_length
       colorSchemeName:(NSString *)color_scheme_name_ns
 scatterPlotParameters:(SCScatterPlotParameters *)spp
            orderIndex:(int)order;


-(void)addWindowDataToPlotByName:(NSString *)plot_name rect:(NSRect)rect_;

-(void)addControllableParameter:(NSString*)param_name 
                       minValue:(double)min_value 
                       maxValue:(double)max_value 
                      initValue:(double)init_value;
-(void)addControllableButton:(NSString*)button_name 
                   initValue:(BOOL)init_value 
                    offLabel:(NSString*)off_label 
                     onLabel:(NSString *)on_label;

-(void)writeTextToConsole:(NSString*)text;
-(void)writeAttributedTextToConsole:(NSString*)text textColor:(NSColor *)color textSize:(int)size;
-(void)writeWarningToConsole:(NSString*)text;

/* These methods are related to what the model has might have to do both before and after a plot duration.  Since the
 * code that loops through the plot duration is in SimController, we have to expose these calls this way.  Otherwise,
 * we'd have controller calls in the simmodel code.  No way is really that abstract, but this seems better since the
 * SimulationController already knows about the SimModel and the concept of a plot duration.  */
- (void)callInitForRun;
- (void)callInitForPlotDuration;
- (void)callCleanupAfterPlotDuration;
- (void)callCleanupAfterRun;

- (void) aPlotHappened;         /* managed variables need to know this, which is communicated from the simulation controller. */

@property(assign) BOOL doPlotInParallel;
@property(assign) SimController *simController;
@property(retain) NSLock *computeLock;
@property(assign) int nStepsInFullPlot;
@property(assign) int nStepsBetweenPlotting;
@property(assign) int nStepsBetweenDrawing;
@property(assign) BOOL doRedrawBasedOnTimer;
@property(assign) BOOL doRunImmediatelyAfterInit;
@property(assign) BOOL doOpenInDemoMode;

@property(assign) NSMutableDictionary * windowParametersByPlotName;

@property(readonly) NSArray *plotNames;  // what are the copy semantics for the getters? -DCS:2009/05/12
@property(readonly) NSSet *variableNames;
@property(readwrite, assign) SimParameterModel *simParameterModel;


-(NSDictionary*) runModelForNSteps:(int)nsteps;
-(NSDictionary*) runModelAmountOfTime:(double)time_in_ms currentIteration:(int*)current_iteration; // Sets value of current_iteration

@end
