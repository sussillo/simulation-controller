#include "SCPlotParameters.h"

int SC_LAST_IN_ORDER = -1;

extern NSString * const SCWriteToControllerConsoleAttributedNotification; // for sending colored notes to the controller console
void writeWarningToConsoleSCPP(NSString* text )
{
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
    [nc postNotificationName:SCWriteToControllerConsoleAttributedNotification object:nil userInfo:dictionary];
}


/* A basic initialization with no intelligence.  Just make sure all the pointers are set to NULL, basically.  */
void SCInitPStruct(pStruct * pdata)
{
    if ( !pdata )
        assert ( 0 );
    
    pdata->isActive = false;
    pdata->title = NULL;
    pdata->xAxisType = SC_AXIS_LINEAR;
    pdata->yAxisType = SC_AXIS_LINEAR;
    pdata->xMin = 0.0;
    pdata->xMax = 0.0;
    pdata->doCropWithXMinMax = false;
    pdata->yMin = 0.0;
    pdata->yMax = 0.0;
    pdata->doCropWithYMinMax = false;
    pdata->xTicks = 0.0;
    pdata->yTicks = 0.0;
    pdata->xLabel = NULL;
    pdata->yLabel = NULL;
    pdata->doDrawXAxis = false;
    pdata->doDrawYAxis = false;
    pdata->backColor.red = 0.0;
    pdata->backColor.green = 0.0;
    pdata->backColor.blue = 0.0;
    pdata->backColor.alpha = 1.0;
    pdata->foreColor.red = 0.0;
    pdata->foreColor.green = 0.0;
    pdata->foreColor.blue = 0.0;
    pdata->foreColor.alpha = 1.0;
    pdata->gridType = SC_GRID_NONE;
    pdata->boxStyle = SC_BOX_ONE;
    pdata->multiAxisStyle = SC_MULTIAXIS_STACK_X_AND_Y;
}


void SCInitPStructWithSensibleValues(pStruct * pdata)
{
//    SCTextCopy("Plot title", &pdata->title);
    pdata->isActive = true;
    pdata->title = NULL;
    pdata->xAxisType = SC_AXIS_LINEAR;
    pdata->yAxisType = SC_AXIS_LINEAR;
    pdata->fontSize = 12.0;
    pdata->xMin = 0.0;
    pdata->xMax = 100.0;
    pdata->doCropWithXMinMax = false;
    pdata->yMin = 0.0;
    pdata->yMax = 1.0;
    pdata->doCropWithYMinMax = false;
    pdata->xTicks = 0.0;
    pdata->yTicks = 0.0;
    pdata->doDrawXAxis = true;
    pdata->doDrawYAxis = true;
    pdata->backColor.red = 1.0;
    pdata->backColor.green = 1.0;
    pdata->backColor.blue = 1.0;
    pdata->backColor.alpha = 1.0;
    pdata->foreColor.red = 0.0;
    pdata->foreColor.green = 0.0;
    pdata->foreColor.blue = 0.0;
    pdata->foreColor.alpha = 1.0;
    pdata->gridType = SC_GRID_NONE;
    pdata->boxStyle = SC_BOX_ONE;
}


void SCInitAxisWithSensibleValues(SCAxisParameters * ap)
{
    ap->label = NULL;
    ap->isXAxis = true;
    ap->axisType = SC_AXIS_LINEAR;
    ap->doDrawAxis = true;
    ap->axisToAxisSpacing = 0;
    ap->axisRatio = 1.0;
    ap->min = 0.0;
    ap->max = 0.0;
    ap->doCropWithMinMax = false;
    ap->ticks = 0.0;
}


void SCDeallocPStruct(pStruct * pdata)
{
    if ( pdata == NULL )
        assert(0);              // coudn't have been on purpose

    free (pdata->title);
    free (pdata->xLabel);
    free (pdata->yLabel);

    free (pdata );
    pdata = NULL;
}


