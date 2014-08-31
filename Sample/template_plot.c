/***************************************************************************************
 HEADER FILES
***************************************************************************************/

#include <stdlib.h>
#include <math.h>
#include <Carbon/Carbon.h>
#ifndef _NO_USER_LIBRARY_
#include <SimulationControllerFramework/SCPlotParameters.h>
#include <SimulationControllerFramework/SimulationController.h> 
#else
#include "SCPlotParameters.h"
#include "SimulationController.h"
#endif

/**************************************************************************************
 PLOTTING GLOBALS
***************************************************************************************/

/* xx1xx */
double simTime, runTime, plotTime, plotDuration, DT;



SCTimePlotParameters TPParams;  
SCPlotParameters PParams;
SCHistogramPlotParameters HPParams;  
SCMultiLinesPlotParameters MLPParams;
SCBarPlotParameters BPParams;  
SCFitPlotParameters FPParams;
SCSmoothPlotParameters SmPParams; 
SCScatterPlotParameters ScPParams;
SCAxisParameters AxParams;

//FILE						*theFile;

/***************************************************************************************
 DEFINES	
***************************************************************************************/

/***************************************************************************************
 GLOBALS	
***************************************************************************************/

double y;
/***************************************************************************************
 MODEL INITIALIZATION	
***************************************************************************************/
void * InitModel()
{

/* xx2xx */
    DT = 0.1;
    simTime = -DT;
    int nPoints, plotNum, drawNum;
    plotDuration = 100.0;
    plotNum = 1000;
    drawNum = 1;

/* xx7xx */
    SCStartRunImmediatelyAfterInit(false);    
    nPoints = ceil(plotDuration/DT);
    SCSetNStepsInFullPlot(nPoints);
    SCSetNStepsBetweenPlotting(nPoints/plotNum);
    //SCSetNStepsBetweenDrawing(nPoints/drawNum);
    SCDoRedrawBasedOnTimer(true);
    SCDoPlotInParallel(false);



    SCCallParameterActionOnAll();

    
    y = 0.0;
	
    return NULL;
}


/**************************************************************************************
 ARRANGE WINDOWS
	SCSetWindowData(plot_name, fromLeft, fromBottom, width, height);
***************************************************************************************/
void AddWindowDataForPlots(const char * plotName, void * modelData)
{
    /* xx5xx */
    if (!strcmp(plotName, "plot"))
    {
        SCSetWindowData(plotName, 0.0, 0.5, 1.0, 0.5);
    }
}


/**************************************************************************************
SET UP PLOTTING
	SCAddWatchedTimeColumn("x", &x, SC_KEEP_DURATION); SC_KEEP_PLOT_POINT 
	SCAddWatchedTimeColumns("x", &x, N, SC_KEEP_DURATION); SC_KEEP_REDRAW
	SCAddWatchedFixedSizeColumn("x", &x, N); SCAddStaticColumn("x", &x, N); 
	SCAddManagedColumn("x"); SCAddManagedColumns("x", N);
	SCAddManagedColumnWithSize("x", size);
	SCAddManagedColumns("x", N);    
	SCAddManagedColumnsWithSize("x", N, size);  
	SCAddExpressionVariable("f", "function");
	SCAddVarsToTimePlot("plot", "t", "x", &TPParams);
	SCAddVarsToPlot("plot", "x", "y", &PParams);
	SCAddVarsToMultiLines("plot", "t", "low"NULL, "hi"NULL, "lbls"NULL, &MLPParams);
	SCAddVarsToBar("plot", "data", N, &BPParams);
	SCAddVarsToHistogram("plot", "data", N, &HPParams);
	SCAddVarsToFit("plot", "t", "x", &FPParams, "func", nP, "p1", v1, "p2", v2);
	SCAddVarsToSmooth("plot", "t", "x", &FPParams);
	SCAddVarsToScatter("plot", "x", "y", "size", "color", "colorScheme");
	SCAddAxisToPlot("name", &AxParams); SCColorRangeFromName("color", &color);
	SCColorRangeFromNames("color1", "color2", N, &colors, alpha);
	SCAddColorScheme("colorScheme", Nc, &CRType, &xStart, &xStop, &colors); 
	SC_TIME_PLOTS_SAME_LINE; SC_TIME_PLOTS_NO_LINE; SC_LINE_STYLE_STANDARD; 
	SC_LINE_STYLE_EMPTY; SC_LINE_STYLE_SOLID; SC_LINE_STYLE_DOTTED; 
	SC_LINE_STYLE_FINE_DOTS; SC_LINE_STYLE_COARSE_DASH; 
	SC_LINE_STYLE_FINE_DASH; SC_LINE_STYLE_DASH_DOT;
	SC_POINT_STYLE_EMPTY; SC_POINT_STYLE_CIRCLE; SC_POINT_STYLE_FILLED_CIRCLE; 
	SC_POINT_STYLE_TRIANGLE; SC_POINT_STYLE_FILLED_TRIANGLE; 
	SC_POINT_STYLE_BOX; SC_POINT_STYLE_FILLED_BOX; 
	SC_POINT_STYLE_DIAMOND; SC_POINT_STYLE_FILLED_DIAMOND; 
	SC_POINT_STYLE_PLUS; SC_POINT_STYLE_CROSS;
***************************************************************************************/
void AddPlotsAndRegisterWatchedVariables(void * modelData)
{

    /* xx8xx */
    SCInitTimePlotParametersWithSensibleValues(&TPParams);
    TPParams.lineType = SC_TIME_PLOTS_SAME_LINE;
    TPParams.lineWidth = 2.0;
    SCColorFromName("blue", &TPParams. lineColor);
    TPParams.markerStyle = SC_POINT_STYLE_DIAMOND;
    TPParams.markerSize = 8.0;
    SCColorFromName("red", &TPParams.markerColor);
    TPParams.yOffset = 1.0;
    

    /* xx9xx */
    SCAddPlot("plot", false);

    SCAddWatchedTimeColumn("plotTime", &plotTime, SC_KEEP_DURATION);
    SCAddWatchedTimeColumn("y", &y, SC_KEEP_DURATION);
    SCAddVarsToTimePlot("plot", "plotTime", "y", &TPParams);
}



