#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/runtime.h>

#import "Fonts.h"
#import "LoaderConfig.h"
#import "Logger.h"
#import "RCTInstance.h"
#import "RCTCxxBridge.h"
#import "Settings.h"
#import "Themes.h"
#import "Utils.h"

static NSURL         *sourceUrl;
static NSString      *bunnyPatchesBundlePath;
static NSURL         *pyoncordDirectory;
static LoaderConfig  *loaderConfig;
static NSTimeInterval shakeStartTime = 0;
static BOOL           isShaking      = NO;
id                    gBridge        = nil;

static id createRCTSource(NSURL *url, NSData *data)
{
    Class RCTSourceClass = NSClassFromString(@"RCTSource");
    if (!RCTSourceClass)
    {
        BunnyLog(@"RCTSource class not found in runtime");
        return nil;
    }

    // Try RCTSourceCreate if available as an exported C function
    typedef id (*RCTSourceCreateFunc)(NSURL *, NSData *, int64_t);
    RCTSourceCreateFunc rctSourceCreate =
        (RCTSourceCreateFunc) dlsym(RTLD_DEFAULT, "RCTSourceCreate");
    if (rctSourceCreate)
    {
        return rctSourceCreate(url, data, (int64_t) data.length);
    }

    // Fallback: instantiate via alloc and set properties via KVC / ivars
    id newSource = [[RCTSourceClass alloc] init];
    @try
    {
        [newSource setValue:url forKey:@"url"];
        [newSource setValue:data forKey:@"data"];
        [newSource setValue:@(data.length) forKey:@"length"];
    }
    @catch (NSException *e)
    {
        BunnyLog(@"Failed to set RCTSource properties via KVC: %@", e);
        Ivar urlIvar = class_getInstanceVariable(RCTSourceClass, "_url");
        if (urlIvar) object_setIvar(newSource, urlIvar, url);
        Ivar dataIvar = class_getInstanceVariable(RCTSourceClass, "_data");
        if (dataIvar) object_setIvar(newSource, dataIvar, data);
    }
    return newSource;
}

