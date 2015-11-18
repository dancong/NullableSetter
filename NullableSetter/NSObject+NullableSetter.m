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

#define GENERIC_FUNCTION_FOR_TYPE(__type__)                       \
__type__ __type__##GenericFunction(id self, SEL cmd, ...) {         \
    va_list arguments, copiedArguments;                         \
    va_start ( arguments, cmd );                                \
    va_copy(copiedArguments, arguments);                        \
    va_end(arguments);                                          \
    void * returnValue = getReturnValue(self, cmd, copiedArguments);  \
    __type__ returnedInt = *(__type__ *)returnValue;                \
    return returnValue;                                         \
}                                                               \

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
    //auto-generate custom non-null setters protecting properties not be null
    @synchronized(self) {
        [self enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
            NSString *propName = @(property_getName(property));
            
            SEL customSetterName = NSSelectorFromString([self customSetterName:propName]);
            SEL origSetterName = NSSelectorFromString([self origSetterName:propName]);
            
            Method origMethod = class_getInstanceMethod(self.class, origSetterName);
            const char *encoding = method_getTypeEncoding(origMethod);
            

            [self addSelector:customSetterName toClass:self.class originalSelector:origSetterName methodTypeEncoding:encoding];
            
            nullable_swizzleInstanceMethod(self.class, origSetterName, customSetterName);
        }];
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

-(void)addSelector:(SEL)selector
           toClass:(Class)aClass
  originalSelector:(SEL)originalSel
methodTypeEncoding:(const char *)encoding
{
    
    //NSMethodSignature *signature = [aClass methodSignatureForSelector:originalSel];
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:encoding];
    const char *type = [signature methodReturnType];
    IMP implementation = (IMP)objectGenericFunction;
    
    
    if (strcmp(@encode(id), type) == 0) {
        // the argument is an object
        implementation = (IMP)objectGenericFunction;
    }
    else if (strcmp(@encode(int), type) == 0)
    {
        // the argument is an int
        implementation = (IMP)intGenericFunction;
    }
    else if (strcmp(@encode(long), type) == 0)
    {
        // the argument is a long
        implementation = (IMP)longGenericFunction;
        
    }
    else if (strcmp(@encode(double), type) == 0)
    {
        // the argument is double
        implementation = (IMP)doubleGenericFunction;
    }
    else if (strcmp(@encode(float), type) == 0)
    {
        // the argument is float
        implementation = (IMP)floatGenericFunction;
    }
    else if (strcmp(@encode(void), type) == 0)
    {
        // the argument is void
        implementation = (IMP)voidGenericFunction;
    }
    else
    {
        // the argument is char or others
        implementation = (IMP)intGenericFunction;
    }
    
    
    class_addMethod(aClass,
                    selector,
                    implementation, encoding);
}

float floatGenericFunction(id self, SEL cmd, ...) {
    
    // Pass self, cmd and the arg list to the main function: getReturnValue
    // This function forward the invocation with all arguments, then
    // returns a generic pointer: it could be a pointer to an integer, to an object, to anything
    // The important thing is that it's ALWAYS a pointer, but this function must return
    // a pointer only in the object case. In other case, we need to access to the pointed value
    va_list arguments;
    va_start ( arguments, cmd );
    void * returnValue = getReturnValue(self, cmd, arguments);
    va_end(arguments);
    
    
    // Find the pointed float value and return it
    float returnedFloat = *(float *)returnValue;
    
    // free the memory allocated from previous function (not needed in object)
    free(returnValue);
    
    return returnedFloat;
}

int intGenericFunction(id self, SEL cmd, ...) {
    
    va_list arguments;
    va_start ( arguments, cmd );
    void * returnValue = getReturnValue(self, cmd, arguments);
    va_end(arguments);
    
    int returnedInt = *(int *)returnValue;
    
    // free the memory allocated from previous function (not needed in object)
    free(returnValue);
    
    return returnedInt;
}

void voidGenericFunction(id self, SEL cmd, ...) {
    

    va_list arguments;
    va_start ( arguments, cmd );
    getReturnValue(self, cmd, arguments);
    va_end(arguments);
    
}

double doubleGenericFunction(id self, SEL cmd, ...) {
    

    va_list arguments;
    va_start ( arguments, cmd );
    void * returnValue = getReturnValue(self, cmd, arguments);
    va_end(arguments);
    
    double returnedDouble = *(double *)returnValue;
    
    // free the memory allocated from previous function (not needed in object)
    free(returnValue);
    
    return returnedDouble;
}

