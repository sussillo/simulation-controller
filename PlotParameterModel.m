
#import "PlotParameterModel.h"

@implementation SCCommandParameters

- (id)init
{
    if (self = [super init])
    {
        // Initialization code here
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

@synthesize xAxis;
@synthesize yAxis;

@end


@implementation SCPlotCommandParameters

- (id)init
{
    if (self = [super init])
    {
      // Initialization code here
    }
    return self;
}

- (void)dealloc 
{ 
    [lineColor release];
    lineColor = nil;
    [markerColor release];
    markerColor = nil;

    [super dealloc];
}

@synthesize lineStyle;
@synthesize lineWidth;
@synthesize lineColor;
@synthesize markerStyle;
@synthesize markerSize;
@synthesize markerColor;
@synthesize xOffset;
@synthesize yOffset;

+ (SCPlotCommandParameters *)copyFromCStruct:(SCPlotParameters *)pp
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    SCPlotCommandParameters *lppm = [[SCPlotCommandParameters alloc] init];
    
    [lppm setLineStyle: pp->lineStyle];
    [lppm setLineWidth: pp->lineWidth];
    [lppm setLineColor:[NSColor colorWithCalibratedRed:pp->lineColor.red 
                                green:pp->lineColor.green 
                                blue:pp->lineColor.blue  
                                alpha:pp->lineColor.alpha]];
    [lppm setMarkerStyle: pp->markerStyle];
    [lppm setMarkerSize: pp->markerSize];
    [lppm setMarkerColor:[NSColor colorWithCalibratedRed:pp->markerColor.red 
                                  green:pp->markerColor.green 
                                  blue:pp->markerColor.blue  
                                  alpha:pp->markerColor.alpha]];
    [lppm setXOffset: pp->xOffset];
    [lppm setYOffset: pp->yOffset];

    [lppm setXAxis: pp->xAxis];
    [lppm setYAxis: pp->yAxis];

    [pool release];

    return lppm;
}

@end


@implementation SCTimePlotCommandParameters

- (id)init
{
    if (self = [super init])
    {
        // Initialization code here
    }
    return self;
}

- (void)dealloc 
{ 
    [lineColor release];
    lineColor = nil;
    [markerColor release];
    markerColor = nil;
    
    [super dealloc];
}

@synthesize lineType;
@synthesize lineWidth;
@synthesize lineColor;
@synthesize markerStyle;
@synthesize markerSize;
@synthesize markerColor;
@synthesize xOffset;
@synthesize yOffset;


+ (SCTimePlotCommandParameters *)copyFromCStruct:(SCTimePlotParameters *)tpp
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    SCTimePlotCommandParameters *flppm = [[SCTimePlotCommandParameters alloc] init];
    
    [flppm setLineType: tpp->lineType];
    [flppm setLineWidth: tpp->lineWidth];
    [flppm setLineColor:[NSColor colorWithCalibratedRed:tpp->lineColor.red 
                                green:tpp->lineColor.green 
                                blue:tpp->lineColor.blue  
                                alpha:tpp->lineColor.alpha]];
    [flppm setMarkerStyle: tpp->markerStyle];
    [flppm setMarkerSize: tpp->markerSize];
    [flppm setMarkerColor:[NSColor colorWithCalibratedRed:tpp->markerColor.red 
                                  green:tpp->markerColor.green 
                                  blue:tpp->markerColor.blue  
                                  alpha:tpp->markerColor.alpha]];
    [flppm setXOffset: tpp->xOffset];
    [flppm setYOffset: tpp->yOffset];

    [flppm setXAxis: tpp->xAxis];
    [flppm setYAxis: tpp->yAxis];

    [pool release];

    return flppm;
}

@end



// @implementation PointsCommandParameters

// - (id)init
// {
//     if ( self = [super init] )
//     {
//       // Initialization code here
//     }
//     return self;
// }

// - (void)dealloc 
// { 
//     [markerColor release];
//     markerColor = nil;

