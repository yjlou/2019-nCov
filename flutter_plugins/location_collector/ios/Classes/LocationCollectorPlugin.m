#import "LocationCollectorPlugin.h"
#if __has_include(<location_collector/location_collector-Swift.h>)
#import <location_collector/location_collector-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "location_collector-Swift.h"
#endif

@implementation LocationCollectorPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLocationCollectorPlugin registerWithRegistrar:registrar];
}
@end
