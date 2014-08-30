#ifndef __SC_USER_VARIABLE_H__
#define __SC_USER_VARIABLE_H__

#import <Foundation/Foundation.h>
#import "PlotParameterModel.h"
#import "SimParameterModel.h"

extern int SC_VARIABLE_LENGTH;

typedef enum                    
{
    SC_TIME_COLUMN = 0,    /* For a single dimension watched variable. e.g. plotTime, in many simulations.  */
    SC_FIXED_SIZE_COLUMN,       /* For a column variable that might be used in a bar plot or in a histogram. */
    SC_MANAGED_COLUMN,     /* SC manages the memory for user. */
    SC_EXPRESSION_COLUMN,  /* An expression used in DG to plot other columns of data. e.g.  'log(uservar) + 1.0' */
    SC_MAKE_NOW_COLUMN,     /* An array of data that is simply given in the form of a plot command (like in plotcore). */
    SC_STATIC_COLUMN            /* An array of data that is sent to DG once, and is never changed (e.g. plotTime column) */
} SCUserDataType;


/* This structure definitely needs to be cleaned up.  A strong candidate for a little subclassing. -DCS:2009/10/13 */
@interface SCUserData : NSObject
{
    NSString * dataName;
    SCUserDataType dataType;      
    SCDataHoldType dataHoldType; /* How long is the data refreshed for watched variables. */
    /* Points to a double *, except in the case of the a SC_MANAGED_VAR_COLUMN or SC_STATIC_COLUMN, then it points to
     * SCManagedColumn. These Managed Columns are owned by SimModel. */
    NSValue * dataPtr;          /* The data pointed to is owned by the user, so they have to deallocate it. */
    NSString * expression;      /* Used if the variable type is SC_EXPRESSION_VAR, e.g.  'log(uservar) + 1.0'. */
    NSData * makePlotNowData;   /* Used for make plot now, where the data travels along. If nil, the make now command is using watched data. */
    NSString * varNameToCopy;   /* Used for a make now plot that takes data from a watched variable. */
    int dim1;                   /* The size of the column at a point in time.  So no time dimension. */
    BOOL isSilent;              /* Some variables don't get plotted, they just hang around. (No by default). */
}

@property(copy) NSString * dataName;
@property(assign) SCUserDataType dataType;
@property(assign) SCDataHoldType dataHoldType;
@property(retain) NSValue * dataPtr;
@property(assign) int dim1;
@property(retain) NSString * expression;
@property(retain) NSData * makePlotNowData;
@property(retain) NSString * varNameToCopy;
@property(assign) BOOL isSilent;

@end


#endif