//     [super dealloc];
// }

// @synthesize markerStyle;
// @synthesize markerSize;
// @synthesize markerColor;
// @synthesize xOffset;
// @synthesize yOffset;

// + (PointsCommandParameters *)copyFromCStruct:(SCPointsPlotParameters *)points_command_parameters
// {
//     NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
//     PointsCommandParameters *pppm = [[PointsCommandParameters alloc] init];
    
//     [pppm setMarkerStyle: points_command_parameters->markerStyle];
//     [pppm setMarkerSize: points_command_parameters->markerSize];
//     [pppm setMarkerColor:[NSColor colorWithCalibratedRed:points_command_parameters->markerColor.red 
//                                   green:points_command_parameters->markerColor.green 
//                                   blue:points_command_parameters->markerColor.blue  
//                                   alpha:points_command_parameters->markerColor.alpha]];
//     [pppm setXOffset: points_command_parameters->xOffset];
//     [pppm setYOffset: points_command_parameters->yOffset];

//     [pppm setXAxis: points_command_parameters->xAxis];
//     [pppm setYAxis: points_command_parameters->yAxis];

//     [pool release];

//     return pppm;
// }

// @end


// @implementation FastPointsCommandParameters

// - (id)init
// {
//     if ( self = [super init] )
//     {
//       // Initialization code here
//     }
//     return self;
// }

// - (void)dealloc 
// { 
//     [markerColor release];
//     markerColor = nil;

//     [super dealloc];
// }

// @synthesize markerStyle;
// @synthesize markerSize;
// @synthesize markerColor;
// @synthesize xOffset;
// @synthesize yOffset;

// + (FastPointsCommandParameters *)copyFromCStruct:(SCFastPointsPlotParameters *)fast_points_command_parameters
// {
//     NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
//     FastPointsCommandParameters *fpppm = [[FastPointsCommandParameters alloc] init];
    
//     [fpppm setMarkerStyle: fast_points_command_parameters->markerStyle];
//     [fpppm setMarkerSize: fast_points_command_parameters->markerSize];
//     [fpppm setMarkerColor:[NSColor colorWithCalibratedRed:fast_points_command_parameters->markerColor.red 
//                                   green:fast_points_command_parameters->markerColor.green 
//                                   blue:fast_points_command_parameters->markerColor.blue  
//                                   alpha:fast_points_command_parameters->markerColor.alpha]];
//     [fpppm setXOffset: fast_points_command_parameters->xOffset];
//     [fpppm setYOffset: fast_points_command_parameters->yOffset];
//     [fpppm setXAxis: fast_points_command_parameters->xAxis];
//     [fpppm setYAxis: fast_points_command_parameters->yAxis];

//     [pool release];

//     return fpppm;
// }

// @end


@implementation SCBarCommandParameters

- (id)init
{
    if ( self = [super init] )
    {
      // Initialization code here
    }
    return self;
}


- (void)dealloc 
{ 
    [barColor release];
    barColor = nil;
    [super dealloc];
}

@synthesize barColor;
@synthesize offset;
@synthesize distanceBetweenBars;
@synthesize barsAreVertical;

+ (SCBarCommandParameters *)copyFromCStruct:(SCBarPlotParameters *)bpp
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    SCBarCommandParameters *bcp = [[SCBarCommandParameters alloc] init];
    
    [bcp setBarColor:[NSColor colorWithCalibratedRed:bpp->barColor.red 
                               green:bpp->barColor.green 
                               blue:bpp->barColor.blue  
                               alpha:bpp->barColor.alpha]];
    [bcp setOffset: bpp->offset];
    [bcp setDistanceBetweenBars: bpp->distanceBetweenBars];
    [bcp setBarsAreVertical: bpp->barsAreVertical];

    [bcp setXAxis: bpp->xAxis];
    [bcp setYAxis: bpp->yAxis];

    [pool release];

    return bcp;    
}


@end


@implementation SCHistogramCommandParameters

