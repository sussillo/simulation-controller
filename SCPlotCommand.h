#ifndef __SC_PLOT_COMMAND_H
#define __SC_PLOT_COMMAND_H

#import <Foundation/Foundation.h>
#import "SCUserVariable.h"
#import "SCPlotParameters.h"


/* The different types of DG commands that are supported by SC. */
typedef enum
{
    SC_NIL_COMMAND = 0,            /* Just for initialization. */
    SC_SILENT_COMMAND,              /* Used to pass watched variables that aren't plotted to the silent history controller. */
    SC_LINE_COMMAND,               /* will draw a line or a number of lines in a clean (and potentially SLOW way) */
    SC_FAST_LINE_COMMAND,          /* will draw a number of lines (or a single line) in a fast and dirty way */
    SC_POINTS_COMMAND,             /* (clean) same distinction here as for the lines plots.  */
    SC_FAST_POINTS_COMMAND,        /* it'll be fast, but it might not look exactly right  */
    SC_BAR_COMMAND,                /* a good-ol bar plot */
    SC_HISTOGRAM_COMMAND,          /* plot a histogram based on data provided by the user */
    SC_FIT_COMMAND,                /* fit a set of a data with a function */
    SC_SMOOTH_COMMAND,             /* smooth data using a polynomial fit, called LOESS. */
    SC_MULTILINES_COMMAND,         /* Plot multiple lines (e.g. the spikes in a voltage trace of a neuron. */
    SC_AXIS_COMMAND,               /* Add additional axis to a given plot. */
    SC_RANGE_COMMAND,              /* Plot rectangles */
    SC_SCATTER_COMMAND             /* A traditional scatter plot with varying point sizes and colors. */
} SCPlotCommandType;


/* The base class for all of the plot commands tha DG understands. */
@interface SCPlotCommand : NSObject 
{
    SCPlotCommandType commandType;     /* what kind of plot is this (line, fast line, histogram, etc.) ? */
    SCPlotCommandParameters * commandParameters; 
    NSString *plotName;                            /* This is the name of the plot (as in axis or canvas) to which this command belongs. */
    int order;                                     /* What order do the plots display in DG? */
}
@property(assign) SCPlotCommandType commandType;
@property(retain) SCCommandParameters * commandParameters; // I guess this gets the reference counting correct ( by putting a retain ). 
@property(retain) NSString *plotName;
@property(assign) int order;

- (NSArray*)allNames;
- (NSDictionary*)allVariables;   /* Indexed by the variable names. */

@end


@interface SCSilentCommand : SCPlotCommand
{
    NSArray *names;          
    NSDictionary *variables; 
}
@property(retain) NSArray *names;
@property(retain) NSDictionary *variables;

@end


/* Serves for the points plot as well. */
@interface SCLineCommand : SCPlotCommand
{
    NSString *xName;          
    SCUserData *xVariable;    
    NSString *yName;          
    SCUserData *yVariable;    
}
@property(retain) NSString *xName;
@property(retain) SCUserData *xVariable;
@property(retain) NSString *yName;
@property(retain) SCUserData *yVariable;

@end


// The nLines may not be necessary because the NSArray can give a count, or one can simply use fast iteration. -DCS:2009/10/08
/* Serves for the fast points plot as well. */
@interface SCFastLineCommand : SCPlotCommand
{
    NSString *xName;          
    SCUserData *xVariable;    
    int nLines;               /* How many lines are plotted in the corresponding DGPlots command. (Note, not DGPlot). */
    NSArray *yNames;          
    NSDictionary *yVariables; 
}
@property(retain) NSString *xName;
@property(retain) SCUserData *xVariable;
@property(assign) int nLines;
@property(retain) NSArray *yNames;
@property(retain) NSDictionary *yVariables;

@end


@interface SCBarCommand : SCPlotCommand 
{
    NSString * name;       
    SCUserData * variable; 
}
@property(retain) NSString * name;
@property(retain) SCUserData * variable;

@end


@interface SCHistogramCommand : SCPlotCommand
{
    NSString * name;       
    SCUserData * variable; 
}
@property(retain) NSString * name;
@property(retain) SCUserData * variable;

@end


@interface SCFitCommand : SCPlotCommand
{
    NSString *xName;          
    SCUserData *xVariable;    
    NSString *yName;          
    SCUserData *yVariable;    
    NSString *expression;
    NSArray *fitParameterNames;
    NSArray *fitParameterValues;
}
@property(retain) NSString *xName;
@property(retain) SCUserData *xVariable;
@property(retain) NSString *yName;
@property(retain) SCUserData *yVariable;
@property(retain) NSString * expression;
@property(retain) NSArray * fitParameterNames;
@property(retain) NSArray * fitParameterValues;

@end




@interface SCSmoothCommand : SCPlotCommand
{
    NSString *xName;          
    SCUserData *xVariable;    
    NSString *yName;          
    SCUserData *yVariable;    
}
@property(retain) NSString *xName;
@property(retain) SCUserData *xVariable;
@property(retain) NSString *yName;
@property(retain) SCUserData *yVariable;

@end



@interface SCMultiLinesCommand : SCPlotCommand
{
    NSString * linesName;          
    SCUserData * linesVariable;    
    NSString * lowerLimitsName;
    SCUserData * lowerLimitsVariable;
    NSString * upperLimitsName;
    SCUserData * upperLimitsVariable;
    NSString * labelsName;
    SCUserData * labelsVariable;
}
@property(retain) NSString * linesName;
@property(retain) SCUserData * linesVariable;
@property(retain) NSString * lowerLimitsName;
@property(retain) SCUserData * lowerLimitsVariable;
@property(retain) NSString * upperLimitsName;
@property(retain) SCUserData * upperLimitsVariable;
@property(retain) NSString * labelsName;
@property(retain) SCUserData * labelsVariable;

@end



@interface SCAxisCommand : SCPlotCommand
{}
@end



@interface SCRangeCommand : SCPlotCommand
{
    NSString * xMinName;
    SCUserData * xMinVariable;
    NSString * xMaxName;
    SCUserData * xMaxVariable;
    NSString * yMinName;
    SCUserData *yMinVariable;
    NSString * yMaxName;
    SCUserData * yMaxVariable;
    NSString * rangeColorName;
    SCUserData * rangeColorVariable;
    
    NSString * colorSchemeName;
}
@property(retain) NSString * xMinName;
@property(retain) SCUserData * xMinVariable;
@property(retain) NSString * xMaxName;
@property(retain) SCUserData * xMaxVariable;
@property(retain) NSString * yMinName;
@property(retain) SCUserData *yMinVariable;
@property(retain) NSString * yMaxName;
@property(retain) SCUserData * yMaxVariable;
@property(retain) NSString * rangeColorName;
@property(retain) SCUserData * rangeColorVariable;
@property(retain) NSString * colorSchemeName;


@end


@interface SCScatterCommand : SCPlotCommand 
{
    NSString * xName;
    SCUserData * xVariable;
    NSString * yName;
    SCUserData * yVariable;
    NSString * pointSizeName;
    SCUserData * pointSizeVariable;
    NSString * pointColorName;
    SCUserData * pointColorVariable;

    NSString * colorSchemeName;
}
@property(retain) NSString * xName;
@property(retain) SCUserData * xVariable;
@property(retain) NSString * yName;
@property(retain) SCUserData * yVariable;
@property(retain) NSString * pointSizeName;
@property(retain) SCUserData * pointSizeVariable;
@property(retain) NSString * pointColorName;
@property(retain) SCUserData * pointColorVariable;
@property(retain) NSString * colorSchemeName;

@end


#endif