static NSArray<NSData *> *prepareInjectionScripts(void)
{
    NSMutableArray<NSData *> *scripts = [NSMutableArray array];

    NSBundle *bunnyPatchesBundle = [NSBundle bundleWithPath:bunnyPatchesBundlePath];
    if (!bunnyPatchesBundle)
    {
        BunnyLog(@"Failed to load BunnyPatches bundle from path: %@", bunnyPatchesBundlePath);
        showErrorAlert(@"Loader Error",
                       @"Failed to initialize mod loader. Please reinstall the tweak.", nil);
        return scripts;
    }

    NSURL *patchPath = [bunnyPatchesBundle URLForResource:@"payload-base" withExtension:@"js"];
    if (!patchPath)
    {
        BunnyLog(@"Failed to find payload-base.js in bundle");
        showErrorAlert(@"Loader Error",
                       @"Failed to initialize mod loader. Please reinstall the tweak.", nil);
        return scripts;
    }

    NSData *patchData = [NSData dataWithContentsOfURL:patchPath];
    if (patchData)
    {
        [scripts addObject:patchData];
    }

    __block NSData *bundle =
        [NSData dataWithContentsOfURL:[pyoncordDirectory URLByAppendingPathComponent:@"bundle.js"]];

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);

    NSURL *bundleUrl;
    if (loaderConfig.customLoadUrlEnabled && loaderConfig.customLoadUrl)
    {
        bundleUrl = loaderConfig.customLoadUrl;
        BunnyLog(@"Using custom load URL: %@", bundleUrl.absoluteString);
    }
    else
    {
        bundleUrl = [NSURL
            URLWithString:@"https://github.com/revenge-mod/revenge-bundle/releases/latest/download/revenge.js"];
        BunnyLog(@"Using default bundle URL: %@", bundleUrl.absoluteString);
    }

    NSMutableURLRequest *bundleRequest =
        [NSMutableURLRequest requestWithURL:bundleUrl
                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                            timeoutInterval:3.0];

    NSString *bundleEtag = [NSString
        stringWithContentsOfURL:[pyoncordDirectory URLByAppendingPathComponent:@"etag.txt"]
                       encoding:NSUTF8StringEncoding
                          error:nil];
    if (bundleEtag && bundle)
    {
        [bundleRequest setValue:bundleEtag forHTTPHeaderField:@"If-None-Match"];
    }

    NSURLSession *session = [NSURLSession
        sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session
        dataTaskWithRequest:bundleRequest
          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
              if ([response isKindOfClass:[NSHTTPURLResponse class]])
              {
                  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                  if (httpResponse.statusCode == 200 && data.length > 0)
                  {
                      bundle = data;
                      [bundle
                          writeToURL:[pyoncordDirectory URLByAppendingPathComponent:@"bundle.js"]
                          atomically:YES];

                      NSString *etag = [httpResponse.allHeaderFields objectForKey:@"Etag"];
                      if (etag)
                      {
                          [etag
                              writeToURL:[pyoncordDirectory URLByAppendingPathComponent:@"etag.txt"]
                              atomically:YES
                                encoding:NSUTF8StringEncoding
                                   error:nil];
                      }
                  }
              }
              dispatch_group_leave(group);
          }] resume];

    // Wait at most 3.5 seconds to avoid freezing app launch indefinitely
    dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 3.5 * NSEC_PER_SEC));

    NSData *themeData =
        [NSData dataWithContentsOfURL:[pyoncordDirectory
                                          URLByAppendingPathComponent:@"current-theme.json"]];
    if (themeData)
    {
        NSError      *jsonError = nil;
        NSDictionary *themeDict = [NSJSONSerialization JSONObjectWithData:themeData
                                                                  options:0
                                                                    error:&jsonError];
        if (!jsonError && [themeDict isKindOfClass:[NSDictionary class]])
        {
            BunnyLog(@"Loading theme data...");
            if (themeDict[@"data"] && [themeDict[@"data"] isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *data = themeDict[@"data"];
                if (data[@"semanticColors"] && data[@"rawColors"])
                {
                    BunnyLog(@"Initializing theme colors from theme data");
                    initializeThemeColors(data[@"semanticColors"], data[@"rawColors"]);
                }
            }

            NSString *themeJsonStr = [[NSString alloc] initWithData:themeData
                                                           encoding:NSUTF8StringEncoding];
            if (themeJsonStr)
            {
                NSString *jsCode =
                    [NSString stringWithFormat:@"globalThis.__PYON_LOADER__.storedTheme=%@;",
                                               themeJsonStr];
                NSData *themeJsData = [jsCode dataUsingEncoding:NSUTF8StringEncoding];
                if (themeJsData)
                {
                    [scripts addObject:themeJsData];
                }
            }
        }
        else
        {
            BunnyLog(@"Error parsing theme JSON: %@", jsonError);
        }
    }
    else
    {
        BunnyLog(@"No theme data found at path: %@",
                 [pyoncordDirectory URLByAppendingPathComponent:@"current-theme.json"]);
    }

    NSData *fontData = [NSData
        dataWithContentsOfURL:[pyoncordDirectory URLByAppendingPathComponent:@"fonts.json"]];
    if (fontData)
    {
        NSError      *jsonError = nil;
        NSDictionary *fontDict  = [NSJSONSerialization JSONObjectWithData:fontData
                                                                 options:0
                                                                   error:&jsonError];
        if (!jsonError && [fontDict isKindOfClass:[NSDictionary class]] && fontDict[@"main"])
        {
            BunnyLog(@"Found font configuration, applying...");
            patchFonts(fontDict[@"main"], fontDict[@"name"]);
        }
    }

    if (bundle && bundle.length > 0)
    {
        BunnyLog(@"Adding JS bundle to injection queue (%lu bytes)", (unsigned long) bundle.length);
        [scripts addObject:bundle];
    }
    else
    {
        BunnyLog(@"Warning: No bundle data available to inject");
    }

    NSURL *preloadsDirectory = [pyoncordDirectory URLByAppendingPathComponent:@"preloads"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:preloadsDirectory.path])
    {
        NSError *error = nil;
        NSArray *contents =
            [[NSFileManager defaultManager] contentsOfDirectoryAtURL:preloadsDirectory
                                          includingPropertiesForKeys:nil
                                                             options:0
                                                               error:&error];
        if (!error && contents)
        {
            for (NSURL *fileURL in contents)
            {
                if ([[fileURL pathExtension] isEqualToString:@"js"])
                {
                    BunnyLog(@"Adding preload JS file %@", fileURL.absoluteString);
                    NSData *data = [NSData dataWithContentsOfURL:fileURL];
                    if (data)
                    {
                        [scripts addObject:data];
                    }
                }
            }
        }
        else
        {
            BunnyLog(@"Error reading contents of preloads directory");
        }
    }

    return scripts;
}

