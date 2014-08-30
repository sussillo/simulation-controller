
#import <Cocoa/Cocoa.h>
#import <DataGraph/DataGraph.h>

#import "SCPlotCommand.h"
#import "SimController.h"

// Should PlotController really be MyDocument? -DCS:2009/05/17 MyDocument contains the window controller, which contains
// the history controller. Since the history controller holds the "document data" (i.e. the plot), this surely can't be
// a correct abstraction.  My gut tells me that there are really multiple kinds of documents, plot controllers (no
// history) and history controllers.  The data resides then in these classes (plus the plot parameters, I guess.)  In
// this way I would be able to save and load previous experiments using the documen-based application architecture,
// which has so much of this already set up.

@interface PlotController : NSObject 
{
    IBOutlet DGController *drawController;
    NSString *plotName;

    int nPointsToSave;               /* We know beforehand for time columns how much data we'll have to store.  Set in SimController.  */
    NSMutableSet *variableNames;     /* the names of the data for this plot. It's a set so checking for duplicates happens automatically. */
    NSMutableDictionary *variableData; /* The specific details about the variables, dimensions, etc. */
    NSMutableSet *watchedVariableNames; /* all variables except for expressions and make now columns. */
    NSArray *plotCommandDataList;    /* an array of SCPlotCommands.  This is used to create the commands in DG. */
    NSDictionary *colorSchemesByName;      /* a dictionary of SCPlotCommands color schemes keyed by the color_scheme name.  */
    NSMutableDictionary *colorSchemesDGByName; /* a dictionary of DGColorSchemes keyed by the color_scheme name.  */
    DefaultAxisParameters* defaultAxisParameters; /* hold it's own version, even if it comes from the simmmodel originally. */
    NSMutableArray *additionalXAxisParameters; /* An array of the SCPlotCommands that are additional X axis. */
    NSMutableArray *additionalYAxisParameters; /* An array of the SCPlotCommands that are additional Y axis . */

    /* The various types of columns. */
    NSMutableDictionary *columnsOfWatchedVarsByName; /* dictionary of DGDataColumns that were added for watched columns */
    NSDictionary *columnsAllVarsByName;       /* All watched and expression columns (not make now commands). */

    /* A dictionary of columns.  These aren't indexed by history index because they are created and destroyed for each now
     * plot in the history.  So we only need a list of the current ones, which correspond to the array of plot
     * commands in plotNowCommandDataByHistoryIdx for the relevant history index. */
    NSMutableDictionary * plotNowDGColumns;
    NSMutableArray * plotNowDGCommands;

    NSDictionary *latestPlotChunk; // chunk of plot data, I'm not sure it needs to be a class variable. -DCS:2009/10/06

    BOOL doClearPlotNowCommandsAfterEachDuration; /* Should the system keep or delete the make now commands after each plot duration is finished? */
    BOOL doClearWatchedColumnsOnNextDraw; /* An optimization to avoid flicker.  Set in addNewPlot, used in drawPlot. */

    NSLock *computeLock;         /* Stop sim when switching histories. */
    NSWindow *docWindow;        /* pointer to the window for this plot */


    /* These may end up in another simultaion model class.  But for now, they go here. -DCS:2009/05/04 */
    BOOL loupeIsOn;             /* show the magnification loop */
    DGCommand * legendCommand;
    DGMagnifyCommand *** magnifyCommands;

    /* Should we plot the controllers in parallel?  Even though each plot controller is responsible for only it's own
     * plot, this makes a decision to plot in the main thread or not.  If the user wants parallel plotting, then the
     * plotting doesn't happen in the main thread. */
    BOOL doPlotInMainThread;      
    BOOL doPlot;                /* should we plot at all? (yes, by default) */
}

@property(assign) BOOL doPlotInMainThread;
@property(assign) int nPointsToSave;
@property(retain) NSLock *computeLock;
@property(copy) DefaultAxisParameters *defaultAxisParameters;
@property(copy) NSString *plotName;
@property(retain) NSWindow *docWindow;
@property(assign) BOOL doClearPlotNowCommandsAfterEachDuration;


//- (void)setPlotCommandDataList:(NSArray *)plot_command_data_list;
-(void) setPlotCommandDataList:(NSArray *)plot_command_data_list;
-(void) setColorSchemes:(NSDictionary *)color_scheme_dict;

-(void) getVariableInfoFromPlotCommand:(NSArray *)plot_command_list variableNames:(NSMutableSet *)variable_names 
                   watchedVariableNames:(NSMutableSet*)watched_variable_names variableData:(NSMutableDictionary *)variable_data;

-(void) buildPlotCommand;

/* Hook to allow plot controllers to set up for the run. */
-(void) prepPlotForRun:(id)arg;
-(void) addNewPlot:(id)arg;
-(void) clearPlotOfMakeNowPlots;

/* External */
-(void) drawPlot:(NSDictionary *)arg; // all of above are now in dictionary -DCS:2009/09/16

/* Internal */
-(void) drawCompletePlot:(NSDictionary *)plot plotNowCommands:(NSArray*)plot_now_data;
-(void) drawIncrementalPlot;
                                    

/* This is a hook that provide plot controllers an entry point to cleaning up (or whatever they do) after a full plot
 * duration. */
-(void) plotDurationFinished:(id)arg;
/* Hook to provide an entry for plot controllers to clean up (or do whatever) when the simulation stops. */
-(void) simulationStopped:(id)arg;

-(void) addDGColumn:(NSDictionary *)variable_data alreadyAdded:(NSMutableSet *)already_added
         theColumns:(NSMutableDictionary *)the_columns;

/* This is for adding plot commands on the fly. */
-(void) addMakePlotNowCommand:(SCPlotCommand*)plot_command;
-(void) addMakePlotNowCommandInternal:(SCPlotCommand *)plot_command;
-(void) removePlotNowDGColumnsAndCommands;

-(void) clearWatchedColumnsFromDG:(id)arg;
-(void) clearCurrentValuesForVariable:(NSString *)var_name;

@end


