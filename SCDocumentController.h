//
//  SPDocumentController.h
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

#import <Cocoa/Cocoa.h>

// we use a subclass of NSDocumentController so that we can:
//
// 1. Tell NSOpenPanel to allow the user to "open" directories as documents
// 2. Load the contents of the Desktop Pictures folder whenever a new window is created

@interface SCDocumentController : NSDocumentController {

}

@end
