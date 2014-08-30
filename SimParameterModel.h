
#import <Foundation/Foundation.h>


#import "SimParameter.h"

/* Add the extra class layer because due to the GUI layout, the parameters are more than a simple array.  It also
 * includes a number of parameters that are "special" in that they have a slider attached to them. */

@interface SimParameterModel : NSObject
{
    
    // if the objects don't change, but the objects internal values, is NSArray still appropriate? -DCS:2009/05/13
    NSMutableArray * fakeParameters;
    NSMutableArray * parameterNames;      // this array is in the order in which the parameters were presented.
    NSMutableDictionary * parametersDict;    // Dictionary from names to SimParameters.
    NSMutableArray * parameters;            // unordered

    // For the sliders, we probably have to have something special like, below, because how would we specify a binding
    // to something internal to an array? I should read the NSArrayController documentation before going on, but I don't
    // see how I'll get around this problem. -DCS:2009/05/13

    int nUIParameters;
    SimParameter * parameter1;
    SimParameter * parameter2;
    SimParameter * parameter3;
    SimParameter * parameter4;
    SimParameter * parameter5;
    SimParameter * parameter6;
    SimParameter * parameter7;
    SimParameter * parameter8;

    NSMutableArray * fakeButtons;
    NSMutableArray * buttonNames; // this array is necessary to get the order of the buttons exactly as described in the model program.
    NSMutableDictionary * buttonsDict;
    NSMutableArray * buttons;

    int nUIButtons;             // not the number of buttons, but the number with separate UI controls! -DCS:2009/05/14
    SimButton * button1;
    SimButton * button2;
    SimButton * button3;
    SimButton * button4;
    SimButton * button5;
    SimButton * button6;
    SimButton * button7;
    SimButton * button8;
    SimButton * button9;
    SimButton * button10;
}

@property(readonly) NSMutableArray * parameterNames;
@property(readonly) NSMutableArray * buttonNames;

/* I just point these into the array, then bind to these values and everything works out. */
@property (readwrite, assign) SimParameter *parameter1;
@property (readwrite, assign) SimParameter *parameter2;
@property (readwrite, assign) SimParameter *parameter3;
@property (readwrite, assign) SimParameter *parameter4;
@property (readwrite, assign) SimParameter *parameter5;
@property (readwrite, assign) SimParameter *parameter6;
@property (readwrite, assign) SimParameter *parameter7;
@property (readwrite, assign) SimParameter *parameter8;

@property (readwrite, assign) SimButton *button1;
@property (readwrite, assign) SimButton *button2;
@property (readwrite, assign) SimButton *button3;
@property (readwrite, assign) SimButton *button4;
@property (readwrite, assign) SimButton *button5;
@property (readwrite, assign) SimButton *button6;
@property (readwrite, assign) SimButton *button7;
@property (readwrite, assign) SimButton *button8;
@property (readwrite, assign) SimButton *button9;
@property (readwrite, assign) SimButton *button10;

-(void) broadcastParameterValues;
-(void) resetParameterValuesToDefaults;
-(void) resetButtonValuesToDefaults;

-(void) addParameter:(SimParameter *)sim_parameter; /* Give warning if duplicated parameter. */
-(void) addParameterAllowingOverwrite:(SimParameter *)sim_parameter; /* Just over write the thing. */

-(double) valueForParameter:(NSString *)param_name;
-(void) setValueForParameter:(NSString *)param_name_string value:(double)value doBroadcast:(BOOL)do_broadcast;

-(void) addButton:(SimButton *)sim_button;
-(void) addButtonAllowingOverwrite:(SimButton *)sim_button;

-(double) valueForButton:(NSString *)button_name;
-(void) setValueForButton:(NSString *)button_name value:(BOOL)value doBroadcast:(BOOL)do_broadcast;;

//-(void) notifyUserOfChanges;

-(NSMutableArray*)parameters;
-(NSMutableDictionary*)parametersDict;
-(NSMutableArray*)buttons;
-(NSMutableDictionary*)buttonsDict;

@end