- (id)init
{
    if ( self = [super init] )
    {
      // Initialization code here
    }
    return self;
}


- (void)dealloc 
{ 
    [barColor release];
    barColor = nil;
    [super dealloc];
}

@synthesize barType;
@synthesize barColor;
@synthesize binRangeLow;
@synthesize binRangeHigh;
@synthesize barsAreVertical;
@synthesize lineWidth;
@synthesize units;
@synthesize spacingType;
@synthesize spacing;
@synthesize smoothValue;


+ (SCHistogramCommandParameters *)copyFromCStruct:(SCHistogramPlotParameters *)hpp
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    SCHistogramCommandParameters *hcp = [[SCHistogramCommandParameters alloc] init];

    [hcp setBarType: hpp->barType];
    [hcp setBarColor:[NSColor colorWithCalibratedRed:hpp->barColor.red 
                               green:hpp->barColor.green 
                               blue:hpp->barColor.blue  
                               alpha:hpp->barColor.alpha]];
    [hcp setBinRangeLow: hpp->binRangeLow];
    [hcp setBinRangeHigh: hpp->binRangeHigh];
    [hcp setBarsAreVertical: hpp->barsAreVertical];
    [hcp setLineWidth: hpp->lineWidth];
    [hcp setUnits: hpp->units];
    [hcp setSpacingType: hpp->spacingType];
    [hcp setSpacing: hpp->spacing];
    [hcp setSmoothValue: hpp->smoothValue];

    [hcp setXAxis: hpp->xAxis];
    [hcp setYAxis: hpp->yAxis];
    
    [pool release];

    return hcp;    
}


@end


@implementation SCFitCommandParameters

- (id)init
{
    if (self = [super init])
    {
      // Initialization code here
    }
    return self;
}

- (void)dealloc 
{ 
    [lineColor release];
    lineColor = nil;
    [super dealloc];
}

@synthesize lineStyle;
@synthesize lineWidth;
@synthesize lineColor;

+ (SCFitCommandParameters *)copyFromCStruct:(SCFitPlotParameters *)fpp
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    SCFitCommandParameters *fcp = [[SCFitCommandParameters alloc] init];
    
    [fcp setLineStyle: fpp->lineStyle];
    [fcp setLineWidth: fpp->lineWidth];
    [fcp setLineColor: [NSColor colorWithCalibratedRed:fpp->lineColor.red 
                                green:fpp->lineColor.green 
                                blue:fpp->lineColor.blue  
                                alpha:fpp->lineColor.alpha]];

    [fcp setXAxis: fpp->xAxis];
    [fcp setYAxis: fpp->yAxis];

    [pool release];

    return fcp;
}

@end


@implementation SCSmoothCommandParameters

- (id)init
{
    if (self = [super init])
    {
      // Initialization code here
    }
    return self;
}

- (void)dealloc 
{ 
    [lineColor release];
    lineColor = nil;
    [super dealloc];
}

@synthesize smoothness;
@synthesize lineStyle;
@synthesize lineWidth;
@synthesize lineColor;

+ (SCSmoothCommandParameters *)copyFromCStruct:(SCSmoothPlotParameters *)spp
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    SCSmoothCommandParameters *scp = [[SCSmoothCommandParameters alloc] init];

    [scp setSmoothness: spp->smoothness];
    [scp setLineStyle: spp->lineStyle];
    [scp setLineWidth: spp->lineWidth];
    [scp setLineColor: [NSColor colorWithCalibratedRed:spp->lineColor.red 
                                green:spp->lineColor.green 
                                blue:spp->lineColor.blue  
                                alpha:spp->lineColor.alpha]];
    [scp setXAxis: spp->xAxis];
    [scp setYAxis: spp->yAxis];

    
    [pool release];

    return scp;
}

@end


@implementation SCMultiLinesCommandParameters

- (id)init
{
    if (self = [super init])
    {
      // Initialization code here
    }
    return self;
}

