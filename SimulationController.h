#ifndef __SIMULATION_CONTROLLER_H
#define __SIMULATION_CONTROLLER_H

#include "SCPlotParameters.h"

#ifdef __cplusplus
extern "C" {
#endif 

/* These are the C interfaces, which should work for any objective C, C, or C++. */

/* Tell SC where you would like the windows to be placed on the screen. */
void SCSetWindowData(const char * plot_name, double left, double bottom, double width, double height);

/* Programmatically stop the simulation from running. Should be an SCStartRunning()? -DCS:2009/06/27 */
void SCStopRunning();

/* Set the maximum histories that SC will save.  By default the number of histories saved is unlimited.  Trust me, on a
 * modern computer you don't need set this unless you are doing something that involves tens of thousands of plot
 * durations and tons of data.  An input of 0 will not keep any histories at all. */
void SCSetMaxHistoryCount(int max_history_count);
    
/* Update the plots in parallel, if you are on a multicore machine. 
 *
 * False by default, because DG can be choppy, so it's apparently buggy.  Nevertheless, things can be much faster if you
 * have a multicore system and you set this to true.  */
void SCDoPlotInParallel(bool do_plot_in_parallel); 

/* Set the total simulation steps are in the plot? */
void SCSetNStepsInFullPlot(int n_steps_in_full_plot);

/* Set how often you want to plot a simulated point? (analogous to dtPlot in plotcore). */
void SCSetNStepsBetweenPlotting(int n_steps_between_plotting);

/* Give the option to start the run without the user pressing the "Run" button, if no called, it's assumed false. */
void SCStartRunImmediatelyAfterInit(bool do_start_run);

/* Should SC open in "demo" mode?  Demo mode minimizes the controller panel and sets the size of all the windows
 * normalized to the total screen size (as opposed to the total screen size minus the area the controller panel takes
 * up).  The default is false. */
void SCOpenInDemoMode(bool do_open_in_demo_mode);

/* SC Will measuring 30msec intervals (about the time your eye will notice a static image) so that you get nice plots.
 * The default is to have SC handle how often to redraw for you.  There are circumstances where you might want to
 * control it however (so set to false and see function below).  Specifically, if you are plotting fixed size columns
 * and want to see them at every plot point.  Think partial differential equation in time.  The default is true, so if
 * you don't know what you're doing, or don't care, then don't even bother to call this function with false. */
void SCDoRedrawBasedOnTimer(bool do_redraw_based_on_timer);
/* How often do you want those plotted points to be drawn to the screen?  If the above SCRedrawBasedOnTimer is set to
 * false, then choose how often (in terms of plot points you'd like to redraw to the screen.  Useful for plotting
 * functions through time e.g. sine(x+t). Make this parameter a multiple of n_steps_between_plotting. */
void SCSetNStepsBetweenDrawing(int n_steps_between_drawing);


/* Write to the SC interface either comments or comments with values. */
void SCWriteText(const char * text);
/* User configured. */
void SCWriteAttributedText(const char * text, char * text_color, int text_size);
/* Big and red. */
void SCWriteWarning(const char * text);
/* "text = value". */
void SCWriteLine(const char * text, double value);
/* Same as SCWriteLine, but included for consistency. */
void SCWriteLineDouble(const char * text, double value);
/* same but for integers. */
void SCWriteLineInt(const char * text, int value);


/* Simply declare a plot to SC.  If one uses any of the SCAddVariablesTo*PlotByName, then the SCAddPlot command is
 * unnecessary. Of course, one may declare the plot and then use SCAddVariablesTo*PlotByName if one wishes.  One must
 * use this function if there are exists a plot that will only have SCMake*PlotNow functions.  Should any make now plots
 * be deleted after each plot duration or should the be kept around until they are explicitly cleared by the user? By
 * default the answer is YES.  If this function isn't called, (since plots are added implicitly) the answer is still
 * YES. */
void SCAddPlot(char * plot_name, bool do_delete_makenowplots_after_duration);

/* Create an ADDITIONAL X or Y axis in the plot (the default axis is always there, so unless you are trying to do
 * something fancy, you probably don't need to to call this function).  If you create any additional axis, then you need
 * to specify to which axis a command should be drawn in the command options of the added commands.*/
void SCAddAxisToPlot(char * plot_name, SCAxisParameters * axis_parameters);

/* Create a color range in DG.  This can be used currently with scatter plots to get the points to color differently
 * based on how the values of the points fall into certain ranges.  All the values are copied, so you are responsible
 * for deallocating any memory for structures passed to this function. */
void SCAddColorSchemeToPlot(char * plot_name, char * color_scheme_name, int nranges, SCColorRangeType * range_types, 
                            double * range_starts, double * range_stops, SCColor * colors);



/* Add parameters to the user interface and set or query their value. */
void SCAddControllableParameter(char * param_name, double min_value, double max_value, double init_value);
double SCGetParameterValue(char * param_name);

/* Set the parameter value associated with the string param_name.  Calling this function will execute a callback to the
 * ParameterAction function so that your code can initialize whatever structures effectively.  So don't call
 * SCGetParameterValue inside of ParameterAction for the same parameter name, otherwise you'll create an infinite
 * recursion. */
void SCSetParameterValue(char * param_name, double value);

/* After creating all of the controllable parameters, some users like to call ParameterAction() for each defined
 * parameter, where ParameterAction is the function that ininitializes the model with parameters.  This way the
 * definition only happens in one place and is thus less error prone.  Use the following function for this purpose
 * (typically at the end of InitModel() or AddControllableParameters(), depending on your style. */
void SCCallParameterActionOnAll();
/* Add buttons the the user interface and set or query their value. */
void SCAddControllableButton(char * button_name, bool init_value, char * on_label, char * off_label);
bool SCGetButtonValue(char * button_name);
/* Set the button value associated with the string button_name */
void SCSetButtonValue(char * button_name, bool value);


/* For certain kinds of data, the plot time sequence being the chief example, you know it's never going to be updated.
 * So it's wasteful to constantly copy it, as would happen in a watched column.  So the SCAddStaticColumn will create a
 * column of data in DG only once and then you can refer to it as you would any other column (by it's string name).
 * That way you can have a slightly faster simulation when you use data that doesn't actually change (along side data
 * that does change, of course).  The data is copied directly in this command, so as far as SC is concerned the data
 * pointer can be deallocated after this command completes. */
void SCAddStaticColumn(char * var_name, double * data_ptr, int length);
    
/* Mark a variable with double type to be watched and thus accumlated through time, which enables it to be plotted as a
 * plot that grow with time. This function will take a value at each time for the variable, which is why it's called
 * watched.  The data pointer supplied to this function must be valid for the life of the simulation. */
void SCAddWatchedTimeColumn(char * var_name, double * data_ptr, SCDataHoldType data_hold_type);

/* Mark an array of doubles to be watched by the simulation controller. This enables multiple variables to be
 * accumulated through time and subsequently plotted in a line plot, for example.  The concept here is that each double
 * in the array is a separate variable x_i vs x_j.  The data pointer supplied to this function must be valid for the
 * life of the simulation. */
void SCAddWatchedTimeColumns(char * var_array_name, double * data_ptr, int length, SCDataHoldType data_hold_type);

/* Mark an array of doubles to be watched by the simulation controller, but this time, it's a single column variable, as
 * opposed to an array of scalar variables, which are rows that are added at each time point.  The distinction is
 * important for certain types of plots, such as bar plots, which require columns.  You can also plot functions in time,
 * if both the x and y variables to either a line or points plot are columns.  Note that column variables are not
 * appropriate for fastline or fastpoints plots, because those are essentially time plots, where one wants to print a
 * lot of dots or lines moving across the screen with time.  The data pointer supplied to this function must be valid
 * for the life of the simulation.*/
void SCAddWatchedFixedSizeColumn(char * var_name, double * data_ptr, int length);

/* Expression variables. They are computed entirely within DG based on the values of other variables.  This is extremely
 * useful for prettifying the plots without having to write any C code to do it.  For example, you have variable x and
 * y, which you've accumulated data on both of them.  Then you can use an expression column to create f(x,y),
 * e.g. sin(x)*sin(y) using a simple string.  Expression variables are used just like any other column of data,
 * i.e. they have to be associated to a plot. */
void SCAddExpressionColumn(char * var_name, char * expression);

/* The SC manages the data because the user doesn't know how much data to add beforehand.  Useful for spike rasters and
 * spike times, basically variable length stuff.  The upside is that the memory management is handled by SC.  The
 * downside is that the user has to manually add data because there is no way to know when or if it happens.  */
void SCAddManagedColumn(char * var_name, bool do_clear_after_plot_duration);
/* The managed column will take care of data management for you.  It initializes the save buffer to size of about 1000.
 * However, if you are working with a VERY large buffer (like a million) then you don't want the system to chug
 * needlessly on constant reallocations.  So you can provide a size hint, if you like and the managed column will start
 * with a buffer of that size.  Again, it's NOT necessary unless you are working with sizes much larger than about
 * 1000. */
void SCAddManagedColumnWithSize(char * var_name, bool do_clear_after_plot_duration, int size_hint);

/* Add multiple managed variables (ncolumns of them).  The vars will be name "var_name_prefix0, var_name_prefix1, ... */
void SCAddManagedColumns(char * var_name_prefix, int ncolumns, bool do_clear_after_plot_duration);    
void SCAddManagedColumnsWithSize(char * var_name_prefix, int ncolumns, bool do_clear_after_plot_duration, int size_hint);    

/* By far the best way to add data to the managed column is the first command, when you have magically saved up a large
 * number of values and then can submit them all at once.  The whole point of a managed column is that you many not know
 * how much data there is, which in turn means you are gathering it bit by bit.  Fine.  But to the extent you can pass
 * chunks of data, the faster you're program will be. */    

/* Add data from a pointer to the managed column. */
void SCAddDataToManagedColumn(char * var_name, double * new_data, int length);
/* Add a single value to the managed columns. */
void SCAddOneValueToManagedColumn(char * var_name, double value);
/* Add N values to the managed columns. e.g.  
* SCAddManyValuesToManagedColumn("spikeTimes", 5, 22.0, 23.1, 24.4, 25.0, 27.2) */
void SCAddManyValuesToManagedColumn(char * var_name, int nvalues, ...);
    
/* Copy the data from a managed column.  The space is allocated for you and the number of values is set in nvalues_ptr.
 * After the data is copied any modificatons to the data pointer will not affect the managed column, they will be
 * completely separate. It's YOUR responsibility to free this data when you are done with it.  The parameter nvalues_ptr
 * should be either a local variable or you allocate it yourself.  For example, in your code you would have
 * 
 * double * data = NULL;
 * int nvalues = 0;
 * SCCopyDataFromManagedColumn("interesting_variable", &data, &nvalues);
 *
 * for ( int i = 0; i < nvalues; i++ )
 *    SCWriteLine("data", data[i]);
 *
 */
void SCCopyDataFromManagedColumn(char * var_name, double ** data_ptr_ptr, int * nvalues_ptr);
    
void SCClearManagedColumn(char * var_name);
void SCClearManagedColumnsWithPrefix(char * var_name_prefix, int ncolumns); /* e.g.  "spikes", 2 -> "spikes0", "spikes1" */

/* This function returns all the data from a specific history index for a given variable name. The history indices are
 * expressed in "human indices", starting from one, which are the same units that are shown in the history values on the
 * side of the plot view.  This means that the minimum history is 1 and the maximum number is the max number of
 * histories.  Keep in mind that if you request a history that isn't there, for example, if you are only saving the 10
 * previous histories and the current plot is 20, then requesting history 7 will bonk.  In this case the *nvalues_ptr
 * will be set to 0, so that should be a way of testing if you screwed up.  The data_ptr_ptr will be allocated for you
 * and the number of elements stored in nvalues_ptr.  You are responsible for freeing data_ptr_ptr. */    

/* For example: */
/*     double * history_time = NULL; */
/*     double * history_cell_0 = NULL; */
/*     int nvalues = 0; */
/*     SCCopyDataFromHistoryWithIndex("TimePlotting", NDurations-1, &history_time, &nvalues); */
/*     SCCopyDataFromHistoryWithIndex("cell_values0", NDurations-1, &history_cell_0, &nvalues); */
/*     SCMakePlotNow("outputs", history_time, history_cell_0, nvalues, &lpp, SC_LAST_IN_ORDER); */

/*     if ( history_time != NULL ) */
/*         free(history_time); */
/*     if ( history_cell_0 != NULL ) */
/*         free(history_cell_0); */
/* */
/* NOTE WELL: IF THE CURRENT HISTORY IS REQUESTED FROM WITHIN RunModelOneStep you will lose data.  The reason why is
 * that chunks of data are added to the history after a number of calls to RunModelOneStep.  You'll lose those. SO DON'T
 * DO IT unles you don't mind! */  
void SCCopyDataFromHistoryWithIndex(char * var_name, int history_index, int sample_every, double **data_ptr_ptr, int * nvalues_ptr);

/* Return all the requested histories in a flat array.  This is convient for doing a computation over the entire list of
 * histories but keep in mind that you'll not know the boundaries between one history and the next.  The indices are
 * inclusive so 3,5, would include histories 3, 4, 5, a total of 3 histories returned.  The data_ptr_ptr will be
 * allocated for you and the number of elements stored in nvalues_ptr.  You are responsible for freeing data_ptr_ptr. */

/* For example: */
/*     SCCopyFlatDataFromHistories("TimePlotting", NDurations-1, NDurations, &history_time, &nvalues); */
/*     SCCopyFlatDataFromHistories("cell_values0", NDurations-1, NDurations, &history_cell_0, &nvalues); */
/*     SCColorFromName("red", &(lpp.lineColor)); */
/*     SCMakePlotNow("outputs", history_time, history_cell_0, nvalues, &lpp, SC_LAST_IN_ORDER); */

/*     if ( history_time != NULL ) */
/*         free(history_time); */
/*     if ( history_cell_0 != NULL ) */
/*         free(history_cell_0); */
/* NOTE WELL: IF THE CURRENT HISTORY IS REQUESTED FROM WITHIN RunModelOneStep you will lose data.  The reason why is
 * that chunks of data are added to the history after a number of calls to RunModelOneStep.  You'll lose those. SO DON'T
 * DO IT unles you don't mind! */
void SCCopyFlatDataFromHistories(char * var_name, int history_start_idx, int history_stop_idx, int sample_every,
                                 double ** data_ptr_ptr, int * nvalues_ptr);


/* Return all the requested histories in an array of flat arrays.  This function is used for sets of variables that have
 * been declared using, for example, SCAddWatchedTimeColumns, where one provides a variables prefix, such as "cells" and
 * then creates a number of time columns, such as cell0, cell1, ..., cell9.  The data and length pointers will be
 * allocated for you but you are required to deallocate all the associated memory, as in the example below. */
/*     double ** flat_histories = NULL; */
/*     int * history_lengths = NULL;     */
/*     double * history_time = NULL; */
/*     int nvalues = 0; */
    
/*     SCCopyFlatDataFromHistories("TimePlotting", NDurations-1, NDurations-1, &history_time, &nvalues); */
/*     SCCopyFlatDataFromHistoriesForColumns("all cell values", 0, 9, NDurations-1, NDurations-1, &flat_histories, &history_lengths); */

/*     if ( flat_histories && history_lengths && history_time ) /\* make sure nothing was returned NULL  *\/ */
/*     { */
/*         SCWriteText("buster"); */
/*         SCPlotParameters line_plot_parameters; */
/*         SCInitPlotParameters(&line_plot_parameters); */
/*         for ( int i = 0; i < 9; i++ ) */
/*         { */
/*             line_plot_parameters.yOffset += 2.0; */
/*             SCMakePlotNow("outputs", history_time, flat_histories[i], history_lengths[i], &line_plot_parameters, SC_LAST_IN_ORDER); */
/*             free(flat_histories[i]); */
/*         }    */
/*         free(flat_histories); */
/*         free(history_lengths); */
/*         free(history_time); */
/*     } */
/* NOTE WELL: IF THE CURRENT HISTORY IS REQUESTED FROM WITHIN RunModelOneStep you will lose data.  The reason why is
 * that chunks of data are added to the history after a number of calls to RunModelOneStep.  You'll lose those. SO DON'T
 * DO IT unles you don't mind! */
void SCCopyFlatDataFromHistoriesForColumns(char * var_name_prefix, int var_start_idx, int var_stop_idx, 
                                           int history_start_idx, int history_stop_idx, int sample_every,
                                           double *** data_ptr_ptr_ptr, int ** nvalues_ptr_ptr);

/* Return all the data from the histories in the inclusive boundaries [history_start_idx history_stop_idx] as an array
 * of double arrays, and the length of each history as an array given nvalues_ptr_ptr.  The array of arrays of data will
 * be allocated for you and so will the array of history lengths. You are responsible for freeing the array of arrays as well as the array of lengths.  */

/* For example: */
/*     double ** history_time_pp = NULL; */
/*     double ** history_cell_0_pp = NULL; */
/*     int * history_lengths = NULL; */
    
/*     SCCopyStructuredDataFromHistories("TimePlotting", NDurations-2, NDurations, &history_time_pp, &history_lengths); */
/*     SCCopyStructuredDataFromHistories("cell_values0", NDurations-2, NDurations, &history_cell_0_pp, &history_lengths); */
/*     SCColorFromName("red", &(lpp.lineColor)); */
     
/*     if ( history_cell_0_pp != NULL ) */
/*     { */
/*         lpp.lineWidth = 15; */
/*         for ( int i = 0; i < 3; i++ ) */
/*         { */
/*             lpp.lineWidth -= 5; */
/*             SCMakePlotNow("outputs", history_time_pp[i], history_cell_0_pp[i], history_lengths[i], &lpp, SC_LAST_IN_ORDER); */
/*         } */

/*         for ( int i = 0; i < 3; i++ ) */
/*         { */
/*             free(history_cell_0_pp[i]); */
/*             free(history_time_pp[i]); */
/*         } */
/*         free(history_time_pp); */
/*         free(history_cell_0_pp); */
/*         free(history_lengths); */
/*     } */
/* NOTE WELL: IF THE CURRENT HISTORY IS REQUESTED FROM WITHIN RunModelOneStep you will lose data.  The reason why is
 * that chunks of data are added to the history after a number of calls to RunModelOneStep.  You'll lose those. SO DON'T
 * DO IT unles you don't mind! */
void SCCopyStructuredDataFromHistories(char * var_name, int history_start_idx, int history_stop_idx, int sample_every, double *** data_ptr_ptr_ptr, int ** nvalues_ptr_ptr);



/* Used to clear plots mid-duration so that one may have multiple SCMake*PlotNow calls. The plot is automatically
 * cleared at the end of each duration.  This function has no effect on plots of watched variables. */ 
void SCClearMakeNowPlots(char * plot_name);
    

/* The SCAddVarsToX sssociate variables with plots, and also create the plots if they weren't created yet.  The order of
 * the created DG commands is the order in which the variables are associated to the plots.  So later stuff is on top of
 * earlier stuff.  There is no need to explicitly muck around with the order as a parameter here because it's simple
 * enough to order these calls in your code.  */

/* The SCMakeXNow commands will create plotting commands on the fly with DATA (not watched variable). Keep in mind that
 * the order parameter is only wrt to those commands that _HAVE BEEN ADDED AT THE TIME THAT THIS COMMAND IS BEING
 * ADDED_.  The default ordering is to put the command last (on top of everything else) use SC_LAST_IN_ORDER as the
 * value for order in this case and a number between 0 and nplots for that placement.  The number is 0 is the farthest
 * back. */
void SCAddVarsToTimePlot(char * plot_name, char * x_var_name, char * y_var_name, SCTimePlotParameters * tpp);

/* Theses command update an entire set of values at each time point.  In a sense, they are updating an entire function at
 * each time point, x_vector(t).  The value x_vector(t-dt) is no longer shown. Think simulation of a partial differential equation. */
/* Plots a new line at each time point. */
void SCAddVarsToPlot(char * plot_name, char * x_var_name, char * y_var_name, SCPlotParameters * pp);
void SCMakePlotNow(char * plot_name, double * xdata, double * ydata, int data_length, SCPlotParameters * pp, int order);
void SCMakePlotNowFMC(char * plot_name, char * x_var_name, char * y_var_name, SCPlotParameters * pp, int order);

/* Plots a new bar plot at each time point from a watched column, raw data, or a managed column. */
void SCAddVarsToBar(char * plot_name, char *var_name, SCBarPlotParameters * bpp);
void SCMakeBarNow(char * plot_name, double * data, int data_length, SCBarPlotParameters * bpp, int order);
void SCMakeBarNowFMC(char * plot_name, char * var_name, SCBarPlotParameters * bpp, int order);

/* Plots a new histogram at each time point from a watched column, or make one from raw data or a managed column. */
void SCAddVarsToHistogram(char * plot_name, char *var_name, SCHistogramPlotParameters * hpp); 
void SCMakeHistogramNow(char * plot_name, double * data, int data_length, SCHistogramPlotParameters * hpp, int order);
void SCMakeHistogramNowFMC(char * plot_name, char * var_name, SCHistogramPlotParameters * hpp, int order);

/* An updated function approximation based on an expression.  So you have some data pairs, (x_t, y_t) for t..1-T.  You
 * think the function y = f(x,theta) can approximate the data well.  This function takes, x, y and the approximation
 * parameters, theta, and finds the the best fit.  The function is definitely going to have local minima, so your
 * initial guesses are important. 
 *
 * E.g.  SCAddVarsToFit("plot1", "myx", "myy", fapp, "sin(a*x + b)", 2, "a", 1.0, "b", 2.0) This says to try a sinusoidal
 * function approximation of y = f(x), of watched variables "myx" and "myy" with parameters a and b, having initial
 * guesses 1.0 and 2.0, respectively. Keep in mind that your parameters will mess up if they coincide with variables or
 * function names that already exist.  Examples "sin", "e", etc. Also note that the independent variable in the
 * expression is "x".  This can't be changed so be sure to use "x".*/
void SCAddVarsToFit(char * plot_name, char * x_var_name, char * y_var_name, SCFitPlotParameters * fpp, char * expression, int nparams, ...);
/* Create a fit plot from data supplied to the function. */
void SCMakeFitNow(char * plot_name, double * xdata, double * ydata, int data_length, SCFitPlotParameters * fpp, int order, char * expression, int nparams, ...);
void SCMakeFitNowFMC(char * plot_name, char * x_var_name, char * y_var_name, SCFitPlotParameters * fpp, int order, char * expression, int nparams, ...);

/* Create a smoothed version of noisy data.  The smoothness parameter from [0 .. inf]*width of the data gives how smoothed the function
 * should be. A value to close to zero might now show up, so keep it increasing. */
/* Loess (the smoothing method) works by fitting an interval with a first or second order polynomial using weighted
 * least squares. Then uses the value of that polynomial as the function value. This is done for each point so the
 * interval is constantly shifting and might have a variable number of data points. The width variable is xmax-xmin and
 * is only defined inside that field. So you would enter 0.1 and the fit would be relative to 0.1*width. */
void SCAddVarsToSmooth(char * plot_name, char * x_var_name, char * y_var_name, SCSmoothPlotParameters * spp);
void SCMakeSmoothNow(char * plot_name, double * xdata, double * ydata, int data_length, SCSmoothPlotParameters * spp, int order);
void SCMakeSmoothNowFMC(char * plot_name, char * x_var_name, char * y_var_name, SCSmoothPlotParameters * spp, int order);

/* This command creates multiple lines of varying heights.  The example is an integrate and fire simulation.  You want
 * to plot the actual spike from the threhold voltage to the maximum spike voltage and you want to plot the spike every
 * time the neuron spikes.  This is the command you would use to do that. 
 * 
 * The lines_var_name is the name of the variable that gives the locations of the lines.  The lower_limits_var_name is
 * the name of the variable that gives the left/bottom limit values of the lines, if the string is null then the
 * fixedLowerValue in the parameters structure is used.  The upper_limits_var_name gives the right/top limit values of
 * the lines.  Again, if the string is null, then the fixedUpperValue is used for all the lines.  Finally, you can add
 * labels (numbers) to each line.  The name of the variable is label_var_name.  If null, then there are no labels.  */
void SCAddVarsToMultiLines(char * plot_name, char * lines_var_name, char * lower_limits_var_name, char * upper_limits_var_name, 
                           char * labels_var_name, SCMultiLinesPlotParameters * mlpp);
void SCMakeMultiLinesNow(char * plot_name, double * lines_data, double * lower_limits_data, double * upper_limits_data, 
                         double * labels_data, int data_length, SCMultiLinesPlotParameters * mlpp, int order);
/* void SCMakeMultiLinesNowFMC */  // Not added because it's a specialty command.  Let me know if you need it and I'll add it. -DCS:2009/11/08

/* A range is a rectangle, a set of arbitrary rectangles or an alternating set of rectangles with a stride.  There are a
 * number of options for this command.  On can set a static range for a single rectangle, put a rectangle on the entire
 * screen, create alternating rectangles with a given width, or dynamically set the edges of an arbitrary number of
 * rectangles with watched variable columns.  If you want to dynamically update the rectangle using watched variables
 * use the SCAddVarsToRange command.  If either x min or x max is taken from a column, then both of them have to be.
 * The same goes for ymin and ymax.  If you want only the x or y values set dynamically, then leave the other (y or x)
 * names set to NULL.  Otherwise the SCMakeRangeNow, which draws one range based on static values given via the
 * parameters structure.  Alternating rectangles can only be set statically.  The color range options is allowed.  One
 * can defined a color range and then use it, along with a color range data column, to defined the colors of the ranges.
 * If you prefer a static color then leave both the range_color_var_name and color_scheme_name as NULL and set the
 * static color in the parameters structure. */
void SCAddVarsToRange(char * plot_name, char * x_min_var_name, char * x_max_var_name, char * y_min_var_name, char * y_max_var_name, 
                      char * range_color_var_name, char * color_scheme_name, SCRangePlotParameters * rpp);
void SCMakeRangeNow(char * plot_name, double * x_min_data, double * x_max_data, double * y_min_data, double * y_max_data, double* range_color_data, int data_length,
                    char * color_scheme_name, SCRangePlotParameters * rpp, int order);
/* void SCMakeRangeNowFMC */  // Not added because it's a specialty command.  Let me know if you need it and I'll add it. -DCS:2009/11/08

/* A scatter plot. This means that both the size and color of the point can be data dependent (as opposed to just a
 * regular points plot, where these two graphic elements are constant across the set of points. Both point_size_name and
 * point_color_name can be NULL, in which case either of them will be assumed uniform and the relevant size is set in
 * the parameters structure.  If the point_color_name is non-NULL, then a color scheme must have been added and the name
 * included as color_scheme_name, otherwise leave color_scheme_name NULL also. */    
void SCAddVarsToScatter(char * plot_name, char * x_var_name, char * y_var_name, 
                        char * point_size_name, char * point_color_name, char * color_scheme_name, 
                        SCScatterPlotParameters *spp); 
/* Supply the data directly for a single scatter.  The color scheme must have been defined beforehand.  The data x_data
 * and y_data cannot be empty, however if point_size_data is NULL then the points will have uniform size and if the
 * point_color_data is empty then the points will all have the same color.  These uniform paramteters are set in the
 * parameters structure. */
void SCMakeScatterNow(char * plot_name, double * x_data, double * y_data, double * point_size_data, double * point_color_data, int data_length, 
                      char * color_scheme_name, SCScatterPlotParameters *spp, int order);
/* void SCMakeScatterNow */   // Not added because it's a specialty command.  Let me know if you need it and I'll add it. -DCS:2009/11/08


/* Assumes pData is already allocated. */
void SCInitPStruct(SCDefaultAxisParameters * dap); /* set everything either to 0, 0.0, false, or NULL, depending. */
void SCInitPStructWithSensibleValues(SCDefaultAxisParameters * dap); /* takes a stab at reasonable values. */

/* Memory must be allocated beforehand. */
void SCInitPlotParametersWithSensibleValues(SCPlotParameters * lpp);
void SCInitTimePlotParametersWithSensibleValues(SCTimePlotParameters * flpp);
void SCInitBarPlotParametersWithSensibleValues(SCBarPlotParameters * bpp);
void SCInitHistogramPlotParametersWithSensibleValues(SCHistogramPlotParameters * hpp);
void SCInitFitPlotParametersWithSensibleValues(SCFitPlotParameters * fpp);
void SCInitSmoothPlotParametersWithSensibleValues(SCSmoothPlotParameters * spp);
void SCInitMultiLinesPlotParametersWithSensibleValues(SCMultiLinesPlotParameters * mlpp);    
void SCInitRangePlotParametersWithSensibleValues(SCRangePlotParameters * rpp);
void SCInitScatterPlotParametersWithSensibleValue(SCScatterPlotParameters * spp);
void SCInitAxisWithSensibleValues(SCAxisParameters * ap);
/* Same as above, cuz the damned names are too long! */
void SCInitPlotParameters(SCPlotParameters * lpp);
void SCInitTimePlotParameters(SCTimePlotParameters * flpp);
//void SCInitPointsPlotParameters(SCPointsPlotParameters * ppp);
//void SCInitFastPointsPlotParameters(SCFastPointsPlotParameters * fppp);
void SCInitBarPlotParameters(SCBarPlotParameters * bpp);
void SCInitHistogramPlotParameters(SCHistogramPlotParameters * hpp);
void SCInitFitPlotParameters(SCFitPlotParameters * fpp);
void SCInitSmoothPlotParameters(SCSmoothPlotParameters * spp);
void SCInitMultiLinesPlotParameters(SCMultiLinesPlotParameters * mlpp);    
void SCInitRangePlotParameters(SCRangePlotParameters * rpp);
void SCInitScatterPlotParameters(SCScatterPlotParameters * spp);
void SCInitAxis(SCAxisParameters * ap);


/* Deallocate of the pData structure. */
void SCDeallocPStruct(SCDefaultAxisParameters * dap);
/* void SCDeallocDefaultAxisParameters(SCDefaultAxisParameters * dap);*/

 /* Copy the string in label to the destination dest. Dest is freed if non-NULL and then malloced. */
void SCTextCopy(char * label, char ** dest);
void SCColorCopy(SCColor *src, SCColor *dest);

/* Come up with the correct colors from a string.  This function looks up every color table under the sun to see if the
 * string color_name is found.  If so, then the color structure is filled out and the function returns 1.  If the string
 * is not found anywhere, the function returns 0 and a warning message is printed in the console. */
int SCColorFromName(char * color_name, SCColor * cs);

/* Creats a palette of colors by linear interpolation from color 1 to color 2.  The number of colors is ncolors and cs
 * must be preallocated to hold ncolors worth of colors.  The opacity value alpha will be set for all of them. */
int SCColorRangeFromNames(char * color_name_1, char * color_name_2, int ncolors, SCColor * cs, float alpha);




/* THESE FUNCTIONS ARE OBSOLETE, THEY'VE BEEN RENAMED IN A SLIGHTLY MORE TERSE FASHION.  SO DON'T USE ANYTHING BELOW
 * THIS COMMENT LINE.  */
void SCMakeLinePlotNow(char * plot_name, double * xdata, double * ydata, int data_length, 
                       SCPlotParameters * line_plot_parameters, int order);
void SCMakeBarPlotNow(char * plot_name, double * data, int data_length, 
                      SCBarPlotParameters * bar_plot_parameters, int order);
void SCMakeHistogramPlotNow(char * plot_name, double * data, int data_length, 
                            SCHistogramPlotParameters * histogram_plot_parameters, int order);
void SCAddVariablesToFastLinePlotByName(char * plot_name, char * x_var_name, char * y_var_name, 
                                        SCTimePlotParameters * fast_line_plot_parameters); 
void SCAddVariablesToLinePlotByName(char * plot_name, char * x_var_name, char * y_var_name, 
                                    SCPlotParameters * line_plot_parameters);
void SCAddVariablesToBarPlotByName(char * plot_name, char *var_name, SCBarPlotParameters * bar_plot_parameters); 
void SCAddVariablesToHistogramPlotByName(char * plot_name, char *var_name, SCHistogramPlotParameters * histogram_plot_parameters);
void SCAddWatchedVariableArray(char * var_array_name, double * data_ptr, int length, SCDataHoldType data_hold_type); 
void SCAddWatchedVariable(char * var_name, double * data_ptr, SCDataHoldType data_hold_type); /* obsolete name */
void SCAddWatchedColumnVariable(char * var_name, double * data_ptr, int length); /* obsolete name */
void SCAddManagedColumnVariable(char * var_name); /* obsolete name */
void SCAddManagedColumnVariables(char * var_name_prefix, int ncolumns); /* obsolete name */
void SCAddExpressionVariable(char * var_name, char * expression); /* Obsolete. */


// NOT USED BY THE USER, USED BY THE SIMULATION CONTROLLER PROGRAM.  
void SCPrivateSetSimModelPointer(void * sim_model_ptr);
void SCPrivateSetSimControllerPointer(void * sim_controller_ptr);

#ifdef __cplusplus
}
#endif 


#endif