void SCInitPlotParametersWithSensibleValues(SCPlotParameters * plot_parameters)
{
    if ( !plot_parameters )
        assert ( 0 );
    
    plot_parameters->lineStyle = DGSolidLineStyle;
    plot_parameters->lineWidth = 1.0;
    plot_parameters->lineColor.red = 0.0;
    plot_parameters->lineColor.green = 0.0;
    plot_parameters->lineColor.blue = 0.0;
    plot_parameters->lineColor.alpha = 1.0;
    
    plot_parameters->markerStyle = DGEmptyPointStyle;
    plot_parameters->markerSize = 0.0;
    plot_parameters->markerColor.red = 0.0;
    plot_parameters->markerColor.green = 0.0;
    plot_parameters->markerColor.blue = 0.0;
    plot_parameters->markerColor.alpha = 1.0;
    plot_parameters->xOffset = 0.0;
    plot_parameters->yOffset = 0.0;
    plot_parameters->xAxis = 0;
    plot_parameters->yAxis = 0;
}


void SCInitTimePlotParametersWithSensibleValues(SCTimePlotParameters * time_plot_parameters)
{
    if ( !time_plot_parameters )
        assert ( 0 );
    
    time_plot_parameters->lineType = DGPlotsCommandSameLine;
    time_plot_parameters->lineWidth = 1.0;
    time_plot_parameters->lineColor.red = 0.0;
    time_plot_parameters->lineColor.green = 0.0;
    time_plot_parameters->lineColor.blue = 0.0;
    time_plot_parameters->lineColor.alpha = 1.0;
    
    time_plot_parameters->markerStyle = DGEmptyPointStyle;
    time_plot_parameters->markerSize = 0.0;
    time_plot_parameters->markerColor.red = 0.0;
    time_plot_parameters->markerColor.green = 0.0;
    time_plot_parameters->markerColor.blue = 0.0;
    time_plot_parameters->markerColor.alpha = 1.0;
    time_plot_parameters->xOffset = 0.0;
    time_plot_parameters->yOffset = 0.0;
    time_plot_parameters->xAxis = 0;
    time_plot_parameters->yAxis = 0;
}


// void SCInitPointsPlotParametersWithSensibleValues(SCPointsPlotParameters * points_plot_parameters)
// {
//     if ( !points_plot_parameters )
//         assert ( 0 );
    
//     points_plot_parameters->markerStyle = DGCirclePointStyle;
//     points_plot_parameters->markerSize = 1.0;
//     points_plot_parameters->markerColor.red = 0.0;
//     points_plot_parameters->markerColor.green = 0.0;
//     points_plot_parameters->markerColor.blue = 0.0;
//     points_plot_parameters->markerColor.alpha = 1.0;
//     points_plot_parameters->xOffset = 0.0;
//     points_plot_parameters->yOffset = 0.0;
//     points_plot_parameters->xAxis = 0;
//     points_plot_parameters->yAxis = 0;
// }


// void SCInitFastPointsPlotParametersWithSensibleValues(SCFastPointsPlotParameters * fast_points_plot_parameters)
// {
//     if ( !fast_points_plot_parameters )
//         assert ( 0 );
    
//     fast_points_plot_parameters->markerStyle = DGCirclePointStyle;
//     fast_points_plot_parameters->markerSize = 1.0;
//     fast_points_plot_parameters->markerColor.red = 0.0;
//     fast_points_plot_parameters->markerColor.green = 0.0;
//     fast_points_plot_parameters->markerColor.blue = 0.0;
//     fast_points_plot_parameters->markerColor.alpha = 1.0;
//     fast_points_plot_parameters->xOffset = 0.0;
//     fast_points_plot_parameters->yOffset = 0.0;
//     fast_points_plot_parameters->xAxis = 0;
//     fast_points_plot_parameters->yAxis = 0;
// }


