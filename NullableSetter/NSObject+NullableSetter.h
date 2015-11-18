//
//  NSObject.h
//  NullableSetter
//
//  Created by Dan Cong on 18/11/15.
//  Copyright © 2015 dancyd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (NullableSetter)

//auto-generate custom non-null setters protecting properties not be null
- (void)protectNullableSetters;

//with given property name list
- (void)protectNullableSettersWithPropNames:(NSArray *)propNames;

@end
