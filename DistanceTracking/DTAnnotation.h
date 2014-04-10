//
//  DTAnnotation.h
//  DistanceTracking
//
//  Created by Igor Bogatchuk on 4/3/14.
//  Copyright (c) 2014 Igor Bogatchuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface DTAnnotation : NSObject  <MKAnnotation>

@property (nonatomic, assign, readonly) CLLocationDegrees latitude;
@property (nonatomic, assign, readonly) CLLocationDegrees longitude;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* subtitle;

- (id)initWithLatitude:(CLLocationDegrees)latitude
             longitude:(CLLocationDegrees)longitude
                 title:(NSString*)title
              subtitle:(NSString*)subtitle;
@end
