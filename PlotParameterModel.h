#import <Cocoa/Cocoa.h>
#import "SCPlotParameters.h"


/* Used for type polymorphism in the code. */
@interface SCCommandParameters : NSObject
{
    int xAxis;
    int yAxis;
}

@property(assign) int xAxis;
@property(assign) int yAxis;

@end

/* The Objective-C version of the parameter model for line parameters that correspond to DataGraph line command
 * properties. */
@interface SCPlotCommandParameters : SCCommandParameters
{
    SCLineStyle lineStyle;
    double lineWidth;
    NSColor *lineColor;
    SCPointStyle markerStyle;
    double markerSize;
    NSColor *markerColor;
    double xOffset;
    double yOffset;
}

@property(assign) SCLineStyle lineStyle;
@property(assign) double lineWidth;
@property(retain) NSColor *lineColor;
@property(assign) SCPointStyle markerStyle;
@property(assign) double markerSize;
@property(retain) NSColor *markerColor;
@property(assign) double xOffset;
@property(assign) double yOffset;

+ (SCPlotCommandParameters *)copyFromCStruct:(SCPlotParameters *)plot_parameters;


@end


/* The Objective-C version of the parameter model for fast line parameters that correspond to DataGraph line command
 * properties. */
@interface SCTimePlotCommandParameters : SCCommandParameters
{
    SCTimePlotLineStyle lineType;
    double lineWidth;
    NSColor *lineColor;
    SCPointStyle markerStyle;
    double markerSize;
    NSColor *markerColor;
    double xOffset;
    double yOffset;
}

@property(assign) SCTimePlotLineStyle lineType;
@property(assign) double lineWidth;
@property(retain) NSColor *lineColor;
@property(assign) SCPointStyle markerStyle;
@property(assign) double markerSize;
@property(retain) NSColor *markerColor;
@property(assign) double xOffset;
@property(assign) double yOffset;

+ (SCTimePlotCommandParameters *)copyFromCStruct:(SCTimePlotParameters *)time_plot_parameters;


@end



/* The Objective-C version of the parameter model for point parameters that correspond to DataGraph line command
 * properties (with no line and only points). */
// @interface PointsCommandParameters : SCCommandParameters
// {
//     SCPointStyle markerStyle;
//     double markerSize;
//     NSColor *markerColor;
//     double xOffset;
//     double yOffset;
// }

// @property(assign) SCPointStyle markerStyle;
// @property(assign) double markerSize;
// @property(retain) NSColor *markerColor;
// @property(assign) double xOffset;
// @property(assign) double yOffset;

// + (PointsCommandParameters *)copyFromCStruct:(SCPointsPlotParameters *)points_command_parameters;


// @end


// @interface FastPointsCommandParameters : SCCommandParameters
// {
//     SCPointStyle markerStyle;
//     double markerSize;
//     NSColor *markerColor;
//     double xOffset;
//     double yOffset;
// }

// @property(assign) SCPointStyle markerStyle;
// @property(assign) double markerSize;
// @property(retain) NSColor *markerColor;
// @property(assign) double xOffset;
// @property(assign) double yOffset;

// + (FastPointsCommandParameters *)copyFromCStruct:(SCFastPointsPlotParameters *)fast_points_command_parameters;


// @end


@interface SCBarCommandParameters : SCCommandParameters
{
    NSColor *barColor;
    double offset;
    double distanceBetweenBars;
    Boolean barsAreVertical;
}

@property(retain) NSColor *barColor;
@property(assign) double offset;
@property(assign) double distanceBetweenBars;
@property(assign) Boolean barsAreVertical;

+ (SCBarCommandParameters *)copyFromCStruct:(SCBarPlotParameters *)bar_plot_parameters;

@end


@interface SCHistogramCommandParameters : SCCommandParameters
{
    SCHistogramBarType barType;
    NSColor *barColor;
    double binRangeLow;
    double binRangeHigh;
    Boolean barsAreVertical;
    double lineWidth;
    SCHistogramUnits units;
    SCHistogramSpacingType spacingType;
    double spacing;
    double smoothValue;
}

@property(assign) SCHistogramBarType barType;
@property(retain) NSColor *barColor;
@property(assign) double binRangeLow;
@property(assign) double binRangeHigh;
@property(assign) Boolean barsAreVertical;
@property(assign) double lineWidth;
@property(assign) SCHistogramUnits units;
@property(assign) SCHistogramSpacingType spacingType;
@property(assign) double spacing;
@property(assign) double smoothValue;

+ (SCHistogramCommandParameters *)copyFromCStruct:(SCHistogramPlotParameters *)histogram_plot_parameters;

@end


/* The Objective-C version of the parameter model for fit parameters that correspond to DataGraph fit command
 * properties. */
@interface SCFitCommandParameters : SCCommandParameters
{
    SCLineStyle lineStyle;
    double lineWidth;
    NSColor *lineColor; 
}

@property(assign) SCLineStyle lineStyle;
@property(assign) double lineWidth;
@property(retain) NSColor *lineColor;

+ (SCFitCommandParameters *)copyFromCStruct:(SCFitPlotParameters *)fcp;


@end


/* The Objective-C version of the parameter model for fit parameters that correspond to DataGraph fit command
 * properties. */
@interface SCSmoothCommandParameters : SCCommandParameters
{
    double smoothness;
    SCLineStyle lineStyle;
    double lineWidth;
    NSColor *lineColor; 
}

@property(assign) double smoothness;
@property(assign) SCLineStyle lineStyle;
@property(assign) double lineWidth;
@property(retain) NSColor *lineColor;

