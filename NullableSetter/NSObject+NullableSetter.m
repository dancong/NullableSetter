//
//  NSObject.m
//  NullableSetter
//
//  Created by Dan Cong on 18/11/15.
//  Copyright © 2015 dancyd. All rights reserved.
//

#import "NSObject+NullableSetter.h"

#import <UIKit/UIKit.h>

#import <objc/runtime.h>
#import <objc/message.h>

#define NULLABLE_PREFIX @"nullable_"


typedef long long long_long;
typedef unsigned char unsigned_char;
typedef unsigned int unsigned_int;
typedef unsigned short unsigned_short;
typedef unsigned long unsigned_long;
typedef unsigned long long unsigned_long_long;
typedef  char * char_x;


#define else_if_getReturnValue_for_type(type, returnType)  \
else if (strcmp(@encode( type ), returnType) == 0)         \
{                                                          \
    if (sizeOfReturnValue != 0)                            \
    {                                                      \
        type *value = malloc(sizeOfReturnValue);           \
        [invocation getReturnValue:value];                 \
        finalValue = value;                                \
    }                                                      \
}                                                          \

//promoteType is used for the second argument of va_arg
//because char, short, unsigned char, unsigned short, bool, _Bool will be promoted to int type.
#define else_if_setArgument_for_promoteType(type, promoteType, charType, invocation, arguments, idx)    \
else if (strcmp(@encode( type ), charType) == 0)                                                        \
{                                                                                                       \
    promoteType value = va_arg(arguments, promoteType);                                                 \
    [invocation setArgument:&value atIndex:idx];                                                        \
}                                                                                                       \

#define else_if_setArgument_for_type(type, charType, invocation, arguments, idx)                 \
else if (strcmp(@encode( type ), charType) == 0)                                                 \
{                                                                                                \
type value = va_arg(arguments, type);                                                            \
[invocation setArgument:&value atIndex:idx];                                                     \
}                                                                                                \

/**
 This function forward the original invocation, then returns a generic pointer
 to the return value (that can be of any type)
 */
