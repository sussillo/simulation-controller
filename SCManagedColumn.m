
#import "SCManagedColumn.h"
#import "DebugLog.h"

#define SC_MANAGED_COLUMN_DEFAULT_LENGTH 1024

@implementation SCColumn

- (id)init
{
    if ( self = [super init] )
    {
        length = 0;
        insertIdx = 0;
        isOwner = NO;
        data = NULL;
    }
    return self;
}

-(id) initColumnWithDataPtr:(double *)data_ptr length:(int)length_
{
    if ( self = [super init] )
    {
        length = length_;
        DebugNSLog(@"SCColumn initColumnWithDataPtr: length: %i.\n", length);
        insertIdx = length;
        isOwner = NO;
        data = data_ptr;
    }
    return self;
}


-(id) initColumnWithDataCopy:(double *)data_ptr length:(int)length_
{
    if ( self = [super init] )
    {
        if ( length_ > 0 )
        {
            length = length_;   
            DebugNSLog(@"SCColumn initColumnWithDataCopy: length: %i.\n", length);
            insertIdx = length;
            isOwner = YES;
            data = (double *)malloc(length*sizeof(double));
            for ( int i = 0; i < length_; i++ )
                data[i] = data_ptr[i];
        }
    }
    return self;    
}


- (void)dealloc
{
    DebugNSLog(@"SCColumn: dealloc.\n");
    if ( isOwner && data )
        free(data);
    length = 0;
    insertIdx = 0;
    data = NULL;
    [super dealloc];
}


- (double *)getData
{
    return data;
}


- (int)getDataLength
{
    return insertIdx;
}


-(NSString *)stringRepresentation;
{
    NSMutableString * string_rep = [NSMutableString string];
    
    for (int i = 0; i < length; i++ )
    {
        [string_rep appendFormat:@"%lf    ", data[i]];
    } 
    
    return string_rep;
}


-(NSString *)matlabStringRepresentation;
{
    NSMutableString * string_rep = [NSMutableString string];

    [string_rep appendString:@"["];
    for ( int i = 0; i < length; i++ )
    {
        [string_rep appendFormat:@"%lf ", data[i]];
        if ( i % 10 == 9 && i != length-1 )
            [string_rep appendString:@"...\n"];
        
    } 
    [string_rep appendString:@"]"];
    
    return string_rep;
}



@end


#define SC_MANAGED_COLUMN_MINIMUM_LENGTH 32

@implementation SCManagedColumn


#define SCMC_DO_DEBUG 0

- (id)init
{
    if ( self = [super init] )
    {
        isOwner = YES;
        length = SC_MANAGED_COLUMN_DEFAULT_LENGTH;
        insertIdx = 0;
        data = (double *)malloc(length*sizeof(double));
        if ( SCMC_DO_DEBUG )
        {
            for ( int i = 0; i < length; i++ )
                data[i] = 0.0;
        }
    }
    return self;
}


- (id)initColumnWithSize:(int)length_
{
    if ( self = [super init] )
    {
        if ( length_ < SC_MANAGED_COLUMN_MINIMUM_LENGTH )
            length = SC_MANAGED_COLUMN_MINIMUM_LENGTH;
        else
            length = length_;        

        DebugNSLog(@"SCManagedColumn initColumnWithSize: length: %i.\n", length);
        isOwner = YES;
        insertIdx = 0;
        if ( length > 0 )
        {
            data = (double *)malloc(length*sizeof(double));
            if ( SCMC_DO_DEBUG )
            {
                for ( int i = 0; i < length; i++ )
                    data[i] = 0.0;
            }
        }
        else 
            data = NULL;
    }
    return self;
}


- (void)dealloc
{
    DebugNSLog(@"SCManagedColumn: dealloc.\n");
    [super dealloc];
}


+(int) defaultLength
{
    return SC_MANAGED_COLUMN_DEFAULT_LENGTH;
}


- (int)getDataLength            /* Note that we override the intuitive "length" name above because user can add data. */
{
    return insertIdx;
}


- (void)reallocAndCopyData:(int)at_least_as_big_as
{
    int new_length = SC_MANAGED_COLUMN_MINIMUM_LENGTH;
    if ( length > 0 )
    {
        new_length = 2*length;
    }
    while ( new_length < at_least_as_big_as ) // perhaps should have a check here? -DCS:2009/10/27
    {
        new_length *= 2;
    }
    DebugNSLog(@"SCManagedColumn reallocAndCopyData: %i", new_length);

 
   double * new_data = (double *)malloc(new_length*sizeof(double));
    if ( SCMC_DO_DEBUG )
    {
        for ( int i = 0; i < new_length; i++ )
            new_data[i] = 0.0;
    }

    for ( int i = 0; i < insertIdx; i++ )
        new_data[i] = data[i];

    if ( data )
        free(data);
    data = new_data;
    length = new_length;
}


