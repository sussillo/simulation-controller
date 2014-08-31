/* This is a sample simulation that defines all of the necessary variables and plot parameters, etc., so that the
 * simulation controller can do it's thing. */

#include <stdlib.h>
#include <math.h>
#include <Carbon/Carbon.h>
#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>
#ifndef _NO_USER_LIBRARY_
#include <SimulationControllerFramework/SCPlotParameters.h>             // incorporate a header file from framework -- SHH@7/8/09
#include <SimulationControllerFramework/SimulationController.h>         // incorporate a header file from framework -- SHH@7/8/09
#else
#include "SCPlotParameters.h"
#include "SimulationController.h"
#endif

#define MY_PI 3.14159
#define NVARS 50 
#define NRANDOMVARS 250
#define NSPIKERASTERS 100
#define NSINEFUNVALS 250
#define NRECTS 100
double *XValues;
double *Variables;
double *RandomVariables;
double *SineValues;
double *TimeValues;
double *VariableSubset1;
double *RectXMins;
double *RectXMaxs;
double *RectYMins;
double *RectYMaxs;

double simTime;
double plotTime;
double plotDuration;
double DT;
int plotIters;
gsl_rng * RNG;
const gsl_rng_type * RNG_type;

//double jumpValue;


void* InitModel()
{
    simTime = 0.0;
    plotTime = 0.0;
    plotDuration = 1000.0;
    DT = 1.0;
    plotIters = 0;
    
    // These two values need to be bullet proofed.  If you draw less than you plot, you've got a problem. Perhaps a
    // simple error message would be enough.
    int draw_every = 1;        /* draw every draw_every steps */
    int plot_every = 1;        /* plot one in plot_every points */
    bool do_start_run = false;
    bool do_plot_in_parallel = false;
    int max_history_count = -1;
    bool do_redraw_based_on_timer = true;
    
    SCSetNStepsInFullPlot((int)(plotDuration/DT));
    SCSetNStepsBetweenPlotting(plot_every);
    SCDoRedrawBasedOnTimer(do_redraw_based_on_timer);
    //SCSetNStepsBetweenDrawing(draw_every);
    SCStartRunImmediatelyAfterInit(do_start_run);
    SCDoPlotInParallel(do_plot_in_parallel);
    if ( max_history_count >= 0 )
        SCSetMaxHistoryCount(max_history_count);

    /* Allocate the simulation variables. */
    XValues = (double *)malloc(NVARS*sizeof(double));
    Variables = (double *)malloc(NVARS*sizeof(double));
    RandomVariables = (double *)malloc(NRANDOMVARS*sizeof(double));
    SineValues = (double *)malloc(NSINEFUNVALS*sizeof(double));
    TimeValues = (double *)malloc(NSINEFUNVALS*sizeof(double));
    RectXMins = (double *)malloc(NRECTS*sizeof(double));
    RectXMaxs = (double *)malloc(NRECTS*sizeof(double));
    RectYMins = (double *)malloc(NRECTS*sizeof(double));
    RectYMaxs = (double *)malloc(NRECTS*sizeof(double));

    for (int i = 0; i < NRECTS; i++ )
    {
        RectXMins[i] = 450.0;
        RectXMaxs[i] = 475.0;
        RectYMins[i] = 5.0;
        RectYMaxs[i] = 6.0;
    }
    for (int i = 0; i < NVARS; i++ ) 
    {
        Variables[i] = 0.0;
        XValues[i] = (double)i;
    }
    VariableSubset1 = &Variables[0];

    gsl_rng_env_setup();
    RNG_type = gsl_rng_default;
    RNG = gsl_rng_alloc(RNG_type);

    return NULL;                /* could return the appropriate data, if we didn't want to use globals */
}


void AddControllableParameters(void * model_data)
{
    SCAddControllableParameter("sleep_ms", 0.0, 5.0, 4.0); /* slow down the sim for the sake of viewing the plots */
    SCAddControllableParameter("freq", 0.0, 0.1, 1.0/30.0);
    SCAddControllableParameter("amp", 0.0, 10.0, 1.0);
    SCAddControllableParameter("jumpValue", 0.0, 20.0, 1.0);
/*     SCAddControllableParameter("test4", 0.4, 1.0, 0.0); */
/*     SCAddControllableParameter("test5", 0.5, 1.0, 0.0); */
/*     SCAddControllableParameter("test6", 0.6, 1.0, 0.0); */
/*     SCAddControllableParameter("test7", 0.7, 1.0, 0.0); */
/*     SCAddControllableParameter("test8", 0.8, 1.0, 0.0); */
}


void AddControllableButtons(void * model_data)
{
    SCAddControllableButton("learn", false, "No Learn", "Learn");
    SCAddControllableButton("plotsomething", false, "Plot A", "Plot B");
    SCAddControllableButton("wiggle", true, "Don't Wiggle", "Wiggle");
/*     SCAddControllableButton("test3", true, "no test3", "test3"); */
/*     SCAddControllableButton("test4", true, "no test4", "test4"); */
/*     SCAddControllableButton("test5", true, "no test5", "test5"); */
/*     SCAddControllableButton("test6", true, "no test6", "test6"); */
/*     SCAddControllableButton("test7", true, "no test7", "test7"); */
/*     SCAddControllableButton("test8", true, "no test8", "test8"); */
}



