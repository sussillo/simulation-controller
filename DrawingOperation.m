
#import "DrawingOperation.h"

@implementation  DrawingOperation

@synthesize doClearWatchedColumns;
@synthesize doPlot;
@synthesize plotBlock;
@synthesize plotController; 

-(id)init
{
    if (self = [super init])
    {
      // Initialization code here
    }
    return self;
}


- (void)dealloc
{
    //DebugNSLog(@"Here I am");
    [plotBlock release];
    [plotController release];
    [super dealloc];
}


-(BOOL)isConcurrent
{
    return NO;
}


-(void)main 
{
    //DebugNSLog(@"DrawingOperation main");
    if ( plotController != nil && plotBlock != nil )
    {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];

        NSArray *keys = [NSArray arrayWithObjects:@"plotBlock", @"doPlot", @"doClearWatchedColumns", nil];
        NSArray *objects = [NSArray arrayWithObjects:plotBlock, [NSNumber numberWithBool:doPlot], [NSNumber numberWithBool:doClearWatchedColumns], nil];
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
        
        [plotController drawPlot:dictionary];

        [pool release];
    }
}






@end