- (void)dealloc 
{ 
    [lineColor release];
    lineColor = nil;
    [super dealloc];
}

@synthesize linesAreVertical; 
@synthesize fixedLowerLimit;
@synthesize fixedUpperLimit;
@synthesize labelAtTop;
@synthesize lineStyle;
@synthesize lineWidth;
@synthesize lineColor;

+ (SCMultiLinesCommandParameters *)copyFromCStruct:(SCMultiLinesPlotParameters *)mlpp
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    SCMultiLinesCommandParameters *mlcp = [[SCMultiLinesCommandParameters alloc] init];

    [mlcp setLinesAreVertical: mlpp->linesAreVertical];
    [mlcp setFixedLowerLimit: mlpp->fixedLowerLimit];
    [mlcp setFixedUpperLimit: mlpp->fixedUpperLimit];
    [mlcp setLabelAtTop: mlpp->labelAtTop];
    [mlcp setLineStyle: mlpp->lineStyle];
    [mlcp setLineWidth: mlpp->lineWidth];
    [mlcp setLineColor: [NSColor colorWithCalibratedRed:mlpp->lineColor.red 
                                 green:mlpp->lineColor.green 
                                 blue:mlpp->lineColor.blue  
                                 alpha:mlpp->lineColor.alpha]];

    [mlcp setXAxis: mlpp->xAxis];
    [mlcp setYAxis: mlpp->yAxis];

    [pool release];

    return mlcp;
}

@end


@implementation SCRangeCommandParameters

- (id)init
{
    if (self = [super init])
    {
      // Initialization code here
    }
    return self;
}

- (void)dealloc 
{ 
    [lineColor release];
    [fillColor release];
    [super dealloc];
}

@synthesize xRangeType;
@synthesize yRangeType;
@synthesize xMin;
@synthesize xMax;
@synthesize xStride;
@synthesize yMin;
@synthesize yMax;
@synthesize yStride;
@synthesize lineStyle;
@synthesize lineWidth;
@synthesize lineColor;    
@synthesize fillColor;


+ (SCRangeCommandParameters *)copyFromCStruct:(SCRangePlotParameters *)rpp
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    SCRangeCommandParameters *rcp = [[SCRangeCommandParameters alloc] init];
    
    [rcp setXRangeType: rpp->xRangeType];
    [rcp setYRangeType: rpp->yRangeType];
    [rcp setXMin: rpp->xMin];
    [rcp setXMax: rpp->xMax];
    [rcp setXStride: rpp->xStride];
    [rcp setYMin: rpp->yMin];
    [rcp setYMax: rpp->yMax];
    [rcp setYStride: rpp->yStride];
    [rcp setLineStyle: rpp->lineStyle];
    [rcp setLineWidth: rpp->lineWidth];
    [rcp setLineColor: [NSColor colorWithCalibratedRed: rpp->lineColor.red 
                                green: rpp->lineColor.green 
                                blue: rpp->lineColor.blue  
                                alpha: rpp->lineColor.alpha]];

    [rcp setFillColor: [NSColor colorWithCalibratedRed: rpp->fillColor.red 
                                green: rpp->fillColor.green 
                                blue: rpp->fillColor.blue  
                                alpha: rpp->fillColor.alpha]];
    [rcp setXAxis: rpp->xAxis];
    [rcp setYAxis: rpp->yAxis];

    [pool release];

    return rcp;
}

@end


@implementation SCScatterCommandParameters

- (id)init
{
    if (self = [super init])
    {
      // Initialization code here
    }
    return self;
}

- (void)dealloc 
{ 
    [borderColor release];
    [markerColor release];
    [super dealloc];
}


@synthesize markerStyle;
@synthesize borderSize;
@synthesize borderColor;
@synthesize markerSize;
@synthesize markerColor;
@synthesize scaleType;
@synthesize scale;
@synthesize colorType;