void AddPlotsAndRegisterWatchedVariables(void * model_data)
{
    /* Mark the variables that are to be watched, and ultimately plotted. */

    SCAddWatchedTimeColumn("plottime", &plotTime, SC_KEEP_DURATION);
    /* The SCAddWatchedTimeColumns command tacks a number at the end, so we get y0, y1, ..., y_{NVARS-1}. */
    SCAddWatchedTimeColumns("y", Variables, NVARS, SC_KEEP_DURATION);
    SCAddWatchedTimeColumns("v1", VariableSubset1, 10, SC_KEEP_DURATION);

    /* Column variables are used for bar graphs and histograms. */
    SCAddWatchedFixedSizeColumn("barValues", &Variables[40], 10);        
    SCAddWatchedFixedSizeColumn("XValues", XValues, 10);
    SCAddWatchedFixedSizeColumn("randVals", RandomVariables, NRANDOMVARS);

    SCAddWatchedFixedSizeColumn("RectXMins", RectXMins, NRECTS);
    SCAddWatchedFixedSizeColumn("RectXMaxs", RectXMaxs, NRECTS);
    SCAddWatchedFixedSizeColumn("RectYMins", RectYMins, NRECTS);
    SCAddWatchedFixedSizeColumn("RectYMaxs", RectYMaxs, NRECTS);

    for ( int i = 0; i < NSINEFUNVALS; i++ )
    {
        TimeValues[i] = -6.0 + 12.0*(double)i/(double)NSINEFUNVALS;
    }
    SCAddStaticColumn("timevalues", TimeValues, NSINEFUNVALS);
    SCAddWatchedFixedSizeColumn("sinevalues", SineValues, NSINEFUNVALS);
    
    /* Create managed variables (i.e. variable length) with the name given.  Managed variables are used when you can't
     * determine the length of the data beforeand (for example a spike raster of a stochastic process. */
    SCAddManagedColumnWithSize("varlength1", true, 2000);
    SCAddManagedColumnWithSize("varlength2", true, 2000);

    /* An expression variable is computed within DG based on the values of other variables.  This is extremely useful
     * for prettifying the plots without having to write any C code to do it.  Expression variables are used just like
     * any other column of data, i.e. they have to be associated to a plot.  The expression have to be in the same plot
     * as the data upon which they express!  */
    SCAddExpressionColumn("v1mv2", "varlength1 * varlength2");
    SCAddExpressionColumn("v1pv2", "varlength1 + varlength2");

    /* Create n managed variables with name given and a number taked on.  So "spikes0", "spikes2", ..., "spikes9". */
    //SCAddManagedColumns("spikes", NSPIKERASTERS);
    //SCAddManagedColumns("spikeTimes", NSPIKERASTERS);

    /* Note the lack of s on the function name. Therefore the managed variables "spikes" and "spikeTimes" are created. */
    SCAddManagedColumn("spikes", true);
    SCAddManagedColumn("spikeTimes", true);
    SCAddManagedColumn("spikes0", true);
    SCAddManagedColumn("spikeTimes0", true);

    /* There are only necessary because of the SCMakeLinePlotNow SCMakePointsPlotNow type plots.  Normally the plots are
     * implicitly declared when a watched variable is associated to a plot, but if there is a plot with nothing but
     * "make now" type data, then it has to be explicitly declared beforehand.  You can explicitly declare all your
     * plots, if you like or in you are confused. */
    SCAddPlot("plot_1", false);
    SCAddPlot("plot_2", true);
    SCAddPlot("plot_5", true);
    SCAddPlot("plot_6", true);
    SCAddPlot("plot_7", true);

    SCColor colors[10];
/*     SCColorFromName("steel", &colors[0]);     */
/*     SCColorFromName("blueberry", &colors[1]);     */
/*     SCColorFromName("tan", &colors[2]);     */
/*     SCColorFromName("blue", &colors[3]); */
/*     SCColorFromName("cyan", &colors[4]); */
/*     SCColorFromName("lavender", &colors[5]); */
/*     SCColorFromName("licorice", &colors[6]); */
/*     SCColorFromName("orange", &colors[7]); */
/*     SCColorFromName("brown", &colors[8]); */
/*     SCColorFromName("cayenne", &colors[9]); */
    SCColorRangeFromNames("orange", "blue", 10, colors, 1.0);

    SCColorRangeType color_range_types[10];
    double color_range_starts[10];
    double color_range_stops[10];
    double j = -7;
    for ( int i = 0; i < 10; i++ )
    {
        color_range_types[i] = SC_COLOR_RANGE_LTE_LT;
        color_range_starts[i] = (double)j;
        color_range_stops[i] = (double)j+1.4;
        j = j+1.4;
        // colors are defined just above
    }
    SCAddColorSchemeToPlot("plot_5", "mycolors", 10, color_range_types, color_range_starts, color_range_stops, colors);
    SCAddColorSchemeToPlot("plot_4", "mycolors", 10, color_range_types, color_range_starts, color_range_stops, colors);

    
    
    char y_var_name_buff[50];
    int i = 0;

    SCTimePlotParameters flpp;
    SCInitTimePlotParameters(&flpp); 

    i = 0;
    flpp.lineType = SC_TIME_PLOTS_SAME_LINE;
    flpp.lineWidth = 2.0;
    SCColorCopy(&colors[0], &(flpp.lineColor));
    flpp.yOffset = 1.0;
    flpp.xOffset = 0.0;
    flpp.markerStyle = SC_POINT_STYLE_EMPTY;
    flpp.markerColor = colors[2];
    flpp.markerSize = 10;
    SCAddVarsToTimePlot("plot_0", "plottime",  "v1", &flpp );
    
    SCRangePlotParameters rpp;
    SCInitRangePlotParameters(&rpp);
    rpp.xRangeType = SC_RANGE_COLUMNS;
    rpp.yRangeType = SC_RANGE_COLUMNS;
    rpp.lineWidth = 1.0;
    rpp.lineStyle = SC_LINE_STYLE_SOLID;
    colors[3].alpha = 0.7;
    SCColorCopy(&colors[3], &(rpp.fillColor));
    SCAddVarsToRange("plot_5", "RectXMins", "RectXMaxs", "RectYMins", "RectYMaxs", "RectYMins", "mycolors", &rpp);


    SCPlotParameters lpp;
    SCInitPlotParameters(&lpp);    
    lpp.lineStyle = SC_LINE_STYLE_SOLID;
    lpp.lineWidth = 1.0; /* linewidth matters for line plots because of bug in Mac OS -DCS:2009/08/25 */
    SCColorCopy(&colors[7], &(lpp.lineColor));
    SCAddVarsToPlot("plot_1", "varlength1",  "varlength2", &lpp );
    
    SCTimePlotParameters tpp;
    SCInitTimePlotParameters(&tpp);    
    lpp.lineStyle = SC_LINE_STYLE_SOLID;
    lpp.lineWidth = 1.0; /* linewidth matters for line plots because of bug in Mac OS -DCS:2009/08/25 */
    SCColorCopy(&colors[2], &(tpp.lineColor));
    SCAddVarsToTimePlot("plot_1", "v1mv2", "v1pv2", &tpp );

    SCInitPlotParameters(&lpp);
    lpp.lineStyle = SC_LINE_STYLE_EMPTY;
    lpp.markerStyle = SC_POINT_STYLE_CIRCLE;
    SCColorCopy(&colors[5], &(lpp.lineColor));
    SCAddVarsToPlot("plot_2", "timevalues",  "sinevalues", &lpp );

    SCFitPlotParameters fpp;
    SCInitFitPlotParameters(&fpp);
    SCColorCopy(&colors[3], &fpp.lineColor);
    fpp.lineWidth = 10.0;
    SCAddVarsToFit("plot_2", "timevalues", "sinevalues", &fpp, "sin(a*x + b)", 2, "a", 1.0, "b", 0.5);

    SCSmoothPlotParameters spp;
    SCInitSmoothPlotParameters(&spp);
    SCColorCopy(&colors[4], &(spp.lineColor));
    spp.smoothness = 0.1;
    spp.lineWidth = 10;
    spp.lineStyle = SC_LINE_STYLE_SOLID;
    SCAddVarsToSmooth("plot_2", "timevalues", "sinevalues", &spp);


    /* Note this is not a fast line plot, but a regular line plot, so the entire plot is redrawn at every redraw.  This
     * only works for a line width of 1, due to a bug in the apple OS drawing routines.  See how in the fast drawing
     * routine, one declars a number of variables to be drawn.  In the case of the regular line plot, one declares n
     * plots for n lines, which is what is done here. -DCS:2009/09/29*/
    {
        SCPlotParameters lpp;
        SCInitPlotParameters(&lpp);        
        for ( int j = 0; j < 10; j++ )
        {
            sprintf(y_var_name_buff, "y%d", 3*10+j);
            lpp.lineWidth = 1.0; /* linewidth matters for line plots because of bug in Mac OS -DCS:2009/08/25 */
            SCColorCopy(&colors[3], &(lpp.lineColor));
            lpp.yOffset = j;
            SCAddVarsToPlot("plot_3", "plottime",  y_var_name_buff, &lpp );
        }
    }

    SCAxisParameters xap;
    SCInitAxis(&xap);
    xap.isXAxis = true;
    xap.axisType = SC_AXIS_LINEAR;
    xap.min = -7.0;
    xap.max = 7.0;
    xap.ticks = 1.0;
    xap.axisRatio = 1.0;
    xap.axisToAxisSpacing = 5;
    SCAddAxisToPlot("plot_4", &xap);

    SCBarPlotParameters bpp;
    SCInitBarPlotParameters(&bpp);
    bpp.xAxis = 0;
    SCColorCopy(&colors[4], &bpp.barColor);
    bpp.barsAreVertical = true;
    
    SCAddVarsToBar("plot_4", "barValues", &bpp);

    SCScatterPlotParameters scpp;
    SCInitScatterPlotParametersWithSensibleValue(&scpp);
    scpp.markerSize = 8;
    SCColorCopy(&colors[9], &scpp.borderColor);
    scpp.borderSize = 3;
    SCColorCopy(&colors[0], &scpp.markerColor);
    scpp.colorType = SC_SCATTER_PLOT_COLOR_BORDER;
    scpp.xAxis = 1;
    SCAddVarsToScatter("plot_4", "timevalues", "sinevalues", NULL, "timevalues", "mycolors", &scpp);


    /* Plot a histogram of random values.  The parameters here are setup for a "smooth" histogram, so there are no bars,
     * rather something that looks like a probability distribution.  There are a lot of parameters to the histogram
     * plot, so check them out.  The basic idea is you feed the plot the raw data and it'll make the histogram for
     * you. */
    SCHistogramPlotParameters hpp;
    SCInitHistogramPlotParameters(&hpp);
    colors[2].alpha = 0.5;
    SCColorCopy(&colors[2], &(hpp.barColor));
    hpp.barsAreVertical = true; 
    hpp.barType = SC_HISTOGRAM_BAR_SMOOTH;
    hpp.units = SC_HISTOGRAM_UNITS_PROBABILITY;
    hpp.spacingType = SC_HISTOGRAM_SPACING_MHO2_HO2;
    hpp.spacing = 1.0;
    hpp.smoothValue = 0.2;
    SCAddVarsToHistogram("plot_6", "randVals", &hpp);    

    /* This is the faster plotting when you don't care that all the spikes are in the same column.  The spikes MUST BE IN TEMPORAL ORDER!!! */
    SCInitAxis(&xap);
    xap.isXAxis = true;
    xap.axisType = SC_AXIS_LINEAR;
    xap.min = 0.0;
    xap.max = 1000.0;
    xap.ticks = 100.0;
    xap.axisRatio = 10.0;
    xap.axisToAxisSpacing = 0;
    SCAddAxisToPlot("plot_7", &xap);
    
    SCAxisParameters yap;
    SCInitAxis(&yap);
    yap.isXAxis = false;
    yap.axisType = SC_AXIS_LINEAR;
    yap.min = 0.0;
    yap.max = 100.0;
    yap.ticks = 10.0;
    yap.axisRatio = 10.0;
    yap.axisToAxisSpacing = 0;
    SCAddAxisToPlot("plot_7", &yap);
    
    SCTimePlotParameters fppp;
    SCInitTimePlotParameters(&fppp); 
    fppp.lineType = SC_TIME_PLOTS_NO_LINE;
    fppp.markerStyle = SC_POINT_STYLE_CIRCLE;
    fppp.markerSize = 3.0;
    fppp.xAxis = 1;
    fppp.yAxis = 1;
    SCColor black;
    black.red = 0.0;
    black.green = 0.0;
    black.blue = 0.0;
    black.alpha = 0.6;
    SCColorCopy(&black, &(fppp.markerColor));
    SCAddVarsToTimePlot("plot_7", "spikeTimes",  "spikes", &fppp );

    SCInitHistogramPlotParameters(&hpp);
    SCColorCopy(&colors[7], &(hpp.barColor));
    hpp.barsAreVertical = true;
    hpp.units = SC_HISTOGRAM_UNITS_COUNT;
    hpp.spacing = 5.0;
    hpp.spacingType = SC_HISTOGRAM_SPACING_MHO2_HO2;
    hpp.xAxis = 1;
    hpp.yAxis = 0;
    SCAddVarsToHistogram("plot_7", "spikeTimes", &hpp);

    SCInitHistogramPlotParameters(&hpp);
    SCColorCopy(&colors[7], &(hpp.barColor));
    hpp.barsAreVertical = false;
    hpp.units = SC_HISTOGRAM_UNITS_COUNT;
    hpp.xAxis = 0;
    hpp.yAxis = 1;
    SCAddVarsToHistogram("plot_7", "spikes", &hpp);

    SCMultiLinesPlotParameters mlpp;
    SCInitMultiLinesPlotParameters(&mlpp);
    mlpp.lineWidth = 4.0;
    mlpp.lineStyle = SC_LINE_STYLE_COARSE_DASH;
    mlpp.linesAreVertical = true;
    mlpp.xAxis = 1;
    mlpp.yAxis = 1;
    SCColorCopy(&colors[0], &mlpp.lineColor);
    SCAddVarsToMultiLines("plot_7", "spikeTimes0", NULL, NULL, NULL, &mlpp);
}



