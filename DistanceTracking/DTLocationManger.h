//
//  DTLocationManger.h
//  DistanceTracking
//
//  Created by Igor Bogatchuk on 4/9/14.
//  Copyright (c) 2014 Igor Bogatchuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class DTLocationManger;

typedef enum
{
    DTLocationMangerGPSSignalStrengthInvalid = 0,
    DTLocationMangerGPSSignalStrengthWeak,
    DTLocationMangerGPSSignalStrengthMedium,
    DTLocationMangerGPSSignalStrengthStrong
} DTLocationMangerGPSSignalStrength;

@protocol DTLocationManagerDelegate <NSObject>

@optional
- (void)locationManager:(DTLocationManger*)locationManager didUpdateTotalDistance:(CLLocationDistance)distance;
- (void)locationManager:(DTLocationManger*)locationManager didUpdateSignalStrength:(DTLocationMangerGPSSignalStrength)signalStrength;
- (void)locationManager:(DTLocationManger*)locationManager didGetWaypoint:(CLLocation*)waypoint shouldBeTracked:(BOOL)shouldBeTracked;

@end

@interface DTLocationManger : NSObject

@property (nonatomic, weak) id<DTLocationManagerDelegate> delegate;
@property (nonatomic, assign) CLLocationDistance totalDistance;
@property (nonatomic, strong) CLLocation* previousLocation;
@property (nonatomic, assign) DTLocationMangerGPSSignalStrength signalStrength;

+ (CLAuthorizationStatus)authorizationStatus;

- (BOOL)startLocationUpdates;
- (void)stopLocationUpdates;
- (void)pauseLocationUpdates;
- (BOOL)resumeLocationUpdates;

@end
