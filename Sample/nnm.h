//
//  nnm.h
//  Sample
//
//  Created by Soonhac Hong on 7/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SimulationControllerFramework/SCAppController.h>
#import <SimulationControllerFramework/SCPlotParameters.h>
#import <SimulationControllerFramework/DebugLog.h>

/* These are the functions that the simulation must implement in order for the SimulationController to work. */
void AddControllableParameters(void);
void AddControllableButtons(void);
void* InitModel(void);       /* returns any data necessary for RunModelOneStep */
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

SCAppController* _SCAppController;

@protocol nnm
- (void)showFramework;
@end

@interface nnm : NSObject {
    
}

@end