void SCInitBarPlotParametersWithSensibleValues(SCBarPlotParameters * bar_plot_parameters)
{
    if ( !bar_plot_parameters )
        assert ( 0 );

    bar_plot_parameters->barColor.red = 0.0;
    bar_plot_parameters->barColor.green = 0.0;
    bar_plot_parameters->barColor.blue = 0.0;
    bar_plot_parameters->barColor.alpha = 1.0;
    bar_plot_parameters->offset = 0.0;
    bar_plot_parameters->distanceBetweenBars = 0.0;
    bar_plot_parameters->barsAreVertical = true;
    bar_plot_parameters->xAxis = 0;
    bar_plot_parameters->yAxis = 0;
}


void SCInitHistogramPlotParametersWithSensibleValues(SCHistogramPlotParameters * histogram_plot_parameters)
{
    if ( !histogram_plot_parameters )
        assert ( 0 );
    
    histogram_plot_parameters->barType = SC_HISTOGRAM_BAR_BARS;
    histogram_plot_parameters->barColor.red = 0.0;
    histogram_plot_parameters->barColor.green = 0.0;
    histogram_plot_parameters->barColor.blue = 0.0;
    histogram_plot_parameters->barColor.alpha = 1.0;
    /* If the binRangeLow == binRangeHigh, then SC shouldn't modify the DG field, leaving the range at -Inf to +Inf. */
    histogram_plot_parameters->binRangeLow = 0.0; /* intended to be as small as possible. */ 
    histogram_plot_parameters->binRangeHigh = 0.0; /* intended to be as large as possible. */
    histogram_plot_parameters->barsAreVertical = true;       /* true gives vertical bars, false gives horizontal bars */
    histogram_plot_parameters->units = SC_HISTOGRAM_UNITS_COUNT;
    histogram_plot_parameters->spacingType = SC_HISTOGRAM_SPACING_AUTOMATIC;
    histogram_plot_parameters->spacing = 0.0;
    histogram_plot_parameters->lineWidth = 1.0;
    histogram_plot_parameters->smoothValue = 0.5;
    histogram_plot_parameters->xAxis = 0;
    histogram_plot_parameters->yAxis = 0;
}


void SCInitFitPlotParametersWithSensibleValues(SCFitPlotParameters * fpp)
{
    if ( !fpp )
        assert ( 0 );

    fpp->lineStyle = DGSolidLineStyle;
    fpp->lineWidth = 1.0;
    fpp->lineColor.red = 0.0;
    fpp->lineColor.green = 0.0;
    fpp->lineColor.blue = 0.0;
    fpp->lineColor.alpha = 1.0;    
    fpp->xAxis = 0;
    fpp->yAxis = 0;
}


void SCInitSmoothPlotParametersWithSensibleValues(SCSmoothPlotParameters * spp)
{
    if ( !spp )
        assert ( 0 );

    spp->smoothness = 1.0;
    spp->lineStyle = DGSolidLineStyle;
    spp->lineWidth = 1.0;
    spp->lineColor.red = 0.0;
    spp->lineColor.green = 0.0;
    spp->lineColor.blue = 0.0;
    spp->lineColor.alpha = 1.0;    
    spp->xAxis = 0;
    spp->yAxis = 0;
}