%group Bridgeless

%hook RCTInstance

- (void)_loadScriptFromSource:(id)source
{
    NSURL *url = nil;
    @try
    {
        url = [source valueForKey:@"url"];
    }
    @catch (NSException *e)
    {
        BunnyLog(@"Could not get URL from source: %@", e);
    }

    if (!url || ![url.absoluteString containsString:@"main.jsbundle"])
    {
        return %orig(source);
    }

    gBridge = self;
    BunnyLog(@"Stored RCTInstance bridge reference: %@", gBridge);

    NSArray<NSData *> *scripts = prepareInjectionScripts();
    for (NSData *scriptData in scripts)
    {
        id patchSource = createRCTSource(sourceUrl, scriptData);
        if (patchSource)
        {
            BunnyLog(@"Injecting script via RCTInstance (_loadScriptFromSource:) (size: %lu)",
                     (unsigned long) scriptData.length);
            %orig(patchSource);
        }
    }

    BunnyLog(@"Executing original main.jsbundle via RCTInstance (_loadScriptFromSource:)");
    %orig(source);
}

%end

%end

%group BridgelessNoUnderscore

%hook RCTInstance

- (void)loadScriptFromSource:(id)source
{
    NSURL *url = nil;
    @try
    {
        url = [source valueForKey:@"url"];
    }
    @catch (NSException *e)
    {
        BunnyLog(@"Could not get URL from source: %@", e);
    }

    if (!url || ![url.absoluteString containsString:@"main.jsbundle"])
    {
        return %orig(source);
    }

    gBridge = self;
    BunnyLog(@"Stored RCTInstance bridge reference: %@", gBridge);

    NSArray<NSData *> *scripts = prepareInjectionScripts();
    for (NSData *scriptData in scripts)
    {
        id patchSource = createRCTSource(sourceUrl, scriptData);
        if (patchSource)
        {
            BunnyLog(@"Injecting script via RCTInstance (loadScriptFromSource:) (size: %lu)",
                     (unsigned long) scriptData.length);
            %orig(patchSource);
        }
    }

    BunnyLog(@"Executing original main.jsbundle via RCTInstance (loadScriptFromSource:)");
    %orig(source);
}

%end

%end

%group LegacyBridge

%hook RCTCxxBridge

- (void)executeApplicationScript:(NSData *)script url:(NSURL *)url async:(BOOL)async
{
    if (![url.absoluteString containsString:@"main.jsbundle"])
    {
        return %orig(script, url, async);
    }

    gBridge = self;
    BunnyLog(@"Stored RCTCxxBridge bridge reference: %@", gBridge);

    NSArray<NSData *> *scripts = prepareInjectionScripts();
    for (NSData *scriptData in scripts)
    {
        BunnyLog(@"Injecting script via RCTCxxBridge (size: %lu)", (unsigned long) scriptData.length);
        %orig(scriptData, sourceUrl, YES);
    }

    BunnyLog(@"Executing original main.jsbundle via RCTCxxBridge");
    %orig(script, url, async);
}

