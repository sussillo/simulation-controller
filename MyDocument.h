//
//  MyDocument.h
//  simulation_controller
//
//  Created by David Sussillo on 4/30/09.
//  Copyright Columbia U. 2009 . All rights reserved.
//


/* Why is there no data in my document?  Isn't that a little funny, or is it because I actually have two different types
 * of documents? Should I subclass the document and then put the data in there, or should the controller hold the data?
 * -DCS:2009/05/13 */

#import <Cocoa/Cocoa.h>

#import "MyDocumentWindowController.h"
#import "SimController.h"

@interface MyDocument : NSDocument
{
    MyDocumentWindowController *myDocWinCon;
    SimController *simController;
}

@property(assign) SimController *simController;

/* In order for these actions to be in the first responder chain, they have to be set in the file's owner of the nib and
 * thus in MyDocumnt.  They can't be set in plot controller or history controller, which are only top level objects in
 * the NIB. */
- (IBAction) pushParameters:(id)sender;
- (IBAction) toggleRun:(id)sender;
- (IBAction) togglePlot:(id)sender;

- (IBAction) toggleDisplayMode:(id)sender;

- (IBAction) toggleButton1:(id)sender;
- (IBAction) toggleButton2:(id)sender;
- (IBAction) toggleButton3:(id)sender;
- (IBAction) toggleButton4:(id)sender;
- (IBAction) toggleButton5:(id)sender;
- (IBAction) toggleButton6:(id)sender;
- (IBAction) toggleButton7:(id)sender;
- (IBAction) toggleButton8:(id)sender;
- (IBAction) toggleButton9:(id)sender;
- (IBAction) toggleButton10:(id)sender;
- (IBAction) pushAllSlidersUp:(id)sender;
- (IBAction) pushAllSlidersDown:(id)sender;

- (IBAction) pushSliderUp1:(id)sender;
- (IBAction) pushSliderUp2:(id)sender;
- (IBAction) pushSliderUp3:(id)sender;
- (IBAction) pushSliderUp4:(id)sender;
- (IBAction) pushSliderUp5:(id)sender;
- (IBAction) pushSliderUp6:(id)sender;
- (IBAction) pushSliderUp7:(id)sender;
- (IBAction) pushSliderUp8:(id)sender;

- (IBAction) pushSliderDown1:(id)sender;
- (IBAction) pushSliderDown2:(id)sender;
- (IBAction) pushSliderDown3:(id)sender;
- (IBAction) pushSliderDown4:(id)sender;
- (IBAction) pushSliderDown5:(id)sender;
- (IBAction) pushSliderDown6:(id)sender;
- (IBAction) pushSliderDown7:(id)sender;
- (IBAction) pushSliderDown8:(id)sender;


@end
