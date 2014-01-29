//
//  RFKeychain.h
//  EISENHOWERCommon
//
//  Created by Tim Brückmann on 25.01.13.
//  Copyright (c) 2013 Rheinfabrik. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFKeychain : NSObject

+ (BOOL)setPassword:(NSString *)password
            account:(NSString *)account
            service:(NSString *)service;
+ (NSString *)passwordForAccount:(NSString *)account
                         service:(NSString *)service;
+ (BOOL)deletePasswordForAccount:(NSString *)account
                         service:(NSString *)service;

@end
