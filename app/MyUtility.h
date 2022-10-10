//
//  MyUtility.h
//  iSH
//
//  Created by pcl on 10/10/22.
//

#import <Foundation/Foundation.h>

#import "Terminal.h"

NS_ASSUME_NONNULL_BEGIN



@interface MyUtility : NSObject

+ (int)boot;
+ (int)startSession;

@end

static Terminal *myutility_terminal;

NS_ASSUME_NONNULL_END
