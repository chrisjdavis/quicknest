//
//  RFKeychain.m
//  EISENHOWERCommon
//
//  Created by Tim Brückmann on 25.01.13.
//  Copyright (c) 2013 Rheinfabrik. All rights reserved.
//

#import "RFKeychain.h"
#import <Security/Security.h>

@implementation RFKeychain

+ (BOOL)setPassword:(NSString *)password
            account:(NSString *)account
            service:(NSString *)service
{
    NSString *existingPassword = [self passwordForAccount:account service:service];
    
    OSStatus status = noErr;
    
    if (existingPassword) {
        if ([existingPassword isEqualToString:password] == NO) {
            CFMutableDictionaryRef query = [self createDictionaryForService:service account:account];
            NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
            const void *keys[] = { kSecValueData };
            const void *values[] = { (__bridge CFDataRef)passwordData };
            CFDictionaryRef attributesToUpdate = CFDictionaryCreate(NULL,
                                                                    keys,
                                                                    values,
                                                                    sizeof(keys) / sizeof(*keys),
                                                                    &kCFTypeDictionaryKeyCallBacks,
                                                                    &kCFTypeDictionaryValueCallBacks);

            status = SecItemUpdate(query, attributesToUpdate);
            
            CFRelease(query);
		}
    } else {
        NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
        CFMutableDictionaryRef query = [self createDictionaryForService:service account:account];
        CFDictionarySetValue(query, kSecValueData, (__bridge CFDataRef)passwordData);
        
        status = SecItemAdd(query, NULL);
        
        CFRelease(query);
    }
    
    return status == noErr;
}

+ (NSString *)passwordForAccount:(NSString *)account
                         service:(NSString *)service
{
    CFMutableDictionaryRef query = [self createDictionaryForService:service account:account];
    CFDictionarySetValue(query, kSecReturnData, kCFBooleanTrue);
    
    CFTypeRef result;
    OSStatus status = SecItemCopyMatching(query, &result);
    
    CFRelease(query);
    
    if (status != noErr) {
        return nil;
    }
    
    NSData *resultData = (__bridge_transfer NSData *)result;
    NSString *resultString = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    return resultString;
}

+ (BOOL)deletePasswordForAccount:(NSString *)account
                         service:(NSString *)service
{
    CFMutableDictionaryRef query = [self createDictionaryForService:service account:account];
    
    OSStatus status = SecItemDelete(query);
    
    CFRelease(query);
    
    return (
            status == noErr
            || status == errSecItemNotFound
            );
}

+ (CFMutableDictionaryRef)createDictionaryForService:(NSString *)service
                                             account:(NSString *)account
{
    CFMutableDictionaryRef query = CFDictionaryCreateMutable(NULL,
                                                             0,
                                                             &kCFTypeDictionaryKeyCallBacks,
                                                             &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(query, kSecClass, kSecClassGenericPassword);
    CFDictionarySetValue(query, kSecAttrService, (__bridge CFStringRef)service);
    CFDictionarySetValue(query, kSecAttrAccount, (__bridge CFStringRef)account);
    return query;
}

@end