void * getReturnValue(id self, SEL cmd, va_list argumentsToCopy) {
    
    if (!self || !NSStringFromSelector(cmd))
        return nil;
    
    // Copy the variable argument list into another va_list
    // Why? read this: http://julipedia.meroh.net/2011/09/using-vacopy-to-safely-pass-ap.html
    va_list arguments;
    va_copy(arguments, argumentsToCopy);
    
    // Obtain the method signature and the relative number of arguments of the selector
    NSMethodSignature *signature = [self methodSignatureForSelector:cmd];
    NSUInteger numberOfArguments = [signature numberOfArguments];
    
    // Prepare the invocation with variable number of arguments
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    
    // Set the target of the invocation
    [invocation setTarget:self];
    
    // Set the selector. Since the swizzling is enabled, the original selector has prefix
    NSString *swizzleSelector = [NSString stringWithFormat:@"%@%@", NULLABLE_PREFIX, NSStringFromSelector(cmd)];
    SEL selectorToExecute = NSSelectorFromString(swizzleSelector);
    [invocation setSelector:selectorToExecute];
    
    // Get the return value size for later use
    NSUInteger sizeOfReturnValue = [signature methodReturnLength];
    
    
    
    // Now we start a loop through all arguments, to add them to the invocation
    // We use numberOfArguments-2 because of the first two arguments (self and cmd) are the
    // hidden arguments, and are not present in the va_list
    for ( int x = 0; x < numberOfArguments - 2; x++ )
    {
        
        // Set the index for cleaner code
        int idx = x+2;
        
        // The type of the argument at this index
        const char *type = [signature getArgumentTypeAtIndex:idx];
        
#pragma mark - setArgument
        
        // An if-elseif to find the correct argument type
        // Extendend comments only in the first two cases
        if (strcmp(@encode(id), type) == 0) {
            
            // The argument is an object
            // We obtain a pointer to the argument through va_arg, the second parameter is the lenght of the argument
            // va_arg return the pointer and then move it's pointer to the next item
            id argument = va_arg(arguments, id);
            
            
            //check if nil, don't invoke
            if (!argument) {
                return nil;
            }
            
            // Set the argument. The method wants a pointer to the pointer
            [invocation setArgument:&argument atIndex:idx];
        }
        else_if_setArgument_for_promoteType(char, int, type, invocation, arguments, idx)
        else_if_setArgument_for_type(int, type, invocation, arguments, idx)
        else_if_setArgument_for_promoteType(short, int, type, invocation, arguments, idx)
        else_if_setArgument_for_type(long, type, invocation, arguments, idx)
        else_if_setArgument_for_type(long_long, type, invocation, arguments, idx)
        else_if_setArgument_for_promoteType(unsigned_char, int, type, invocation, arguments, idx)
        else_if_setArgument_for_type(unsigned_int, type, invocation, arguments, idx)
        else_if_setArgument_for_promoteType(unsigned_short, int, type, invocation, arguments, idx)
        else_if_setArgument_for_type(unsigned_long, type, invocation, arguments, idx)
        else_if_setArgument_for_type(unsigned_long_long, type, invocation, arguments, idx)
        else_if_setArgument_for_promoteType(float, double, type, invocation, arguments, idx)
        else_if_setArgument_for_type(double, type, invocation, arguments, idx)
        else_if_setArgument_for_promoteType(bool, int, type, invocation, arguments, idx)
        else_if_setArgument_for_promoteType(_Bool, int, type, invocation, arguments, idx)
        else_if_setArgument_for_type(char_x, type, invocation, arguments, idx)
        else_if_setArgument_for_type(SEL, type, invocation, arguments, idx)
        else_if_setArgument_for_type(CGRect, type, invocation, arguments, idx)
        else
        {
            // the argument is char, short, unsigned char, unsigned short, bool, _Bool or others, will promote to int
            int anInt = va_arg(arguments, int);
            [invocation setArgument:&anInt atIndex:idx];
        }
    }
    
    // Invoke the invocation
    [invocation invoke];
    
    // End the variable arguments
    va_end ( arguments );
    
    // Now we get the expected method return type...
    const char *returnType = [signature methodReturnType];
    
    // ... and prepare a generic void pointer to store the pointer to the final value
    void *finalValue = nil;
    
#pragma mark - getReturnValue
    
    // Again, we must use different code depending on the return type
    if (strcmp(@encode(id), returnType) == 0) {
        // the return value is an object
        if (sizeOfReturnValue != 0)
        {
            // Create a new pointer to object
            id anObject;
            
            // Put the return value (that is a pointer to object) at the memory address indicated: the pointer to the anObject pointer.
            [invocation getReturnValue:&anObject];
            
            // return a generic void * pointer to anObject. We are returing a pointer to a pointer:
            // finalValue points to anObject that points to the real object on the heap
            finalValue = (__bridge void *)anObject;
        }
    }
    else_if_getReturnValue_for_type(char, returnType)
    else_if_getReturnValue_for_type(int, returnType)
    else_if_getReturnValue_for_type(short, returnType)
    else_if_getReturnValue_for_type(long, returnType)
    else_if_getReturnValue_for_type(long_long, returnType)
    else_if_getReturnValue_for_type(unsigned_char, returnType)
    else_if_getReturnValue_for_type(unsigned_int, returnType)
    else_if_getReturnValue_for_type(unsigned_short, returnType)
    else_if_getReturnValue_for_type(unsigned_long, returnType)
    else_if_getReturnValue_for_type(unsigned_long_long, returnType)
    else_if_getReturnValue_for_type(float, returnType)
    else_if_getReturnValue_for_type(double, returnType)
    else_if_getReturnValue_for_type(bool, returnType)
    else_if_getReturnValue_for_type(_Bool, returnType)
    else_if_getReturnValue_for_type(char_x, returnType)
    else_if_getReturnValue_for_type(SEL, returnType)
    else_if_getReturnValue_for_type(CGRect, returnType)
    else
    {
        // the return value is something different
        if (sizeOfReturnValue != 0)
        {
            int *anInt = malloc(sizeOfReturnValue);
            [invocation getReturnValue:anInt];
            finalValue = anInt;
        }
    }
    
    
    return finalValue;
}


