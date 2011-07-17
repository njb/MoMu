/*----------------------------------------------------------------------------
  MoMu: A Mobile Music Toolkit
  Copyright (c) 2010 Nicholas J. Bryan, Jorge Herrera, Jieun Oh, and Ge Wang
  All rights reserved.
    http://momu.stanford.edu/toolkit/
 
  Mobile Music Research @ CCRMA
  Music, Computing, Design Group
  Stanford University
    http://momu.stanford.edu/
    http://ccrma.stanford.edu/groups/mcd/
 
 MoMu is distributed under the following BSD style open source license:
 
 Permission is hereby granted, free of charge, to any person obtaining a 
 copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The authors encourage users of MoMu to include this copyright notice,
 and to let us know that you are using MoMu. Any person wishing to 
 distribute modifications to the Software is encouraged to send the 
 modifications to the original authors so that they can be incorporated 
 into the canonical version.
 
 The Software is provided "as is", WITHOUT ANY WARRANTY, express or implied,
 including but not limited to the warranties of MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE and NONINFRINGEMENT.  In no event shall the authors
 or copyright holders by liable for any claim, damages, or other liability,
 whether in an actino of a contract, tort or otherwise, arising from, out of
 or in connection with the Software or the use or other dealings in the 
 software.
 -----------------------------------------------------------------------------*/
//-----------------------------------------------------------------------------
// name: mo_compass.mm
// desc: MoPhO API for compass
//
// authors: Nick Bryan
//          Jorge Herrera
//          Jieun Oh
//          Ge Wang
//
//    date: Fall 2009
//    version: 1.0.0
//
// Mobile Music research @ CCRMA, Stanford University:
//     http://momu.stanford.edu/
//-----------------------------------------------------------------------------
#include "mo_compass.h"


@implementation CompassDelegate
@synthesize locationManager;
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)heading
{
    // update the compass server data
    MoCompass::update( heading );
}

@end


// static initialization
CLHeading * MoCompass::m_heading;
double MoCompass::m_magneticHeading = 0.0;
double MoCompass::m_trueHeading = 0.0;
CLLocationDirection MoCompass::m_accuracy = 0.0;
double MoCompass::m_trueOffset = 0;
double MoCompass::m_magneticOffset = 0;
CompassDelegate * MoCompass::compassDelegate;
std::vector< MoCompassCallback > MoCompass::m_clients;
std::vector<void *> MoCompass::m_clientData;