+ (SCScatterCommandParameters *)copyFromCStruct:(SCScatterPlotParameters *)spp
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    SCScatterCommandParameters *scp = [[SCScatterCommandParameters alloc] init];
    [scp setMarkerStyle: spp->markerStyle];
    [scp setBorderSize: spp->borderSize];
    [scp setBorderColor: [NSColor colorWithCalibratedRed: spp->borderColor.red 
                                  green: spp->borderColor.green 
                                  blue: spp->borderColor.blue  
                                  alpha: spp->borderColor.alpha]];
    [scp setMarkerSize: spp->markerSize];
    [scp setMarkerColor: [NSColor colorWithCalibratedRed: spp->markerColor.red 
                                  green: spp->markerColor.green 
                                  blue: spp->markerColor.blue  
                                  alpha: spp->markerColor.alpha]];
    [scp setScaleType: spp->scaleType];
    [scp setScale: spp->scale];
    [scp setColorType: spp->colorType];

    [scp setXAxis: spp->xAxis];
    [scp setYAxis: spp->yAxis];

    [pool release];
    
    return scp;
}

@end


@implementation SCAxisCommandParameters

- (id)init
{
    if (self = [super init])
    {
      // Initialization code here
    }
    return self;
}

- (void)dealloc 
{ 
    [label release];
    [super dealloc];
}

@synthesize label;
@synthesize isXAxis;
@synthesize axisType;
@synthesize doDrawAxis;         
@synthesize axisToAxisSpacing;   
@synthesize axisRatio;            
@synthesize min;              
@synthesize max;              
@synthesize doCropWithMinMax;
@synthesize ticks;

+ (SCAxisCommandParameters *)copyFromCStruct:(SCAxisParameters *)ap
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    SCAxisCommandParameters *acp = [[SCAxisCommandParameters alloc] init];

    if ( ap->label  )
        [acp setLabel:[NSString stringWithUTF8String:ap->label]];
    [acp setIsXAxis: ap->isXAxis];
    [acp setAxisType: ap->axisType];
    [acp setDoDrawAxis: ap->doDrawAxis];
    [acp setAxisToAxisSpacing: ap->axisToAxisSpacing];
    [acp setAxisRatio: ap->axisRatio];
    [acp setMin: ap->min];
    [acp setMax: ap->max];
    [acp setDoCropWithMinMax: ap->doCropWithMinMax];
    [acp setTicks: ap->ticks];
     
    [pool release];

    return acp;
}

@end


@implementation DefaultAxisParameters

- (id)init
{
    if ( self = [super init] )
    {
      // Initialization code here
    }
    return self;
}


- (void)dealloc 
{ 
    [title release];            // apparently it's safer to avoid the access methods when deallocating or setting up? -DCS:2009/05/15
    title = nil;
    
    [xLabel release];
    xLabel = nil;
    
    [yLabel release];
    yLabel = nil;
    
    [backColor release];
    backColor = nil;
    
    [foreColor release];
    foreColor = nil;

    [super dealloc];
}


@synthesize isActive;
@synthesize title;
@synthesize fontSize;
@synthesize xAxisType;
@synthesize yAxisType;
@synthesize xMin;                // min range on x axis
@synthesize xMax;                // max range on x axis
@synthesize doCropWithXMinMax;
@synthesize xScale;              // not clear
@synthesize yMin;                // min range on x axis
@synthesize yMax;                // max range on x axis
@synthesize doCropWithYMinMax;
@synthesize yScale;              // not clear
@synthesize xTicks;              // tick size on the x axis
@synthesize yTicks;              // tick size on the y axis
@synthesize doDrawXAxis;
@synthesize doDrawYAxis;
@synthesize xLabel;              // label on the x axis
@synthesize yLabel;              // label on the y axis
@synthesize backColor;
@synthesize foreColor;
@synthesize gridType;
@synthesize boxStyle;
@synthesize multiAxisStyle;

