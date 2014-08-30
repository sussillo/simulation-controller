#import "SCPlotCommand.h"


@implementation SCPlotCommand

- (id)init
{
    if ( self = [super init] )
    {
        commandType = SC_NIL_COMMAND;
        order = -1;             /* Leave it alone, the default ordering (the creation ordering by the user) is fine. */
    }
    return self;
}


- (void)dealloc
{
    [plotName release];
    [commandParameters release];
    [super dealloc];
}


@synthesize commandType;
@synthesize commandParameters;
@synthesize plotName;
@synthesize order;


-(NSArray*)allNames
{
    return [NSArray array];                 /* Nothing to return. */
}


-(NSDictionary*)allVariables
{
    return [NSDictionary dictionary];                 /* Nothing to return. */
}



@end



@implementation SCSilentCommand

- (id)init
{
    if ( self = [super init] )
    {
        commandType = SC_SILENT_COMMAND;
    }
    return self;
}


- (void)dealloc
{
    [names release];
    [variables release];
    [super dealloc];
}

@synthesize names;
@synthesize variables;


-(NSArray*)allNames
{
    NSMutableArray *all_names = [NSMutableArray arrayWithCapacity:[names count]];
    [all_names addObjectsFromArray:names];
    return all_names;
}


-(NSDictionary*)allVariables
{
    NSMutableDictionary * all_variables = [NSMutableDictionary dictionaryWithCapacity:[names count]];
    [all_variables addEntriesFromDictionary:variables];
    return all_variables;
}


@end





@implementation SCLineCommand

- (id)init
{
    if ( self = [super init] )
    {
        commandType = SC_LINE_COMMAND;
    }
    return self;
}


- (void)dealloc
{
    [xName release];
    [xVariable release];
    [yName release];
    [yVariable release];
    [super dealloc];
}

@synthesize xName;
@synthesize xVariable;
@synthesize yName;
@synthesize yVariable;


-(NSArray*)allNames
{
    return [NSArray arrayWithObjects:xName,yName,nil];
}


-(NSDictionary*)allVariables
{
    return [NSDictionary dictionaryWithObjectsAndKeys:xVariable,xName,yVariable,yName,nil];
}


@end



@implementation SCFastLineCommand

- (id)init
{
    if ( self = [super init] )
    {
        commandType = SC_FAST_LINE_COMMAND;
    }
    return self;
}


- (void)dealloc
{
    [xName release];
    [xVariable release];
    [yNames release];
    [yVariables release];
    [super dealloc];
}

@synthesize xName;
@synthesize xVariable;
@synthesize nLines;
@synthesize yNames;
@synthesize yVariables;


-(NSArray*)allNames
{
    NSMutableArray *all_names = [NSMutableArray arrayWithCapacity:(1 + [yNames count])];
    [all_names addObject:xName];
    [all_names addObjectsFromArray:yNames];
    return all_names;
}


-(NSDictionary*)allVariables
{
    NSMutableDictionary * all_variables = [NSMutableDictionary dictionaryWithCapacity:(1 + [yNames count])];
    [all_variables setObject:xVariable forKey:xName];
    [all_variables addEntriesFromDictionary:yVariables];
    return all_variables;
}


@end


@implementation SCBarCommand

- (id)init
{
    if ( self = [super init] )
    {
        commandType = SC_BAR_COMMAND;
    }
    return self;
}


- (void)dealloc
{
    [name release];
    [variable release];
    [super dealloc];
}


@synthesize name;
@synthesize variable;


-(NSArray*)allNames
{
    return [NSArray arrayWithObjects:name,nil];
}


-(NSDictionary*)allVariables
{
    return [NSDictionary dictionaryWithObjectsAndKeys:variable,name,nil];
}


@end


@implementation SCHistogramCommand

- (id)init
{
    if ( self = [super init] )
    {
        commandType = SC_HISTOGRAM_COMMAND;
    }
    return self;
}


- (void)dealloc
{    
    [name release];
    [variable release];
    [super dealloc];
}


@synthesize name;
@synthesize variable;


