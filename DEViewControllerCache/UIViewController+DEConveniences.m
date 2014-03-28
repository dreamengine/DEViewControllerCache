//
//  UIViewController+DEConveniences.m
//
//
//  Created by Jeremy Flores on 5/1/13.
//  Copyright (c) 2013 Dream Engine Interactive, Inc. All rights reserved.
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

#import "UIViewController+DEConveniences.h"

@implementation UIViewController (DEConveniences)

#pragma mark - Convenience Constructors

+(instancetype) controller {
    return [self controllerWithNibName: NSStringFromClass([self class])
                             nibBundle: nil];
}

+(instancetype) controllerWithNibName:(NSString *)nibName {
    return [self controllerWithNibName: nibName
                             nibBundle: nil];
}

+(instancetype) controllerWithNibName: (NSString *)nibName
                            nibBundle: (NSBundle *)nibBundle {
    NSURL *url = [[NSBundle mainBundle] URLForResource: nibName
                                         withExtension: @"nib"];
    BOOL doesNibExist = [url checkResourceIsReachableAndReturnError:nil];
    
    UIViewController *controller = nil;
    if (doesNibExist) {
        controller = [[self alloc] initWithNibName: nibName
                                            bundle: nibBundle];
    }
    else {
        controller = [[self alloc] init];
    }
    
    return controller;
}

#pragma mark - Is Visible

// from: http://stackoverflow.com/a/6529792/708798
-(BOOL) isVisible {
    return self.isViewLoaded && self.view.window;
}

@end
