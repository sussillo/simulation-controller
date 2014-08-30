#import <Cocoa/Cocoa.h>

#include <DataGraph/DataGraph.h>

#import "SimController.h"
#import "ParametersController.h"
#import "SimModel.h"
#import "SCDocumentController.h"
#import "LockingButton.h"
#import "LockingSlider.h"
#import "SCPlotCommand.h"

// Where does SimController get initiated?  Should I create a constructor for the object, and if so, will it actually
// get called? -DCS:2009/05/01

typedef enum
{
    SC_CONTROLLER_EXPERIMENTAL_MODE = 0,
    SC_CONTROLLER_DEMONSTRATION_MODE
} SCControllerDisplayMode;


extern NSString * const SCWriteToControllerConsoleNotification;
extern NSString * const SCWriteToControllerConsoleAttributedNotification;
extern NSString * const SCSilentHistoryControllerName;

@class SimModel;

@interface SimController : NSWindowController 
{
    IBOutlet id runButton;
    IBOutlet id plotButton;
    IBOutlet id parametersButton;

    IBOutlet id saveConsoleButton;
    IBOutlet id clearConsoleButton;

    IBOutlet id controllerConsole;
    IBOutlet id controllerConsoleScroller;
    float scrollerLocation;
    
    /* These outlets are necessary to save the compute lock to the object.  Otherwise, all the action happens through
     * KVC bindings in the NIB. */
    IBOutlet LockingSlider* parameter1;
    IBOutlet LockingSlider* parameter2;
    IBOutlet LockingSlider* parameter3;
    IBOutlet LockingSlider* parameter4;
    IBOutlet LockingSlider* parameter5;
    IBOutlet LockingSlider* parameter6;
    IBOutlet LockingSlider* parameter7;
    IBOutlet LockingSlider* parameter8;
    IBOutlet LockingButton* button1;
    IBOutlet LockingButton* button2;
    IBOutlet LockingButton* button3;
    IBOutlet LockingButton* button4;
    IBOutlet LockingButton* button5;
    IBOutlet LockingButton* button6;
    IBOutlet LockingButton* button7;
    IBOutlet LockingButton* button8;
    IBOutlet LockingButton* button9;
    IBOutlet LockingButton* button10;

    IBOutlet LockingButton* buttonSliderUp1;
    IBOutlet LockingButton* buttonSliderUp2;
    IBOutlet LockingButton* buttonSliderUp3;
    IBOutlet LockingButton* buttonSliderUp4;
    IBOutlet LockingButton* buttonSliderUp5;
    IBOutlet LockingButton* buttonSliderUp6;
    IBOutlet LockingButton* buttonSliderUp7;
    IBOutlet LockingButton* buttonSliderUp8;
    IBOutlet LockingButton* buttonSliderDown1;
    IBOutlet LockingButton* buttonSliderDown2;
    IBOutlet LockingButton* buttonSliderDown3;
    IBOutlet LockingButton* buttonSliderDown4;
    IBOutlet LockingButton* buttonSliderDown5;
    IBOutlet LockingButton* buttonSliderDown6;
    IBOutlet LockingButton* buttonSliderDown7;
    IBOutlet LockingButton* buttonSliderDown8;

    IBOutlet LockingButton* buttonAllSlidersDown;
    IBOutlet LockingButton* buttonAllSlidersUp;
    IBOutlet LockingSlider *sliderAllHistories;
    IBOutlet NSTextField *sliderAllHistoriesValue;
    IBOutlet NSTextField *buttonAllSlidersDownValue;
    IBOutlet NSTextField *buttonAllSlidersUpValue;

    NSLock *historySliderLock;

    NSLock *consoleLock;
    

    NSWindow *simulationControllerWindow;
    
    /* All the variables, etc. that are encapsulated in the simulation.  */
    SimModel * simModel;
    
    NSLock *computeLock;         // Test to see if this is fast enough.
    SCDocumentController* documentController;
    NSMutableDictionary* plotControllers; /* of plotcontroller objects. */
    ParametersController *parametersController; /* open the parameters window. */
    
    /* Variables related to plotting, or setting window size, or computational efficiency, etc. */
    int nCores;
    BOOL simIsRunning;
    double screenHeight;
    double screenWidth;
    BOOL doPlot;
    SCControllerDisplayMode displayMode; /* demo or experimentation. */
    
    
    int nHistories;             /* The number of histories that have been added. */
    int fullPlotIter;           /* How many full plots have we done. */
    int iterThroughCurrentPlot;        /* How many plot chunks in the CURRENT plot have we done? */

    NSNumber * fontSize;
    NSNumber * buttonFontSize;

    int maxHistoryCount;        /* How many histories should we hold onto? */
}

@property(readwrite, assign) NSNumber* fontSize;
@property(readwrite, assign) NSNumber* buttonFontSize;
@property(assign) BOOL doPlot;
@property(assign) NSLock *computeLock;
@property(assign) double screenWidth;
@property(readwrite, assign) SimModel *simModel;
@property(readwrite, assign) ParametersController *parametersController;
@property(assign) int maxHistoryCount;

@property(assign) LockingSlider* parameter1; /* KVC */
@property(assign) LockingSlider* parameter2;
@property(assign) LockingSlider* parameter3;
@property(assign) LockingSlider* parameter4;
@property(assign) LockingSlider* parameter5;
@property(assign) LockingSlider* parameter6;
@property(assign) LockingSlider* parameter7;
@property(assign) LockingSlider* parameter8;


