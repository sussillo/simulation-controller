
#import "SimParameterModel.h"
#import "DebugLog.h"

extern NSString * const SCNotifyModelOfButtonChange;
extern NSString * const SCNotifyModelOfParameterChange;


@implementation SimParameterModel

- (id)init
{
    if ( self = [super init] )
    {
        nUIButtons = 10;
        nUIParameters = 8;
        fakeParameters = [[NSMutableArray alloc] init];
        parametersDict = [[NSMutableDictionary alloc] init]; 
        parameters = [[NSMutableArray alloc] init];
        parameterNames = [[NSMutableArray alloc] init];
        
        fakeButtons = [[NSMutableArray alloc] init];
        buttonsDict = [[NSMutableDictionary alloc] init];
        buttons = [[NSMutableArray alloc] init];
        buttonNames = [[NSMutableArray alloc] init];

        /* Setup the fake parameters, which are used to bound the slider values when there aren't enough paramters to bind
         * all of the explicitly defined UI elements. */
        SimParameter * sp;
        while ( [fakeParameters count] < nUIParameters )
        {
            sp = [[SimParameter alloc] init];
            [sp setDoShow:NO];
            [fakeParameters addObject:sp];
            [sp release];
        }
        
        /* Add fake buttons but don't show them, used for when there are less user defined buttons than UI buttons.  */
        [fakeButtons release];
        fakeButtons = [[NSMutableArray alloc] init];
        SimButton * sb;
        while ( [fakeButtons count] < nUIButtons )
        {
            sb = [[SimButton alloc] init];
            [sb setDoShow:NO];
            [fakeButtons addObject:sb];
            [sb release];
        }
    }

    return self;
}


- (void)dealloc
{
    [parameterNames release];
    [parametersDict release];
    [parameters release];
    [fakeParameters release];
    [buttonNames release];
    [buttonsDict release];
    [buttons release];
    [fakeButtons release];
    [super dealloc];
}

@synthesize parameterNames;

@synthesize parameter1;
@synthesize parameter2;
@synthesize parameter3;
@synthesize parameter4;
@synthesize parameter5;
@synthesize parameter6;
@synthesize parameter7;
@synthesize parameter8;

@synthesize buttonNames;
@synthesize button1;
@synthesize button2;
@synthesize button3;
@synthesize button4;
@synthesize button5;
@synthesize button6;
@synthesize button7;
@synthesize button8;
@synthesize button9;
@synthesize button10;

extern NSString * const SCWriteToControllerConsoleNotification;
extern NSString * const SCWriteToControllerConsoleAttributedNotification;
-(void)writeTextToConsole:(NSString*)text
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSDictionary *d = [NSDictionary dictionaryWithObject:text forKey:@"message"];
    [nc postNotificationName:SCWriteToControllerConsoleNotification object:self userInfo:d];
}

-(void)writeWarningToConsole:(NSString*)text 
{
    NSColor *txtColor = [NSColor redColor];
    NSFont *txtFont = [NSFont boldSystemFontOfSize:13];
    NSDictionary *txtDict = [NSDictionary
                                dictionaryWithObjectsAndKeys:txtFont,
                                NSFontAttributeName, txtColor, 
                                NSForegroundColorAttributeName, nil];


    NSArray *keys = [NSArray arrayWithObjects:@"message", @"attributes", nil];
    NSArray *objects = [NSArray arrayWithObjects:text, txtDict, nil];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:SCWriteToControllerConsoleAttributedNotification object:self userInfo:dictionary];
}


- (void)resetSliders
{
    int parameter_count = [parametersDict count];
    int pcidx = 0;
    
    /* Order the parameters exactly in the order the user defined them. */
    NSEnumerator *enumerator = [parameterNames objectEnumerator];

    if ( parameter_count > 0 )
        [self setParameter1:[parametersDict objectForKey:[enumerator nextObject]]];
    else
        [self setParameter1:[fakeParameters objectAtIndex:(pcidx++)]];
    
    if ( parameter_count > 1 )
        [self setParameter2:[parametersDict objectForKey:[enumerator nextObject]]];
    else
        [self setParameter2:[fakeParameters objectAtIndex:(pcidx++)]];
    
    if ( parameter_count > 2 )
        [self setParameter3:[parametersDict objectForKey:[enumerator nextObject]]];
    else
        [self setParameter3:[fakeParameters objectAtIndex:(pcidx++)]];

    if ( parameter_count > 3 )
        [self setParameter4:[parametersDict objectForKey:[enumerator nextObject]]];
    else
        [self setParameter4:[fakeParameters objectAtIndex:(pcidx++)]];

    if ( parameter_count > 4 )
        [self setParameter5:[parametersDict objectForKey:[enumerator nextObject]]];
    else
        [self setParameter5:[fakeParameters objectAtIndex:(pcidx++)]];

    if ( parameter_count > 5 )
        [self setParameter6:[parametersDict objectForKey:[enumerator nextObject]]];
    else 
        [self setParameter6:[fakeParameters objectAtIndex:(pcidx++)]];

    if ( parameter_count > 6 )
        [self setParameter7:[parametersDict objectForKey:[enumerator nextObject]]];
    else
        [self setParameter7:[fakeParameters objectAtIndex:(pcidx++)]];

    if ( parameter_count > 7 )
        [self setParameter8:[parametersDict objectForKey:[enumerator nextObject]]];
    else
        [self setParameter8:[fakeParameters objectAtIndex:(pcidx++)]];
}


