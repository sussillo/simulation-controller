#ifndef __MODEL_H
#define __MODEL_H

#include "SimulationController.h"

#ifdef __cplusplus
extern "C" {
#endif 


/* These are the functions that the simulation must implement in order for the SimulationController to work. */
#ifndef _NO_USER_LIBRARY_           //This definition may be declared as -D_NO_USER_LIBRARY_=1 in other C flags, build information of Xcode. -SHH@7/15/09
void _AddControllableParameters();
void _AddControllableButtons();
void* _InitModel();       /* returns any data necessary for RunModelOneStep */
void _AddPlotsAndRegisterWatchedVariables(void * model_data);
void _SetPlotParameters(pStruct * pData, const char * plot_name, void * model_data); /* set the axis parameters for the plot.  */
void _AddWindowDataForPlots(const char * plot_name, void * model_data);
void _ParameterAction(const char * parameter_name, double parameter_value, void * model_data);
void _ButtonAction(const char * button_name, bool button_value, void * model_data);
void _InitForRun(void * model_data);
void _InitForPlotDuration(void * model_data);
void _RunModelOneStep(void * model_data, bool is_plot_iter);
void _CleanupAfterPlotDuration(void * model_data);
void _CleanupAfterRun(void * model_data);
void _CleanupModel(void * model_data);
//void ParameterAction(const char*, double, void*);         // declaration again -- SHH@7/7/09
#else
void AddControllableParameters();
void AddControllableButtons();
void* InitModel();       /* returns any data necessary for RunModelOneStep */
void AddPlotsAndRegisterWatchedVariables(void * model_data);
void SetPlotParameters(pStruct * pData, const char * plot_name, void * model_data);
void AddWindowDataForPlots(const char * plot_name, void * model_data);
void ParameterAction(const char * parameter_name, double parameter_value, void * model_data);
void ButtonAction(const char * button_name, bool button_value, void * model_data);
void InitForRun(void * model_dat);
void InitForPlotDuration(void * model_data);
void RunModelOneStep(void * model_data, bool is_plot_iter);
void CleanupAfterPlotDuration(void * model_data);
void CleanupAfterRun(void * model_data);
void CleanupModel(void * model_data);    
#endif


#ifdef __cplusplus
}
#endif


#endif
