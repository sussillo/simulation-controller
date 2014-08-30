#import <Foundation/Foundation.h>


/* A read-only interface. */
@interface SCColumn : NSObject
{
    BOOL isOwner;
    int length;                 /* The total length of allocated storage. */
    double * data;              /* data -> [0 | 1 | 2 | 3 | 4 | 5 ]  */
    int insertIdx;
}

-(id)initColumnWithDataPtr:(double *)data_ptr length:(int)length; /* Simply connect the pointer */
-(id)initColumnWithDataCopy:(double *)data_ptr length:(int)length; /* Copy the data. */

-(double *) getData;
-(int) getDataLength;

-(NSString *)stringRepresentation;
-(NSString *)matlabStringRepresentation;

@end


@interface SCManagedColumn : SCColumn
{
    //int insertIdx;        /* index from data[0] to current insertion point. */
}

+(int) defaultLength;
-(id) initColumnWithSize:(int)length_;
-(void) addData:(double *)new_data nData:(int)ndata;
-(void) resetCurrentPosition;
-(void) resetCurrentPositionAndZero;

@end


@interface SCManagedPlotColumn : SCManagedColumn
{
    int insertIdxSinceLastPlot; /* index from data[lastPlotStartIdx] to current insertion point. */
    int lastPlotStartIdx;             /* Need this for when reallocations happen. */

    BOOL doClearAfterPlotDuration; /* default is true */

                                /* data -> [0 | 1 | 2 | 3 | 4 | 5 ]  */
    double * dataSinceLastPlot; /* dataslp -> ----------              so the new data since the last plot is 3,4,5. */
    BOOL dataWasClearedSinceLastPlot; /* Determines whether or not DG gets an append (NO) or a full write of the data (YES).  */
}

@property(assign) BOOL doClearAfterPlotDuration;
@property(readonly) BOOL dataWasClearedSinceLastPlot;

-(void) aPlotHappened;
-(double *) getDataSinceLastPlot;
-(int) getDataLengthSinceLastPlot;

-(void) resetCurrentPositionAfterPlot;
-(void) resetCurrentPositionAndZeroAfterPlot;

@end