@property(assign) LockingButton* button1; /* KVC */
@property(assign) LockingButton* button2; /* KVC */
@property(assign) LockingButton* button3; /* KVC */
@property(assign) LockingButton* button4; /* KVC */
@property(assign) LockingButton* button5; /* KVC */
@property(assign) LockingButton* button6; /* KVC */
@property(assign) LockingButton* button7; /* KVC */
@property(assign) LockingButton* button8; /* KVC */
@property(assign) LockingButton* button9; /* KVC */
@property(assign) LockingButton* button10; /* KVC */


-(void) copyDataFromPlot:(NSString *)plot_name
             forVariable:(NSString *)var_name 
              historyIdx:(int)history_idx
             sampleEvery:(int)sample_every
              dataPtrPtr:(double**)data_ptr_ptr
              nValuesPtr:(int *)nvalues_ptr;

-(void) copyFlatDataFromPlot:(NSString *)plot_name
                 forVariable:(NSString *)var_name 
             historyStartIdx:(int)history_start_idx 
              historyStopIdx:(int)history_stop_idx
                 sampleEvery:(int)sample_every
                  dataPtrPtr:(double **)data_ptr_ptr
                  nValuesPtr:(int *)nvalues_ptr;    

-(void) copyStructuredDataFromPlot:(NSString *)plot_name
                       forVariable:(NSString *)var_name 
                   historyStartIdx:(int)history_start_idx 
                    historyStopIdx:(int)history_stop_idx
                       sampleEvery:(int)sample_every
                     dataPtrPtrPtr:(double ***)data_ptr_ptr_ptr
                     nValuesPtrPtr:(int **)nvalues_ptr_ptr;    


- (void) drawMakeNowCommand:(SCPlotCommand *)plot_command; // Used by SimModel for passing down the make now commands.  -DCS:2009/11/02
- (void) clearMakeNowPlots:(NSString *)plot_name;         // **

- (void) clearAllPlotHistoriesOfVariable:(NSString *)var_name;

- (void)setDocumentController:(SCDocumentController *)dc;

- (void) loadPlots;


- (void)stopRunning;

- (IBAction) pushClearConsole:(id)sender;
- (IBAction) pushParameters:(id)sender;

- (IBAction) pushRun:(id)sender;
- (IBAction) toggleRun:(id)sender;

- (IBAction) pushPlot:(id)sender;
- (IBAction) togglePlot:(id)sender;

- (IBAction) pushSaveConsole:(id)sender;
- (IBAction) toggleDisplayMode:(id)sender;

/* These actions are necessary to signal the model that a button has been pushed and we call the ButtonAction function.
 * All of the logic of what happens to the value of the button model is accomplished through KVC compliant bindings in
 * the NIB. */
- (IBAction) pushButton1:(id)sender;
- (IBAction) toggleButton1:(id)sender;

- (IBAction) pushButton2:(id)sender;
- (IBAction) toggleButton2:(id)sender;

- (IBAction) pushButton3:(id)sender;
- (IBAction) toggleButton3:(id)sender;

- (IBAction) pushButton4:(id)sender;
- (IBAction) toggleButton4:(id)sender;

- (IBAction) pushButton5:(id)sender;
- (IBAction) toggleButton5:(id)sender;

- (IBAction) pushButton6:(id)sender;
- (IBAction) toggleButton6:(id)sender;

- (IBAction) pushButton7:(id)sender;
- (IBAction) toggleButton7:(id)sender;

- (IBAction) pushButton8:(id)sender;
- (IBAction) toggleButton8:(id)sender;

- (IBAction) pushButton9:(id)sender;
- (IBAction) toggleButton9:(id)sender;

- (IBAction) pushButton10:(id)sender;
- (IBAction) toggleButton10:(id)sender;

- (IBAction) pushAllSlidersUp:(id)sender;
- (IBAction) pushAllSlidersDown:(id)sender;
- (IBAction) pushAllSlidersUpExternal:(id)sender;
- (IBAction) pushAllSlidersDownExternal:(id)sender;

- (IBAction) touchedSlider1:(id)sender;
- (IBAction) touchedSlider2:(id)sender;
- (IBAction) touchedSlider3:(id)sender;
- (IBAction) touchedSlider4:(id)sender;
- (IBAction) touchedSlider5:(id)sender;
- (IBAction) touchedSlider6:(id)sender;
- (IBAction) touchedSlider7:(id)sender;
- (IBAction) touchedSlider8:(id)sender;

- (IBAction) pushSliderUp1:(id)sender;
- (IBAction) pushSliderUp2:(id)sender;
- (IBAction) pushSliderUp3:(id)sender;
- (IBAction) pushSliderUp4:(id)sender;
- (IBAction) pushSliderUp5:(id)sender;
- (IBAction) pushSliderUp6:(id)sender;
- (IBAction) pushSliderUp7:(id)sender;
- (IBAction) pushSliderUp8:(id)sender;

- (IBAction) pushSliderDown1:(id)sender;
- (IBAction) pushSliderDown2:(id)sender;
- (IBAction) pushSliderDown3:(id)sender;
- (IBAction) pushSliderDown4:(id)sender;
- (IBAction) pushSliderDown5:(id)sender;
- (IBAction) pushSliderDown6:(id)sender;
- (IBAction) pushSliderDown7:(id)sender;
- (IBAction) pushSliderDown8:(id)sender;


- (IBAction) historySliderChanged:(id)arg;


- (void) writeStatusToConsole:(NSString*)text;
- (void) writeWarningToConsole:(NSString*)text;


- (void) checkSimModel;


@end