long longGenericFunction(id self, SEL cmd, ...) {
    
    va_list arguments;
    va_start ( arguments, cmd );
    void * returnValue = getReturnValue(self, cmd, arguments);
    va_end(arguments);
    
    double returnedLong = *(long *)returnValue;
    
    // free the memory allocated from previous function (not needed in object)
    free(returnValue);
    
    return returnedLong;
}

CGRect rectGenericFunction(id self, SEL cmd, ...) {
    
    va_list arguments;
    va_start ( arguments, cmd );
    void * returnValue = getReturnValue(self, cmd, arguments);
    va_end(arguments);
    
    CGRect returnedRect = *(CGRect *)returnValue;
    
    // free the memory allocated from previous function (not needed in object)
    free(returnValue);
    
    return returnedRect;
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
        
#pragma mark - Second Switch
#pragma mark -
        
        
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
        else if (strcmp(@encode(int), type) == 0)
        {
            // the argument is an int
            int anInt = va_arg(arguments, int);
            [invocation setArgument:&anInt atIndex:idx];
        }
        else if (strcmp(@encode(long), type) == 0)
        {
            // the argument is a long
            long aLong = va_arg(arguments, long);
            [invocation setArgument:&aLong atIndex:idx];
        }
        else if ((strcmp(@encode(double), type) == 0) || (strcmp(@encode(float), type) == 0))
        {
            // the argument is float or double
            double aDouble = va_arg(arguments, double);
            [invocation setArgument:&aDouble atIndex:idx];
        }
        else if ((strcmp(@encode(CGRect), type) == 0))
        {
            // the argument is CGRect
            CGRect aRect = va_arg(arguments, CGRect);
            [invocation setArgument:&aRect atIndex:idx];
        }
        else
        {
            // the argument is char or others
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
    
#pragma mark - Third Switch
#pragma mark -
    
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
    else if (strcmp(@encode(int), returnType) == 0)
    {
        // the return value is an int
        if (sizeOfReturnValue != 0)
        {
            // If I pass a pointer to a stack allocated variable to the upper function (up-stack)
            // I have undefined behavior, since the stack allocated variable becomes garbage when the
            // function ends. Instead, I use malloc to put the variable on the heap.
            // I need to free it in the upper function
            // Moreover, another thinkg: I pass anInt (and not &anInt) to getReturnValue because
            // when working with primitive types on the heap, the syntax is different:
            // *anInt = 10; -> put 10 in the heap address pointed by anInt
            // so, because getReturnValue wants the memory address where put the int, I simply pass anInt.
            // With objects the story is different. When I do for example: NSString *string; I don't have yet
            // the memory address (string points to nil), when I do [[NSString alloc] init] I change the value of string
            // pointer. Then, to fill that memory address, I have to pass &string.
            int *anInt = malloc(sizeOfReturnValue);
            [invocation getReturnValue:anInt];
            
            // in this case, we are returnig a generic pointer that points to an int
            finalValue = anInt;
        }
        
    }
    else if (strcmp(@encode(long), returnType) == 0)
    {
        // the return value is a long
        if (sizeOfReturnValue != 0)
        {
            long *aLong = malloc(sizeOfReturnValue);
            [invocation getReturnValue:aLong];
            finalValue = aLong;
        }
    }
    else if (strcmp(@encode(float), returnType) == 0)
    {
        // the return value is float
        if (sizeOfReturnValue != 0)
        {
            float *aFloat = malloc(sizeOfReturnValue);
            [invocation getReturnValue:aFloat];
            finalValue = aFloat;
        }
    }
    else if (strcmp(@encode(double), returnType) == 0)
    {
        // the return value is double
        if (sizeOfReturnValue != 0)
        {
            double *aDouble = malloc(sizeOfReturnValue);
            [invocation getReturnValue:aDouble];
            finalValue = aDouble;
        }
    }
    else if (strcmp(@encode(CGRect), returnType) == 0)
    {
        // the return value is double
        if (sizeOfReturnValue != 0)
        {
            CGRect *aRect = malloc(sizeOfReturnValue);
            [invocation getReturnValue:aRect];
            finalValue = aRect;
        }
    }
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

@end