+ (SCSmoothCommandParameters *)copyFromCStruct:(SCSmoothPlotParameters *)scp;


@end


@interface SCMultiLinesCommandParameters : SCCommandParameters
{
    BOOL linesAreVertical; 
    double fixedLowerLimit;
    double fixedUpperLimit;
    BOOL labelAtTop;       
    SCLineStyle lineStyle;
    double lineWidth;
    NSColor *lineColor;    
}

@property(assign) BOOL linesAreVertical; 
@property(assign) double fixedLowerLimit;
@property(assign) double fixedUpperLimit;
@property(assign) BOOL labelAtTop;       
@property(assign) SCLineStyle lineStyle;
@property(assign) double lineWidth;
@property(retain) NSColor *lineColor;    

+ (SCMultiLinesCommandParameters *)copyFromCStruct:(SCMultiLinesPlotParameters *)mlpp;

@end


@interface SCRangeCommandParameters : SCCommandParameters
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
    NSColor *lineColor;    
    NSColor *fillColor;
}

@property(assign) SCRangeType xRangeType;
@property(assign) SCRangeType yRangeType;
@property(assign) double xMin;     
@property(assign) double xMax;     
@property(assign) double xStride;  
@property(assign) double yMin;     
@property(assign) double yMax;     
@property(assign) double yStride;  
@property(assign) SCLineStyle lineStyle;
@property(assign) double lineWidth;
@property(retain) NSColor *lineColor;    
@property(retain) NSColor *fillColor;

+(SCRangeCommandParameters *)copyFromCStruct:(SCRangePlotParameters *)rpp;

@end


@interface SCScatterCommandParameters: SCCommandParameters
{
    SCPointStyle markerStyle;
    double borderSize;
    NSColor *borderColor;
    double markerSize;
    NSColor *markerColor;
    SCScatterPlotScaleType scaleType;
    double scale;
    SCScatterPlotColorType colorType;
}

@property(assign) SCPointStyle markerStyle;
@property(assign) double borderSize;
@property(retain) NSColor *borderColor;
@property(assign) double markerSize;
@property(retain) NSColor *markerColor;
@property(assign) SCScatterPlotScaleType scaleType;
@property(assign) double scale;
@property(assign) SCScatterPlotColorType colorType;

+ (SCScatterCommandParameters *)copyFromCStruct:(SCScatterPlotParameters *)spp;

@end

@interface SCAxisCommandParameters : SCCommandParameters
{
    NSString * label;
    BOOL isXAxis;
    SCAxisType axisType;
    BOOL doDrawAxis;         
    int axisToAxisSpacing;   
    double axisRatio;            
    double min;              
    double max;              
    BOOL doCropWithMinMax;
    double ticks;   
}

@property(retain) NSString *label;
@property(assign) BOOL isXAxis;
@property(assign) SCAxisType axisType;
@property(assign) BOOL doDrawAxis;         
@property(assign) int axisToAxisSpacing;   
@property(assign) double axisRatio;            
@property(assign) double min;              
@property(assign) double max;              
@property(assign) BOOL doCropWithMinMax;
@property(assign) double ticks;

+ (SCAxisCommandParameters * )copyFromCStruct:(SCAxisParameters *)ap;

@end


/* The objective-C version of the parameter model for global properties of a plot, such as axis offsets and titles, etc. */
// Dangerous name conflict with user parameter version of this. 
@interface DefaultAxisParameters : NSObject <NSCopying>
{
    BOOL isActive;
    NSString *title;
    int fontSize;
    SCAxisType xAxisType;
    SCAxisType yAxisType;
    double xMin;                // min range on x axis
    double xMax;                // max range on x axis
    BOOL doCropWithXMinMax;
    double xScale;              // not clear
    double yMin;                // min range on x axis
    double yMax;                // max range on x axis
    BOOL doCropWithYMinMax;
    double yScale;              // not clear
    double xTicks;              // tick size on the x axis
    double yTicks;              // tick size on the y axis
    BOOL doDrawXAxis;
    BOOL doDrawYAxis;
    NSString *xLabel;              // label on the x axis
    NSString *yLabel;              // label on the y axis
    NSColor *backColor;
    NSColor *foreColor;
    SCGridType gridType;        // have the grid on or not.
    SCBoxStyle boxStyle;        // what kind of box around the axis
    SCMultiAxisStyle multiAxisStyle;
}

@property(assign) BOOL isActive;
@property(copy) NSString *title;
@property(assign) int fontSize;
@property(assign) SCAxisType xAxisType;
@property(assign) SCAxisType yAxisType;
@property(assign) double xMin;
@property(assign) double xMax;
@property(assign) BOOL doCropWithXMinMax;
@property(assign) double xScale;
@property(assign) double yMin;
@property(assign) double yMax;
@property(assign) BOOL doCropWithYMinMax;
@property(assign) double yScale;
@property(assign) double xTicks;
@property(assign) double yTicks;
@property(assign) BOOL doDrawXAxis;
@property(assign) BOOL doDrawYAxis;
@property(copy) NSString *xLabel;
@property(copy) NSString *yLabel;
@property(retain) NSColor *backColor;
@property(retain) NSColor *foreColor;
@property(assign) SCGridType gridType;
@property(assign) SCBoxStyle boxStyle;
@property(assign) SCMultiAxisStyle multiAxisStyle;
                
+ (DefaultAxisParameters *)copyFromPStruct:(pStruct *)pdata;
                

@end