/* All values set as percentages of the total screen size. */
/* The frame is set with four variables, which are defined in a rectangle.
 * 1. x - the x coordinate value of the bottom left corner
 * 2. y - the y coordinate value of the bottom left corner
 * 3. width - the width of the window
 * 4. height  - the height of the window
 *
 * So the window is defined by the bottom left point and the heigh and width.  To normalize for varied screen sizes, we
 * work in over screen percentage.
 *
 *  (x%, y%+height%) --- (x%+width%,y%+height%)
 *    |                    |
 *  (x%,y%)    -----   (x%+width%,y%)
 *
 * SCSetWindowData(char * plot_name, double x%, double y%, double width%, double height%);  
 */
void AddWindowDataForPlots(const char * plot_name, void * model_data)
{
    if ( !strcmp(plot_name, "plot_0") )
        SCSetWindowData(plot_name, 0.0, 0.00, 0.5, 0.25);
    if ( !strcmp(plot_name, "plot_1") )
        SCSetWindowData(plot_name, 0.0, 0.25, 0.5, 0.25);
    if ( !strcmp(plot_name, "plot_2") )
        SCSetWindowData(plot_name, 0.0, 0.50, 0.5, 0.25);
    if ( !strcmp(plot_name, "plot_3") )
        SCSetWindowData(plot_name, 0.0, 0.75, 0.5, 0.25);
    if ( !strcmp(plot_name, "plot_4") )
        SCSetWindowData(plot_name, 0.5, 0.0, 0.5, 0.25);
    if ( !strcmp(plot_name, "plot_5") )
        SCSetWindowData(plot_name, 0.5, 0.25, 0.5, 0.25);
    if ( !strcmp(plot_name, "plot_6") )
        SCSetWindowData(plot_name, 0.5, 0.50, 0.5, 0.25);
    if ( !strcmp(plot_name, "plot_7") )
        SCSetWindowData(plot_name, 0.5, 0.75, 0.5, 0.25);
}



