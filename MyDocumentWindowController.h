//
//  MyDocumentWindowController.h
//  simulation_controller
//
//  Created by David Sussillo on 4/30/09.
//  Copyright Columbia U. 2009 . All rights reserved.
//


#import <Cocoa/Cocoa.h>

#import "HistoryController.h"

@interface MyDocumentWindowController : NSWindowController
{
    HistoryController * historyController;
}

- (HistoryController *)historyController;

@end
