#ifndef __SCPLOT_PARAMETERS_H
#define __SCPLOT_PARAMETERS_H

// Notes to myself... -DCS:2009/10/21
// 
// minimize and use menu to get them back 
// readout of window locations.  
// The parameters window really needs to be modal.  If the user clicks on a graph UI element, a deadlock can happen.
//
//#import <DataGraph/DataGraph.h>
#import <DataGraph/DGPlotsCommandConstants.h>
#import <DataGraph/DGCommandConstants.h>
#import <DataGraph/DGAxisCommandConstants.h>
#import <DataGraph/DGCanvasCommandConstants.h>
#import <DataGraph/DGRangeCommandConstants.h>
#import <DataGraph/DGPointsCommandConstants.h>

extern int SC_LAST_IN_ORDER;

/* CGFloat is a mac os type that is a float in 32 bit applications and a double in 64 bit applications. */
typedef struct SCColorType
{
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;                /* 0 is totally transparent, 1 is totally opaque. */
} SCColor;
 
typedef SCColor colorStruct;    /* let peeps use the old name. */


/* These top three type variables are used for time plots and fast time plots. It's a question of how much data you want
 * to hold onto (effectivey see in the plots) during a plot duration. */
typedef enum 
{
    /* These top three are used with time columns. */
    SC_KEEP_DURATION = 0,       /* the default - save the variable data for the entire duration of the plot  (see the whole line) */
    SC_KEEP_PLOT_POINT,         /* literally hold onto only the last plot point (see a moving point) */
    SC_KEEP_REDRAW,              /* since one can have a couple of points per redraw, (see only a plot chunk's worth, like a moving worm) */

    /* BELOW, INTERNAL USE ONLY */
    SC_KEEP_EVERYTHING_GIVEN,      /* (INTERNAL ONLY) Used for managed columns.  */
    SC_KEEP_COLUMN_AT_PLOT_TIME,  /* (INTERNAL ONLY) Used for fixed size column variables. */
    SC_KEEP_NONE                   /* (INTERNAL ONLY) Used for expression columns and makeXNow commands . */
} SCDataHoldType;


/* For use with many plot command types.  It defines the line style for any line in the command.  This DOESN'T go with
 * the TimePlot command. */
typedef enum
{
    SC_LINE_STYLE_EMPTY = DGEmptyLineStyle,
    SC_LINE_STYLE_SOLID = DGSolidLineStyle,
    SC_LINE_STYLE_DOTTED = DGDottedLineStyle,
    SC_LINE_STYLE_FINE_DOTS = DGFineDotsLineStyle,
    SC_LINE_STYLE_COARSE_DASH = DGCoarseDashLineStyle,
    SC_LINE_STYLE_FINE_DASH = DGFineDashLineStyle,
    SC_LINE_STYLE_DASH_DOT = DGDashDotLineStyle,
    SC_LINE_STYLE_STANDARD = DGStandardLineStyle
} SCLineStyle;


/* The line styles for time plots are very much reduced. */
typedef enum
{
    SC_TIME_PLOTS_SAME_LINE = DGPlotsCommandSameLine,
    SC_TIME_PLOTS_NO_LINE = DGPlotsCommandNoLine
} SCTimePlotLineStyle;


/* Set the point style for a large number of plot commands.  The non-filled type has a space in the middle that can have
 * a separate color (the marker color), otherwise the color of the filled points (and border of non-filled) is set by
 * the line color in the plot command or the border color in the scatter parameters.  The line color is used to set the
 * border of the point, even if there is no line (i.e. SC_LINE_EMPTY) , so it's quite configurable. */