/* There should be as many pStruct definitions as there are distinct plot names defined in the function 
   SCaddVariablesToPlotByName(plot_name_buff, x_var_name_buff,  y_var_name_buff);  */
/* Only fill in the values that you would like to modify.  The system will make reasonable guesses for defaults, to the
 * extent it knows about the information. */
void SetPlotParameters(SCDefaultAxisParameters * dap, const char * plot_name, void * model_data)
{
    if ( !strcmp(plot_name, "plot_0") )
    {
        SCTextCopy((char *)plot_name, &dap->title);
        //dap->xAxisType = SC_AXIS_LINEAR;
        //dap->xAxisType = SC_AXIS_REVERSE;
        //dap->xAxisType = SC_AXIS_LOGARITHMIC; 
        dap->xAxisType = SC_AXIS_REVERSE_LOGARITHMIC; // made reversed logaritmic
        dap->yAxisType = SC_AXIS_REVERSE;
        dap->xMin = 0.0;
        dap->xMax = plotDuration;
        dap->xTicks = 10.0;
        SCTextCopy("Foo Label", &dap->xLabel);
        dap->yMin = 0.0;
        dap->yMax = 10.0;
        dap->yTicks = 1.0;
        dap->gridType = SC_GRID_NONE;
        SCTextCopy("Foo Y Label", &dap->yLabel);
    }

    if ( !strcmp(plot_name, "plot_1") )    
    {
        SCTextCopy((char *)plot_name, &dap->title);
        dap->xMin = -1.0;
        dap->xMax = 10.0;
        dap->xTicks = 1.0;
        SCTextCopy("Too Label", &dap->xLabel);
        dap->yMin = -1.0;
        dap->yMax = 10.0;
        dap->yTicks = 1.0;
        dap->gridType = SC_GRID_X_ONLY;
        SCTextCopy("Too Y Label", &dap->yLabel);
    }

    if ( !strcmp(plot_name, "plot_2") )
    {
        SCTextCopy((char *)plot_name, &dap->title);
        dap->xMin = -6.0;
        dap->xMax = 6.0;
        dap->xTicks = 10.0;
        SCTextCopy("Goo Label", &dap->xLabel);
        dap->yMin = -3.0;
        dap->yMax = 3.0;
        dap->yTicks = 1.0;
        SCTextCopy("Goo Y Label", &dap->yLabel);
    }

    if ( !strcmp(plot_name, "plot_3") )
    {
        SCTextCopy("Zarg the destroyer!", &dap->title);
        dap->xMin = 0.0;
        dap->xMax = plotDuration;
        dap->xTicks = 40.0;
        SCTextCopy("Joo Label", &dap->xLabel);
        dap->yMin = 0.0;
        dap->yMax = 10.0;
        dap->yTicks = 1.0;
        dap->gridType = SC_GRID_Y_ONLY;
        SCTextCopy("Joo Y Label", &dap->yLabel);
    }

    if ( !strcmp(plot_name, "plot_4") )
    {
        SCTextCopy((char *)plot_name, &dap->title);
        dap->xMin = 0.0;
        dap->xMax = 10+1;
        dap->xTicks =(dap->xMax - dap->xMin)/5.0;
        dap->yMin =-5.0;
        dap->yMax = 5.0;
        dap->yTicks = (dap->yMax - dap->yMin)/5.0;
        dap->gridType = SC_GRID_X_AND_Y;
        dap->doDrawXAxis = false;
        dap->doDrawYAxis = false;
        dap->boxStyle = SC_BOX_ONLY_AXIS;
        SCTextCopy("Joo Y Label", &dap->yLabel);
    }

    if ( !strcmp(plot_name, "plot_5") )
    {
        SCTextCopy((char *)plot_name, &dap->title);
        dap->xMin = 0.0;
        dap->xMax = plotDuration;
        dap->xTicks =(dap->xMax - dap->xMin)/5.0;
        dap->yMin = 0.0;
        dap->yMax = 10.0;
        dap->yTicks = (dap->yMax - dap->yMin)/5.0;
        dap->gridType = SC_GRID_X_AND_Y;
        SCTextCopy("5 Y Label", &dap->yLabel);
    }

    if ( !strcmp(plot_name, "plot_6") )
    {
        SCTextCopy((char *)plot_name, &dap->title);
        dap->xMin = 0.0;
        dap->xMax = 10;
        dap->xTicks = (dap->xMax - dap->xMin)/10.0;
        dap->doCropWithXMinMax = false;
        dap->yMin = 0.0;
        dap->yMax = 0.6;
        dap->yTicks = (dap->yMax - dap->yMin)/5.0;
        dap->doCropWithYMinMax = false;
        dap->gridType = SC_GRID_X_AND_Y;
        SCTextCopy("6 Yaya Label", &dap->yLabel);
    }

    if ( !strcmp(plot_name, "plot_7") )
    {
        SCTextCopy((char *)plot_name, &dap->title);
        dap->xMin = 0.0;
        dap->xMax = 50.0;
        dap->xTicks = 10.0;
        dap->yMin = 0.0;
        dap->yMax = 50.0;
        dap->yTicks = 10.0;
        dap->gridType = SC_GRID_NONE;
        dap->xAxisType = SC_AXIS_REVERSE;
        dap->yAxisType = SC_AXIS_REVERSE;
        SCTextCopy("6 Y Label", &dap->yLabel);
    }
    
}

