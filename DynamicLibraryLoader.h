/*
 *  DynamicLibraryLoader.h
 *  SimulationControllerFramework
 *
 *  Created by Soonhac Hong on 7/7/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef __DYNAMIC_LIBRARY_LOADER_H
#define __DYNAMIC_LIBRARY_LOADER_H

void* lib_handle;

void openDynamicLibrary(void);
void closeDynamicLibrary(void);

#endif