//
//  UserInfo.h
//  NullableSetter
//
//  Created by Dan Cong on 18/11/15.
//  Copyright © 2015 dancyd. All rights reserved.
//

#import <Foundation/Foundation.h>

enum Gender {
    Male,
    Female,
    Other,
};

@interface UserInfo : NSObject

@property(nonatomic, strong)NSString *address;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, strong)NSDictionary *extDic;
@property(nonatomic, assign)enum Gender gender;
@property(nonatomic, assign)BOOL married;
@property(nonatomic, assign)short age;
@property(nonatomic, assign)float weight;
@property(nonatomic, assign)double height;
@property(nonatomic, assign)long mobile;
@property(nonatomic, assign)int card;

@end