/* Be very careful with this function!  These parameters may be updated MANY times by the slider! Literally, as you drag
 * the slider, this function could be called 50 times.  So it really should only be used to set a value.
 * -DCS:2009/06/01 */
void ParameterAction(const char * parameter_name, double parameter_value, void* model_data)
{
    SCWriteLine(parameter_name, parameter_value);
}

/* Since this is called from a button instead of a slider UI element, there isn't the same concern. */
void ButtonAction(const char * button_name, bool button_value, void * model_data)
{
    SCWriteLine(button_name, (double)button_value);
    if ( !strcmp(button_name, "plotsomething") )
    {
        
        double myX[4];
        myX[0] = 0.0;
        myX[1] = 2.5;
        myX[2] = 5.0;
        myX[3] = 10.0;
        SCPlotParameters lpp;
        SCInitPlotParameters(&lpp);
        SCColor blue;
        SCColorFromName("blue", &blue);
        SCColorCopy(&blue, &(lpp.lineColor));
        lpp.lineWidth = 4.0;
        SCMakePlotNow("plot_1", myX, myX, 4, &lpp, SC_LAST_IN_ORDER);
        SCMakePlotNowFMC("plot_1", "spikes0", "spikeTimes0", &lpp, SC_LAST_IN_ORDER);

        SCBarPlotParameters bpp;
        SCInitBarPlotParameters(&bpp);
        SCMakeBarNowFMC("plot_1", "spikeTimes0", &bpp, 0);

        SCHistogramPlotParameters hpp;
        SCInitHistogramPlotParameters(&hpp);
        SCMakeHistogramNowFMC("plot_1", "spikeTimes", &hpp, 0);

        SCFitPlotParameters fpp;
        SCInitFitPlotParameters(&fpp);
        SCMakeFitNowFMC("plot_1", "varlength1", "varlength2", &fpp, SC_LAST_IN_ORDER, "a*x", 1, "a", 1.0);

        SCSmoothPlotParameters spp;
        SCInitSmoothPlotParameters(&spp);
        SCMakeSmoothNowFMC("plot_1", "varlength1", "varlength2", &spp, SC_LAST_IN_ORDER);
    }
    
}


