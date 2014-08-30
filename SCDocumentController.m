//
//  SPDocumentController.m
//  SimplePicture
//
//  Created by Scott Stevenson on 9/28/07.
//
//  Personal site: http://theocacao.com/
//  Post for this sample: http://theocacao.com/document.page/497
//
//  The code in this project is intended to be used as a learning
//  tool for Cocoa programmers. You may freely use the code in
//  your own programs, but please do not use the code as-is in
//  other tutorials.

#import "SCDocumentController.h"
#import "MyDocument.h"
#import "DebugLog.h"

@implementation SCDocumentController

/* Nice bit of code demonstrating how to override the open method of the DocumentController in order to be able to
 * upload folders. */
// - (int)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)types
// {
//     // we customize this method so that we can tell the NSOpenPanel
//     // that it's okay for the user to "open" a directory as a document
    
//     [openPanel setCanChooseDirectories:YES];
//     return [super runModalOpenPanel:openPanel forTypes:types];
// }


- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError
{
#ifndef _NO_USER_LIBRARY_       //This definition may be declared as -D_NO_USER_LIBRARY_=1 in other C flags, build information of Xcode. -SHH@7/15/09
    MyDocument *doc = [[MyDocument alloc] init];
    [doc makeWindowControllers];
#else
    MyDocument* doc = [super openUntitledDocumentAndDisplay:displayDocument error:outError];
#endif
    DebugNSLog(@"SCDocumentController openUntitledDocumentAndDisplay");

    // when a blank document window is opened, we want to display the
    // contents of the users's Pictures folder
    //[doc setFileName:@"Desktop Pictures"];
    //[doc setPathForImages:@"/Library/Desktop Pictures"];

    // setting importingImages to YES will start the spinner
    //[doc setImportingImages:YES];

    // this will create a new background thread which will load
    // all images from the folder. Doing this in the background
    // allows the UI to stay responsive in the foreground.
    //[NSThread detachNewThreadSelector:@selector(threadedReloadImageList)
    //          toTarget:doc
    //          withObject:nil];                               
    return doc;
}

@end
 
