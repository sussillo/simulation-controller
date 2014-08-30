

#import "MyDocumentWindowController.h"
#import "DebugLog.h"

@implementation MyDocumentWindowController


- (id)init
{
    if ( self = [super init] )
    {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
#ifndef _NO_USER_LIBRARY_       //This definition may be declared as -D_NO_USER_LIBRARY_=1 in other C flags, build information of Xcode. -SHH@7/15/09
        const char* scframepath = getenv("SC_FRAMEWORK_PATH");
        if ( !scframepath )
        {
            DebugNSLog(@"[%s] main: SC_USER_LIBRARY_PATH not set.  Aborting.\n", __FILE__);
            exit(EXIT_FAILURE);
        }
        NSString *framePath = [[NSString alloc] initWithUTF8String:scframepath];
        NSString *nibFilePath = [[NSString alloc] initWithString:@"/SimulationControllerFramework.framework/Versions/A/Resources"];
        framePath=[framePath stringByAppendingString:nibFilePath];
        NSBundle* aBundle = [NSBundle bundleWithPath:framePath];
#else
        NSBundle* aBundle = [NSBundle mainBundle];
#endif
        NSMutableArray *topLevelObjs = [NSMutableArray array]; 
        NSDictionary* nameTable = [NSDictionary dictionaryWithObjectsAndKeys:self, NSNibOwner, topLevelObjs, NSNibTopLevelObjects, nil]; 
        if (![aBundle loadNibFile:@"MyDocument" externalNameTable:nameTable withZone:nil]) 
        { 
            DebugNSLog(@"Warning! Could not load myNib file.\n"); 
            return nil; 
        }

        char * classname;
        int classname_length = 0;
        int i = 0;
        for (i = 0; i < [topLevelObjs count]; i++ )
        {
            classname = (char *)object_getClassName((id)[topLevelObjs objectAtIndex:i]);
            classname_length = 0;
            while ( classname[classname_length] != '\0' )
                classname_length++;

            if ( strcmp(classname, "HistoryController") == 0 )
            {
                historyController = [topLevelObjs objectAtIndex:i];
                //[historyController release];
            }
            
        }
        [pool release];
    }

    DebugNSLog(@"HistoryController showing %@", historyController);                
    DebugNSLog(@"Retain count %d", [historyController retainCount]);
    return self;
}



- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    if ( [historyController plotName] != nil )
    {
        DebugNSLog(@"%@", [historyController plotName]);
        return [NSString stringWithString:[historyController plotName]];
    }
    
    else
        return displayName;
}

// - (void)synchronizeWindowTitleWithDocumentName
// {
//     [self windowTitleForDocumentDisplayName:nil];
// }


- (HistoryController *)historyController
{
    // Should I autorelease this or do anything else funny? -DCS:2009/05/08 I don't think I should autorelease this
    // because I want to keep it around and I didn't copy it.  Neither do I want to make a copy of it, that wouldn't
    // make much sense either.  The upshot is that it's a high level control object and it needs to be shared between a
    // couple of other high level objects.  Is there really anything else to be said?  -DCS:2009/05/08
    return historyController;
}


@end
