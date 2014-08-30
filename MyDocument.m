//
//  MyDocument.m
//  simulation_controller
//
//  Created by David Sussillo on 4/30/09.
//  Copyright Columbia U. 2009 . All rights reserved.
//


/* A commom mistake made by novice Cocoa programmers is to treat the document object as a model, though it's really a
 * controller object that adapts between the view of the document itself and whatever model is being used to hold the
 * representation. */

#import "MyDocument.h"
#import "MyDocumentWindowController.h"

@implementation MyDocument

- (id)init
{
    if (self = [super init])
    {
      // Initialization code here
    }
    return self;
}

@synthesize simController;


- (NSString *)windowNibName
{
    // Override returning the nib file name of the document If you need to use a subclass of NSWindowController or if
    // your document supports multiple NSWindowControllers, you should remove this method and override
    // -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}


// Create a new instance of the controller subclass in the MyDocument? method - (void)makeWindowControllers and add the
// controller to the document with - (void)addWindowController:(NSWindowController *)aController (do not override the -
// (NSString *)windowNibName method).

- (void)makeWindowControllers
{
    myDocWinCon = [[MyDocumentWindowController alloc] init];
    [myDocWinCon showWindow:self];
    [self addWindowController:myDocWinCon]; // does this mean there is another window controller, still? -DCS:2009/05/08
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that
    // you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or
    // -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems, you should use the deprecated API
    // -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or
    // -writeToFile:ofType: instead.

    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL,
    // ensure that you set *outError when returning NO.

    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    
    // For applications targeted for Panther or earlier systems, you should use the deprecated API
    // -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or
    // -loadFileWrapperRepresentation:ofType: instead.
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}


/* Send all of these to be handled by the SimController object.  These actions are here simply so that a user can use
 * the keyboard shortcuts when the simulation controller window isn't in focus. */
- (IBAction) pushParameters:(id)sender
{
    [self.simController pushParameters:sender];
}

- (IBAction) toggleRun:(id)sender
{
    [self.simController toggleRun:sender];
}

- (IBAction) togglePlot:(id)sender
{
    [self.simController togglePlot:sender];
}

- (IBAction) toggleDisplayMode:(id)sender
{
    [self.simController toggleDisplayMode:sender];
}

- (IBAction) toggleButton1:(id)sender
{
    [self.simController toggleButton1:sender];
}

- (IBAction) toggleButton2:(id)sender
{
    [self.simController toggleButton2:sender];
}

- (IBAction) toggleButton3:(id)sender
{
    [self.simController toggleButton3:sender];
}

- (IBAction) toggleButton4:(id)sender
{
    [self.simController toggleButton4:sender];
}

- (IBAction) toggleButton5:(id)sender
{
    [self.simController toggleButton5:sender];
}

- (IBAction) toggleButton6:(id)sender
{
    [self.simController toggleButton6:sender];
}

- (IBAction) toggleButton7:(id)sender
{
    [self.simController toggleButton7:sender];
}

- (IBAction) toggleButton8:(id)sender
{
    [self.simController toggleButton8:sender];
}

- (IBAction) toggleButton9:(id)sender
{
    [self.simController toggleButton9:sender];
}

- (IBAction) toggleButton10:(id)sender
{
    [self.simController toggleButton10:sender];
}

- (IBAction) pushAllSlidersUp:(id)sender
{
    [self.simController pushAllSlidersUpExternal:sender];
}

- (IBAction) pushAllSlidersDown:(id)sender
{
    [self.simController pushAllSlidersDownExternal:sender];
}

- (IBAction) pushSliderUp1:(id)sender
{
    [self.simController pushSliderUp1:sender];
}

- (IBAction) pushSliderUp2:(id)sender
{
    [self.simController pushSliderUp2:sender];
}

- (IBAction) pushSliderUp3:(id)sender
{
    [self.simController pushSliderUp3:sender];
}

- (IBAction) pushSliderUp4:(id)sender
{
    [self.simController pushSliderUp4:sender];
}

- (IBAction) pushSliderUp5:(id)sender
{
    [self.simController pushSliderUp5:sender];
}

- (IBAction) pushSliderUp6:(id)sender
{
    [self.simController pushSliderUp6:sender];
}

- (IBAction) pushSliderUp7:(id)sender
{
    [self.simController pushSliderUp7:sender];
}

- (IBAction) pushSliderUp8:(id)sender
{
    [self.simController pushSliderUp8:sender];
}

- (IBAction) pushSliderDown1:(id)sender
{
    [self.simController pushSliderDown1:sender];
}

- (IBAction) pushSliderDown2:(id)sender
{
    [self.simController pushSliderDown2:sender];
}

- (IBAction) pushSliderDown3:(id)sender
{
    [self.simController pushSliderDown3:sender];
}

- (IBAction) pushSliderDown4:(id)sender
{
    [self.simController pushSliderDown4:sender];
}

- (IBAction) pushSliderDown5:(id)sender
{
    [self.simController pushSliderDown5:sender];
}

- (IBAction) pushSliderDown6:(id)sender
{
    [self.simController pushSliderDown6:sender];
}

- (IBAction) pushSliderDown7:(id)sender
{
    [self.simController pushSliderDown7:sender];
}

- (IBAction) pushSliderDown8:(id)sender
{
    [self.simController pushSliderDown8:sender];
}

@end