/**************************************************************************************
 PLOT DATA
***************************************************************************************/
void SetPlotParameters(SCDefaultAxisParameters * dap, const char * plot_name, void * model_data)
{
/* xx6xx */
    SCInitPStructWithSensibleValues(dap);
    SCTextCopy("", &dap-> title); //(char *)plot_name
    dap->gridType = SC_GRID_NONE; //SC_GRID_X_ONLY; SC_GRID_Y_ONLY; SC_GRID_X_AND_Y
    dap->xAxisType = SC_AXIS_LINEAR; //SC_AXIS_REVERSE; SC_AXIS_LOGARITHMIC;
    dap->yAxisType = SC_AXIS_LINEAR; //SC_AXIS_REVERSE_LOGARITHMIC;
    //dap->boxStyle = SC_BOX_AXIS; //SC_BOX_ONE; SC_BOX_ONLY_AXIS; SC_BOX_OFFSET_AXIS
    if (!strcmp(plot_name, "plot"))
    {
        SCTextCopy("t", &dap->xLabel);
        SCTextCopy("x", &dap->yLabel);
        dap->xMin = 0.0;
        dap->xMax = plotDuration;
        dap->xTicks = plotDuration/5;
        dap->yMin = -1.0;
        dap->yMax = 1.0;
        dap->yTicks = 0.2;
    }
}


/**************************************************************************************
 SET UP BUTTONS	
***************************************************************************************/
void AddControllableButtons(void * model_data)
{
    SCAddControllableButton("going", false, "Continuous", "One-Shot");
}


/**************************************************************************************
 BUTTON ACTION
***************************************************************************************/
void ButtonAction(const char * button_name, bool button_value, void * model_data)
{

}


/**************************************************************************************
 SET UP PARAMETERS	
***************************************************************************************/
void AddControllableParameters(void * model_data)
{
    /* xx4xx */
    SCAddControllableParameter("freq", 0.0, 2.0, 1.0);
    SCAddControllableParameter("amp", 0.0, 1.0, 1.0);
    SCAddControllableParameter("sleep", 0.0, 5000.0, 5000.0);
}


/**************************************************************************************
 PARAMETER ACTION
***************************************************************************************/
void ParameterAction(const char * parameter_name, double parameter_value, void * model_data)
{
}


/**************************************************************************************
 RUN ONE TIME STEP 
	SCGetButtonValue("name"); SCSetButtonValue("name"); 
	SCGetParameterValue("name"); SCSetParameterValue("name"); 
	SCWriteText("text"); SCWriteLine("name", var); 
	SCWriteAttributedText("text", "color", size); SCWriteWarning("text");
	SCAddDataToManagedColumn("x", &x, N);
	SCAddOneValueToManagedColumn("x", x);
	SCAddManyValuesToManagedColumn("x", N, x1, x2, ...);
***************************************************************************************/
void RunModelOneStep(void * model_data, bool is_plot_iter)
{
    /* xx3xx */
    simTime += DT;
    runTime += DT;
    plotTime += DT;
    double amp = SCGetParameterValue("amp");
    
    y = amp*sin(SCGetParameterValue("freq")* plotTime);
    
    usleep(SCGetParameterValue("sleep"));               /* slow things down for presentation */
}


/**************************************************************************************
 INITIALIZATIONS
 	SCClearMakeNowPlots("plot");
	SCMakePlotNow("plot", &x, &y, N, &PParms, order); SC_LAST_IN_ORDER
	SCMakeBarNow("plot", &x, &y, N, &BPParms, order);
	SCMakeHistogramNow("plot", &data, N, &HPParms, order);
	SCMakeFitNow("plot", &x, &y, N, &FPParams, order, "func", nP, "p1", v1, "p2", v2);
	SCMakeSmoothNow("plot", &x, &y, N, &SPParams, order);
	SCMakeScatterNow("plot", &x, &y, &size, &xColor, N, &colorScheme, &ScPParams, order);
	SCMakePlotNowFMC("plot", "x", "y", &PParams, order);
	SCMakeBarNowFMC("plot", "x", &BPParams, order);
	SCMakeHistogramNowFMC("plot", "x", &HPParams, order);
	SCMakeFitNowFMC("plot", "x", "y", &FPParams, order, "func", nP, "p1", "v1", ...); 
	SCMakeSmoothNowFMC("plot", "x", "y", &SmPParams, order);
	SCCopyDataFromManagedColumn("x", **data, &nValues);
        SCClearManagedColumn("x");
	SCClearManagedColumnsWithPrefix("x", N);
***************************************************************************************/
void InitForPlotDuration(void * model_data)
{
    /* xx2xx */
    plotTime = -DT;
}


void InitForRun(void* model_data)
{
    /* xx2xx */
    runTime = -DT;
}


/**************************************************************************************
 CLEAN UP
	SCStopRuning(); 
***************************************************************************************/
void CleanupAfterPlotDuration(void * model_data)
{
    if (SCGetButtonValue("going"))
    {
        SCStopRunning();
    }
}


void CleanupAfterRun(void * model_data)
{
    
}


void CleanupModel(void * model_data)
{
    
}

/**************************************************************************************
 ADDITIONAL PROCEDURES
***************************************************************************************/