- (void)addData:(double *)new_data nData:(int)ndata;
{
    if ( new_data == NULL || ndata < 1 )
        return;
    
    assert ( insertIdx <= length ); /* <= because last add could have incremented insertIdx by one.  */
    
    // e.g.  10 + 10 > 15, we'll have a[10]-a[19], so must realloc to at least
    // e.g.  5 + 10 > 15, we'll have a[10], a[11], a[12], a[13], a[14] inserted, OK no realloc. 
    // e.g.  1 + 15 > 15, we'll have to realloc immediately. 
    // e.g.  0 + 15 > 15, this won't happen because of above return, but we'd have to realloc if it did.
    BOOL did_realloc = NO;
    if ( ndata + insertIdx > length ) 
    {
        [self reallocAndCopyData:(ndata+insertIdx)];
        did_realloc = YES;
    }
    

    assert ( ndata + insertIdx <= length );

    for ( int i = 0; i < ndata; i++ )
    {
        data[insertIdx] = new_data[i];
        insertIdx++;
    }
}


- (void) resetCurrentPosition
{
    insertIdx = 0;
}


- (void) resetCurrentPositionAndZero
{
    insertIdx = 0;
    for ( int i = 0; i < length; i++ )
        data[i] = 0.0;
}


-(NSString *)stringRepresentation;
{
    NSMutableString * string_rep = [NSMutableString string];
    
    for (int i = 0; i < insertIdx; i++ )
    {
        [string_rep appendFormat:@"%lf    ", data[i]];
    } 
    
    return string_rep;
}


-(NSString *)matlabStringRepresentation;
{
    NSMutableString * string_rep = [NSMutableString string];

    [string_rep appendString:@"["];
    for ( int i = 0; i < insertIdx; i++ )
    {
        [string_rep appendFormat:@"%lf ", data[i]];
        if ( i % 10 == 9 && i != insertIdx-1 )
            [string_rep appendString:@"...\n"];
        
    } 
    [string_rep appendString:@"]"];
    
    return string_rep;
}


@end


@implementation SCManagedPlotColumn


- (id)init
{
    if ( self = [super init] )
    {
        lastPlotStartIdx = 0;
        dataWasClearedSinceLastPlot = YES; // means a setDataFromPointer in PlotController
        dataSinceLastPlot = data;
    }
    return self;
}


- (id)initColumnWithSize:(int)length_
{
    if ( self = [super initColumnWithSize:length_] )
    {
        lastPlotStartIdx = 0;
        dataWasClearedSinceLastPlot = YES; // means a setDataFromPointer in PlotController
        dataSinceLastPlot = data;
    }
    return self;
}


- (void)dealloc
{
    DebugNSLog(@"SCManagedPlotColumn: dealloc.\n");
    [super dealloc];
}

@synthesize doClearAfterPlotDuration;
@synthesize dataWasClearedSinceLastPlot;


- (void)reallocAndCopyData:(int)at_least_as_big_as
{
    DebugNSLog(@"SCManagedPlotColumn reallocAndCopyData.");
    [super reallocAndCopyData:at_least_as_big_as];
    dataSinceLastPlot = &data[lastPlotStartIdx];
}


- (void)addData:(double *)new_data nData:(int)ndata;
{
    [super addData:new_data nData:ndata];
    insertIdxSinceLastPlot += ndata;
}


-(double *) getDataSinceLastPlot
{
    return dataSinceLastPlot;
}

-(int) getDataLengthSinceLastPlot
{
    return insertIdxSinceLastPlot;
}


/* Should be called after every incremental plot in a plot duration. */
-(void) aPlotHappened
{
    dataWasClearedSinceLastPlot = NO; // means an appendValuesFromPointer in PlotController
    lastPlotStartIdx = insertIdx;
    dataSinceLastPlot = &data[lastPlotStartIdx];
    insertIdxSinceLastPlot = 0;
}


- (void) resetCurrentPosition
{
    [super resetCurrentPosition]; 
    dataWasClearedSinceLastPlot = YES; //  means a setDataFromPointer in PlotController
    dataSinceLastPlot = data;
    insertIdxSinceLastPlot = 0;
    lastPlotStartIdx = 0;
}


- (void) resetCurrentPositionAndZero
{
    [super resetCurrentPositionAndZero];
    dataWasClearedSinceLastPlot = YES; // means a setDataFromPointer in PlotController
    dataSinceLastPlot = data;
    insertIdxSinceLastPlot = 0;
    lastPlotStartIdx = 0;
}


-(void) resetCurrentPositionAfterPlot
{
    if ( doClearAfterPlotDuration ) 
    {
        [super resetCurrentPosition]; 
        dataWasClearedSinceLastPlot = YES; //  means a setDataFromPointer in PlotController
        dataSinceLastPlot = data;
        insertIdxSinceLastPlot = 0;
        lastPlotStartIdx = 0;
    }
    else
    {
        dataWasClearedSinceLastPlot = YES; //  means a setDataFromPointer in PlotController
        dataSinceLastPlot = data; /* All the data has to be plotted. */
        lastPlotStartIdx = 0;     /* Plot everything so this goes to the beginning as well. */
        insertIdxSinceLastPlot = insertIdx; /* All the data has to be replotted. */
    }
    
}

-(void) resetCurrentPositionAndZeroAfterPlot
{ assert ( 0 ); }


@end



