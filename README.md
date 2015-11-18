# NullableSetter
NullableSetter is a NSObject category protecting properties can't be set null

Inspired by FLCodeInjector: https://github.com/lombax85/FLCodeInjector, this NSObject category auto-generate setter for all encode types of properties, add non-null validation for id type argument.

usage:


    #import "NSObject+NullableSetter.h"
    
    UserInfo *info = [UserInfo new];
    
    info.name = @"1";
    info.url = @"a";
    
    NSLog(@"name = %@, url = %@, gender = %d", info.name, info.url, info.gender);
    
    [info protectNullableSetters];
    
    info.name = nil;
    info.url = @"b";
    info.gender = YES;
    NSLog(@"name = %@, url = %@ gender = %d", info.name, info.url, info.gender);
    

print:

2015-11-18 15:06:28.799 NullableSetter[26333:2580472] name = 1, url = a, gender = 0

2015-11-18 15:06:28.800 NullableSetter[26333:2580472] name = 1, url = b gender = 1