typedef enum
{
    SC_POINT_STYLE_EMPTY = DGEmptyPointStyle,
    SC_POINT_STYLE_CIRCLE = DGCirclePointStyle,
    SC_POINT_STYLE_FILLED_CIRCLE = DGFilledCirclePointStyle,
    SC_POINT_STYLE_TRIANGLE = DGTrianglePointStyle,
    SC_POINT_STYLE_FILLED_TRIANGLE = DGFilledTrianglePointStyle,
    SC_POINT_STYLE_BOX = DGBoxPointStyle,
    SC_POINT_STYLE_FILLED_BOX = DGFilledBoxPointStyle,
    SC_POINT_STYLE_DIAMOND = DGDiamondPointStyle,
    SC_POINT_STYLE_FILLED_DIAMOND = DGFilledDiamondPointStyle,
    SC_POINT_STYLE_PLUS = DGPlusPointStyle,
    SC_POINT_STYLE_CROSS = DGCrossPointStyle
} SCPointStyle;



/* The grid style within the axis. */
typedef enum
{
    SC_GRID_NONE = 4,           /* default */
    SC_GRID_X_ONLY = 2,
    SC_GRID_Y_ONLY = 3,
    SC_GRID_X_AND_Y = 1
} SCGridType;


/* The box style around the axis. */
typedef enum
{
    SC_BOX_ONE = 1,             /* default */
    SC_BOX_AXIS = 2,
    SC_BOX_ONLY_AXIS = 3,
    SC_BOX_OFFSET_AXIS = 4
} SCBoxStyle;

/* How are multiple axis situated with respect to one another. */
typedef enum
{
    SC_MULTIAXIS_STACK_X_AND_Y = DGCanvasCommandStackXStackY, /* default */
    SC_MULTIAXIS_JOIN_X = DGCanvasCommandJoinXStackY,
    SC_MULTIAXIS_JOIN_Y = DGCanvasCommandStackXJoinY,
    SC_MULTIAXIS_JOIN_X_AND_Y = DGCanvasCommandJoinXJoinY
} SCMultiAxisStyle;


/* The type of axis, i.e. how is the data drawn? */
typedef enum
{
    SC_AXIS_LINEAR = DGAxisTypeLinear, /* default */
    SC_AXIS_REVERSE = DGAxisTypeReverse,
    SC_AXIS_LOGARITHMIC = DGAxisTypeLogarithmic,
    SC_AXIS_REVERSE_LOGARITHMIC = DGAxisTypeReverseLogarithmic
} SCAxisType;


typedef enum
{
    SC_HISTOGRAM_UNITS_COUNT = 1, /* default */
    SC_HISTOGRAM_UNITS_DENSITY = 2,
    SC_HISTOGRAM_UNITS_PROBABILITY = 3,
    SC_HISTOGRAM_UNITS_PERCENT_IN_BIN = 4
} SCHistogramUnits;

typedef enum
{
    SC_HISTOGRAM_SPACING_AUTOMATIC = 1, /* default, datagraph handles the spacing */
    SC_HISTOGRAM_SPACING_MHO2_HO2 = 2,  /* center the bar over the value e.g. 0.5 to 1.5 for a bar on 1. */
    SC_HISTOGRAM_SPACING_ZERO_TO_H = 3, /* center the bar to the right of center, so 1.0 to 2.0 for a bar on 1. */
    SC_HISTOGRAM_SPACING_LOG_BIN = 4  /* log binning so the bins are 1, 2, 4, 8, etc. */
} SCHistogramSpacingType;


// 1 is centers, 2 is profile, 3 is bars, 4 is spaced bars, 5 is left/below, 6 is right/above, 7,8,9 doesn't show up.
typedef enum
{
    SC_HISTOGRAM_BAR_CENTER = 1,
    SC_HISTOGRAM_BAR_STAIRS = 2,
    SC_HISTOGRAM_BAR_BARS = 3,  /* default */
    SC_HISTOGRAM_BAR_SPACED_BARS = 4,
    SC_HISTOGRAM_BAR_LEFT_OR_BELOW = 5,
    SC_HISTOGRAM_BAR_RIGHT_OR_ABOVE = 6,
    SC_HISTOGRAM_BAR_SMOOTH = 10
} SCHistogramBarType;