-(NSArray*)allNames
{
    return [NSArray arrayWithObjects:name,nil];
}


-(NSDictionary*)allVariables
{
    return [NSDictionary dictionaryWithObjectsAndKeys:variable,name,nil];
}


@end


@implementation SCFitCommand

- (id)init
{
    if ( self = [super init] )
    {
        commandType = SC_FIT_COMMAND;
    }
    return self;
}


- (void)dealloc
{
    [xName release];
    [xVariable release];
    [yName release];
    [yVariable release];
    [expression release];
    [fitParameterNames release];
    [fitParameterValues release];
    [super dealloc];
}

@synthesize xName;
@synthesize xVariable;
@synthesize yName;
@synthesize yVariable;
@synthesize expression;
@synthesize fitParameterNames;
@synthesize fitParameterValues;

-(NSArray*)allNames
{
    return [NSArray arrayWithObjects:xName,yName,nil];
}


-(NSDictionary*)allVariables
{
    return [NSDictionary dictionaryWithObjectsAndKeys:xVariable,xName,yVariable,yName,nil];
}


@end


@implementation SCSmoothCommand

- (id)init
{
    if ( self = [super init] )
    {
        commandType = SC_SMOOTH_COMMAND;
    }
    return self;
}


- (void)dealloc
{
    [xName release];
    [xVariable release];
    [yName release];
    [yVariable release];
    [super dealloc];
}

@synthesize xName;
@synthesize xVariable;
@synthesize yName;
@synthesize yVariable;

-(NSArray*)allNames
{
    return [NSArray arrayWithObjects:xName,yName,nil];
}


-(NSDictionary*)allVariables
{
    return [NSDictionary dictionaryWithObjectsAndKeys:xVariable,xName,yVariable,yName,nil];
}


@end


@implementation SCMultiLinesCommand

- (id)init
{
    if ( self = [super init] )
    {
        commandType = SC_MULTILINES_COMMAND;
    }
    return self;
}


- (void)dealloc
{
    [linesName release];
    [linesVariable release];
    [lowerLimitsName release];
    [lowerLimitsVariable release];
    [upperLimitsName release];
    [upperLimitsVariable release];
    [labelsName release];
    [labelsVariable release];
    [super dealloc];
}


@synthesize linesName;
@synthesize linesVariable;
@synthesize lowerLimitsName;
@synthesize lowerLimitsVariable;
@synthesize upperLimitsName;
@synthesize upperLimitsVariable;
@synthesize labelsName;
@synthesize labelsVariable;


-(NSArray*) allNames
{
    /* We have to do it this way because it's within the specs that some of these should be empty strings without any
     * variable information. */
    NSMutableArray * all_names = [NSMutableArray arrayWithCapacity:4];
    
    if ( [linesName length] > 0 )
        [all_names addObject:linesName];
    if ( [lowerLimitsName length] > 0 )
        [all_names addObject:lowerLimitsName];
    if ( [upperLimitsName length] > 0 )
        [all_names addObject:upperLimitsName];
    if ( [labelsName length] > 0 )
        [all_names addObject:labelsName];
    
    return all_names;
}


-(NSDictionary*) allVariables
{
    /* We have to do it this way because it's within the specs that some of these should be empty strings without any
     * variable information. */
    NSMutableDictionary * all_variables = [NSMutableDictionary dictionaryWithCapacity:4];
    
    if ( linesVariable )
        [all_variables setObject:linesVariable forKey:linesName];
    if ( lowerLimitsVariable )
        [all_variables setObject:lowerLimitsVariable forKey:lowerLimitsName];
    if ( upperLimitsVariable )
        [all_variables setObject:upperLimitsVariable forKey:upperLimitsName];
    if ( labelsVariable )
        [all_variables setObject:labelsVariable forKey:labelsName];

    return all_variables;
}


@end


@implementation SCAxisCommand

- (id)init
{
    if ( self = [super init] )
    {
        commandType = SC_AXIS_COMMAND;
    }
    return self;
}


- (void)dealloc
{
    [super dealloc];
}



