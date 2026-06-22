#import <Foundation/Foundation.h>

@class CDKConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface CDKStandardOutputCapture : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithConfiguration:(CDKConfiguration *)configuration NS_DESIGNATED_INITIALIZER;
- (BOOL)startWithError:(NSError * _Nullable * _Nullable)error;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