/* Call this function before the start of the RUN button. */
void InitForRun(void * model_data)
{
    SCWriteText("InitForRun");
    SCWriteAttributedText("User attributed text test!", "purple", 20);
    SCWriteWarning("User warning test!");
}


/* At the beginning of each plot duration this function is called in the event that some storage needs to be allocated
 * or some state initialized. */
void InitForPlotDuration(void * model_data)
{
    SCWriteText("InitForPlotDuration");
    plotTime = 0.0;
    SCWriteLine("simTime", simTime);
    SCWriteLine("jumpValue", SCGetParameterValue("jumpValue"));

    SCColor blue;
    blue.red = 0.0;
    blue.green = 0.0;
    blue.blue = 1.0;
    blue.alpha = 1.0;

    SCColor red;
    red.red = 1.0;
    red.green = 0.0;
    red.blue = 0.0;
    red.alpha = 1.0;

    SCColor yellow;
    yellow.red = 1.0;
    yellow.green = 1.0;
    yellow.blue = 0.0;
    yellow.alpha = 1.0;

    
    /* Note that one can plot in the InitForPlotDuration. Basically, you can set up lines and they will persist for the
     * entire ensuing plot duration.  Here we simply plot a line with some points on top of it that move with the jump
     * value. */
    SCPlotParameters lpp;
    SCInitPlotParameters(&lpp);
    SCColorCopy(&blue, &(lpp.lineColor));
    lpp.lineWidth = 4.0;
    double myData[4];
    myData[0] = 1.0;
    myData[1] = SCGetParameterValue("jumpValue");
    myData[2] = 6.0;
    myData[3] = 10.0;

    double myX[4];
    myX[0] = 0.0;
    myX[1] = 2.5;
    myX[2] = 5.0;
    myX[3] = 10.0;
    SCMakePlotNow("plot_1", myX, myData, 4, &lpp, SC_LAST_IN_ORDER);

    SCColorCopy(&red, &(lpp.lineColor));
    lpp.lineWidth = 2.0;
    SCMakePlotNow("plot_1", myX, myData, 4, &lpp, SC_LAST_IN_ORDER);


    SCPlotParameters ppp; // declared above
    SCInitPlotParameters(&ppp);
    ppp.markerSize = 24;
    ppp.markerStyle = SC_POINT_STYLE_TRIANGLE;
    SCColorCopy(&blue, &(ppp.markerColor));

    SCMakePlotNow("plot_1", myX, myData, 4, &ppp, 2);


    SCRangePlotParameters rpp;
    SCInitRangePlotParameters(&rpp);
    rpp.xRangeType = SC_RANGE_COLUMNS;
    rpp.yRangeType = SC_RANGE_COLUMNS;
    rpp.lineWidth = 1.0;
    rpp.lineStyle = SC_LINE_STYLE_SOLID;
    blue.alpha = 0.5;
    SCColorCopy(&blue, &(rpp.fillColor));
    SCMakeRangeNow("plot_5", RectXMins, RectXMaxs, RectYMins, RectYMaxs, NULL, NRECTS, NULL, &rpp, 0);

    SCHistogramPlotParameters hpp;
    SCInitHistogramPlotParameters(&hpp);
    SCColorCopy(&yellow, &(hpp.barColor));
    hpp.barsAreVertical = true;
    hpp.barType = SC_HISTOGRAM_BAR_BARS;
    hpp.units = SC_HISTOGRAM_UNITS_PROBABILITY;
    hpp.spacingType = SC_HISTOGRAM_SPACING_MHO2_HO2;
    hpp.spacing = 0.25;
    SCMakeHistogramNow("plot_6", RandomVariables, NRANDOMVARS, &hpp, 0);

    SCFitPlotParameters fpp;
    SCInitFitPlotParameters(&fpp);
    SCColorCopy(&blue, &(fpp.lineColor));
    fpp.lineWidth = 10;
    fpp.lineStyle = SC_LINE_STYLE_FINE_DOTS;
    SCMakeFitNow("plot_2", TimeValues, SineValues, NSINEFUNVALS, &fpp, 0, "cos(a*x + b)", 2, "a", 2.0, "b", 2.5);

    SCSmoothPlotParameters spp;
    SCInitSmoothPlotParameters(&spp);
    SCColorCopy(&yellow, &(spp.lineColor));
    yellow.alpha = 0.5;
    spp.smoothness = 0.5;
    spp.lineWidth = 10;
    spp.lineStyle = SC_LINE_STYLE_FINE_DOTS;
    SCMakeSmoothNow("plot_2", TimeValues, SineValues, NSINEFUNVALS, &spp, 0);

    SCInitRangePlotParameters(&rpp);
    rpp.xRangeType = SC_RANGE_INTERVAL;
    rpp.yRangeType = SC_RANGE_ALTERNATES;
    rpp.xMin = 0.0;
    rpp.xMax = plotDuration;
    rpp.yMin = 0.0;
    rpp.yStride = 10.0;
    rpp.lineWidth = 1.0;
    rpp.xAxis = 1;
    rpp.yAxis = 1;
    rpp.lineStyle = SC_LINE_STYLE_EMPTY;
    yellow.alpha = 0.1;
    SCColorCopy(&yellow, &(rpp.fillColor));
    SCMakeRangeNow("plot_7", NULL, NULL, NULL, NULL, NULL, 0, NULL, &rpp, 0);

    SCScatterPlotParameters scpp;
    SCInitScatterPlotParametersWithSensibleValue(&scpp);
    scpp.markerSize = 8;
    SCColorCopy(&yellow, &scpp.borderColor);
    scpp.borderSize = 3;
    SCColorCopy(&red, &scpp.markerColor);
    scpp.colorType = SC_SCATTER_PLOT_COLOR_BORDER;
    scpp.xAxis = 1;
    SCMakeScatterNow("plot_4", SineValues, TimeValues, TimeValues, TimeValues, NSINEFUNVALS, "mycolors", &scpp, 0);

}