/* This type relates to the Range command, which draws sets of rectangles. */
typedef enum
{
    SC_RANGE_EVERYTHING = DGRangeCommandEverything,    /* The range is the entire x or y axis. */
    SC_RANGE_INTERVAL = DGRangeCommandInterval,          /* The range has a specified numeric start and stop value */
    SC_RANGE_ALTERNATES = DGRangeCommandAlternates,        /* The range is a set of rectangles at a given interval. */
    SC_RANGE_COLUMNS = DGRangeCommandColumns            /* The range is specified by a watched user variable.  */
} SCRangeType;


// DG values are not seperated into a separate joint, so use the number definitions below for now. . -DCS:2009/10/28
/* typedef enum */
/* { */
/*     SC_COLOR_RANGE_MATCH = DGColorSchemeMatchValue,     // v = specified */
/*     SC_COLOR_RANGE_LT_LT = DGColorSchemeMatchRangeOO,   // a <  v <  b */
/*     SC_COLOR_RANGE_LTE_LT = DGColorSchemeMatchRangeCO,  // a <= v <  b */
/*     SC_COLOR_RANGE_LT_LTE = DGColorSchemeMatchRangeOC,  // a <  v <= b */
/*     SC_COLOR_RANGE_LTE_LTE = DGColorSchemeMatchRangeCC, // a <= v <= b */
/* } SCColorRangeType; */

/* This type relates to create color ranges, as a means for encoding from value to color, for use in a scatter plot, for
 * example. */
typedef enum
{
    SC_COLOR_RANGE_MATCH = 1,     // v = specified
    SC_COLOR_RANGE_LT_LT = 2,   // a <  v <  b
    SC_COLOR_RANGE_LTE_LT = 3,  // a <= v <  b
    SC_COLOR_RANGE_LT_LTE = 4,  // a <  v <= b
    SC_COLOR_RANGE_LTE_LTE = 5, // a <= v <= b
} SCColorRangeType;


/* Used to set the parameter of how a scatter plot scales the points based on a user defined variable. */
typedef enum
{
    SC_SCATTER_PLOT_SCALE_BY_DIAMETER = DGPointsCommandDiameter,
    SC_SCATTER_PLOT_SCALE_BY_AREA = DGPointsCommandArea
} SCScatterPlotScaleType;


/* Uesd to set the parmaeter of how a scatter plot determines how the user defined color scheme shold be used, as the
 * fill color or the border color. */
typedef enum
{
    SC_SCATTER_PLOT_COLOR_FILL = DGPointsCommandFill,
    SC_SCATTER_PLOT_COLOR_BORDER = DGPointsCommandLine
} SCScatterPlotColorType;


/* Attempt to use the old plot struct from plotcore, in an attempt to keep things as similar as possible.  In DG, this
 * corresponds a choice selection of properties from a combination of the the DEFAULT axis, the style settings and canvas
 * settings. */
typedef struct SCDefaultAxisParametersType
{
    Boolean isActive;             /* Show the window (default true)?  This is useful for hiding a window by modifying only one place. */
    char * title;
    SCAxisType xAxisType;       /* What kind of axis is this, e.g. linear, logarithmic, reversed, etc. */
    SCAxisType yAxisType;       /* What kind of axis is this, e.g. linear, logarithmic, reversed, etc. */
    int fontSize;               /* not implemented yet. -DCS:2009/05/20 */
    double xMin;                /* min range for x data */
    double xMax;                /* max range for x data */
    Boolean doCropWithXMinMax;  /* if data goes outside of [xMin xMax] should it be plotted or not (default yes). */
    double yMin;                /* min range for y data */
    double yMax;                /* max range for y data */
    Boolean doCropWithYMinMax;   /* if data goes outside of [yMin yMax] should it be plotted or not (default yes). */
    double xTicks;              /* How often a number is printed in the x axis, a value of 200 gives numbers at 0, 200, 400, etc. */
                                /* if set to 0.0 or not set at all, then the ticks are automatically set by DG (useful for zooming) */
    double yTicks;              /* How often a number is printed in the y axis, a value of 200 gives numbers at 0, 200, 400, etc. */
                                /* if set to 0.0 or not set at all, then the ticks are automatically set by DG (useful for zooming) */
    Boolean doDrawXAxis;        /* Bother to even draw the x axis? */
    Boolean doDrawYAxis;        /* Bother to even draw the y axis? */
    char * xLabel;              /* a label for the x axis */
    char * yLabel;              /* a label for the y axis */
    SCColor backColor;      /* not implemented yet, can't figure out the DG commands  -DCS:2009/05/20 */
    SCColor foreColor;      /* not implemented yet, can't figure out the DG commands  -DCS:2009/05/20 */    
    SCGridType gridType;        /* grid lines in the plot along the x, y or both axis.  */
    SCBoxStyle boxStyle;        /* a couple of options on how the axis lines are placed relative to each other.  */
    SCMultiAxisStyle multiAxisStyle; /* Should multiple axis in a plot be stacked or joined (don't worry if you don't have multiple axis). */
} SCDefaultAxisParameters;