#define GENERIC_FUNCTION_NAME_FOR_TYPE(type)  type##GenericFunction

#define GENERIC_FUNCTION_FOR_TYPE(type)                                 \
    type type##GenericFunction(id self, SEL cmd, ...) {                 \
    va_list arguments, copiedArguments;                                 \
    va_start ( arguments, cmd );                                        \
    va_copy(copiedArguments, arguments);                                \
    va_end(arguments);                                                  \
    void * returnValue = getReturnValue(self, cmd, copiedArguments);    \
    type returnedType = *(type *)returnValue;                           \
    return returnedType;                                                \
}                                                                       \

static void nullable_swizzleInstanceMethod(Class c, SEL orig, SEL swizzle)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, swizzle);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, swizzle, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
}

@implementation NSObject (NullableSetter)

- (void)protectNullableSetters;
{
    @synchronized(self) {
        [self enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
            NSString *propName = @(property_getName(property));
            [self generateNonNullSetterWithPropName:propName];
        }];
    }
}

- (void)protectNullableSettersWithPropNames:(NSArray *)propNames
{
    @synchronized(self) {
        for (NSString *propName in propNames) {
            [self generateNonNullSetterWithPropName:propName];
        }
    }
}

- (void)generateNonNullSetterWithPropName:(NSString *)propName
{
    SEL customSetterName = NSSelectorFromString([self customSetterName:propName]);
    SEL origSetterName = NSSelectorFromString([self origSetterName:propName]);
    
    Method origMethod = class_getInstanceMethod(self.class, origSetterName);
    const char *encoding = method_getTypeEncoding(origMethod);
    
    if (![self respondsToSelector:customSetterName]) {
        [self addSelector:customSetterName toClass:self.class originalSelector:origSetterName methodTypeEncoding:encoding];
        
        nullable_swizzleInstanceMethod(self.class, origSetterName, customSetterName);
    }
}

