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


@implementation UIViewController (DEViewControllerCacheReuse)

// fill out in subclass
-(void)willBeReused {
}

@end


@interface DEViewControllerInternalCache : NSCache
@end

@implementation DEViewControllerInternalCache

// from: http://stackoverflow.com/a/19549090/708798
-(id)init {
    if (self=[super init]) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver: self
               selector: @selector(removeAllObjects)
                   name: UIApplicationDidReceiveMemoryWarningNotification
                 object: nil];
    }
    
    return self;
}

-(void)dealloc {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

@end


// custom class so we can identify whether or not a repopulation operation has already been enqueued for the next run loop iteration
@interface DERepopulationBlockOperation : NSBlockOperation
@end

@implementation DERepopulationBlockOperation
@end


@interface DEViewControllerCache () <NSCacheDelegate>

@property (readonly, strong, nonatomic) DEViewControllerInternalCache *cache;

@property (strong, nonatomic) NSMutableDictionary *repopulationDictionary;

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

-(void)emptyCache {
    [self.cache removeAllObjects];
    [self.repopulationDictionary removeAllObjects];
}


#pragma mark - NSCacheDelegate

-(void)cache:(NSCache *)cache willEvictObject:(id)obj {
    if ([obj isKindOfClass:[NSMutableSet class]]) {
        NSMutableSet *instances = (NSMutableSet *)obj;

        [self removeUnusedControllersFromInstances:instances];

        if (instances.count > 0) {
            Class controllerClass = [[instances anyObject] class];
            self.repopulationDictionary[(id<NSCopying>)controllerClass] = instances;
        }
    }
    
    if (self.repopulationDictionary.count > 0) {
        // check to make sure we don't have a repopulation operation already enqueued since this -cache:willEvictObject: may be called multiple times per run loop iteration
        NSArray *operations = [[NSOperationQueue mainQueue] operations];

        BOOL containsRepopulationOperation = NO;

        for (NSOperation *operation in operations) {
            if ([operation isKindOfClass:[DERepopulationBlockOperation class]]) {
                containsRepopulationOperation = YES;
            }
        }

        if (!containsRepopulationOperation) {
            __weak DEViewControllerCache *weakSelf = self;
            DERepopulationBlockOperation *repopulationOperation = [DERepopulationBlockOperation blockOperationWithBlock: ^{
                [weakSelf repopulateCache];
            }];

            // we can't control whether or not an object should be evicted, so wait until the next run loop iteration and then repopulate the cache from our repopulation dictionary.
            [[NSOperationQueue mainQueue] addOperation:repopulationOperation];
        }
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


#pragma mark - Repopulation

-(void)repopulateCache {
    for (Class controllerClass in self.repopulationDictionary) {
        NSMutableSet *repopulationInstances = self.repopulationDictionary[(id<NSCopying>)controllerClass];

        // remove any repopulation instances that should no longer be cached
        [self removeUnusedControllersFromInstances:repopulationInstances];

        // in the event that a controller was requested before this method was called, get the set of those controllers which are now in the cache
        NSMutableSet *instances = [self instancesForControllerClass:controllerClass];

        // merge the recently-cached instances with the repopulation instances
        [instances unionSet:repopulationInstances];
    }

    [self.repopulationDictionary removeAllObjects];
}


#pragma mark - Lazy Loading

-(DEViewControllerInternalCache *)cache {
    if (!_cache) {
        _cache = [DEViewControllerInternalCache new];
        _cache.delegate = self;
    }

    return _cache;
}

-(NSMutableDictionary *)repopulationDictionary {
    if (!_repopulationDictionary) {
        _repopulationDictionary = [NSMutableDictionary dictionary];
    }
    
    return _repopulationDictionary;
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

+(void)emptyCache {
    [[self defaultCache] emptyCache];
}

@end
