//
//  DTLocationManger.m
//  DistanceTracking
//
//  Created by Igor Bogatchuk on 4/9/14.
//  Copyright (c) 2014 Igor Bogatchuk. All rights reserved.
//

#import "DTLocationManger.h"

static const NSInteger kDTWalkingSpeedThreshold = 12.5;            // walking speed threshold, m/s
static const NSInteger kDTDistanceFilter = 5;

static const NSInteger kDTDeferredLocationUpdatesTimeOut = 20;
static const NSInteger kDTDeferredLocationUpdatesTraveledDistance = 20;

static const NSInteger kDTSignalAccuracyStrong = 20;
static const NSInteger kDTSignalAccuracyMedium = 50;
static const NSInteger kDTSignalAccuracyWeak = 90;

@interface DTLocationManger() <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, assign) BOOL isDefferingUpdates;

@end

@implementation DTLocationManger

- (id)init
{
    if ((self = [super init]))
    {
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.activityType = CLActivityTypeFitness;
        self.locationManager.pausesLocationUpdatesAutomatically = YES;
        self.locationManager.distanceFilter = [CLLocationManager deferredLocationUpdatesAvailable] ? kCLDistanceFilterNone : kDTDistanceFilter;

        self.totalDistance = 0;
        self.signalStrength = DTLocationMangerGPSSignalStrengthInvalid;
    }
    
    return self;
}

- (void)setTotalDistance:(CLLocationDistance)totalDistance
{
    _totalDistance = totalDistance;
    
    if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateTotalDistance:)])
    {
        [self.delegate locationManager:self didUpdateTotalDistance:self.totalDistance];
    }
}

- (void)setSignalStrength:(DTLocationMangerGPSSignalStrength)signalStrength
{
    _signalStrength = signalStrength;
    
    if ([self.delegate respondsToSelector:@selector(locationManager:didUpdateSignalStrength:)])
    {
        [self.delegate locationManager:self didUpdateSignalStrength:signalStrength];
    }
}

#pragma mark - public

+ (CLAuthorizationStatus)authorizationStatus
{
    return [CLLocationManager authorizationStatus];
}

- (BOOL)startLocationUpdates
{
    self.totalDistance = 0;
    self.previousLocation = nil;
    self.isDefferingUpdates = NO;
    self.signalStrength = DTLocationMangerGPSSignalStrengthInvalid;
    
    return [self startUpdatingLocation];
}

- (void)stopLocationUpdates
{
    [self.locationManager stopUpdatingLocation];
}

- (void)pauseLocationUpdates
{
    [self.locationManager stopUpdatingLocation];
    self.signalStrength = DTLocationMangerGPSSignalStrengthInvalid;
}

- (BOOL)resumeLocationUpdates
{
    return [self startUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations
{
    CLLocation* currentLocation = [locations lastObject];
    self.signalStrength = [self signalStrengthForLocation:currentLocation];
    
    if (self.previousLocation != nil)
    {
        if ([currentLocation horizontalAccuracy] >= 0 && [currentLocation horizontalAccuracy] <= kDTSignalAccuracyMedium)
        {
            CLLocationDistance distance = 0;
            CGFloat speed = 0;
            
            distance = [currentLocation distanceFromLocation:self.previousLocation];
            NSTimeInterval time = [currentLocation.timestamp timeIntervalSinceDate:self.previousLocation.timestamp];
            speed = distance / time;
            if (speed < kDTWalkingSpeedThreshold)
            {
                [self.delegate locationManager:self didGetWaypoint:currentLocation shouldBeTracked:YES];
                self.totalDistance += distance;
            }
            else
            {
                [self.delegate locationManager:self didGetWaypoint:currentLocation shouldBeTracked:NO];
            }
        }
    }
    
    self.previousLocation = currentLocation;
    
    if ([CLLocationManager deferredLocationUpdatesAvailable])
    {
        if (!self.isDefferingUpdates)
        {
            [self.locationManager allowDeferredLocationUpdatesUntilTraveled:kDTDeferredLocationUpdatesTraveledDistance timeout:kDTDeferredLocationUpdatesTimeOut];
            self.isDefferingUpdates = YES;
        }

    }
}

- (void)locationManager:(CLLocationManager*)manager didFinishDeferredUpdatesWithError:(NSError*)error
{
    self.isDefferingUpdates = NO;
}

- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [self startUpdatingLocation];
}

#pragma mark -

- (DTLocationMangerGPSSignalStrength)signalStrengthForLocation:(CLLocation*)location
{
    DTLocationMangerGPSSignalStrength result = DTLocationMangerGPSSignalStrengthInvalid;
    
    if ([location horizontalAccuracy] >= 0 && [location horizontalAccuracy] <= kDTSignalAccuracyStrong)
    {
        result = DTLocationMangerGPSSignalStrengthStrong;
    }
    else if ([location horizontalAccuracy] > kDTSignalAccuracyStrong && [location horizontalAccuracy] <= kDTSignalAccuracyMedium)
    {
        result = DTLocationMangerGPSSignalStrengthMedium;
    }
    else if ([location horizontalAccuracy] > kDTSignalAccuracyMedium && [location horizontalAccuracy] <= kDTSignalAccuracyWeak)
    {
        result = DTLocationMangerGPSSignalStrengthWeak;
    }
    return result;
}

- (BOOL)startUpdatingLocation
{
    BOOL result = NO;
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
    {
        [self.locationManager startUpdatingLocation];
        result = YES;
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"LocationServicesRestricted", @"") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied && [CLLocationManager locationServicesEnabled] == YES)
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"LocationServicesDenied", @"") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
    }
    return result;
}

@end
