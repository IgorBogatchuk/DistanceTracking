//
//  DTMapViewController.m
//  DistanceTracking
//
//  Created by Igor Bogatchuk on 4/9/14.
//  Copyright (c) 2014 Igor Bogatchuk. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <objc/runtime.h>
#import "DTMapViewController.h"
#import "DTLocationManger.h"
#import "DTAnnotation.h"

static NSString* const kDTShouldLineBeTrackedKey = @"kDTShouldLineBeTrackedKey";

@interface DTMapViewController () <DTLocationManagerDelegate>

@property (nonatomic, strong) DTLocationManger* locationManager;
@property (nonatomic, strong) IBOutlet MKMapView* mapView;
@property (nonatomic, weak) IBOutlet UITextView* textView;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *signalStrengthLabel;

@property (nonatomic, assign) BOOL isTracking;
@property (nonatomic, strong) NSMutableArray* trackingPoints;
@property (nonatomic, strong) MKPolyline* trackingPolyline;
@property (nonatomic, strong) CLLocation* previousWaypoint;

@end

@implementation DTMapViewController

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureLocationManager];
    [self configureMapView];
    self.isTracking = YES;
}

- (void)configureLocationManager
{  
    self.locationManager = [DTLocationManger new];
    self.locationManager.delegate = self;
    [self.locationManager startLocationUpdates];
}

- (void)configureMapView
{
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MKUserTrackingModeFollowWithHeading;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSMutableArray*)trackingPoints
{
    if (_trackingPoints == nil)
    {
        _trackingPoints = [NSMutableArray new];
    }
    return _trackingPoints;
}

#pragma mark MapViewDelegate

- (void)mapView:(MKMapView*)mapView didUpdateUserLocation:(MKUserLocation*)userLocation
{
    [self.mapView setCenterCoordinate:userLocation.location.coordinate animated:YES];
    [self.mapView setRegion:MKCoordinateRegionMake(userLocation.location.coordinate, MKCoordinateSpanMake(0.005, 0.005)) animated:YES];
}

- (MKOverlayRenderer*)mapView:(MKMapView*)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKOverlayRenderer* result = nil;
    if ([overlay isKindOfClass:[MKPolyline class]])
    {
        MKPolylineRenderer* renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        
        NSDictionary* userInfo = objc_getAssociatedObject(overlay, "userInfo");
        if ([userInfo[kDTShouldLineBeTrackedKey] boolValue] != NO)
        {
            renderer.alpha = 0.8;
        }
        else
        {
            renderer.alpha = 0.3;
        }
        renderer.strokeColor = [UIColor blueColor];
        renderer.lineWidth = 5;
        result = renderer;
    }
    return result;
}

- (void)mapView:(MKMapView*)mapView didSelectAnnotationView:(MKAnnotationView*)view
{
    CLLocation* location = objc_getAssociatedObject(view.annotation, "location");
    self.textView.text = [self.textView.text stringByAppendingString:location.description != nil ? location.description : @"\nERROR: nil description"];
    [self scrollTextViewToBottom:self.textView];
}

#pragma mark - DTLocationManagerDelegate

- (void)locationManager:(DTLocationManger*)locationManager didUpdateTotalDistance:(CLLocationDistance)distance
{
    [self.distanceLabel setText:[NSString stringWithFormat:@"%f",distance]];
}

- (void)locationManager:(DTLocationManger*)locationManager didGetWaypoint:(CLLocation*)waypoint shouldBeTracked:(BOOL)shouldBeTracked
{    
    if (self.locationManager.previousLocation != nil)
    {
        if (shouldBeTracked == self.isTracking)
        {
            [self.trackingPoints addObject:waypoint];
        }
        else
        {
            self.isTracking = shouldBeTracked;
            [self.mapView addOverlay:self.trackingPolyline];
            self.trackingPolyline = nil;
            [self.trackingPoints removeAllObjects];
            [self.trackingPoints addObject:self.locationManager.previousLocation];
            [self.trackingPoints addObject:waypoint];
        }
        
        MKPolyline* polyLine = [self polyLineForPoints:self.trackingPoints userInfo:@{kDTShouldLineBeTrackedKey : @(shouldBeTracked)}];
        if (polyLine != nil)
        {
            [self.mapView removeOverlay:self.trackingPolyline];
            [self.mapView addOverlay:polyLine];
            self.trackingPolyline = polyLine;
        }
    
        DTAnnotation* annotation = [[DTAnnotation alloc] initWithLatitude:waypoint.coordinate.latitude longitude:waypoint.coordinate.longitude title:@"" subtitle:@""];
        objc_setAssociatedObject(annotation, "location", waypoint, OBJC_ASSOCIATION_RETAIN);
        [self.mapView addAnnotation:annotation];
    }
    
    self.previousWaypoint = waypoint;
}

- (void)locationManager:(DTLocationManger*)locationManager didUpdateSignalStrength:(DTLocationMangerGPSSignalStrength)signalStrength
{
    NSString* resultString;
    switch (signalStrength)
    {
        case DTLocationMangerGPSSignalStrengthInvalid:
            resultString = @"no signal";
            break;
        case DTLocationMangerGPSSignalStrengthWeak:
            resultString = @"weak";
            break;
        case DTLocationMangerGPSSignalStrengthMedium:
            resultString = @"medium";
            break;
        case DTLocationMangerGPSSignalStrengthStrong:
            resultString = @"strong";
            break;
        default:
            resultString = @"no signal";
            break;
    }
    self.signalStrengthLabel.text = resultString;
}

#pragma mark -

- (MKPolyline*)polyLineForPoints:(NSArray*)points userInfo:(NSDictionary*)userInfo
{
    MKPolyline* polyline = [self polyLineForPoints:points];
    objc_setAssociatedObject(polyline, "userInfo", userInfo, OBJC_ASSOCIATION_RETAIN);
    return polyline;
}

- (MKPolyline*)polyLineForPoints:(NSArray*)points
{
    NSUInteger i = 0;
    CLLocationCoordinate2D *coordinates = malloc(sizeof(CLLocationCoordinate2D) * [points count]);
    for (CLLocation* point in points)
    {
        coordinates[i++] = point.coordinate;
    }
    MKPolyline* polyline = [MKPolyline polylineWithCoordinates:coordinates count:[points count]];
    free(coordinates);
    
    return polyline;
}

#pragma mark -

- (void)scrollTextViewToBottom:(UITextView*)textView
{
    [textView scrollRangeToVisible:NSMakeRange([textView.text length], 0)];
    [textView setScrollEnabled:NO];
    [textView setScrollEnabled:YES];
}

@end