//-----------------------------------------------------------------------------
// name: checkSetup()
// desc: idempotent one-time setup
//-----------------------------------------------------------------------------
void MoCompass::checkSetup()
{
    // no need
    if( compassDelegate != NULL )
        return;
    
    // allocate a location Delegate object
    compassDelegate = [CompassDelegate alloc];
    // sanity check
    assert( compassDelegate != NULL );
    
    compassDelegate.locationManager = [[[CLLocationManager alloc] init] autorelease];
    
    // check if the hardware has a compass
    if( compassDelegate.locationManager.headingAvailable == NO )
    {
        // No compass is available. This application cannot function without a compass, 
        // so a dialog will be displayed and no magnetic data will be measured.
        compassDelegate.locationManager = nil;
        UIAlertView *noCompassAlert = [[UIAlertView alloc] 
                                       initWithTitle:@"No Compass!" 
                                       message:@"This device does not have the ability to measure magnetic fields."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
        [noCompassAlert show];
        [noCompassAlert release];
    }
    else
    {
        // heading service configuration
        compassDelegate.locationManager.headingFilter = kCLHeadingFilterNone;
        // this is default anyway, but just to make sure
        compassDelegate.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        // setup delegate callbacks
        compassDelegate.locationManager.delegate = compassDelegate;
        // start the compass
        [compassDelegate.locationManager startUpdatingHeading];
    }
}


//-----------------------------------------------------------------------------
// name: update()
// desc: update the internal accelerometer data and process any callbacks
//-----------------------------------------------------------------------------
void MoCompass::update( CLHeading * heading )
{
    // update the current heading
    
    // Release the old heading
    [m_heading release];
    
    // Assign the current
    m_heading = heading;
    
    // Retain the current
    [m_heading retain];
    
    // Update other data members
    m_magneticHeading = [m_heading magneticHeading];
    m_trueHeading = [m_heading trueHeading];
    m_accuracy = [m_heading headingAccuracy];
    
    // process all callbacks
    for( int i=0; i < m_clients.size(); i++ )  
        (m_clients[i])( m_heading, m_clientData[i]);  
}


//-----------------------------------------------------------------------------
// name: getMagneticHeading()
// desc: gets the magnetic heading of the compass
//-----------------------------------------------------------------------------
double MoCompass::getMagneticHeading()
{
    // one-time setup, if needed
    checkSetup();
    
    return m_magneticHeading;
}


//-----------------------------------------------------------------------------
// name: getTrueHeading()
// desc: gets the true heading of the compass
//-----------------------------------------------------------------------------
double MoCompass::getTrueHeading()
{
    // one-time setup, if needed
    checkSetup();
    
    return m_trueHeading;
}


//-----------------------------------------------------------------------------
// name: getAccuracy()
// desc: gets the accuracy in degress of the current heading value
//-----------------------------------------------------------------------------
double MoCompass::getAccuracy()
{
    // one-time setup, if needed
    checkSetup();
    
    return m_accuracy;
}


//-----------------------------------------------------------------------------
// name: getTimestamp()
// desc: gets the timestamp of the current heading value
//-----------------------------------------------------------------------------
NSDate * MoCompass::getTimestamp()
{
 
	// one-time setup, if needed
    checkSetup();
	
	return [m_heading timestamp];
 
}


//-----------------------------------------------------------------------------
// name: setOffset()
// desc: stores an offset using the current magnetic heading of the compass to be used later
//-----------------------------------------------------------------------------
void MoCompass::setOffset()
{
    // one-time setup, if needed
    checkSetup();
    
    // NSLog(@"Seeing Offset\n");
    m_magneticOffset = getMagneticHeading();
    m_trueOffset = getTrueHeading();
}


//-----------------------------------------------------------------------------
// name: clearOffset()
// desc: stores an offset using the current magnetic heading of the compass to be used later
//-----------------------------------------------------------------------------
void MoCompass::clearOffset()
{
    // one-time setup, if needed
    checkSetup();
    
    m_magneticOffset = 0;
    m_trueOffset = 0;
}


//-----------------------------------------------------------------------------
// name: getMagneticOffset()
// desc: get magnet offset
//-----------------------------------------------------------------------------
double MoCompass::getMagneticOffset()
{
    // one-time setup, if needed
    checkSetup();
    
    return m_magneticOffset;
}


//-----------------------------------------------------------------------------
// name: getTrueOffset()
// desc: get true offset
//-----------------------------------------------------------------------------
double MoCompass::getTrueOffset()
{
    // one-time setup, if needed
    checkSetup();
    
    return m_trueOffset;
}


//-----------------------------------------------------------------------------
// name:  add
// desc:  registers a callback to be invoked on subsequent updates       
//-----------------------------------------------------------------------------
void  MoCompass::addCallback(const MoCompassCallback & callback, void * data )
{
    // one-time setup, if needed
    checkSetup();
    
    // NSLog(@"Adding MoCompassCallback\n");
    m_clients.push_back( callback );
    m_clientData.push_back( data );
}


//-----------------------------------------------------------------------------
// name:  add
// desc:  unregisters a callback to be invoked on subsequent updates       
//-----------------------------------------------------------------------------
void  MoCompass::removeCallback(const MoCompassCallback & callback )
{
    // one-time setup, if needed
    checkSetup();
    
    // NSLog(@"Removing MoCompassCallback\n");
    // find the callback and remove

    for( int i=0; i < m_clients.size(); i++ )
    {
        if(m_clients[i]==callback)
        {
            m_clients.erase(m_clients.begin()+i);
            m_clientData.erase(m_clientData.begin()+i);
        }
    }
    
    
}
