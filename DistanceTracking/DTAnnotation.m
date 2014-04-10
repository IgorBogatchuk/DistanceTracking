//
//  DTAnnotation.m
//  DistanceTracking
//
//  Created by Igor Bogatchuk on 4/3/14.
//  Copyright (c) 2014 Igor Bogatchuk. All rights reserved.
//

#import "DTAnnotation.h"

@implementation DTAnnotation

- (id)initWithLatitude:(CLLocationDegrees)latitude
             longitude:(CLLocationDegrees)longitude
                 title:(NSString*)title
              subtitle:(NSString*)subtitle
{
	self = [super init];
	if (self)
	{
		_latitude = latitude;
		_longitude = longitude;
		_title = title;
		_subtitle = subtitle;
	}
	return self;
}

- (CLLocationCoordinate2D)coordinate
{
	return CLLocationCoordinate2DMake(self.latitude, self.longitude);
}

@end
