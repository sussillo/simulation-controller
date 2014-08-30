/* HistoryController */

#import <Cocoa/Cocoa.h>

#import "LockingButton.h"
#import "LockingSlider.h"
#import "PlotController.h"

/* The need has arisen to have a HistoryModel, if you will, divorced from the UI appartus.  Unfortunately, this can't be
 * done because of the implicit tie in this class.  There are IBOutlets and IBActions intermixed with the model.  Now
 * I'll know for the future that these two shouldn't interact.  -DCS:2010/01/21*/
@interface HistoryController : PlotController
{
    IBOutlet LockingSlider *slider;
    IBOutlet NSTextField *sliderValue;
    IBOutlet LockingButton *sliderUp;
    IBOutlet LockingButton *sliderDown;
    IBOutlet NSForm *saveIndicesView;
    
    // Array of states
    NSLock *stateLock;
    /* This keeps the plots for the entire slider history, each element is a full plot dictionary indexed by variable.
     * an array of dictionaries indexed by variable name, keyed to DTContainerForDoubleArray objects.  */
    NSMutableArray *historyPlotData; 
    int maxHistoryCount;        /* How many histories should we hold onto? */
    int totalPlotCount;      /* Keep track of how many plots the controller has gone through. */

    NSString * lastDirectory; /* The last directory the user tried to navigate to. */

    /* An array of arrays of plot command datas (a dictionary). These are the plots the user wanted to draw right
     * then and there, instead of the watched array setup. */
    NSMutableArray * plotNowCommandData;

    /* A special case for 0 maxHistoryCount. We still have to save one history for guessing about sizes and plot now commands.*/
    NSMutableDictionary * historyOfLastPlot;
    NSMutableArray * lastPlotNowData;
    
    /* Since make now plots can be added in parameter action and button action, we need to increment to number of plots
     * only after the first plot is complete. */
    BOOL isFirstPlot;              
    BOOL lastPlotUpdateWasPlotted; /* Used to keep track of the whether we need an incremental or full plot, based on the plot button. */
    BOOL isPlottingHistoryController; /* One history controller doesn't plot and keeps track of all the variables that aren't in plots. */
}

@property(assign) int maxHistoryCount;
@property(assign) BOOL isPlottingHistoryController;

/* NO is error, YES is OK. */
- (BOOL) copyDataForVariable:(NSString *)var_name 
                  historyIdx:(int)history_idx 
                 sampleEvery:(int)sample_every
                  dataPtrPtr:(double**)data_ptr_ptr 
                  nValuesPtr:(int *)nvalues_ptr;

- (BOOL) copyFlatDataForVariable:(NSString *)var_name                   
                 historyStartIdx:(int)history_start_idx 
                  historyStopIdx:(int)history_stop_idx
                     sampleEvery:(int)sample_every
                      dataPtrPtr:(double**)data_ptr_ptr 
                      nValuesPtr:(int *)nvalues_ptr;

- (BOOL) copyStructuredDataForVariable:(NSString *)var_name 
                       historyStartIdx:(int)history_start_idx 
                        historyStopIdx:(int)history_stop_idx
                           sampleEvery:(int)sample_every
                         dataPtrPtrPtr:(double ***)data_ptr_ptr_ptr 
                         nValuesPtrPtr:(int **)nvalues_ptr_ptr; 

- (void) updateGraphic:(BOOL)needs_complete_redraw;
- (void) changeSliderToValue:(int)slider_value;
- (void) addMakePlotNowCommand:(SCPlotCommand *)plot_command doPlot:(BOOL)do_plot;
                                                                          


//- (IBAction)startRunning:(id)sender;

@end
