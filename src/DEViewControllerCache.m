//
//  DEViewControllerCache.m
//
//
//  Created by Jeremy Flores on 3/24/14.
//  Copyright (c) 2014 Dream Engine Interactive, Inc.
//  http://dreamengine.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "DEViewControllerCache.h"

#import "UIViewController+DEConveniences.h"

#import "OSCache.h"


@implementation UIViewController (DEViewControllerCacheReuse)

// fill out in subclass
-(void)willBeReused {
}

@end


// custom class so we can identify whether or not a repopulation operation has already been enqueued for the next run loop iteration
@interface DERepopulationBlockOperation : NSBlockOperation
@end

@implementation DERepopulationBlockOperation
@end


@interface DEViewControllerCache () <NSCacheDelegate>

@property (readonly, strong, nonatomic) OSCache *cache;

@end


@implementation DEViewControllerCache

@synthesize cache = _cache;


#pragma mark - Initializer

-(id)init {
    if (self=[super init]) {
    }
    
    return self;
}


#pragma mark - Default Cache

+(instancetype)defaultCache {
    static DEViewControllerCache *defaultCache = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultCache = [[[self class] alloc] init];
    });

    return defaultCache;
}


#pragma mark - Cache Handling

-(NSMutableSet *)instancesForControllerClass:(Class)controllerClass {
    NSMutableSet *instances = [self.cache objectForKey:controllerClass];

    if (!instances) {
        instances = [NSMutableSet set];
        [self.cache setObject: instances
                       forKey: controllerClass];
    }

    return instances;
}

-(id)controllerForClass:(Class)controllerClass {
    NSMutableSet *instances = [self instancesForControllerClass:controllerClass];

    UIViewController *controller = nil;

    for (UIViewController *instance in instances) {
        if (![self isControllerInUse:instance]) {
            controller = instance;
            if ([controller respondsToSelector:@selector(willBeReused)]) {
                [controller willBeReused];
            }
            break;
        }
    }

    if (!controller) {
        controller = [controllerClass controller];
        [instances addObject:controller];
    }

    return controller;
}


#pragma mark - Cache Reduction

-(void)removeControllerFromCache:(UIViewController *)controller {
    NSMutableSet *instances = [self instancesForControllerClass:controller.class];
    [instances removeObject:controller];
}

-(void)removeClassInstancesFromCache:(Class)controllerClass {
    [self.cache removeObjectForKey:controllerClass];
}

-(void)removeAllClassInstancesFromCache {
    [self.cache removeAllObjects];
}


#pragma mark - NSCacheDelegate

-(BOOL)cache:(NSCache *)cache shouldEvictObject:(id)entry {
    NSMutableSet *instances = [entry object];
    [self removeUnusedControllersFromInstances:instances];
    
    if (instances.count > 0) {
        return NO;
    }
    else {
        return YES;
    }
}


#pragma mark - Instance Pruning

-(void)removeUnusedControllersFromInstances:(NSMutableSet *)instances {
    NSMutableSet *removalSet = [NSMutableSet setWithCapacity:instances.count];

    for (UIViewController *instance in instances) {
        if (![self isControllerInUse:instance]) {
            [removalSet addObject:instance];
        }
    }

    [instances minusSet:removalSet];
}


#pragma mark - Lazy Loading

-(OSCache *)cache {
    if (!_cache) {
        _cache = [OSCache new];
        _cache.delegate = self;
    }

    return _cache;
}


#pragma mark - Is Controller in Use

-(BOOL)isControllerInUse:(UIViewController *)controller {
    if ((controller.isViewLoaded && controller.view.superview) ||
        controller.parentViewController ||
        controller.presentingViewController ||
        controller.navigationController) {
        return YES;
    }
    else {
        return NO;
    }
}


#pragma mark - Default Cache Convenience Methods

+(id)controllerForClass:(Class)controllerClass {
    return [[self defaultCache] controllerForClass:controllerClass];
}

+(void)removeControllerFromCache:(UIViewController *)controller {
    [[self defaultCache] removeControllerFromCache:controller];
}

+(void)removeClassInstancesFromCache:(Class)controllerClass {
    [[self defaultCache] removeClassInstancesFromCache:controllerClass];
}

+(void)removeAllClassInstancesFromCache {
    [[self defaultCache] removeAllClassInstancesFromCache];
}

@end
