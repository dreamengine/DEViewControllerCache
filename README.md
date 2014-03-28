# DEViewControllerCache

[https://github.com/dreamengine/DEViewControllerCache](https://github.com/dreamengine/DEViewControllerCache)

## What It Does

`DEViewControllerCache` is an MIT-licensed cache system that makes `UIViewControllers` reusable. It takes care of recycling objects and automatically instantiates new controller instances when the cache does not have any objects available for recycling (think `-dequeueReusableCellWithIdentifier:` from `UITableViews`). By reducing instantiation events, your app becomes faster and more responsive.

## Definitions

### In Use / Not In Use

An instance of a `UIViewController` is considered to be currently **in use** if any of the following are true:
 
* the controller has a loaded view and that view has superview,
* the controller has a parent view controller,
* the controller has a presenting view controller, or
* the controller has a navigation controller.
 
Otherwise, a view controller instance is considered to be currently **not in use** or **unused**.

### Reuse

An instance of a `UIViewController` is said to be **preparing for reuse** if both of the following are true:
 
 * the instance is already in the cache (i.e. it was previously--but no longer is--in use), and
 * the instance will soon be in use (i.e. it is about to be returned by `-controllerForControllerClass:`).

### Repopulation Event

`DEViewControllerCache` uses a custom `NSCache` object that is also sensitive to low memory warnings. The cache will automatically evict items as memory constraints increase, which means you don't have to worry about `DEViewControllerCache's` caching strategies.

`DEViewControllerCache` has a more intelligent eviction process than `NSCache` provides: if a controller is evicted and the controller is currently in use, then that controller will be re-added in the next run loop iteration. Because the controller is in use, it is therefore already in memory and will remain there, so the cache simply re-acquires the object reference. `DEViewControllerCache` will retain a reference to that controller until it is added back into the cache. Such a process is referred to as a **repopulation event**.

(Due to the limitations of the `NSCache` implementation, we cannot simply prevent certain items from being evicted from the cache, hence the repopulation approach.)

Note that a repopulation event will not occur if the evicted controller is currently not in use.

## How It Works

### Default Cache

`DEViewControllerCache` comes with a default static instance. This can be accessed using `+defaultCache`. For every instance method, there is an equivalent class method for convenience (e.g. calling `+controllerForClass:` is equivalent to calling `[[DEViewControllerCache defaultCache] controllerForClass:]`).

If more complex caching schemes are needed, you can simply ignore this singleton and create multiple instances of `DEViewControllerCache`.

### Accessing UIViewControllers

To retrieve an instance of a `UIViewController` subclass, use `-controllerForClass:` and pass in the subclass's `Class` for the parameter.

If an instance is already in the cache and it is currently unused, then that instance will be returned and it is considered to be reused. Otherwise, no instances are available for that class, so a new view controller object is automatically instantiated (see **Automatic Instantiation** below).

If `-controllerForClass:` will return a reused instance, it will first call `-willBeReused` on the view controller instance if it can respond to that selector. (See **UIViewController Category** below.)

It is expected that controllers returned from `-controllerForClass:` are immediately set up so that they are considered to be in use. Otherwise, the same instance may be returned when calling `-controllerForClass:` again with the same class.
 
Once the controller instance is no longer needed by your application code, the instance should then be updated so that it is considered unused. If your application adheres to normal user interface lifecycles (e.g. pushing/popping a controller in a navigation stack), the unused state should occur automatically.

#### Example

	#import "MyViewController.h"
	
	@implementation MenuController
	
	-(IBAction)buttonTapped {
		MyViewController *controller = [DEViewControllerCache controllerForClass:MyViewController.class];

		// customize/provide data to the controller as necessary
		controller.date = [NSDate date];

		[self.navigationController pushViewController:controller animated:YES];
	}
	
	@end
	
### Automatic Instantiation

`DEViewControllerCache` will automatically instantiate a controller if the cache does not have an object of the same subclass already available. To accomplish this, `DEViewControllerCache` requires that the `UIViewController` subclass either uses a nib with a matching filename (e.g. MyCustomViewController.xib for MyCustomViewController) or that the subclass has a programmatically-defined user interface (i.e. no nibs at all). This is accomplished using `UIViewController+DEConveniences`.

### UIViewController Category

When a `UIViewController` instance is going to be reused, it may sometimes make sense to clean up the instance before displaying it to the user again. For example, if a login controller instance has username and password `UITextFields` that have previously been filled in, those fields should first be cleared before displaying the controller again.

To utilize this feature, simply add a method `-willBeReused` to your controllers and perform whatever necessary cleanup in there. `DEViewControllerCache` will call that method when the reused controller is about to be returned from `-controllerForClass:`.

Note that `-willBeReused` will **not** be called when the controller is first instantiated and returned from `-controllerForClass:`. It will only be invoked when the controller is going to returned from `-controllerForClass:` for the second time or thereafter.

Also note that `-willBeReused` is an optional method, so `DEViewControllerCache` does not require that cached controllers have this method.

#### Example

	@implementation MyLoginViewController

	-(void)willBeReused {
		// not necessary to call super if your controller is a direct subclass of UIViewController,
		// but could be useful if you have deeper inheritance chains
		[super willBeReused];

		self.usernameField.text = @"";
		self.passwordField.text = @"";
		
		self.usernameField.enabled = YES;
		self.usernameField.enabled = YES;
	}
	
	@end

### Manual Cache Management

There may be situations where your application needs to manually remove items from the cache to reduce overall memory overhead. `DEViewControllerCache` provides three tiers of manual cache management.

The first tier is instance specific. To remove a particular instance from a cache, use `-removeControllerFromCache:`.

The second tier is class specific. To remove all instances of a particular `UIViewController` subclass from a cache, use `-removeClassInstancesFromCache:`.

The third tier is cache specific. To remove all instances of all `UIViewController` subclasses from a cache, use `removeAllClassInstancesFromCache`.

Note that these methods will not trigger a repopulation event, so it is guaranteed that manually removing a controller that is currently in use will actually remove it from the cache system.

Also, in the event that calling any of these methods occurs while a repopulation event is in process (i.e. the controller(s) you have requested to be removed from the cache are currently not in the cache but pending repopulation), the controller objects will simply be removed from the repopulation process and, by extent, from the cache system.

#### Example

	#import "MyViewController.h"
	
	@interface MenuController ()
	
	@property (strong, nonatomic) MyViewController *myViewController;
	
	@end
	
	@implementation MenuController

	-(void)someMethod {
		// remove a controller instance from the cache
		[DEViewControllerCache removeControllerFromCache:self.myViewController];
		
		// remove all controller instances of a class from the cache
		[DEViewControllerCache removeClassInstancesFromCache:MyViewController.class];
		
		// remove all controller instances of all classes from the cache
		[DEViewControllerCache removeAllClassInstancesFromCache];
	}
	
	@end