typedef SCDefaultAxisParameters pStruct;


/* Add additional axis using this structure.  In DG this corresponds to adding NEW axis.  Unless you're doing something
 * fancy that involves multiple axis within a single plot window, you don't need to reference this structure. Instead
 * use the SCDefaultAxisParameters structure. */
typedef struct SCAxisParametersType
{
    char * label;               /* a label for the axis */
    Boolean isXAxis;            /* If true, then the data is for an X axis, if false, a Y axis.  */    
    SCAxisType axisType;        /* What kind of axis is this, e.g. linear, logarithmic, reversed, etc. */
    Boolean doDrawAxis;         /* Should we draw the numbers and lines, or just create the space? */
    int axisToAxisSpacing;      /* Space between the axis and the axis to the left/below in pixels (can be negative). */
    double axisRatio;           /* The width/height of the axis relative to the main (default) axis.  */
    double min;                 /* min range for the data ("include in" field in DG) */
    double max;                 /* max range for the data ("include in" field in DG, also sets "Restrict x|y")*/
    Boolean doCropWithMinMax;  /* if data goes outside of [min max] should it be plotted or not (default yes). */
    double ticks;   /* How often a number is printed in the axis, a value of 200 gives numbers at 0, 200, 400, etc. */
} SCAxisParameters;


typedef struct SCPlotParametersType
{
    SCLineStyle lineStyle;
    double lineWidth;
    SCColor lineColor;
    SCPointStyle markerStyle;
    double markerSize;
    SCColor markerColor;
    double xOffset;
    double yOffset;
    int xAxis;                  /* default is the default axis, which is 0 */
    int yAxis;                  /* default is the default axis, which is 0 */
} SCPlotParameters;


typedef struct SCTimePlotParametersType
{
    SCTimePlotLineStyle lineType; /* Line or no line.  This is how it's set in DG, so it's how it's set here. */
    double lineWidth;
    SCColor lineColor;
    SCPointStyle markerStyle;
    double markerSize;
    SCColor markerColor;
    double xOffset;
    double yOffset;
    int xAxis;                  /* default is the default axis, which is 0 */
    int yAxis;                  /* default is the default axis, which is 0 */
} SCTimePlotParameters;


typedef struct SCBarPlotParametersType
{
    SCColor barColor;
    double offset;
    double distanceBetweenBars; /* not supported yet. -DCS:2009/06/29 */
    bool barsAreVertical;       /* true gives vertical bars, false gives horizontal bars (xxx is this a problem?)*/
    int xAxis;                  /* default is the default axis, which is 0 */
    int yAxis;                  /* default is the default axis, which is 0 */
} SCBarPlotParameters;


/* I'm waiting for the DG stuff here because I don't want to wrap it all. */
typedef struct SCBarHistogramParametersType
{
    // Add the options for different types. -DCS:2009/08/27
    SCHistogramBarType barType;
    SCColor barColor;       /* not implemented yet. -DCS:2009/08/27 */
    double lineWidth;           /* not implemented yet. -DCS:2009/08/27 */
    double binRangeLow;         /* filter out values less than this value */
    double binRangeHigh;        /* filter out values greater than this value */
    bool barsAreVertical;       /* true gives vertical bars, false gives horizontal bars */
    SCHistogramUnits units;     /* count, density, probability, etc. */
    SCHistogramSpacingType spacingType; /* what kind of spacing between bars? */
    double spacing;             /* used only for some of the spacings SC_HISTOGRAM_SPACING_MHO2_HO2 and SC_HISTOGRAM_SPACING_ZERO_TO_H */
    double smoothValue;         /* used only for barType == SC_HISTOGRAM_BAR_SMOOTH. It's the percentage of the width. smoothValue*width */
    int xAxis;                  /* default is the default axis, which is 0 */
    int yAxis;                  /* default is the default axis, which is 0 */
} SCHistogramPlotParameters;


