

#import <Cocoa/Cocoa.h>
#import "SimParameterModel.h"


@interface ParametersController : NSWindowController 
{

    NSLock *computeLock;
    SimParameterModel *simParameterModel;
    //NSMutableArray *simParameters;
    IBOutlet NSTableView * parametersTable;    
    IBOutlet NSArrayController * parametersArrayController;
    IBOutlet NSArrayController * buttonsArrayController;
}

-(void) setComputeLock:(NSLock *)compute_lock;
-(void) setSimParameterModel:(SimParameterModel *)sim_parameter_model;
-(SimParameterModel *) simParameterModel;

-(IBAction) pushSaveParameters:(id)sender;
-(IBAction) pushSaveButtons:(id)sender;
-(IBAction) pushLoadParameters:(id)sender;
-(IBAction) pushLoadButtons:(id)sender;

-(IBAction) pushResetParameterValuesToDefaults:(id)sender;
-(IBAction) pushResetButtonValuesToDefaults:(id)sender;
-(IBAction) closeWindow:(id)sender;

-(IBAction) parameterValueChanged:(id)sender;

@end