- (NSMutableDictionary *)parametersDict
{
    return (NSMutableDictionary *)parametersDict;
}


- (NSMutableArray *)parameters
{
    return parameters;
}

-(NSMutableArray*)buttons
{
    return buttons;
}

- (void)addParameter:(SimParameter *)sim_parameter
{
    BOOL do_add = YES;
    if ( [parametersDict objectForKey:[sim_parameter name]] )
        do_add = NO;
    
    if ( do_add )
    {
        [parameterNames addObject:[sim_parameter name]];
        [parameters addObject:sim_parameter];
        [parametersDict setObject:sim_parameter forKey:[sim_parameter name]]; // retained by array
        [self resetSliders];
    }
    else
    {
        DebugNSLog(@"Warning parameter %@ already added.\n", [sim_parameter name]);
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Warning parameter %@ already added.\n", [sim_parameter name]]];
    }
}


- (void)addParameterAllowingOverwrite:(SimParameter *)sim_parameter
{
    [self willChangeValueForKey:@"parameters"]; /* Notify the array controller that the table has to be updated for new items. */

    if ( [parametersDict objectForKey:[sim_parameter name]] ) 
    {
        SimParameter * sp = [parametersDict objectForKey:[sim_parameter name]];
        [sp setValueNoBroadcast: [sim_parameter value]];
        [sp setDefaultValue: [sim_parameter defaultValue]];
        [sp setMinValue: [sim_parameter minValue]];
        [sp setMaxValue: [sim_parameter maxValue]];
    }
    else
    {
        [parameterNames addObject:[sim_parameter name]];
        [parameters addObject:sim_parameter];
        [parametersDict setObject:sim_parameter forKey:[sim_parameter name]]; // retained by array
    }
    
    [self resetSliders];    

    [self didChangeValueForKey:@"parameters"];
}


- (double)valueForParameter:(NSString *)param_name
{
    double value = 0.0;
    SimParameter *sp = [parametersDict objectForKey:param_name];
    if ( sp != nil )
        value = [sp value];
    else
    {
        DebugNSLog(@"SC Error: Parameter with name %@ doesn't exist!\n", param_name);
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Parameter with name %@ doesn't exist! Returning a value of 0. \n", param_name]];
    }

    return value;
}


- (void)setValueForParameter:(NSString *)param_name value:(double)value doBroadcast:(BOOL)do_broadcast
{
    SimParameter *sp = [parametersDict objectForKey:param_name];
    if ( sp != nil )
    {
        if ( do_broadcast )
            [sp setValue:value];
        else 
            [sp setValueNoBroadcast:value];
    }
    else
    {
        DebugNSLog(@"SC Error: Parameter with name %@ doesn't exist!\n", param_name);
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Parameter with name %@ doesn't exist! Parameter not set.\n", param_name]];
    }
}


-(void) resetParameterValuesToDefaults
{ 
    for ( NSString * param_name in parameterNames )
    {
        SimParameter *sp = [parametersDict objectForKey:param_name];
        [sp setValue:[sp defaultValue]];
    }
}



-(void) resetButtonValuesToDefaults
{
    for ( NSString * button_name in buttonNames )
    {
        SimButton * bp = [buttonsDict objectForKey:button_name];
        [bp setValue:[bp defaultValue]];
    }
}

-(void) broadcastParameterValues
{
    for ( NSString * param_name in parameterNames )
    {
        [[parametersDict objectForKey:param_name] broadcastValue];
    }
}

    

- (double)valueForButton:(NSString *)button_name
{
    bool value = false;
    SimButton *sb = [buttonsDict objectForKey:button_name];
    if ( sb != nil )
        value = [sb value];
    else
    {
        DebugNSLog(@"SC Error: Button with name %@ doesn't exist!\n", button_name);
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Button with name %@ doesn't exist! Returning a value of false.\n", button_name]];
    }

    return value;
}