typedef struct SCFitPlotParametersType
{
    SCLineStyle lineStyle;
    double lineWidth;
    SCColor lineColor;
    int xAxis;                  /* default is the default axis, which is 0 */
    int yAxis;                  /* default is the default axis, which is 0 */
} SCFitPlotParameters;


typedef struct SCSmoothPlotParametersType
{
    double smoothness;          /* How smooth is the fit?  This is a multiple of the data width.  larger values lead to smoother plots.  */
    SCLineStyle lineStyle;
    double lineWidth;
    SCColor lineColor;
    int xAxis;                  /* default is the default axis, which is 0 */
    int yAxis;                  /* default is the default axis, which is 0 */
} SCSmoothPlotParameters;


typedef struct SCMultiLinesPlotParametersType
{
    bool linesAreVertical;       /* true gives vertical lines, false gives horizontal lines */    
    /* Note that these two command parameters are only used if the limit variables names in the command are left nil.  */

    /* lower limit value for vertical lines, left limit value for horizontal lines */
    double fixedLowerLimit;          /* if not set, the value is essentially -inf, so the line will always match to the left/lower axis limit */
    /* upper limit value for vertical lines, right limit value for horizontal lines */
    double fixedUpperLimit;          /* if not set, the value is essentially +inf, so the line will always match to the right/upper axis limit */
    bool labelAtTop;                 /* true puts the labels at the top/right of line, false at the bottom/left of the line */

    SCLineStyle lineStyle;
    double lineWidth;
    SCColor lineColor;    
    int xAxis;                  /* default is the default axis, which is 0 */
    int yAxis;                  /* default is the default axis, which is 0 */
} SCMultiLinesPlotParameters;


typedef struct SCRangePlotParametersType
{
    SCRangeType xRangeType;     /* default is everything */
    SCRangeType yRangeType;     /* default is everything  */
    double xMin;                /* used if xRangeType is interval or alternate */
    double xMax;                /* used if xRangeType is interval */
    double xStride;             /* used if xRangeType is alternate */
    double yMin;                /* used if yRangeType is interval or alternate */
    double yMax;                /* used if yRangeType is interval */
    double yStride;             /* used if yRangeType is alternate */

    SCLineStyle lineStyle;
    double lineWidth;
    SCColor lineColor;    
    SCColor fillColor;

    int xAxis;                  /* default is the default axis, which is 0 */
    int yAxis;                  /* default is the default axis, which is 0  */
} SCRangePlotParameters;


typedef struct SCScatterPlotParametersType
{
    SCPointStyle markerStyle;
    double borderSize;         /* border line width around the marker (there are no lines in this plot) */
    SCColor borderColor;         /* color of border around the marker (there are no lines in this plot) */
    double markerSize;           /* If the size is not specified by a user variable (i.e. uniform), then set this value to the size */
    SCColor markerColor;     /* If the color is not specified by a user variable color scheme (i.e. uniform), then use this color  */
    /* If the point size is set by a user variable, then the following parameters are valid. */
    SCScatterPlotScaleType scaleType;     /* scale diameter or area  (diameter is default)*/
    double scale;
    /* If the point color is set by a user defined color scheme, then the following parameters are valid. */
    SCScatterPlotColorType colorType; /* user colors to set the fill color or the border (line) color (fill is default). */

    int xAxis;                  /* default is the default axis, which is 0 */
    int yAxis;                  /* default is the default axis, which is 0 */
} SCScatterPlotParameters;


#endif
