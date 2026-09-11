#import <Foundation/Foundation.h>

@class RCTSource;

@interface RCTInstance : NSObject
- (void)_loadScriptFromSource:(id)source;
- (void)loadScriptFromSource:(id)source;
@end

@interface RCTSource : NSObject
@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, copy, readonly) NSData *data;
@property (nonatomic, assign, readonly) NSUInteger length;
@property (nonatomic, copy, readonly) NSDictionary *files;
@end