void SCInitMultiLinesPlotParametersWithSensibleValues(SCMultiLinesPlotParameters * mlpp)
{
    if ( !mlpp )
        assert ( 0 );
    
    mlpp->linesAreVertical = true;
    // Assumption is that these numbers are so large that no one would ever set them purposefully.  -DCS:2009/10/16
    mlpp->fixedLowerLimit = -1.0e15; // hack this. 
    mlpp->fixedUpperLimit = 1.0e15;  // hack this. -DCS:2009/10/16
    mlpp->labelAtTop = true;
    mlpp->lineStyle = DGSolidLineStyle;
    mlpp->lineWidth = 1.0;
    mlpp->lineColor.red = 0.0;
    mlpp->lineColor.green = 0.0;
    mlpp->lineColor.blue = 0.0;
    mlpp->lineColor.alpha = 1.0;
    mlpp->xAxis = 0;
    mlpp->yAxis = 0;
}

    
void SCInitRangePlotParametersWithSensibleValues(SCRangePlotParameters * rpp)
{
    if ( !rpp )
        assert ( 0 );
    
    rpp->xRangeType = SC_RANGE_EVERYTHING;
    rpp->yRangeType = SC_RANGE_EVERYTHING;
    rpp->xMin = 0.0;
    rpp->xMax = 0.0;
    rpp->xStride = 0.0;
    rpp->yMin = 0.0;
    rpp->yMax = 0.0;
    rpp->yStride = 0.0;
    rpp->lineStyle = DGSolidLineStyle;
    rpp->lineWidth = 1.0;
    rpp->lineColor.red = 0.0;
    rpp->lineColor.green = 0.0;
    rpp->lineColor.blue = 0.0;
    rpp->lineColor.alpha = 1.0;
    rpp->fillColor.red = 0.0;
    rpp->fillColor.green = 0.0;
    rpp->fillColor.blue = 0.0;
    rpp->fillColor.alpha = 1.0;
    rpp->xAxis = 0;
    rpp->yAxis = 0;
}


void SCInitScatterPlotParametersWithSensibleValue(SCScatterPlotParameters * spp)
{
    if ( !spp )
        assert ( 0 );
    
    spp->markerStyle = DGCirclePointStyle;
    spp->borderSize = 1.0;
    spp->borderColor.red = 0.0;         
    spp->borderColor.green = 0.0;         
    spp->borderColor.blue = 0.0;         
    spp->borderColor.alpha = 1.0;
    spp->markerSize = 1.0;
    spp->markerColor.red = 0.0; 
    spp->markerColor.green = 0.0; 
    spp->markerColor.blue = 0.0; 
    spp->markerColor.alpha = 1.0; 
    spp->scaleType = SC_SCATTER_PLOT_SCALE_BY_DIAMETER;
    spp->scale = 1.0;
    spp->colorType = SC_SCATTER_PLOT_COLOR_FILL; 
    spp->xAxis = 0;
    spp->yAxis = 0;
}



void SCInitPlotParameters(SCPlotParameters * lpp)
{
    SCInitPlotParametersWithSensibleValues(lpp);
}

void SCInitTimePlotParameters(SCTimePlotParameters * flpp)
{
    SCInitTimePlotParametersWithSensibleValues(flpp);
}

// void SCInitPointsPlotParameters(SCPointsPlotParameters * ppp)
// {
//     SCInitPointsPlotParametersWithSensibleValues(ppp);
// }

// void SCInitFastPointsPlotParameters(SCFastPointsPlotParameters * fppp)
// {
//     SCInitFastPointsPlotParametersWithSensibleValues(fppp);
// }

void SCInitBarPlotParameters(SCBarPlotParameters * bpp)
{
    SCInitBarPlotParametersWithSensibleValues(bpp);
}

void SCInitHistogramPlotParameters(SCHistogramPlotParameters * hpp)
{
    SCInitHistogramPlotParametersWithSensibleValues(hpp);
}

void SCInitFitPlotParameters(SCFitPlotParameters * fpp)
{
    SCInitFitPlotParametersWithSensibleValues(fpp);
}

void SCInitSmoothPlotParameters(SCSmoothPlotParameters * spp)
{
    SCInitSmoothPlotParametersWithSensibleValues(spp);
}

void SCInitMultiLinesPlotParameters(SCMultiLinesPlotParameters * mlpp)
{
    SCInitMultiLinesPlotParametersWithSensibleValues(mlpp);
}

void SCInitRangePlotParameters(SCRangePlotParameters * rpp)
{
    SCInitRangePlotParametersWithSensibleValues(rpp);
}

void SCInitScatterPlotParameters(SCScatterPlotParameters * spp)
{
    SCInitScatterPlotParametersWithSensibleValue(spp);
}

void SCInitAxis(SCAxisParameters * ap)
{
    SCInitAxisWithSensibleValues(ap);
}

