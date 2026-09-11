#import <AuthenticationServices/AuthenticationServices.h>
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <dlfcn.h>

#import "Logger.h"
#import "Utils.h"

typedef NS_ENUM(NSInteger, BundleIDError) {
    BundleIDErrorIcon,
    BundleIDErrorPasskey
};

static void showBundleIDError(BundleIDError error)
{
    NSString *message;
    NSString *title;
    void (^completion)(void) = nil;

    switch (error)
    {
        case BundleIDErrorIcon:
            message = @"For this to work change the Bundle ID so that it matches your "
                      @"provisioning profile's App ID (excluding the Team ID prefix).";
            title   = @"Cannot Change Icon";
            break;
        case BundleIDErrorPasskey:
            message    = @"Passkeys are not supported when sideloading Discord. "
                         @"Please use a different login method.";
            title      = @"Cannot Use Passkey";
            completion = ^{ exit(0); };
            break;
    }

    showErrorAlert(title, message, completion);
}

%group Sideloading

%hook NSFileManager
- (NSURL *)containerURLForSecurityApplicationGroupIdentifier:(NSString *)groupIdentifier
{
    BunnyLog(@"containerURLForSecurityApplicationGroupIdentifier called! %@",
             groupIdentifier ?: @"nil");

    NSArray *paths    = [self URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL   *lastPath = [paths lastObject];
    NSURL   *appGroupURL = [lastPath URLByAppendingPathComponent:@"AppGroup"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appGroupURL.path])
    {
        [[NSFileManager defaultManager] createDirectoryAtURL:appGroupURL
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:nil];
    }
    return appGroupURL;
}
%end

%hook UIApplication
- (void)setAlternateIconName:(NSString *)iconName completionHandler:(void (^)(NSError *))completion
{
    void (^wrappedCompletion)(NSError *) = ^(NSError *error) {
        if (error)
        {
            showBundleIDError(BundleIDErrorIcon);
        }

        if (completion)
        {
            completion(error);
        }
    };

    %orig(iconName, wrappedCompletion);
}
%end

// https://github.com/khanhduytran0/LiveContainer/blob/main/TweakLoader/DocumentPicker.m
%hook UIDocumentPickerViewController

- (instancetype)initForOpeningContentTypes:(NSArray<UTType *> *)contentTypes asCopy:(BOOL)asCopy
{
    BOOL shouldMultiselect = NO;
    if ([contentTypes count] == 1 && contentTypes[0] == UTTypeFolder)
    {
        shouldMultiselect = YES;
    }

    NSArray<UTType *> *contentTypesNew = @[ UTTypeItem, UTTypeFolder ];

    UIDocumentPickerViewController *ans = %orig(contentTypesNew, YES);
    if (shouldMultiselect)
    {
        [ans setAllowsMultipleSelection:YES];
    }
    return ans;
}

- (instancetype)initWithDocumentTypes:(NSArray<UTType *> *)contentTypes inMode:(NSUInteger)mode
{
    return [self initForOpeningContentTypes:contentTypes asCopy:(mode == 1 ? NO : YES)];
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    if ([self allowsMultipleSelection])
    {
        return;
    }
    %orig(YES);
}

%end

%hook UIDocumentBrowserViewController

- (instancetype)initForOpeningContentTypes:(NSArray<UTType *> *)contentTypes
{
    NSArray<UTType *> *contentTypesNew = @[ UTTypeItem, UTTypeFolder ];
    return %orig(contentTypesNew);
}

%end

%hook NSURL

- (BOOL)startAccessingSecurityScopedResource
{
    %orig;
    return YES;
}

%end

%hook ASAuthorizationController

- (void)performRequests
{
    showBundleIDError(BundleIDErrorPasskey);
}

%end

%end

%ctor
{
    @autoreleasepool
    {
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        BOOL isAppStoreApp =
            receiptURL && [[NSFileManager defaultManager] fileExistsAtPath:receiptURL.path];
        if (!isAppStoreApp)
        {
            %init(Sideloading);
        }
    }
}