- (void)setValueForButton:(NSString *)button_name value:(BOOL)value doBroadcast:(BOOL)do_broadcast
{
    SimButton *sb = [buttonsDict objectForKey:button_name];
    if ( sb != nil )
    {
        if ( do_broadcast )
            [sb setValue:value];
        else
            [sb setValueNoBroadcast:value];
    }
    else
    {
        DebugNSLog(@"SC Error: Button with name %@ doesn't exist!\n", button_name);
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Button with name %@ doesn't exist!  Button value not changed.\n", button_name]];
    }
}


- (void)resetButtons
{
    /* Order the button exactly in the order the user defined them. */
    NSEnumerator *enumerator = [buttonNames objectEnumerator];
    
    int bcidx = 0;
    int button_count = [buttonsDict count];
    if ( button_count > 0 )
        [self setButton1:[buttonsDict objectForKey:[enumerator nextObject]]];
    else 
        [self setButton1:[fakeButtons objectAtIndex:(bcidx++)]];

    if ( button_count > 1 )
        [self setButton2:[buttonsDict objectForKey:[enumerator nextObject]]];
    else
        [self setButton2:[fakeButtons objectAtIndex:(bcidx++)]];

    if ( button_count > 2 )
        [self setButton3:[buttonsDict objectForKey:[enumerator nextObject]]];
    else
        [self setButton3:[fakeButtons objectAtIndex:(bcidx++)]];

    if ( button_count > 3 )
        [self setButton4:[buttonsDict objectForKey:[enumerator nextObject]]];
    else
        [self setButton4:[fakeButtons objectAtIndex:(bcidx++)]];

    if ( button_count > 4 )
        [self setButton5:[buttonsDict objectForKey:[enumerator nextObject]]];
    else
        [self setButton5:[fakeButtons objectAtIndex:(bcidx++)]];
    
    if ( button_count > 5 )
        [self setButton6:[buttonsDict objectForKey:[enumerator nextObject]]];
    else
        [self setButton6:[fakeButtons objectAtIndex:(bcidx++)]];

    if ( button_count > 6 )
        [self setButton7:[buttonsDict objectForKey:[enumerator nextObject]]];
    else
        [self setButton7:[fakeButtons objectAtIndex:(bcidx++)]];

    if ( button_count > 7 )
        [self setButton8:[buttonsDict objectForKey:[enumerator nextObject]]];
    else
        [self setButton8:[fakeButtons objectAtIndex:(bcidx++)]];

    if ( button_count > 8 )
        [self setButton9:[buttonsDict objectForKey:[enumerator nextObject]]];
    else
        [self setButton9:[fakeButtons objectAtIndex:(bcidx++)]];

    if ( button_count > 9 )
        [self setButton10:[buttonsDict objectForKey:[enumerator nextObject]]];
    else
        [self setButton10:[fakeButtons objectAtIndex:(bcidx++)]];

}

- (NSMutableDictionary*)buttonsDict
{
    return (NSMutableDictionary*)buttonsDict;
}

// - (void)setButtonsDict:(NSMutableDictionary *)buttons_dict
// {
//     if ( buttonsDict == buttons_dict )
//         return;
    
//     [buttons_dict retain];
//     [buttonsDict release];
//     buttonsDict = buttons_dict;            
// }



- (void)addButton:(SimButton *)sim_button
{
    BOOL do_add = YES;
    if ( [buttonsDict objectForKey:[sim_button name]] )
        do_add = NO;

    if (  do_add )
    {
        [buttonNames addObject:[sim_button name]];
        [buttons addObject:sim_button];
        [buttonsDict setObject:sim_button forKey:[sim_button name]];
        [self resetButtons];
    }
    else 
    {
        DebugNSLog(@"Warning button %@ already added.\n", [sim_button name]);
        [self writeWarningToConsole:[NSString stringWithFormat:@"SC Error: Warning button %@ already added.\n", [sim_button name]]];
    }
}


- (void)addButtonAllowingOverwrite:(SimButton *)sim_button
{
    [self willChangeValueForKey:@"buttons"]; /* Notify the array controller that the table has to be updated for new items. */

    if ( [buttonsDict objectForKey:[sim_button name]] ) 
    {
        SimButton * sb = [buttonsDict objectForKey:[sim_button name]];
        [sb setValueNoBroadcast: [sim_button value]];
        [sb setDefaultValue: [sim_button defaultValue]];
        [sb setOffLabel: [sim_button offLabel]];
        [sb setOnLabel: [sim_button onLabel]];
    }
    else
    {
        [buttons addObject:sim_button];
        [buttonNames addObject:[sim_button name]];
        [buttonsDict setObject:sim_button forKey:[sim_button name]];
    }

    [self resetButtons];

    [self didChangeValueForKey:@"buttons"];

}


@end
