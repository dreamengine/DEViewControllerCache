//
//  DEViewControllerCache.h
//
//
//  Created by Jeremy Flores on 3/24/14.
//  Copyright (c) 2014 Dream Engine Interactive, Inc. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIViewController (DEViewControllerCacheReuse)

/*
 
 Optional method. Notifies the view controller that it will be reused, providing the ability to, e.g., reset the user interface so it appears in some default state.
 
 
 If a UIViewController being cached by DEViewControllerCache implements this method, it will be called when an instance of that UIViewController will be reused (that is, -controllerForClass: will return that instance for at least the second time). Note that this method will only be called if the instance was already cached and is currently unused.
 
 */
-(void)willBeReused;

@end


@interface DEViewControllerCache : NSObject


#pragma mark - Default Cache

+(instancetype)defaultCache;


#pragma mark - Cache Handling

/*
 
 An instance of a view controller is considered to be currently in use if any of the following are true:
 
 * the controller has a loaded view and that view has superview,
 * the controller has a parent view controller,
 * the controller has a presenting view controller, or
 * the controller has a navigation controller.
 
 Otherwise, a view controller instance is considered to be currently unused.
 
 An instance of a view controller is said to be reused if both of the following are true:
 
 * the instance is already in the cache (i.e. it was previously--but no longer is--in use), and
 * the instance will soon be in use (i.e. it is about to be returned by -controllerForControllerClass:).

 */

/*
 
 Returns an instance of the requested controller class. If an instance is already in the cache and it is currently unused, then that instance will be returned and that instance is considered to be reused. Otherwise, no instances are available for that class, so a new view controller object is instantiated using UIViewController+DEConveniences and added to the cache.
 
 If this method will return a reused instance (as defined above), it will first call -willBeReused on the view controller instance if it can respond to that selector.
 
 Once the controller instance is no longer needed by your application code, the instance should then be updated so that it is considered unused. If adhering to normal user interface lifecycles (e.g. pushing/popping a controller in a navigation stack), the unused state should occur automatically.
 
 It is expected that controllers returned from this method are immediately set up so that they are considered to be in use (as defined above). Otherwise, the same instance may be returned when calling this method more than once with the same class.
 
 */
-(id)controllerForClass:(Class)controllerClass;


#pragma mark - Cache Reduction

/*
 
 Forces removal of object from cache.
 
 */
-(void)removeControllerFromCache:(UIViewController *)controller;

/*
 
 Forces removal of all instances of the provided controller class from the cache.
 
 */
-(void)removeClassInstancesFromCache:(Class)controllerClass;

/*
 
 Forces removal of all instances of all controller classes from the cache.
 
 */
-(void)emptyCache;


#pragma mark - Default Cache Convenience Methods

+(id)controllerForClass:(Class)controllerClass;

+(void)removeControllerFromCache:(UIViewController *)controller;

+(void)removeClassInstancesFromCache:(Class)controllerClass;

+(void)emptyCache;

@end