/* This is the main function, which is called once per simulation time step. The idea is to advance your simulation one
 * time step and plot anything if need be.  The second parameter, is_plot_iter lets you know whether or not this
 * iteration of values will be collected for plotting.  The point is that if you are computing some values only for the
 * sake of plotting them (not crucial to the simulation, then you only need to do it when is_plot_iter is true.
 * Remember that any watched variables are automatically plotted, so you don't need to worry about plotting them ever.
 * That's the whole point, to simplifly RunModelOneStep as much as possible to just the bare bones simulation, making
 * the code much more portable and also intelligable.  Of course, in this "model" file you'll mostly see plotting calls,
 * simply to showcase what SC is all about, but hopefully in your own code this function will primarily be simulation
 * code. */
void RunModelOneStep(void * model_data, bool is_plot_iter)
{
    
    int j = 0;
    
    simTime += DT;
    plotTime += DT;
    double freq = SCGetParameterValue("freq");
    double amp = SCGetParameterValue("amp");
    double jump_value = SCGetParameterValue("jumpValue");
    bool do_wiggle = SCGetButtonValue("wiggle");

    double sleep_ms = SCGetParameterValue("sleep_ms");
    if ( sleep_ms > 0.0 )
        usleep((long)sleep_ms*1000);


    /* Actually update some values that ware watched (the sinusoid plots. ) */
    if ( do_wiggle )
    {
        for ( j = 0; j < NVARS; j++ )
        {
            Variables[j] = amp*sin(freq*0.025*((double)j)*2.0*MY_PI*simTime) + jump_value;
        }
    }

    /* Gather some data */
    if ( (int)simTime % 2 == 0 )
    {
        /* Any of these three methods can add data to a managed data column. */

        //SCAddDataToManagedColumn("varlength1", &Variables[2], 1);
        SCAddOneValueToManagedColumn("varlength1", Variables[2]);
        //SCAddManyValuesToManagedColumn("varlength1", 2, Variables[1], Variables[2]);
        
        //SCAddDataToManagedColumn("varlength2", &Variables[3], 1);
        SCAddOneValueToManagedColumn("varlength2", Variables[3]);
        //SCAddManyValuesToManagedColumn("varlength2", 2, Variables[3], Variables[4]);
    }

    if ( plotTime == 100 )
    {
        SCColor blue;
        blue.red = 0.0;
        blue.green = 0.0;
        blue.blue = 1.0;
        blue.alpha = 1.0;

        SCBarPlotParameters bpp;
        SCInitBarPlotParameters(&bpp);
        SCColorCopy(&blue, &(bpp.barColor));
        bpp.barsAreVertical = false;
        double myBar = SCGetParameterValue("jumpValue");
        bpp.offset = 1.0 + myBar;
        SCMakeBarNow("plot_1", &myBar, 1, &bpp, 0);

        SCMultiLinesPlotParameters mlpp;
        SCInitMultiLinesPlotParameters(&mlpp);
        SCMakeMultiLinesNow("plot_1", &myBar, NULL, NULL, &myBar, 1, &mlpp, 0);
    }

    
    if ( plotTime == 900 )
    {
        SCColor red;
        red.red = 1.0;
        red.green = 0.0;
        red.blue = 0.0;
        red.alpha = 1.0;

        SCBarPlotParameters bpp;
        SCInitBarPlotParameters(&bpp);
        SCColorCopy(&red, &(bpp.barColor));
        bpp.barsAreVertical = false;
        bpp.offset = 2.0;
        
        double myBar = SCGetParameterValue("jumpValue");
        SCMakeBarNow("plot_1", &myBar, 1, &bpp, 0);
    }

    if ( is_plot_iter )
    {
        double mean = SCGetParameterValue("jumpValue");

        /* Thes random variables are for the histogram. */
        for ( int i = 0; i < NRANDOMVARS; i++ )
        {
            RandomVariables[i] =  mean + gsl_ran_gaussian(RNG, 1.0);
        }

        for ( int i = 0; i < NSINEFUNVALS; i++ )
        {
            SineValues[i] = sin(mean*TimeValues[i] + plotTime) + gsl_ran_gaussian(RNG, 0.33);
        }
        
        for ( int i = 0; i < NRECTS; i++ )
        {
            double x_move = gsl_ran_gaussian(RNG, 1.0);
            double y_move = gsl_ran_gaussian(RNG, 0.025);
            RectXMins[i] += x_move;
            RectXMaxs[i] += x_move;
            RectYMins[i] += y_move;
            RectYMaxs[i] += y_move;
        }
        
    }


    /* Something like plotting a spike raster. Since we don't know the length (due to randomness) we use the managed
     * column. */
    if ( 0 )
    {
        for ( int i = 0; i < NSPIKERASTERS; i++ )
        {
            char spike_name_buff[50];
            char spike_time_name_buff[50];
            if ( gsl_ran_gaussian(RNG, 1.0) > (1.5  + 0.01*plotTime))
            {
                double val = i;
                sprintf(spike_name_buff, "spikes%i", i);
                sprintf(spike_time_name_buff, "spikeTimes%i", i);
                SCAddDataToManagedColumn(spike_name_buff, &val, 1);
                SCAddDataToManagedColumn(spike_time_name_buff, &plotTime, 1);
            }
        }
    }
    else if ( 0 )
    {
        for ( int i = 0; i < NSPIKERASTERS; i++ )
        {
            if ( gsl_ran_gaussian(RNG, 1.0) > 2.0 )
            {
                double val = i;
                SCAddDataToManagedColumn("spikes", &val, 1);
                SCAddDataToManagedColumn("spikeTimes", &plotTime, 1);
            }
        }
    }
    else
    {
        double vals[NSPIKERASTERS];
        double spike_times[NSPIKERASTERS];
        int nvals = 0;
        for ( int i = 0; i < NSPIKERASTERS; i++ )
        {
            if ( gsl_ran_gaussian(RNG, 1.0) > (1.5  + 0.001*plotTime) )
            {
                vals[nvals] = i;
                spike_times[nvals] = plotTime;
                nvals++;
            }
        }
        SCAddDataToManagedColumn("spikes", vals, nvals);
        SCAddDataToManagedColumn("spikeTimes", spike_times, nvals);

        if ( gsl_ran_gaussian(RNG, 1.0) > 2.5 )
        {
            double neuron_id = 0.0;
            SCAddDataToManagedColumn("spikes0", &neuron_id, 1);
            SCAddDataToManagedColumn("spikeTimes0", &plotTime, 1);
        }        
    }
}