%end

%end

%hook UIWindow

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        isShaking      = YES;
        shakeStartTime = [[NSDate date] timeIntervalSince1970];
    }
    %orig;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake && isShaking)
    {
        NSTimeInterval currentTime   = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval shakeDuration = currentTime - shakeStartTime;

        if (shakeDuration >= 0.3 && shakeDuration <= 3.0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{ showSettingsSheet(); });
        }
        isShaking = NO;
    }
    %orig;
}

%end

%ctor
{
    @autoreleasepool
    {
        sourceUrl = [NSURL URLWithString:@"bunny"];

        NSString *install_prefix = @"/var/jb";
        isJailbroken             = [[NSFileManager defaultManager] fileExistsAtPath:install_prefix];

        NSString *lumiBundlePath =
            [NSString stringWithFormat:@"%@/Library/Application Support/LumiCordResources.bundle",
                                       install_prefix];
        NSString *bunnyBundlePath =
            [NSString stringWithFormat:@"%@/Library/Application Support/BunnyResources.bundle",
                                       install_prefix];
        NSString *bundlePath =
            [[NSFileManager defaultManager] fileExistsAtPath:lumiBundlePath] ? lumiBundlePath : bunnyBundlePath;
        BunnyLog(@"Is jailbroken: %d", isJailbroken);
        BunnyLog(@"Bundle path for jailbroken: %@", bundlePath);

        NSString *lumiJailedPath = [[NSBundle mainBundle].bundlePath
            stringByAppendingPathComponent:@"LumiCordResources.bundle"];
        NSString *bunnyJailedPath = [[NSBundle mainBundle].bundlePath
            stringByAppendingPathComponent:@"BunnyResources.bundle"];
        NSString *jailedPath =
            [[NSFileManager defaultManager] fileExistsAtPath:lumiJailedPath] ? lumiJailedPath : bunnyJailedPath;
        BunnyLog(@"Bundle path for jailed: %@", jailedPath);
        BunnyLog(@"Selected bundle path: %@", bunnyPatchesBundlePath);

        BOOL bundleExists =
            [[NSFileManager defaultManager] fileExistsAtPath:bunnyPatchesBundlePath];
        BunnyLog(@"Bundle exists at path: %d", bundleExists);

        NSError *error = nil;
        NSArray *bundleContents =
            [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bunnyPatchesBundlePath
                                                                error:&error];
        if (error)
        {
            BunnyLog(@"Error listing bundle contents: %@", error);
        }
        else
        {
            BunnyLog(@"Bundle contents: %@", bundleContents);
        }

        pyoncordDirectory = getPyoncordDirectory();
        loaderConfig      = [[LoaderConfig alloc] init];
        [loaderConfig loadConfig];

        // Detect React Native classes available in the runtime
        Class rctBridgeClass   = objc_getClass("RCTCxxBridge");
        Class rctInstanceClass = objc_getClass("RCTInstance");

        BunnyLog(@"Runtime class detection - RCTCxxBridge: %@, RCTInstance: %@",
                 rctBridgeClass ? @"Found" : @"Not found",
                 rctInstanceClass ? @"Found" : @"Not found");

        if (rctInstanceClass)
        {
            if (class_getInstanceMethod(rctInstanceClass, @selector(loadScriptFromSource:)))
            {
                BunnyLog(@"Initializing BridgelessNoUnderscore hook (loadScriptFromSource:)");
                %init(BridgelessNoUnderscore);
            }
            else
            {
                BunnyLog(@"Initializing Bridgeless hook (_loadScriptFromSource:)");
                %init(Bridgeless);
            }
        }

        if (rctBridgeClass)
        {
            BunnyLog(@"Initializing LegacyBridge hook (RCTCxxBridge)");
            %init(LegacyBridge);
        }

        // Initialize default (ungrouped) hooks like UIWindow
        %init;
    }
}
