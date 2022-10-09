//
//  SceneDelegate.m
//  iSH
//
//  Created by Theodore Dubois on 10/26/19.
//

#import "SceneDelegate.h"
#import "TerminalViewController.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.windowScene = (UIWindowScene *)scene;

    TerminalViewController *vc = [[TerminalViewController alloc] init];
    self.window.rootViewController = vc;

//    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    NSLog(@"+++++++++++++++++++++++++++++++++++++++++++++++++++   willConnectToSession");
}

@end
