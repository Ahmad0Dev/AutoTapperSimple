#import "ATTerms.h"
#import "ATCrypt.h"
#import <Security/Security.h>

@implementation ATTerms

+ (BOOL)hasAccepted {
    // تحقق من Keychain أولاً
    NSDictionary *query = @{
        (__bridge id)kSecClass:            (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:      AT("1b2f2e350e3b2a2a3f28093f282c33393f"),
        (__bridge id)kSecAttrAccount:      AT("393537743b32373b3e3e3f2c743b2f2e352e3b2a2a3f28743b3d283f3f3e"),
        (__bridge id)kSecReturnData:       @YES,
        (__bridge id)kSecMatchLimit:       (__bridge id)kSecMatchLimitOne,
    };
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    
    if (status == errSecSuccess && result) {
        NSData *data = (__bridge_transfer NSData *)result;
        NSString *val = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return [val isEqualToString:AT("3b3d283f3f3e")];
    }
    return NO;
}

+ (void)saveAccepted {
    NSData *data = [AT("3b3d283f3f3e") dataUsingEncoding:NSUTF8StringEncoding];
    
    // حذف القديم أولاً
    NSDictionary *deleteQuery = @{
        (__bridge id)kSecClass:       (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: AT("1b2f2e350e3b2a2a3f28093f282c33393f"),
        (__bridge id)kSecAttrAccount: AT("393537743b32373b3e3e3f2c743b2f2e352e3b2a2a3f28743b3d283f3f3e"),
    };
    SecItemDelete((__bridge CFDictionaryRef)deleteQuery);
    
    // حفظ جديد
    NSDictionary *addQuery = @{
        (__bridge id)kSecClass:                   (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:             AT("1b2f2e350e3b2a2a3f28093f282c33393f"),
        (__bridge id)kSecAttrAccount:             AT("393537743b32373b3e3e3f2c743b2f2e352e3b2a2a3f28743b3d283f3f3e"),
        (__bridge id)kSecValueData:               data,
        (__bridge id)kSecAttrAccessible:          (__bridge id)kSecAttrAccessibleAlways,
    };
    SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
}

+ (void)showIfNeededWithCompletion:(void(^)(BOOL accepted))completion {
    if ([self hasAccepted]) {
        if (completion) completion(YES);
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                win = scene.windows.firstObject;
                break;
            }
        }
        if (!win) { if (completion) completion(NO); return; }

        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:AT("82ee82eb83d282ed7a82fd83de82fd82e982f082f482f582fd83df")
            message:AT("1b2f2e350e3b2a2a3f28101b32373b3e1e3f2c0f2e62343f3f505082f683df83d082e37a82fd83de82f783d883d283d87a83df82f783db83d282e282f374505083d083d583df83dc82e37a82ff82e382fd82f582f37a82f083d282e883d082e37a82f983d27a82f283d082e37a83dd82ea83dd7a82fd83de82f982f582fd82f3745083d083d583df83dc82e37a82fd83de82f082e382f583d083de7a82f983d27a82fd83de83dd83dc82f582e982f37a82fd83de82e383d982e983d082f374505082fd83de82fd82e982f082f482f582fd83df7a82e383de83d37a83df82e982fe83d283de83d082f083d97a82fd83de82ee82f482ef83d082f374")
            preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *agree = [UIAlertAction
            actionWithTitle:AT("82f983d282fd83db83d8")
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *a) {
                [self saveAccepted];
                if (completion) completion(YES);
            }];

        UIAlertAction *decline = [UIAlertAction
            actionWithTitle:AT("82f982eb83db82ec")
            style:UIAlertActionStyleDestructive
            handler:^(UIAlertAction *a) {
                if (completion) completion(NO);
            }];

        [alert addAction:agree];
        [alert addAction:decline];
        [win.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

@end