- (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block {
    Class cls = [self class];
    BOOL stop = NO;
    
    while (!stop && ![cls isEqual:NSObject.class]) {
        unsigned count = 0;
        objc_property_t *properties = class_copyPropertyList(cls, &count);
        
        cls = cls.superclass;
        if (properties == NULL) continue;
        
        for (unsigned i = 0; i < count; i++) {
            block(properties[i], &stop);
            if (stop) break;
        }
        free(properties);
    }
}


- (NSString*)origSetterName:(NSString*)name
{
    name = [self propName:name];
    
    NSRange r;
    r.length = name.length -1 ;
    r.location = 1;
    
    NSString* firstChar = [name stringByReplacingCharactersInRange:r withString:@""];
    
    r.length = 1;
    r.location = 0;
    
    NSString* theRest = [name stringByReplacingCharactersInRange:r withString:@""];
    
    return [NSString stringWithFormat:@"set%@%@:", [firstChar uppercaseString] , theRest];
}

- (NSString*)customSetterName:(NSString*)name
{
    name = [self propName:name];
    
    NSRange r;
    r.length = name.length -1 ;
    r.location = 1;
    
    NSString* firstChar = [name stringByReplacingCharactersInRange:r withString:@""];
    
    r.length = 1;
    r.location = 0;
    
    NSString* theRest = [name stringByReplacingCharactersInRange:r withString:@""];
    
    return [NSString stringWithFormat:@"%@set%@%@:", NULLABLE_PREFIX, [firstChar uppercaseString] , theRest];
}

- (NSString*)propName:(NSString*)name
{
    name = [name stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    NSRange r;
    r.length = name.length -1 ;
    r.location = 1;
    
    NSString* firstChar = [name stringByReplacingCharactersInRange:r withString:@""];
    
    if([firstChar isEqualToString:[firstChar lowercaseString]])
    {
        return name;
    }
    
    r.length = 1;
    r.location = 0;
    
    NSString* theRest = [name stringByReplacingCharactersInRange:r withString:@""];
    
    return [NSString stringWithFormat:@"%@%@", [firstChar lowercaseString] , theRest];
    
}

#pragma mark - AddMethod

GENERIC_FUNCTION_FOR_TYPE(char)
GENERIC_FUNCTION_FOR_TYPE(int)
GENERIC_FUNCTION_FOR_TYPE(short)
GENERIC_FUNCTION_FOR_TYPE(long)
GENERIC_FUNCTION_FOR_TYPE(long_long)
GENERIC_FUNCTION_FOR_TYPE(unsigned_char)
GENERIC_FUNCTION_FOR_TYPE(unsigned_int)
GENERIC_FUNCTION_FOR_TYPE(unsigned_short)
GENERIC_FUNCTION_FOR_TYPE(unsigned_long)
GENERIC_FUNCTION_FOR_TYPE(unsigned_long_long)
GENERIC_FUNCTION_FOR_TYPE(float)
GENERIC_FUNCTION_FOR_TYPE(double)
GENERIC_FUNCTION_FOR_TYPE(bool)
GENERIC_FUNCTION_FOR_TYPE(_Bool)
GENERIC_FUNCTION_FOR_TYPE(char_x)
GENERIC_FUNCTION_FOR_TYPE(SEL)
GENERIC_FUNCTION_FOR_TYPE(CGRect)

#define IMPKey(type) @(@encode( type ))
#define IMPValue(type) [NSValue valueWithPointer:GENERIC_FUNCTION_NAME_FOR_TYPE( type )]
#define IMPKeyValue(type) IMPKey( type ):IMPValue( type )


-(void)addSelector:(SEL)selector
           toClass:(Class)aClass
  originalSelector:(SEL)originalSel
methodTypeEncoding:(const char *)encoding
{
    NSDictionary *imps = @{
                           IMPKeyValue(char),
                           IMPKeyValue(int),
                           IMPKeyValue(short),
                           IMPKeyValue(long),
                           IMPKeyValue(long_long),
                           IMPKeyValue(unsigned_char),
                           IMPKeyValue(unsigned_int),
                           IMPKeyValue(unsigned_short),
                           IMPKeyValue(unsigned_long),
                           IMPKeyValue(unsigned_long_long),
                           IMPKeyValue(float),
                           IMPKeyValue(double),
                           IMPKeyValue(bool),
                           IMPKeyValue(_Bool),
                           IMPKeyValue(char_x),
                           IMPKey(Class)        :[NSValue valueWithPointer:classGenericFunction],
                           IMPKeyValue(SEL),
                           IMPKeyValue(CGRect),
                           IMPKey(void)         :[NSValue valueWithPointer:voidGenericFunction],
                           IMPKey(id)           :[NSValue valueWithPointer:objectGenericFunction],
                           };

    
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:encoding];
    const char *type = [signature methodReturnType];
    
    IMP implementation = (IMP)intGenericFunction;
    
    NSValue *impValue = imps[@(type)];
    
    if (impValue) {
        implementation = (IMP)[impValue pointerValue];
    }

    class_addMethod(aClass,
                    selector,
                    implementation, encoding);
}

void voidGenericFunction(id self, SEL cmd, ...) {
    
    va_list arguments;
    va_start ( arguments, cmd );
    getReturnValue(self, cmd, arguments);
    va_end(arguments);
}

id objectGenericFunction(id self, SEL cmd, ...) {
    
    va_list arguments;
    va_start ( arguments, cmd );
    void * returnValue = getReturnValue(self, cmd, arguments);
    va_end(arguments);
    
    // Since the returnedValue is a pointer itself, we need only to bridge cast it
    id returnedObject = (__bridge id)returnValue;
    
    return returnedObject;
}

Class * classGenericFunction(id self, SEL cmd, ...) {
    
    va_list arguments;
    va_start ( arguments, cmd );
    void * returnValue = getReturnValue(self, cmd, arguments);
    va_end(arguments);
    
    // Since the returnedValue is a pointer itself, we need only to bridge cast it
    Class * returnedObject = (Class *)returnValue;
    
    return returnedObject;
}


@end