@end


@implementation SCRangeCommand

- (id)init
{
    if ( self = [super init] )
    {
        commandType = SC_RANGE_COMMAND;
    }
    return self;
}


- (void)dealloc
{
    [xMinName release];
    [xMinVariable release];
    [xMaxName release];
    [xMaxVariable release];
    [yMinName release];
    [yMinVariable release];
    [yMaxName release];
    [yMaxVariable release];
    [rangeColorName release];
    [rangeColorVariable release];
    [colorSchemeName release];
    [super dealloc];
}

@synthesize xMinName;
@synthesize xMinVariable;
@synthesize xMaxName;
@synthesize xMaxVariable;
@synthesize yMinName;
@synthesize yMinVariable;
@synthesize yMaxName;
@synthesize yMaxVariable;
@synthesize rangeColorName;
@synthesize rangeColorVariable;
@synthesize colorSchemeName;
 
-(NSArray*) allNames
{
    NSMutableArray * all_names = [NSMutableArray arrayWithCapacity:4];
    if ( [xMinName length] > 0 )
        [all_names addObject:xMinName];
    if ( [xMaxName length] > 0 )
        [all_names addObject:xMaxName];
    if ( [yMinName length] > 0 )
        [all_names addObject:yMinName];
    if ( [yMaxName length] > 0 )
        [all_names addObject:yMaxName];
    if ( [rangeColorName length] > 0 )
        [all_names addObject:rangeColorName];
    return all_names;
}


-(NSDictionary*) allVariables
{
    /* We have to do it this way because it's within the specs that some of these should be empty strings without any
     * variable information. */
    NSMutableDictionary * all_variables = [NSMutableDictionary dictionaryWithCapacity:4];
    if ( xMinVariable )
        [all_variables setObject:xMinVariable forKey:xMinName];
    if ( xMaxVariable )
        [all_variables setObject:xMaxVariable forKey:xMaxName];
    if ( yMinVariable )
        [all_variables setObject:yMinVariable forKey:yMinName];
    if ( yMaxVariable )
        [all_variables setObject:yMaxVariable forKey:yMaxName];
    if ( rangeColorVariable )
        [all_variables setObject:rangeColorVariable forKey:rangeColorName];
    return all_variables;
}


@end



@implementation SCScatterCommand

- (id)init
{
    if ( self = [super init] )
    {
        commandType = SC_SCATTER_COMMAND;
    }
    return self;
}


- (void)dealloc
{
    [xName release];
    [xVariable release];
    [yName release];
    [yVariable release];
    [pointSizeName release];
    [pointSizeVariable release];
    [pointColorName release];
    [pointColorVariable release];
    [colorSchemeName release];
    [super dealloc];
}


@synthesize xName;
@synthesize xVariable;
@synthesize yName;
@synthesize yVariable;
@synthesize pointSizeName;
@synthesize pointSizeVariable;
@synthesize pointColorName;
@synthesize pointColorVariable;
@synthesize colorSchemeName;

-(NSArray*) allNames
{
    NSMutableArray * all_names = [NSMutableArray arrayWithCapacity:4];
    
    [all_names addObject:xName];
    [all_names addObject:yName];
    if ( [pointSizeName length] > 0 )
        [all_names addObject:pointSizeName];
    if ( [pointColorName length] > 0 )
        [all_names addObject:pointColorName];
    
    return all_names;
}


-(NSDictionary*) allVariables
{
    /* We have to do it this way because it's within the specs that some of these should be empty strings without any
     * variable information. */
    NSMutableDictionary * all_variables = [NSMutableDictionary dictionaryWithCapacity:4];
    
    if ( xName )
        [all_variables setObject:xVariable forKey:xName];
    if ( yName )
        [all_variables setObject:yVariable forKey:yName];
    if ( [pointSizeName length] > 0 )
        [all_variables setObject:pointSizeVariable forKey:pointSizeName];
    if ( [pointColorName length] > 0 )
        [all_variables setObject:pointColorVariable forKey:pointColorName];

    return all_variables;
}


@end

