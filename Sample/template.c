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

double	x;

/***************************************************************************************
 MODEL INITIALIZATION	
***************************************************************************************/
void * InitModel()
{
    DT = 0.1; 
    simTime = -DT; 
    SCStartRunImmediatelyAfterInit(false);
    SCCallParameterActionOnAll();
	
    return NULL;
}


/**************************************************************************************
 ARRANGE WINDOWS
	SCSetWindowData(plot_name, fromLeft, fromBottom, width, height);
***************************************************************************************/
void AddWindowDataForPlots(const char * plotName, void * modelData)
{
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
    int nPoints, plotNum, drawNum;
    
    plotDuration = 100.0;
    plotNum = 1000;
    drawNum = 1;
    
    nPoints = ceil(plotDuration/DT);
    SCSetNStepsInFullPlot(nPoints);
    SCSetNStepsBetweenPlotting(nPoints/plotNum);
    //SCSetNStepsBetweenDrawing(nPoints/drawNum);
    SCDoRedrawBasedOnTimer(true);
    SCDoPlotInParallel(false);
    
    SCInitTimePlotParametersWithSensibleValues(&TPParams);
    TPParams.lineType = SC_TIME_PLOTS_SAME_LINE;
    TPParams.lineWidth = 2.0;
    SCColorFromName("blue", &TPParams. lineColor);
    TPParams.markerStyle = SC_POINT_STYLE_EMPTY;
    TPParams.markerSize = 8;
    SCColorFromName("red", &TPParams.markerColor);
    TPParams.yOffset = 1.0;
    
    SCInitPlotParametersWithSensibleValues(&PParams);
    PParams.lineStyle = SC_LINE_STYLE_EMPTY;
    PParams.lineWidth = 1.0;  //use 1.0 for speed
    SCColorFromName("black", &PParams.lineColor);
    PParams.markerStyle = SC_POINT_STYLE_CIRCLE;
    PParams.markerSize = 4;
    SCColorFromName("blue", &PParams.markerColor);
    PParams.yOffset = 0.0;
    
    SCInitMultiLinesPlotParametersWithSensibleValues(&MLPParams);
    MLPParams.lineStyle = SC_LINE_STYLE_SOLID;
    MLPParams.lineWidth = 1.0;
    MLPParams.linesAreVertical = true;
    SCColorFromName("black", &MLPParams.lineColor);
    MLPParams.fixedLowerLimit = 0.0;	
    MLPParams.fixedUpperLimit = 1.0;
    
    SCInitHistogramPlotParametersWithSensibleValues(&HPParams);
    HPParams.barType = SC_HISTOGRAM_BAR_BARS; //SMOOTH; CENTER; STAIRS; 
    //SPACED_BARS; LEFT_OR_BELOW; RIGHT_OR_ABOVE; 
    HPParams.units = SC_HISTOGRAM_UNITS_PROBABILITY; //COUNT; DENSITY; PERCENT_IN_BIN
    SCColorFromName("cyan", &HPParams.barColor);
    HPParams.barsAreVertical = true;
    HPParams.spacingType = SC_HISTOGRAM_SPACING_MHO2_HO2; //AUTOMATIC; ZERO_TO_H; LOG_BIN
    HPParams.spacing = 0.05;
    HPParams.smoothValue = 0.2;
    
    SCAddPlot("plot", false);
}


/**************************************************************************************
 PLOT DATA
***************************************************************************************/
void SetPlotParameters(pStruct * pData, const char * plotName, void * modelData)
{
    SCInitPStructWithSensibleValues(pData);
    SCTextCopy("", &pData-> title); //(char *)plotName
    pData->gridType = SC_GRID_NONE; //SC_GRID_X_ONLY; SC_GRID_Y_ONLY; SC_GRID_X_AND_Y
    pData->xAxisType = SC_AXIS_LINEAR; //SC_AXIS_REVERSE; SC_AXIS_LOGARITHMIC;
    pData->yAxisType = SC_AXIS_LINEAR; //SC_AXIS_REVERSE_LOGARITHMIC;
    //pData->boxStyle = SC_BOX_AXIS; //SC_BOX_ONE; SC_BOX_ONLY_AXIS; SC_BOX_OFFSET_AXIS
    if (!strcmp(plotName, "plot"))
    {
        SCTextCopy("t", &pData->xLabel);
        SCTextCopy("x", &pData->yLabel);
        pData->xMin = 0.0;
        pData->xMax = plotDuration;
        pData->xTicks = plotDuration/5;
        pData->yMin = 0.0;
        pData->yMax = 1.0;
        pData->yTicks = 0.2;
    }
}


/**************************************************************************************
 SET UP BUTTONS	
***************************************************************************************/
void AddControllableButtons(void * modelData)
{
    SCAddControllableButton("going", false, "Continuous", "One-Shot");
}


/**************************************************************************************
 BUTTON ACTION
***************************************************************************************/
void ButtonAction(const char * buttonName, bool buttonValue, void * modelData)
{

}


/**************************************************************************************
 SET UP PARAMETERS	
***************************************************************************************/
void AddControllableParameters(void * modelData)
{
    SCAddControllableParameter("x", 0.0, 2.0, 1.0);
}


/**************************************************************************************
 PARAMETER ACTION
***************************************************************************************/
void ParameterAction(const char * parameterName, double parameterValue, void * modelData)
{
    if (!strcmp(parameterName, "x"))
        x = parameterValue;
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
void RunModelOneStep(void * modelData, bool isPlotIter)
{
    simTime += DT; 
    runTime += DT; 
    plotTime += DT;
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
void InitForPlotDuration(void * modelData)
{
    plotTime = -DT;
}


void InitForRun(void* modelData)
{
    runTime = -DT;
}


/**************************************************************************************
 CLEAN UP
	SCStopRuning(); 
***************************************************************************************/
void CleanupAfterPlotDuration(void * modelData)
{
    if (SCGetButtonValue("going"))
    {
        SCStopRunning();
    }
}


void CleanupAfterRun(void * modelData)
{
    
}


void CleanupModel(void * modelData)
{
    
}

/**************************************************************************************
 ADDITIONAL PROCEDURES
***************************************************************************************/
