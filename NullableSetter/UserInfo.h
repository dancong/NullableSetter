//
//  UserInfo.h
//  NullableSetter
//
//  Created by Dan Cong on 18/11/15.
//  Copyright © 2015 dancyd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserInfo : NSObject

@property(nonatomic, strong)NSString *url;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, assign)BOOL gender;

@end
