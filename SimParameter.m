

#import "SimParameter.h"

extern NSString * const SCNotifyModelOfButtonChange;
extern NSString * const SCNotifyModelOfParameterChange;


@implementation SimParameter


- (id)init
{
    if ( self = [super init] )
    {
        [super init];
        name = @"Test Parameter";
        defaultValue = 0.0;
        value = defaultValue;
        minValue = 0.0;
        maxValue = 1.0;
        doShow = YES;
    }
    return self;
}


- (void)dealloc
{
    [name release];
    [super dealloc];
}


@synthesize name;
//@synthesize value;
@synthesize defaultValue;
@synthesize minValue;
@synthesize maxValue;
@synthesize doShow;

-(double) value
{
    return value;
}

-(void) initValue:(double)value_
{
    value = value_;
}

-(void)setValue:(double)value_
{
    value = value_;
    //self.value = value_;
    [self broadcastValue];
}

-(void) setValueNoBroadcast:(double)value_
{
    value = value_;
}

-(void) broadcastValue
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSValue *wrappedValue = [NSValue valueWithBytes:&value objCType:@encode(double)];
    NSArray *keys = [NSArray arrayWithObjects:@"parameterName", @"parameterValue", nil];
    NSArray *objects = [NSArray arrayWithObjects:name, wrappedValue, nil];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    [nc postNotificationName:SCNotifyModelOfParameterChange object:self userInfo:dictionary];
    
    [pool release];
}



-(NSDictionary*) asPropertyListDictionary
{
    NSArray *keys = [NSArray arrayWithObjects:@"name", @"value", @"defaultValue", @"maxValue", @"minValue",nil];
    
    NSArray *objects = [NSArray arrayWithObjects:name, 
                                [NSNumber numberWithDouble:value], 
                                [NSNumber numberWithDouble:defaultValue],
                                [NSNumber numberWithDouble:maxValue],
                                [NSNumber numberWithDouble:minValue], nil];
    
    return [NSDictionary dictionaryWithObjects:objects forKeys:keys];
}


-(void) fromPropertyListDictonary:(NSDictionary *)sim_parameter_dict
{
    [self setName: [sim_parameter_dict objectForKey:@"name"]];
    [self setValue: [[sim_parameter_dict objectForKey:@"value"] doubleValue]];
    [self setDefaultValue: [[sim_parameter_dict objectForKey:@"defaultValue"] doubleValue]];
    [self setMaxValue: [[sim_parameter_dict objectForKey:@"maxValue"] doubleValue]];
    [self setMinValue: [[sim_parameter_dict objectForKey:@"minValue"] doubleValue]];
    [self setDoShow: YES];
}


/* Something about conversions from floats to objects.  There's a problem if you really want to the number 0 in the
 * conversion from the NSNumber object to the float value, I guess. -DCS:2009/05/13 . */
- (void)setNilValueForKey:(NSString *)key
{
    if ( [key isEqualToString:@"value" ] )
    {
        [self setValue:0.0];
    }
    else
    {
        [super setNilValueForKey:key];
    }
}


/* This method is compeletely screwy because the NSDictionaryController used in the SimulationController copies the
 * objects when instantiated in the NIB.  This is a different behavior than the NSArrayController, which is happy to use
 * a reference.  The reason it matters is because of the button1-10, which are depending on references to stay in sync
 * with the parameters panel. Let me be clear: normally copyWithZone makes a copy. -DCS:2009/05/22 */
- (id) copyWithZone: (NSZone *) zone
{
    return [self retain];
}


- (NSUInteger)hash
{
    return [name hash];
}


-(BOOL) isEqual:(id)sim_parameter
{
    if ( [name compare:[sim_parameter name]] == NSOrderedSame )
        return YES;
    else
        return NO;
}


@end




@implementation SimButton

- (id)init
{
    [super init];
    name = @"Test Button";
    [self setOnLabel:name];
    [self setOffLabel:name];
    defaultValue = NO;
    value = defaultValue;
    doShow = YES;
    return self;
}


- (void)dealloc
{
    [name release];
    [onLabel release];
    [offLabel release];
    [super dealloc];
}


@synthesize name;
//@synthesize value;
@synthesize defaultValue;
@synthesize onLabel;
@synthesize offLabel;
@synthesize doShow;


-(BOOL) value
{
    return value;
}

-(void) initValue:(BOOL)value_
{
    value = value_;
}

-(void) setValue:(BOOL)value_
{
    value = value_;             // This is enough to get the UI button value to change if we aren't in nested SCSetButtonValue calls. -DCS:2010/01/20
    //self.value = value_; // causes an infinite loop of this function. 
    [self broadcastValue];
}

-(void) setValueNoBroadcast:(BOOL)value_
{
    value = value_;
}

-(void) broadcastValue
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSValue *wrappedValue = [NSValue valueWithBytes:&value objCType:@encode(BOOL)];
    NSArray *keys = [NSArray arrayWithObjects:@"buttonName", @"buttonValue", nil];
    NSArray *objects = [NSArray arrayWithObjects:name, wrappedValue, nil];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    [nc postNotificationName:SCNotifyModelOfButtonChange object:self userInfo:dictionary];

    [pool release];
}



/* Something about conversions from floats to objects.  There's a problem if you really want to the number 0 in the
 * conversion from the NSNumber object to the float value, I guess. -DCS:2009/05/13 . */
- (void)setNilValueForKey:(NSString *)key
{
    if ( [key isEqualToString:@"value" ] )
    {
        [self setValue:0.0];
    }
    else
    {
        [super setNilValueForKey:key];
    }
}


-(NSDictionary*) asPropertyListDictionary
{
    NSArray *keys = [NSArray arrayWithObjects:@"name", @"onLabel", @"offLabel", @"value", @"defaultValue", nil];
    
    NSArray *objects = [NSArray arrayWithObjects:name, 
                                onLabel,
                                offLabel,
                                [NSNumber numberWithDouble:value],
                                [NSNumber numberWithDouble:defaultValue], nil];
    
    return [NSDictionary dictionaryWithObjects:objects forKeys:keys];
}


-(void) fromPropertyListDictonary:(NSDictionary *)sim_parameter_dict
{
    [self setName: [sim_parameter_dict objectForKey:@"name"]];
    [self setOnLabel: [sim_parameter_dict objectForKey:@"onLabel"]];
    [self setOffLabel: [sim_parameter_dict objectForKey:@"offLabel"]];
    [self setValueNoBroadcast: [[sim_parameter_dict objectForKey:@"value"] doubleValue]];
    [self setDefaultValue: [[sim_parameter_dict objectForKey:@"defaultValue"] doubleValue]];
    [self setDoShow: YES];
}


- (NSUInteger)hash
{
    return [name hash];
}


-(BOOL) isEqual:(id)sim_button
{
    if ( [name compare:[sim_button name]] == NSOrderedSame )
        return YES;
    else
        return NO;
}


/* This method is compeletely screwy because the NSDictionaryController used in the SimulationController copies the
 * objects when instantiated in the NIB.  This is a different behavior than the NSArrayController, which is happy to use
 * a reference.  The reason it matters is because of the button1-10, which are depending on references to stay in sync
 * with the parameters panel. Let me be clear: normally copyWithZone makes a copy. -DCS:2009/05/22 */
- (id) copyWithZone: (NSZone *) zone
{
    return [self retain];
}


@end
