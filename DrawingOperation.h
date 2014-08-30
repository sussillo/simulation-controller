#import <Cocoa/Cocoa.h>
 
#import "PlotController.h"
 
@interface DrawingOperation : NSOperation 
{
    BOOL doPlot;                /* Does the user want SC to plot on this iteration?  (Always save the data.) */
    BOOL doClearWatchedColumns;          /* Do we need a new plot before the next drawing?  Optimization to avoid flickering (keep new plot close in time to draw). */
    NSDictionary *plotBlock;
    PlotController *plotController;
}

@property(assign) BOOL doClearWatchedColumns;
@property(assign) BOOL doPlot;
@property(retain) NSDictionary *plotBlock;
@property(retain) PlotController *plotController;

@end