/* This function is called after a complete plot duration.  If there is any temporary storage that needs to be cleared
 * away, or some state modified, here is the place to do it. */
void CleanupAfterPlotDuration(void * model_data)
{
    plotIters++;
    SCWriteLine("CleanupAfterPlotDuration", plotIters);
    double jump_value = SCGetParameterValue("jumpValue");
    SCSetParameterValue("jumpValue", jump_value + .1);
    if ( plotIters % 2 == 0 )
        SCSetButtonValue("wiggle", true); 
    else
        SCSetButtonValue("wiggle", true);

    if ( plotIters % 10 == 0 )
        SCClearMakeNowPlots("plot_1");

    //SCClearManagedColumns("spikeTimes", 1);
    //SCClearManagedColumn("spikeTimes");
    double * spike_data = NULL;
    int nvalues = 0;
    SCCopyDataFromManagedColumn("spikeTimes0", &spike_data, &nvalues);
    for ( int i = 0; i < nvalues; i++ )
        SCWriteLineInt("spikeTimes0", spike_data[i]);
    free(spike_data);           /* don't forget to clean up. */
}


void CleanupAfterRun(void * model_data)
{
    SCWriteText("CleanupAfterRun");
}


/* Pretty much anything that was malloced in InitModel should be deallocated here.  Same sentiment for resources,
 * etc. */
void CleanupModel(void * model_data)
{
    SCWriteText("CleanupModel");
    
    if ( Variables != NULL )
        free( Variables );
    Variables = NULL;    
}