// Implements the NSCopying protocol with this method.  Can't help but wonder if KVC would have significantly reduced
// the code in this method. -DCS:2009/05/17
- (id) copyWithZone: (NSZone *) zone
{
    DefaultAxisParameters *newPlotParameters = [[DefaultAxisParameters allocWithZone:zone] init];
    [newPlotParameters setIsActive:isActive];
    [newPlotParameters setTitle:title];
    [newPlotParameters setFontSize:fontSize];
    [newPlotParameters setXAxisType:xAxisType];
    [newPlotParameters setYAxisType:yAxisType];
    [newPlotParameters setXMin:xMin];
    [newPlotParameters setXMax:xMax];
    [newPlotParameters setDoCropWithXMinMax:doCropWithXMinMax];
    [newPlotParameters setXScale:xScale];
    [newPlotParameters setYMin:yMin];
    [newPlotParameters setYMax:yMax];
    [newPlotParameters setDoCropWithYMinMax:doCropWithYMinMax];
    [newPlotParameters setYScale:yScale];
    [newPlotParameters setXTicks:xTicks];
    [newPlotParameters setYTicks:yTicks];
    [newPlotParameters setDoDrawXAxis:doDrawXAxis];
    [newPlotParameters setDoDrawYAxis:doDrawYAxis];
    [newPlotParameters setXLabel:xLabel];
    [newPlotParameters setYLabel:yLabel];
    [newPlotParameters setBackColor:backColor];
    [newPlotParameters setForeColor:foreColor];
    [newPlotParameters setGridType:gridType];
    [newPlotParameters setBoxStyle:boxStyle];
    [newPlotParameters setMultiAxisStyle:multiAxisStyle];
    
    return newPlotParameters;
}


+ (DefaultAxisParameters *)copyFromPStruct:(pStruct *)pdata
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    DefaultAxisParameters *ppm = [[DefaultAxisParameters alloc] init];
    
    [ppm setIsActive:pdata->isActive];

    if ( pdata->title)
        [ppm setTitle:[NSString stringWithUTF8String:pdata->title]];

    [ppm setXAxisType:pdata->xAxisType];
    [ppm setYAxisType:pdata->yAxisType];

    [ppm setXMin:pdata->xMin];
    [ppm setXMax:pdata->xMax];
    [ppm setDoCropWithXMinMax:pdata->doCropWithXMinMax];

    //[ppm setXScale:100.0];
    [ppm setXTicks:pdata->xTicks];
    if ( pdata->xLabel )
        [ppm setXLabel:[NSString stringWithUTF8String:pdata->xLabel]];
    
    [ppm setDoDrawXAxis:pdata->doDrawXAxis];
    
    [ppm setYMin:pdata->yMin];
    [ppm setYMax:pdata->yMax];
    [ppm setDoCropWithYMinMax:pdata->doCropWithYMinMax];
    
    //[ppm setYScale:100.0];
    [ppm setYTicks:pdata->yTicks];
    if ( pdata->yLabel )
        [ppm setYLabel:[NSString stringWithUTF8String:pdata->yLabel]];

    [ppm setDoDrawYAxis:pdata->doDrawYAxis];

    
    // These color calls need to be implemented lower down in PlotController. This may take some muckng around with
    // the DGController API because there are a lot of ways to access this stuff in the DataGraph
    // program. -DCS:2009/05/19
    [ppm setBackColor:[NSColor colorWithCalibratedRed:pdata->backColor.red 
                               green:pdata->backColor.green 
                               blue:pdata->backColor.blue  
                               alpha:pdata->backColor.alpha]];
    
    [ppm setForeColor:[NSColor colorWithCalibratedRed:pdata->foreColor.red 
                               green:pdata->foreColor.green 
                               blue:pdata->foreColor.blue  
                               alpha:pdata->foreColor.alpha]];

    [pool release];

    [ppm setGridType:pdata->gridType];
    [ppm setBoxStyle:pdata->boxStyle];
    [ppm setMultiAxisStyle:pdata->multiAxisStyle];
    
     
    return ppm;
}




@end
