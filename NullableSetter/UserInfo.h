//
//  UserInfo.h
//  NullableSetter
//
//  Created by Dan Cong on 18/11/15.
//  Copyright © 2015 dancyd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

enum Gender {
    Male,
    Female,
    Other,
};

typedef void(^aBlock)(void);




@interface UserInfo : NSObject

//objects
@property(nonatomic, strong)NSString *address;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, strong)NSDictionary *extDic;
@property(nonatomic, strong)NSArray *extArr;

//primitives
@property(nonatomic, assign)enum Gender gender;
@property(nonatomic, assign)BOOL married;
@property(nonatomic, assign)short age;
@property(nonatomic, assign)float weight;
@property(nonatomic, assign)double height;
@property(nonatomic, assign)long mobile;
@property(nonatomic, assign)int card;

//struct
@property(nonatomic, assign)CGRect rect;
@property(nonatomic, assign)CGPoint point;

//famous primitives
@property(nonatomic, assign)NSInteger integerCard;
@property(nonatomic, assign)NSUInteger uintegerCard;

//block
@property(nonatomic, assign)aBlock aBlock;

@end
